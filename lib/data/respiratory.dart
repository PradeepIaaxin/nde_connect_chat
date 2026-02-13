// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:nde_email/convo_list_crdt.dart';
import 'package:nde_email/main.dart';
import 'package:nde_email/presantation/chat/chat_contact_list/local_strorage.dart';
import 'package:nde_email/presantation/chat/chat_list/chat_session_storage/chat_session.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/localstorage/local_storage.dart';
import 'package:nde_email/presantation/drive/Bloc/file_bloc/drive_local_storage.dart';
import 'package:nde_email/presantation/drive/Bloc/sharred_bloc/sharred_local.dart';
import 'package:nde_email/presantation/drive/Bloc/starred_bloc/stared_local.dart';
import 'package:nde_email/presantation/mail/mail_list/bloc/mail_list_bloc.dart';
import 'package:nde_email/presantation/mail/mail_list/bloc/mail_list_event.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/app_bar/app_bar_bloc.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/app_bar/app_bar_event.dart';
import 'package:nde_email/utils/reusbale/common_import.dart';
import 'package:nde_email/presantation/login/login_screen.dart';
import 'package:nde_email/presantation/login/login_screen_bloc.dart';
import 'package:nde_email/presantation/login/login_screen_event.dart';
import 'package:nde_email/presantation/login/login_model.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';

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
  static const String deviceIdKey = 'device_id';

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

  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();

    // 1️⃣ Already exists → return it
    final stored = prefs.getString(deviceIdKey);
    if (stored != null && stored.isNotEmpty) {
      return stored;
    }

    String deviceId;

    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final android = await deviceInfo.androidInfo;
        deviceId = android.id;
        log("📱 Android deviceId: $deviceId");
      } else if (Platform.isIOS) {
        final ios = await deviceInfo.iosInfo;
        deviceId = ios.identifierForVendor ?? const Uuid().v4();
        log("📱 iOS deviceId: $deviceId");
      } else {
        deviceId = const Uuid().v4();
      }
    } catch (e) {
      // Fallback
      deviceId = const Uuid().v4();
      log("⚠️ Device ID fallback used: $e");
    }

    // 2️⃣ Persist forever
    await prefs.setString(deviceIdKey, deviceId);

    return deviceId;
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

  static Future<void> clearUserButKeepDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = prefs.getString(deviceIdKey);

    await prefs.clear();

    if (deviceId != null) {
      await prefs.setString(deviceIdKey, deviceId);
    }
  }

  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    log("✅ SharedPreferences cleared");

    await _clearNormalBox(LocalChatStorage.boxName);
    await _clearNormalBox(LocalDriveStorage.boxName);
    await _clearNormalBox(GrpLocalChatStorage.boxName);
    await _clearNormalBox(LocalStarredStorage.boxName);
    await _clearNormalBox(LocalSharredStorage.boxName);

    // ✅ CRDT — TYPED CLEAR ONLY
    await _clearConvoCrdtBox();

    ChatSessionStorage.clear();
    log("✅ All Hive + session data cleared safely");
  }

  static Future<void> _clearNormalBox(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      await Hive.box(boxName).clear();
      log("🧹 Cleared Hive box: $boxName");
    }
  }

  static Future<void> _clearConvoCrdtBox() async {
    const boxName = 'convo_crdt';

    if (Hive.isBoxOpen(boxName)) {
      final Box<ConvoListCrdt> box = Hive.box<ConvoListCrdt>(boxName);

      await box.clear();
      log("🧹 Cleared CRDT box safely: $boxName");
    }
  }

  static Future<void> logout(BuildContext context) async {
    final userId = await getUserId();
    final workspaceId = await getDefaultWorkspace();

    // 1️⃣ Send offline event
    if (userId != null && workspaceId != null) {
      socketService.setUserOffline(userId, workspaceId);
    }

    // 2️⃣ Allow socket flush
    await Future.delayed(const Duration(milliseconds: 200));

    // 3️⃣ Clear local storage
    await clearUser();

    // 4️⃣ 🔥 RESET ALL APP BLOCS (IMPORTANT)
    context.read<MailListBloc>().add(ResetAllMailState());
    context.read<AppBarBloc>().add(ClearMailboxesEvent());
    context.read<LoginBloc>().add(LoginLoggedOut());

    // 5️⃣ Small delay to let blocs emit
    await Future.delayed(const Duration(milliseconds: 50));

    // 6️⃣ NAVIGATE LAST
    MyRouter.pushRemoveUntil(screen: const LoginScreen());

    log("✅ Logout completed safely");
  }
}
