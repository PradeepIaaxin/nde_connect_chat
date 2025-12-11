// sugesstion_local_storage.dart
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/presantation/drive/model/home/suggestion/suggestion_model.dart';

class SugesstionLocalStorage {
  static const String boxName = 'SugesstionBox';
  static const String defaultKeyPrefix = 'starred_messages';

  static Future<void> saveMessages(List<FileModel> files) async {
    try {
      final box = await Hive.openBox(boxName);
      final defaultWorkspace = await UserPreferences.getDefaultWorkspace();
      final key = '$defaultKeyPrefix$defaultWorkspace';

      final jsonList = files.map((file) => file.toJson()).toList();
      await box.put(key, jsonList);
    } catch (e) {
      log('Error saving suggestions: $e');
      rethrow;
    }
  }

  static Future<List<FileModel>> loadMessages() async {
    try {
      final box = await Hive.openBox(boxName);
      final defaultWorkspace = await UserPreferences.getDefaultWorkspace();
      final key = '$defaultKeyPrefix$defaultWorkspace';

      final stored = box.get(key, defaultValue: <Map>[]);

      final list = (stored as List).map((item) {
        try {
          // Safe conversion for each item
          if (item is Map) {
            final jsonMap = item.cast<String, dynamic>();
            return FileModel.fromJson(jsonMap);
          }
          return FileModel.empty();
        } catch (e) {
          // log('Error parsing item: $e\nItem: $item');
          return FileModel.empty();
        }
      }).toList();

      return list.where((model) => model.id.isNotEmpty).toList();
    } catch (e) {
      log('Error loading suggestions: $e');
      return [];
    }
  }
}
