import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/presantation/drive/model/starred/starred_model.dart';
import 'package:nde_email/utils/snackbar/snackbar.dart';

class DriveRepository {
  final Dio dio;
  static const String _baseUrl = 'https://api.nowdigitaleasy.com/drive/v1';

  DriveRepository({Dio? dio}) : dio = dio ?? Dio();

  Future<Map<String, String>> _getHeaders() async {
    final String? accessToken = await UserPreferences.getAccessToken();
    final String? defaultWorkspace =
        await UserPreferences.getDefaultWorkspace();

    if (accessToken == null || defaultWorkspace == null) {
      throw Exception('Missing authentication credentials');
    }

    return {
      'Authorization': 'Bearer $accessToken',
      'x-workspace': defaultWorkspace,
      'Content-Type': 'application/json',
    };
  }

  Future<List<StarredFolder>> fetchStarredFolders({
    required int page,
    required int limit,
    String? sortBy,
  }) async {
    try {
      final headers = await _getHeaders();

      final queryParams = {
        'starred': true,
        'page': page,
        'limit': limit,
        if (sortBy == 'asc' || sortBy == 'dsc') ...{
          'sortBy': 'name',
          'order': sortBy,
        } else if (sortBy != null) ...{
          'sortBy': sortBy,
        },
      };

      final response = await dio.get('$_baseUrl/folders',
          options: Options(headers: headers), queryParameters: queryParams);

      final data = (response.data['rows'] as List?) ?? [];

      return data.map((e) => StarredFolder.fromJson(e)).toList();
    } catch (e) {
      _handleError(e, 'fetchStarredFolders');
      rethrow;
    }
  }

  Future<List<StarredFolder>> fetchingupdatedFolders({
    int page = 1,
    int limit = 55,
    String? sortBy,
    String? fileID,
  }) async {
    try {
      if (fileID == null) throw Exception('fileID is required');
      final headers = await _getHeaders();

      final queryParams = {
        'page': page,
        'limit': limit,
        if (sortBy == 'asc' || sortBy == 'dsc') ...{
          'sortBy': 'name',
          'order': sortBy,
        } else if (sortBy != null) ...{
          'sortBy': sortBy,
        },
      };

      final response = await dio.get(
        '$_baseUrl/folders/$fileID',
        options: Options(headers: headers),
        queryParameters: queryParams,
      );

      final data = (response.data['rows'] as List?) ?? [];
      return data.map((e) => StarredFolder.fromJson(e)).toList();
    } catch (e) {
      _handleError(e, 'fetchingupdatedFolders');
      rethrow;
    }
  }

  Future<List<StarredFolder>> fetchinsideFolders({
    int page = 1,
    int limit = 80,
    String? sortBy,
    String? fileId,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = {
        'page': page,
        'limit': limit,
        if (sortBy == 'asc' || sortBy == 'dsc') ...{
          'sortBy': 'name',
          'order': sortBy,
        } else if (sortBy != null && sortBy.isNotEmpty) ...{
          'sortBy': sortBy,
        } else ...{
          'sortBy': 'name',
        },
      };

      final response = await dio.get('$_baseUrl/folders/$fileId',
          options: Options(headers: headers), queryParameters: queryParams);

      final data = (response.data['rows'] as List?) ?? [];
      return data.map((e) => StarredFolder.fromJson(e)).toList();
    } catch (e) {
      _handleError(e, 'fetchinsideFolders');
      rethrow;
    }
  }

  Future<List<StarredFolder>> fetchTrash({
    int page = 1,
    int limit = 80,
    String? sortBy,
  }) async {
    try {
      final headers = await _getHeaders();

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

      final data = (response.data['rows'] as List?) ?? [];
      return data.map((e) => StarredFolder.fromJson(e)).toList();
    } catch (e) {
      _handleError(e, 'fetchTrash');
      rethrow;
    }
  }

