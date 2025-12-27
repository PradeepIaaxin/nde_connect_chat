import 'package:nde_email/bridge_generated.dart/api.dart';

/// 🔥 Completely resets Loro CRDT state (Rust memory)
Future<void> clearLoroState() async {
  try {
    // This must match whatever you use to reset doc elsewhere
    await resetGlobalDoc();
  } catch (e) {
    // Never crash logout because of CRDT
    // ignore: avoid_print
    print('⚠️ clearLoroState failed: $e');
  }
}
