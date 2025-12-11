import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:nde_email/main.dart';
import 'package:nde_email/presantation/chat/chat_contact_list/local_strorage.dart';
import 'package:nde_email/presantation/chat/chat_list/chat_session_storage/chat_session.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/localstorage/local_storage.dart';
import 'package:nde_email/presantation/drive/Bloc/file_bloc/drive_local_storage.dart';
import 'package:nde_email/presantation/drive/Bloc/sharred_bloc/sharred_local.dart';
import 'package:nde_email/presantation/drive/Bloc/starred_bloc/stared_local.dart';
import 'package:nde_email/presantation/login/login_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nde_email/presantation/login/login_screen.dart';
import 'package:nde_email/presantation/login/login_screen_bloc.dart';
import 'package:nde_email/presantation/login/login_screen_event.dart';
import 'package:nde_email/presantation/login/login_model.dart';

class UserPreferences {
  static const String userKey = 'user_data';
  static const String tokenKey = 'access_token';
  static const String refrshToken = 'refresh_token';
  static const String workspaceKey = 'default_workspace';
  static const String usernameKey = 'username';
  static const String emailKey = 'email';
  static const String profilePicKey = 'profile_pic_key';
  static const String isLoggedInKey = 'isLoggedIn';
  static const String meiliTenantTokenKey = 'meili_tenant_token';
  static const String userIdKey = 'user_id';

  /// **Save user data in SharedPreferences**
  static Future<void> saveUser(UserModel user) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String userJson = jsonEncode(user.toJson());

    await prefs.setString(userKey, userJson);
    await prefs.setString(tokenKey, user.accessToken);
    await prefs.setString(refrshToken, user.refrshToken);
    await prefs.setString(meiliTenantTokenKey, user.meiliTenantToken);
    await prefs.setString(workspaceKey, user.defaultWorkspace);
    await prefs.setString(usernameKey, user.fullName);
    await prefs.setString(emailKey, user.email);
    await prefs.setString(profilePicKey, user.profilePicUrl);
    await prefs.setBool(isLoggedInKey, true);
    await prefs.setString(userIdKey, user.userId);
  }

  /// **Get Access Token**
  static Future<String?> getAccessToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  static Future<void> updateTokens(
      String accessToken, String refreshToken) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, accessToken);
    await prefs.setString(refrshToken, refreshToken);
  }

  static Future<String?> getrefreshToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(refrshToken);
  }

  /// **Get User ID**
  static Future<String?> getUserId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(userIdKey);
  }

  static Future<String?> getMeiliTenantToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(meiliTenantTokenKey);
  }

  /// **Get Default Workspace**
  static Future<String?> getDefaultWorkspace() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(workspaceKey);
  }

  /// **Get Username**
  static Future<String?> getUsername() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(usernameKey);
  }

  /// **Get Email**
  static Future<String?> getEmail() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(emailKey);
  }

  /// **Get Profile Picture Key**
  static Future<String?> getProfilePicKey() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(profilePicKey);
  }

  /// **Get User Model**
  static Future<UserModel?> getUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString(userKey);

    if (userJson != null) {
      try {
        return UserModel.fromJson(jsonDecode(userJson));
      } catch (e) {
        log(" Error decoding user data: $e");
      }
    }
    return null;
  }

  static Future<void> clearUser() async {
    // Clear SharedPreferences
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    log("✅ SharedPreferences cleared.");

    // Clear Hive boxes safely
    await _clearHiveBox(LocalChatStorage.boxName);
    await _clearHiveBox(LocalDriveStorage.boxName);
    await _clearHiveBox(GrpLocalChatStorage.boxName);
    await _clearHiveBox(LocalStarredStorage.boxName);
    await _clearHiveBox(LocalSharredStorage.boxName);
    await prefs.remove(userKey);
    await prefs.remove(tokenKey);
    await prefs.remove(workspaceKey);
    await prefs.remove(usernameKey);
    await prefs.remove(emailKey);
    await prefs.remove(profilePicKey);
    log("✅ Hive boxes cleared.");

    // Clear chat session storage if any
    ChatSessionStorage.clear();

    // Remove additional custom data if needed
    await prefs.remove('callHistory');
  }

  static Future<void> _clearHiveBox(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      await Hive.box(boxName).clear();
    } else {
      var box = await Hive.openBox(boxName);
      await box.clear();
    }
  }

  static Future<void> logout(BuildContext context) async {
    final userId = await UserPreferences.getUserId();
    final workspaceId = await UserPreferences.getDefaultWorkspace();

    // 1️⃣ Emit offline BEFORE disconnect
    if (userId != null && workspaceId != null) {
      socketService.setUserOffline(userId, workspaceId);
    }

    // 2️⃣ WAIT to ensure server receives it
    await Future.delayed(const Duration(milliseconds: 300));

    // 3️⃣ Now trigger logout event in Bloc
    context.read<LoginBloc>().add(LoginLoggedOut());

    // 4️⃣ Wait again to clear data completely
    await Future.delayed(const Duration(milliseconds: 200));

    // 5️⃣ Navigate to Login
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (context) => LoginBloc(authRepository: Auth(),socketBloc: context.read()),
          child: const LoginScreen(),
        ),
      ),
      (route) => false,
    );

    log("✅ User logged out and offline status synced!");
  }
}