  Future<void> starred({required List<String> fileIDs}) async {
    try {
      final headers = await _getHeaders();

      final response = await dio.put(
        '$_baseUrl/star',
        data: {'fileId': fileIDs},
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        Messenger.alertSuccess('Starred successfully!');
      } else {
        log('starred failed: Status ${response.statusCode}, Response: ${response.data}');
      }
    } catch (e, stackTrace) {
      log('Exception in starred: $e\n$stackTrace');
    }
  }

  Future<void> reNamebloc({
    required List<String> fileIDs,
    required String editedName,
  }) async {
    final headers = await _getHeaders();
    bool allSuccess = true;

    for (final id in fileIDs) {
      try {
        final response = await dio.put(
          '$_baseUrl/folders/$id',
          data: {'name': editedName},
          options: Options(headers: headers),
        );

        if (response.statusCode != 200) {
          allSuccess = false;
          log('Failed to rename folder $id: Status ${response.statusCode}, Response: ${response.data}');
        }
      } catch (e, stackTrace) {
        allSuccess = false;
        log('Exception while renaming folder $id: $e\n$stackTrace');
      }
    }

    if (allSuccess) {
      Messenger.alertSuccess('All folders renamed successfully!');
    } else {}
  }

  Future<void> organized({
    required List<String> fileIDs,
    required String pickedColor,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await dio.post(
        '$_baseUrl/organize',
        data: {'fileId': fileIDs, 'color': pickedColor},
        options: Options(headers: headers),
      );
      if (response.statusCode == 200) {
        Messenger.alertSuccess('Organize successfully!');
      } else {
        log(' failed: Status ${response.statusCode}, Response: ${response.data}');
      }
    } catch (e) {
      _handleError(e, 'organized');
      rethrow;
    }
  }

  Future<void> moveToTrash({required List<String> fileIDs}) async {
    try {
      final headers = await _getHeaders();
      final response = await dio.put(
        '$_baseUrl/folders?bin=trash',
        data: {'fileId': fileIDs},
        options: Options(headers: headers),
      );
      if (response.statusCode == 200) {
        Messenger.alertSuccess('Trashed successfully!');
      } else {
        log('starred failed: Status ${response.statusCode}, Response: ${response.data}');
      }
    } catch (e) {
      _handleError(e, 'moveToTrash');
      rethrow;
    }
  }

  Future<void> deletePermanetly({required List<String> fileIDs}) async {
    try {
      final headers = await _getHeaders();
      final response = await dio.put(
        '$_baseUrl/folders/permanent',
        data: {'fileId': fileIDs},
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        if (fileIDs.length == 1) {
          Messenger.alertSuccess('File deleted permanently.');
        } else {
          Messenger.alertSuccess(
              '${fileIDs.length} files deleted permanently.');
        }
      } else {
        log('deletePermanetly failed: Status ${response.statusCode}, Response: ${response.data}');
      }
    } catch (e) {
      _handleError(e, 'deletePermanetly');
    }
  }

  Future<void> restoreAll({required List<String> fileIDs}) async {
    try {
      final headers = await _getHeaders();
      final response = await dio.put(
        '$_baseUrl/folders?bin=restore',
        data: {'fileId': fileIDs},
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        if (fileIDs.length == 1) {
          Messenger.alertSuccess('File restored successfully.');
        } else {
          Messenger.alertSuccess(
              '${fileIDs.length} files restored successfully.');
        }
      } else {
        log('restoreAll failed: Status ${response.statusCode}, Response: ${response.data}');
      }
    } catch (e) {
      _handleError(e, 'restoreAll');
    }
  }

  Future<void> renameFolder(String folderId, String newName) async {
    try {
      final headers = await _getHeaders();

      final response = await dio.put(
        '$_baseUrl/folders/$folderId',
        data: {'name': newName},
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        Messenger.alertSuccess('Folder renamed successfully!');
      } else {
        log('renameFolder failed: Status code ${response.statusCode}, Response: ${response.data}');
      }
    } catch (e, stackTrace) {
      log('renameFolder exception: $e\n$stackTrace');
    }
  }

  void _handleError(Object error, String context) {
    if (error is DioException) {
      log('[$context] DioException: ${error.response?.statusCode} - ${error.message}');
    } else {
      log('[$context] Unexpected error: $error');
    }
  }
}
