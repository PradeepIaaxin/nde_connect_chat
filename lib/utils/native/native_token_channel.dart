import 'package:flutter/services.dart';

class NativeTokenChannel {
  static const MethodChannel _channel = MethodChannel("native_token");

  static Future<void> saveToken(String token, String workspace) async {
    await _channel.invokeMethod("saveToken", {
      "token": token,
      "workspace": workspace,
    });
  }
}
