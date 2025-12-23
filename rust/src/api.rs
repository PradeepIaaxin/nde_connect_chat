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
pub fn decode_message_snapshot(snapshot_base64: String) -> String {
    use base64::engine::general_purpose::STANDARD;
    use base64::Engine;
    use loro::{LoroDoc, ToJson};
    use serde_json::{json, Value};

    let bytes = STANDARD
        .decode(snapshot_base64)
        .expect("Invalid base64 snapshot");

    let snapshot_doc =
        LoroDoc::from_snapshot(&bytes).expect("Invalid Loro snapshot");

    let mut global = GLOBAL_DOC.lock().unwrap();
    *global = snapshot_doc;

    // ✅ Convert FULL document → JSON
    let root_json = global
        .get_deep_value()
        .to_json_value();

    // ✅ Extract only messages
    let messages_json = match &root_json {
        Value::Object(map) => map.get("messages").cloned().unwrap_or(Value::Null),
        _ => Value::Null,
    };

    json!({
        "messages": messages_json
    })
    .to_string()
}



// --------------------------------------------------
//  FULL SNAPSHOT DECODER
//  - Snapshot becomes BASE STATE
// --------------------------------------------------
fn decode_chat_snapshot_internal(snapshot_base64: String) -> String {
    // Decode Base64 → bytes
    let bytes = STANDARD
        .decode(snapshot_base64)
        .expect("Invalid base64 snapshot");

    // Create document from snapshot
    let snapshot_doc =
        LoroDoc::from_snapshot(&bytes).expect("Invalid Loro snapshot");

    // 🔥 Replace GLOBAL_DOC with snapshot state
    let mut global = GLOBAL_DOC.lock().unwrap();
    *global = snapshot_doc;

    // Read movable list from GLOBAL_DOC
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
