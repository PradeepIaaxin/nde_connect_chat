import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:universal_html/html.dart' as html;

Future<Map<String, String?>> getDeviceInfo() async {
  final deviceInfo = DeviceInfoPlugin();

  if (kIsWeb) {
    return {
      'platform': 'web',
      'os': html.window.navigator.platform,
      'browser': html.window.navigator.appName,
      'model': 'browser',
      'userAgent': html.window.navigator.userAgent,
    };
  }

  if (Platform.isAndroid) {
    final android = await deviceInfo.androidInfo;
    return {
      'platform': 'android',
      'os': 'Android ${android.version.release}',
      'browser': null,
      'model': android.model,
      'userAgent': null,
    };
  }

  if (Platform.isIOS) {
    final ios = await deviceInfo.iosInfo;
    return {
      'platform': 'ios',
      'os': 'iOS ${ios.systemVersion}',
      'browser': null,
      'model': ios.utsname.machine,
      'userAgent': null,
    };
  }

  return {
    'platform': 'unknown',
    'os': null,
    'browser': null,
    'model': null,
    'userAgent': null,
  };
}

