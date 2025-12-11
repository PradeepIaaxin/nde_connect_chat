import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/presantation/drive/model/folderinside_model.dart';
import 'package:nde_email/utils/snackbar/snackbar.dart';

class InsidefileRepo {
  final Dio dio;
  static const String _baseUrl = 'https://api.nowdigitaleasy.com/drive/v1';

  InsidefileRepo({Dio? dio}) : dio = dio ?? Dio();

  Future<Map<String, String>?> _getHeaders() async {
    final accessToken = await UserPreferences.getAccessToken();
    final defaultWorkspace = await UserPreferences.getDefaultWorkspace();

    if (accessToken == null || defaultWorkspace == null) {
      log('Missing authentication credentials');
      return null;
    }

    return {
      'Authorization': 'Bearer $accessToken',
      'x-workspace': defaultWorkspace,
      'Content-Type': 'application/json',
    };
  }

  

  Future<List<FolderinsideModel>> fetchStarredFolders({
    int page = 1,
    int limit = 50,
    String? sortBy,
  }) async {
    try {
      final headers = await _getHeaders();
      if (headers == null) return [];

      final response = await dio.get('$_baseUrl/folders',
          options: Options(headers: headers),
          queryParameters: {
            'starred': true,
            'page': page,
            'limit': limit,
            if (sortBy == 'asc' || sortBy == 'dsc') ...{
              'sortBy': 'name',
              'order': sortBy,
            } else if (sortBy != null) ...{
              'sortBy': sortBy,
            },
          });

      final json = response.data as Map<String, dynamic>;
      final List data = json['rows'] ?? [];
      return data.map((e) => FolderinsideModel.fromJson(e)).toList();
    } catch (e, stack) {
      log('fetchStarredFolders error: $e', stackTrace: stack);
      return [];
    }
  }

  Future<void> inreNamebloc({
    required List<String> fileIDs,
    required String editedName,
  }) async {
    final headers = await _getHeaders();
    if (headers == null) return;

    final body = {'name': editedName};

    for (final id in fileIDs) {
      try {
        final response = await dio.put(
          '$_baseUrl/folders/$id',
          data: body,
          options: Options(headers: headers),
        );
        if (response.statusCode != 200) {
          log('Rename failed for $id');
        }
      } catch (e, stack) {
        log('inreNamebloc error for $id: $e', stackTrace: stack);
      }
    }
  }

  Future<List<FolderinsideModel>> fetchingupdatedFolders({
    int page = 1,
    int limit = 50,
    String? sortBy,
    String? fileID,
  }) async {
    if (fileID == null) return [];

    try {
      final headers = await _getHeaders();
      if (headers == null) return [];

      final response = await dio.get('$_baseUrl/folders/$fileID',
          options: Options(headers: headers),
          queryParameters: {
            'page': page,
            'limit': limit,
            if (sortBy == 'asc' || sortBy == 'dsc') ...{
              'sortBy': 'name',
              'order': sortBy,
            } else if (sortBy != null) ...{
              'sortBy': sortBy,
            },
          });

      final json = response.data as Map<String, dynamic>;
      final List data = json['rows'] ?? [];
      return data.map((e) => FolderinsideModel.fromJson(e)).toList();
    } catch (e, stack) {
      log('fetchingupdatedFolders error: $e', stackTrace: stack);
      return [];
    }
  }

  Future<List<FolderinsideModel>> fetchinsideFolders({
    int page = 1,
    int limit = 45,
    String? sortBy,
    String? fileId,
  }) async {
    if (fileId == null) return [];

    try {
      final headers = await _getHeaders();
      if (headers == null) return [];

      final response = await dio.get('$_baseUrl/folders/$fileId',
          options: Options(headers: headers),
          queryParameters: {
            'page': page,
            'limit': limit,
            if (sortBy == 'asc' || sortBy == 'dsc') ...{
              'sortBy': 'name',
              'order': sortBy,
            } else if (sortBy != null) ...{
              'sortBy': sortBy,
            } else if (sortBy != null) ...{
              'sortBy': 'name',
            },
          });

      final json = response.data as Map<String, dynamic>;
      final List data = json['rows'] ?? [];
      return data.map((e) => FolderinsideModel.fromJson(e)).toList();
    } catch (e, stack) {
      log('fetchinsideFolders error: $e', stackTrace: stack);
      return [];
    }
  }

