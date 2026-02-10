import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:nde_email/presantation/chat/Socket/Socket_Service.dart';

class AppLifecycleService with WidgetsBindingObserver {
  static final AppLifecycleService _instance = AppLifecycleService._internal();

  factory AppLifecycleService() => _instance;
  AppLifecycleService._internal();

  bool _initialized = false;
  bool _isOnline = true;

  StreamSubscription<List<ConnectivityResult>>? _networkSub;

  // ========================
  // INIT (call once in main)
  // ========================
  void init() {
    if (_initialized) return;

    WidgetsBinding.instance.addObserver(this);
    _listenNetworkChanges();

    _initialized = true;
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _networkSub?.cancel();
    _initialized = false;
  }

  // ========================
  // 🌐 NETWORK MONITOR
  // ========================
  void _listenNetworkChanges() {
    _networkSub = Connectivity().onConnectivityChanged.listen((results) async {
      final online =
          results.isNotEmpty && !results.contains(ConnectivityResult.none);

      if (_isOnline == online) return;

      _isOnline = online;

      if (online) {
        _log('🌐 NETWORK RESTORED → HARD RECONNECT');
        await SocketService().hardReconnect();
      } else {
        _log('🌐 NETWORK OFFLINE');
      }
    });
  }

  // ========================
  // 📱 APP LIFECYCLE
  // ========================
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        _log('🟢 APP RESUMED');

        if (_isOnline) {
          await SocketService().hardReconnect();
        }
        break;

      case AppLifecycleState.inactive:
        _log('🟡 APP INACTIVE');
        break;

      case AppLifecycleState.paused:
        _log('🔴 APP PAUSED');
        break;

      case AppLifecycleState.detached:
        _log('⚫ APP DETACHED');
        SocketService().disconnect();
        break;

      case AppLifecycleState.hidden:
        _log('🟣 APP HIDDEN');
        break;
    }
  }

  void _log(String msg) {
    // ignore: avoid_print
    print(msg);
  }
}
