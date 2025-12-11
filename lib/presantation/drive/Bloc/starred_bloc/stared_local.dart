import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:nde_email/data/respiratory.dart';

class LocalStarredStorage {
  static const String boxName = 'StarredBox';
  static const String _defaultKeyPrefix = 'starred_messages_';

  /// Save messages list to local storage for the current workspace
  static Future<void> saveMessages(List<Map<String, dynamic>> messages) async {
    try {
      if (!Hive.isBoxOpen(boxName)) {
        await Hive.openBox(boxName);
      }
      final box = Hive.box(boxName);
      final defaultWorkspace = await UserPreferences.getDefaultWorkspace();
      final key = '$_defaultKeyPrefix$defaultWorkspace';

      await box.put(key, messages);
    } catch (e) {
      log('Error saving starred messages: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> loadMessages() async {
    try {
      if (!Hive.isBoxOpen(boxName)) {
        await Hive.openBox(boxName);
      }
      final box = Hive.box(boxName);
      final defaultWorkspace = await UserPreferences.getDefaultWorkspace();
      final key = '$_defaultKeyPrefix$defaultWorkspace';

      final stored = box.get(key, defaultValue: <Map<String, dynamic>>[]);

      // Ensure we have a List first
      if (stored is! List) return [];

      return stored
          .map((item) {
            try {
              // Convert each item to Map<String, dynamic>
              if (item is Map) {
                return item.cast<String, dynamic>();
              }
              return <String, dynamic>{};
            } catch (e) {
              log('Error parsing stored message: $e');
              return <String, dynamic>{};
            }
          })
          .where((map) => map.isNotEmpty)
          .toList();
    } catch (e) {
      log('Error loading starred messages: $e');
      return [];
    }
  }
}
