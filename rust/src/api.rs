use flutter_rust_bridge::frb;
use base64::Engine;
use base64::engine::general_purpose::STANDARD;
use loro::{LoroDoc, ToJson};
use serde_json::{json, Map, Value};
use std::sync::Mutex;
use lazy_static::lazy_static;

// --------------------------------------------------
//  GLOBAL LORO DOCUMENT (Persist across updates)
// --------------------------------------------------
lazy_static! {
    static ref GLOBAL_DOC: Mutex<LoroDoc> = Mutex::new({
        let mut d = LoroDoc::new();
        d.get_list("chatDataList");
        d.get_map("chatData");
        d
    });
}

// --------------------------------------------------
//  FULL SNAPSHOT DECODER (already working)
// --------------------------------------------------
fn decode_chat_snapshot_internal(snapshot_base64: String) -> String {
    // Decode Base64 → bytes
    let bytes = STANDARD.decode(snapshot_base64).expect("Invalid base64");

    // Load snapshot
    let doc = LoroDoc::from_snapshot(&bytes).expect("Invalid snapshot");

    // =========================== chatDataList ===========================
    let mut chat_data_list = Vec::<Value>::new();
    let list = doc.get_list("chatDataList");

    for i in 0..list.len() {
        if let Some(item) = list.get(i) {
            if let Some(v) = item.as_value() {
                chat_data_list.push(v.to_json_value().clone());
            }
        }
    }

    // ============================== chatData =============================
    let mut chat_data = Map::<String, Value>::new();
    let map = doc.get_map("chatData");

    for key in map.keys() {
        let key_string = key.to_string();

        if let Some(value) = map.get(&key) {
            if let Some(v) = value.as_value() {
                chat_data.insert(key_string, v.to_json_value().clone());
            }
        }
    }

    // ============================ Final Output ============================
    let output = json!({
        "chatDataList": chat_data_list,
        "chatData": chat_data
    });

    output.to_string()
}

#[frb]
pub fn decode_chat_snapshot(snapshot_base64: String) -> String {
    decode_chat_snapshot_internal(snapshot_base64)
}

// --------------------------------------------------
//  INCREMENTAL UPDATE (chatlistUpdate socket event)
// --------------------------------------------------
fn import_chat_update_internal(update_bytes: Vec<u8>) -> String {
    let mut doc = GLOBAL_DOC.lock().unwrap();

    // 1) Import incremental CRDT update
    doc.import(&update_bytes).expect("CRDT import failed");

    // 2) Extract updated chatDataList
    let list = doc.get_list("chatDataList");
    let mut chat_data_list = Vec::<Value>::new();

    for i in 0..list.len() {
        if let Some(item) = list.get(i) {
            if let Some(v) = item.as_value() {
                chat_data_list.push(v.to_json_value().clone());
            }
        }
    }

    // 3) Extract updated chatData map
    let map = doc.get_map("chatData");
    let mut chat_data = Map::<String, Value>::new();

    for key in map.keys() {
        if let Some(value) = map.get(&key) {
            if let Some(v) = value.as_value() {
                chat_data.insert(key.to_string(), v.to_json_value().clone());
            }
        }
    }

    // 4) Output JSON (same structure as snapshot)
    let output = json!({
        "chatDataList": chat_data_list,
        "chatData": chat_data
    });

    output.to_string()
}

#[frb]
pub fn import_chat_update(update_bytes: Vec<u8>) -> String {
    import_chat_update_internal(update_bytes)
}
