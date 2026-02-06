import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:bloc/bloc.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/presantation/chat/chat_api_service/secure/secure_storage.dart';

import 'package:nde_email/presantation/chat/chat_contact_list/local_strorage.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/localstorage/local_storage.dart';
import 'package:nde_email/presantation/drive/Bloc/file_bloc/drive_local_storage.dart'
    show LocalDriveStorage;
import 'package:nde_email/presantation/chat/Socket/socket_service.dart';
import 'package:nde_email/presantation/drive/Bloc/sharred_bloc/sharred_local.dart';
import 'package:nde_email/presantation/drive/Bloc/starred_bloc/stared_local.dart';
import 'package:nde_email/presantation/login/login_api.dart';
import 'package:nde_email/presantation/login/loro_cleanup.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nde_email/presantation/login/login_screen_event.dart';
import 'package:nde_email/presantation/login/login_screen_state.dart';
import 'package:nde_email/presantation/login/login_req.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final Auth authRepository;
  Timer? _refreshTimer;
  bool _isRefreshing = false;
  Completer<void>? _refreshCompleter;

  LoginBloc({
    required this.authRepository,
  }) : super(const LoginState()) {
    on<EmailChanged>(_onEmailChanged);
    on<PasswordChanged>(_onPasswordChanged);
    on<LoginApi>(_onLoginSubmitted);
    on<LoginLoggedOut>(_onLogout);
    on<LoginStatusReset>(_onStatusReset);
    on<LoginRefresh>(_onRefreshToken);
    on<EmailSubmit>(_onEmailSubmit);
  }

  void _onEmailChanged(EmailChanged event, Emitter<LoginState> emit) {
    emit(state.copyWith(email: event.email));
  }

  void _onPasswordChanged(PasswordChanged event, Emitter<LoginState> emit) {
    emit(state.copyWith(password: event.password));
  }

  Future<void> _onEmailSubmit(
      EmailSubmit event, Emitter<LoginState> emit) async {
    emit(state.copyWith(status: LoginStatus.loading));

    try {
      await authRepository.checkUserEmail(event.email);
      emit(state.copyWith(status: LoginStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: LoginStatus.errorScreen,
        message: "Please enter a valid email address",
      ));
    }
  }

  Future<void> _onLoginSubmitted(
    LoginApi event,
    Emitter<LoginState> emit,
  ) async {
    emit(state.copyWith(
      status: LoginStatus.loading,
      message: "",
    ));

    try {
      final loginRequest = LoginRequestModel(
        email: event.email,
        password: event.password,
      );

      await authRepository.login(loginRequest);

      // 🔥 GET SAVED TOKENS AFTER LOGIN
      final userId = await UserPreferences.getUserId();
      final workspaceId = await UserPreferences.getDefaultWorkspace();
      final accessToken = await UserPreferences.getAccessToken();
      final refreshToken = await UserPreferences.getrefreshToken();

      // 🔐 SAVE TO SECURE STORAGE
      if (accessToken != null) {
        await SecureStorage.saveToken(accessToken);
      }
      if (refreshToken != null) {
        await SecureStorage.saveRefreshToken(refreshToken);
      }
      if (userId != null) {
        await SecureStorage.saveUserId(userId);
      }
      if (workspaceId != null) {
        await SecureStorage.saveWorkspace(workspaceId);
      }

      // ✅ Initialize socket ONCE
      await SocketService().initialize();
      await SocketService().waitUntilConnected();

      _startRefreshTimer();

      emit(state.copyWith(
        status: LoginStatus.success,
        message: "Login successful!",
      ));
    } catch (e, stackTrace) {
      log("Login error: $e", stackTrace: stackTrace);

      emit(state.copyWith(
        status: LoginStatus.errorScreen,
        message: _getErrorMessage(e),
        hasSubmitted: true,
      ));
    }
  }

  void _onStatusReset(LoginStatusReset event, Emitter<LoginState> emit) {
    emit(state.copyWith(status: LoginStatus.initial));
  }

  Future<void> _onLogout(
    LoginLoggedOut event,
    Emitter<LoginState> emit,
  ) async {
    await performCleanLogout();
    emit(const LoginState());
  }

  Future<void> performCleanLogout() async {
    final userId = await UserPreferences.getUserId();
    final workspaceId = await UserPreferences.getDefaultWorkspace();

    // 1️⃣ Notify offline
    if (userId != null && workspaceId != null) {
      SocketService().setUserOffline(userId, workspaceId);
    }

    SocketService().dispose();
    SocketService().resetForLogout();

    // 2️⃣ Clear SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // 3️⃣ Stop refresh
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _isRefreshing = false;
    _refreshCompleter = null;

    // 4️⃣ Clear Loro (CRDT)
    await clearLoroState();
    

    // 5️⃣ Clear Hive safely
    await Future.wait([
      clearHiveBoxSafe(LocalChatStorage.boxName),
      clearHiveBoxSafe(LocalDriveStorage.boxName),
      clearHiveBoxSafe(GrpLocalChatStorage.boxName),
      clearHiveBoxSafe(LocalStarredStorage.boxName),
      clearHiveBoxSafe(LocalSharredStorage.boxName),
    ]);

    log("✅ FULL logout cleanup completed");
  }

  Future<void> clearHiveBoxSafe(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      await Hive.box(boxName).clear();
    }
  }

  Future<bool> refreshTokenOnStartup(String refreshToken) async {
    if (_isRefreshing) return false;

    _isRefreshing = true;
    try {
      log('Refreshing token on app startup...');

      final response = await http.post(
        Uri.parse("https://api.nowdigitaleasy.com/auth/v1/auth/refresh-token"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['accessToken'];
        final newRefreshToken = data['refreshToken'];

        await UserPreferences.updateTokens(newAccessToken, newRefreshToken);
        await SecureStorage.saveRefreshToken(newRefreshToken);

        log('Tokens refreshed successfully on startup');

        _startRefreshTimer();
        return true;
      } else {
        log('  Token refresh failed on startup: ${response.body}');
        return false;
      }
    } catch (e) {
      log('  Error refreshing token on startup: $e');
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _onRefreshToken(
    LoginRefresh event,
    Emitter<LoginState> emit,
  ) async {
    if (_isRefreshing) {
      await _refreshCompleter?.future;
      return;
    }

    _isRefreshing = true;
    _refreshCompleter = Completer();

    try {
      final refreshToken = await UserPreferences.getrefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        throw Exception('No refresh token available');
      }

      log('Refreshing token...');
      final response = await http.post(
        Uri.parse("https://api.nowdigitaleasy.com/auth/v1/auth/refresh-token"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['accessToken'];
        final newRefreshToken = data['refreshToken'];

        await UserPreferences.updateTokens(newAccessToken, newRefreshToken);
        await SecureStorage.saveToken(newAccessToken);

        log('Tokens refreshed successfully');

        _refreshCompleter!.complete();
      } else {
        log('  Refresh failed with status ${response.statusCode}: ${response.body}');
        _refreshCompleter!.completeError(Exception("Failed to refresh token"));
        throw Exception("Failed to refresh token");
      }
    } catch (e) {
      log('  Error during token refresh: $e');
      emit(state.copyWith(
        status: LoginStatus.errorScreen,
        message: "Session expired. Please login again.",
      ));
      _refreshCompleter?.completeError(e);

      // Perform logout if token refresh fails
      add(LoginLoggedOut());
    } finally {
      _isRefreshing = false;
    }
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 4, seconds: 20),
      (_) {
        if (!_isRefreshing) {
          log('Periodic token refresh triggered');
          add(LoginRefresh());
        }
      },
    );
  }

  String _getErrorMessage(dynamic error) {
    if (error is String) return error;
    if (error.toString().contains('socket') ||
        error.toString().contains('Network is unreachable')) {
      return 'Network error. Please check your internet connection.';
    }
    return 'An unexpected error occurred. Please try again.';
  }
}
