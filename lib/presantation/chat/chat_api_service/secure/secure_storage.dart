import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();

  static const String tokenKey = "access_token";
  static const String workspaceKey = "workspace";
  static const String userIdKey = "user_id";

  static Future<void> saveToken(String token) async {
    await _storage.write(key: tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: tokenKey);
  }

  static Future<void> saveWorkspace(String workspace) async {
    await _storage.write(key: workspaceKey, value: workspace);
  }

  static Future<String?> getWorkspace() async {
    return await _storage.read(key: workspaceKey);
  }

  static Future<void> saveUserId(String id) async {
    await _storage.write(key: userIdKey, value: id);
  }

  static Future<String?> getUserId() async {
    return await _storage.read(key: userIdKey);
  }

  static const String refreshTokenKey = "refresh_token";

  static Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: refreshTokenKey, value: token);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: refreshTokenKey);
  }
}
