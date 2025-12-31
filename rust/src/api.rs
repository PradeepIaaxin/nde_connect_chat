use flutter_rust_bridge::frb;
use base64::Engine;
use base64::engine::general_purpose::STANDARD;
use loro::{LoroDoc, ToJson};

use serde_json::{json, Value};
use std::sync::Mutex;
use lazy_static::lazy_static;

// --------------------------------------------------
//  GLOBAL LORO DOCUMENT (Persists across updates)
// --------------------------------------------------
lazy_static! {
    static ref GLOBAL_DOC: Mutex<LoroDoc> = Mutex::new({
        let d = LoroDoc::new();
        // IMPORTANT: initialize movable list
        d.get_movable_list("chatDataList");
        d.get_map("messages");
        d
    });
}

// --------------------------------------------------
//  RESET GLOBAL DOCUMENT (call before snapshot)
// --------------------------------------------------
#[frb]
pub fn reset_global_doc() {
    let mut global = GLOBAL_DOC.lock().unwrap();
    let d = LoroDoc::new();
    d.get_movable_list("chatDataList");
    d.get_map("messages");
    *global = d;
}



#[frb]
pub fn export_chat_snapshot() -> Vec<u8> {
    let doc = GLOBAL_DOC.lock().unwrap();
    doc.export(loro::ExportMode::Snapshot)
        .expect("Snapshot export failed")
}


#[frb]
pub fn export_chat_frontiers() -> Vec<u8> {
    let doc = GLOBAL_DOC.lock().unwrap();

    // ✅ THIS EXISTS IN LORO 1.10.3
    let frontiers = doc.state_frontiers();

    // Frontiers implements Encode
    frontiers.encode()
}



#[frb]
pub fn decode_message_snapshot(snapshot_base64: String) -> String {
    let bytes = STANDARD
        .decode(snapshot_base64)
        .expect("Invalid base64 snapshot");

    let mut global = GLOBAL_DOC.lock().unwrap();

    global.import(&bytes).expect("CRDT import failed");

    let root_json = global
        .get_deep_value()
        .to_json_value();

    let messages_json = match &root_json {
        serde_json::Value::Object(map) => {
            map.get("messages").cloned().unwrap_or(serde_json::Value::Null)
        }
        _ => serde_json::Value::Null,
    };

    json!({ "messages": messages_json }).to_string()
}




#[frb]
pub fn import_message_update(update_bytes: Vec<u8>) -> String {
    let doc = GLOBAL_DOC.lock().unwrap();

    // Apply CRDT update
    doc.import(&update_bytes)
        .expect("CRDT import failed");

    // 🔥 Convert FULL document → JSON
    let root_json = doc
        .get_deep_value()
        .to_json_value();

    // 🔥 Extract messages map safely
    let messages_json = match &root_json {
        serde_json::Value::Object(map) => {
            map.get("messages").cloned().unwrap_or(serde_json::Value::Null)
        }
        _ => serde_json::Value::Null,
    };

    serde_json::json!({
        "messages": messages_json
    })
    .to_string()
}



// --------------------------------------------------
//  FULL SNAPSHOT DECODER
//  - Snapshot becomes BASE STATE
// --------------------------------------------------
fn decode_chat_snapshot_internal(snapshot_base64: String) -> String {
    let bytes = STANDARD
        .decode(snapshot_base64)
        .expect("Invalid base64 snapshot");

    let mut global = GLOBAL_DOC.lock().unwrap();

    // ✅ SAFE: merge snapshot into existing doc
    global.import(&bytes).expect("CRDT import failed");

    let list = global.get_movable_list("chatDataList");
    let mut chat_data_list = Vec::<Value>::new();

    for i in 0..list.len() {
        if let Some(item) = list.get(i) {
            if let Some(v) = item.as_value() {
                chat_data_list.push(v.to_json_value().clone());
            }
        }
    }

    json!({
        "chatDataList": chat_data_list
    })
    .to_string()
}


#[frb]
pub fn decode_chat_snapshot(snapshot_base64: String) -> String {
    decode_chat_snapshot_internal(snapshot_base64)
}

// --------------------------------------------------
//  INCREMENTAL UPDATE (Socket: chatlistUpdate)
// --------------------------------------------------
fn import_chat_update_internal(update_bytes: Vec<u8>) -> String {
    let doc = GLOBAL_DOC.lock().unwrap();

    // Apply incremental CRDT update
    doc.import(&update_bytes)
        .expect("CRDT import failed");

    // Read movable list after update
    let list = doc.get_movable_list("chatDataList");
    let mut chat_data_list = Vec::<Value>::new();

    for i in 0..list.len() {
        if let Some(item) = list.get(i) {
            if let Some(v) = item.as_value() {
                chat_data_list.push(v.to_json_value().clone());
            }
        }
    }

    json!({
        "chatDataList": chat_data_list
    })
    .to_string()
}

#[frb]
pub fn import_chat_update(update_bytes: Vec<u8>) -> String {
    import_chat_update_internal(update_bytes)
}
