import 'package:flutter/widgets.dart';
import 'package:nde_email/presantation/chat/Socket/socket_service.dart';

class AppLifecycleService with WidgetsBindingObserver {
  static final AppLifecycleService _instance = AppLifecycleService._internal();

  factory AppLifecycleService() => _instance;
  AppLifecycleService._internal();

  void init() {
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        print('🟢 APP RESUMED');
        SocketService().initialize();
        break;

      case AppLifecycleState.inactive:
        print('🟡 APP INACTIVE');
        break;

      case AppLifecycleState.paused:
        print('🔴 APP PAUSED (BACKGROUND)');
        SocketService().disconnect();
        break;

      case AppLifecycleState.detached:
        print('⚫ APP DETACHED (KILLED)');
        SocketService().disconnect();
        break;
      case AppLifecycleState.hidden:
        throw UnimplementedError();
    }
  }
}
