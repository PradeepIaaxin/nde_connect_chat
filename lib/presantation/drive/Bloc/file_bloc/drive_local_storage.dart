import 'dart:developer';

import 'package:hive/hive.dart';
import 'package:nde_email/data/respiratory.dart';

class LocalDriveStorage {
  static const String boxName = 'DriveBox';
  static const String defaultKeyPrefix = 'mydrive_files';

  static Future<void> saveFolders(List<Map<String, dynamic>> folders) async {
    try {
      final box = await Hive.openBox(boxName);
      final workspace = await UserPreferences.getDefaultWorkspace();
      final key = '$defaultKeyPrefix$workspace';
      await box.put(key, folders);
    } catch (e) {
      log('Error saving mydrive folders: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> loadFolders() async {
    try {
      final box = await Hive.openBox(boxName);
      final workspace = await UserPreferences.getDefaultWorkspace();
      final key = '$defaultKeyPrefix$workspace';
      final stored = box.get(key, defaultValue: <Map>[]);

      return (stored as List)
          .where((e) => e is Map)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      log('Error loading mydrive folders: $e');
      return [];
    }
  }
}