  Future<void> organized({
    required List<String> fileIDs,
    required dynamic pickedColor,
  }) async {
    final headers = await _getHeaders();
    if (headers == null) return;

    final body = {
      'fileId': fileIDs,
      'color': pickedColor,
    };

    try {
      final response = await dio.post(
        '$_baseUrl/organize',
        data: body,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        Messenger.alertSuccess(
          fileIDs.length == 1
              ? "Item color updated successfully"
              : "${fileIDs.length} items color updated successfully",
        );
      } else {
        log('Failed to color folder(s): ${response.statusCode}');
      }
    } catch (e, stack) {
      log('organized error: $e', stackTrace: stack);
    }
  }

  Future<List<FolderinsideModel>> fetchTrash({
    int page = 1,
    int limit = 80,
    String? sortBy,
  }) async {
    try {
      final headers = await _getHeaders();
      if (headers == null) return [];

      final queryParams = {
        'page': page,
        'limit': limit,
        'deletedAt': true,
        if (sortBy == 'asc' || sortBy == 'dsc') ...{
          'sortBy': 'updatedAt',
          'order': sortBy,
        } else if (sortBy != null) ...{
          'sortBy': sortBy,
        },
      };

      final response = await dio.get('$_baseUrl/folders',
          options: Options(headers: headers), queryParameters: queryParams);

      final json = response.data as Map<String, dynamic>;
      final List data = json['rows'] ?? [];
      return data.map((e) => FolderinsideModel.fromJson(e)).toList();
    } catch (e, stack) {
      log('fetchTrash error: $e', stackTrace: stack);
      return [];
    }
  }

  Future<void> starred({required List<String> fileIDs}) async {
    final headers = await _getHeaders();
    if (headers == null) return;

    try {
      final response = await dio.put(
        '$_baseUrl/star',
        data: {'fileId': fileIDs},
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        Messenger.alertSuccess(
          fileIDs.length == 1
              ? "Item starred successfully"
              : "${fileIDs.length} items starred successfully",
        );
      } else {
        log('Failed to star folder(s): ${response.statusCode}');
      }
    } catch (e, stack) {
      log('starred error: $e', stackTrace: stack);
    }
  }

  Future<void> moveToTrash({required List<String> fileIDs}) async {
    final headers = await _getHeaders();
    if (headers == null) return;

    try {
      final response = await dio.put(
        '$_baseUrl/folders?bin=trash',
        data: {'fileId': fileIDs},
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        Messenger.alertSuccess(
          fileIDs.length == 1
              ? "Item moved to trash"
              : "${fileIDs.length} items moved to trash",
        );
      } else {
        log('Failed to move to trash: ${response.statusCode}');
      }
    } catch (e, stack) {
      log('moveToTrash error: $e', stackTrace: stack);
    }
  }

  Future<void> deletePermanetly({required List<String> fileIDs}) async {
    final headers = await _getHeaders();
    if (headers == null) return;

    try {
      final response = await dio.put(
        '$_baseUrl/folders/permanent',
        data: {'fileId': fileIDs},
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        Messenger.alertSuccess(
          fileIDs.length == 1
              ? "Item permanently deleted"
              : "${fileIDs.length} items permanently deleted",
        );
      } else {
        log('Failed to permanently delete: ${response.statusCode}');
      }
    } catch (e, stack) {
      log('deletePermanetly error: $e', stackTrace: stack);
    }
  }

  Future<void> restoreAll({required List<String> fileIDs}) async {
    final headers = await _getHeaders();
    if (headers == null) return;

    try {
      final response = await dio.put(
        '$_baseUrl/folders?bin=restore',
        data: {'fileId': fileIDs},
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        Messenger.alertSuccess(
          fileIDs.length == 1
              ? "Item restored successfully"
              : "${fileIDs.length} items restored successfully",
        );
      } else {
        log('Failed to restore: ${response.statusCode}');
      }
    } catch (e, stack) {
      log('restoreAll error: $e', stackTrace: stack);
    }
  }
}
