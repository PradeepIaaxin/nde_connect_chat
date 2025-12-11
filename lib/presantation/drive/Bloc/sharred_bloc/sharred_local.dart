import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:nde_email/data/respiratory.dart';

class LocalSharredStorage {
  static const String boxName = 'SharredBox';
  static const String _defaultKeyPrefix = 'starred_messages_';

  static Future<void> saveMessages(List<Map<String, dynamic>> messages) async {
    try {
      final box = await Hive.openBox(boxName);
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
      final box = await Hive.openBox(boxName);
      final defaultWorkspace = await UserPreferences.getDefaultWorkspace();
      final key = '$_defaultKeyPrefix$defaultWorkspace';

      final stored = box.get(key, defaultValue: <Map>[]);

      // Ensure we have a List first
      if (stored is! List) return [];

      return stored
          .map((item) {
            try {
              if (item is Map) {
                return item.cast<String, dynamic>();
              }
              return <String, dynamic>{};
            } catch (e) {
              log('Error converting stored item: $e');
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

// class LocalSharredStorage {
//   static const String boxName = 'SharredBox';
//   static const String _defaultKeyPrefix = 'starred_messages_';

//   static Future<void> saveMessages(List<Map<String, dynamic>> messages) async {
//     try {
//       final box = await Hive.openBox(boxName);
//       final defaultWorkspace = await UserPreferences.getDefaultWorkspace();
//       final key = '$_defaultKeyPrefix$defaultWorkspace';
//       await box.put(key, messages);
//     } catch (e) {
//       log(('Error saving starred messages: $e');
//       rethrow;
//     }
//   }

//   static Future<List<Map<String, dynamic>>> loadMessages() async {
//     try {
//       final box = await Hive.openBox(boxName);
//       final defaultWorkspace = await UserPreferences.getDefaultWorkspace();
//       final key = '$_defaultKeyPrefix$defaultWorkspace';

//       final stored = box.get(key, defaultValue: <Map>[]);

//       return (stored as List)
//           .map((e) {
//             if (e is Map) {
//               return e.cast<String, dynamic>();
//             }
//             return <String, dynamic>{};
//           })
//           .where((map) => map.isNotEmpty)
//           .toList();
//     } catch (e) {
//       log(('Error loading starred messages: $e');
//       return [];
//     }
//   }
// }
