import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:nde_email/data/respiratory.dart' show UserPreferences;
import 'package:nde_email/presantation/drive/model/mydrive_model.dart';
import 'package:nde_email/utils/const/consts.dart' as DriveService;
import 'package:nde_email/utils/snackbar/snackbar.dart';

class MyDriveRepository {
  final Dio dio;
  // final String _baseUrl;

  MyDriveRepository({Dio? dio}) : dio = dio ?? Dio();

  static const String _baseUrl = 'https://api.nowdigitaleasy.com/drive/v1';

  Future<List<Rows>> fetchMyDriveFolders({
    int page = 1,
    int limit = 50,
    String sortBy = 'updatedAt',
    String order = 'asc',
    String? file,
    String? owner,
    String? myfiles,
    String? fromDate,
    String? endDate,
    String? myfile,
  }) async {
    try {
      log("calling");
      final String? accessToken = await UserPreferences.getAccessToken();
      final String? defaultWorkspace =
          await UserPreferences.getDefaultWorkspace();

      if (accessToken == null || defaultWorkspace == null) {
        throw Exception('Missing authentication credentials');
      }

      final headers = <String, String>{
        'Authorization': 'Bearer $accessToken',
        'x-workspace': defaultWorkspace,
        'Content-Type': 'application/json',
      };

      final queryParams = <String, dynamic>{
        'limit': limit,
        'page': page,
        'sortby': sortBy,
        'order': order,
        if (file != null && file.isNotEmpty) 'file': file,
        if (owner != null && owner.isNotEmpty) 'owner': owner,
        if (myfiles != null && myfiles.isNotEmpty) 'myfiles': myfiles,
        if (fromDate != null && fromDate.isNotEmpty) 'fromdate': fromDate,
        if (endDate != null && endDate.isNotEmpty) 'enddate': endDate,
        if (myfile != null && myfile.isNotEmpty) 'myfile': myfile,
      };

      log('Fetching My Drive folders with queryParams: $queryParams');

      final response = await dio.get(
        '$_baseUrl/folders',
        options: Options(headers: headers),
        queryParameters: queryParams,
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to load My Drive folders: ${response.statusCode}');
      }

      final driveModel = DriveModel.fromJson(response.data);
      log('Fetched: ${driveModel.rows.length} items');
      return driveModel.rows;
    } on DioException catch (e, stack) {
      log('Dio error: ${e.message}', stackTrace: stack);
      throw Exception('Dio error: ${e.response?.data ?? e.message}');
    } catch (e, stack) {
      log('Unexpected error: $e', stackTrace: stack);
      throw Exception('Unexpected error occurred: $e');
    }
  }

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

  Future<List<Rows>> fetchStarredFolders({
    int page = 1,
    int limit = 50,
    String? sortBy,
  }) async {
    try {
      final headers = await _getHeaders();
      if (headers == null) return [];

      final response = await dio.get(
        '$_baseUrl/folders',
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
        },
      );

      final driveModel = DriveModel.fromJson(response.data);
      return driveModel.rows;
    } catch (e, stack) {
      log('fetchStarredFolders error: $e', stackTrace: stack);
      return [];
    }
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
      log(
        'fetchInsideFolders error: $e',
      );
    }
  }

  Future<bool> rename({
    required List<String> fileIDs,
    required String editedName,
  }) async {
    final headers = await _getHeaders();
    if (headers == null) return false;

    final body = {'name': editedName};
    bool allSuccess = true;

    for (final id in fileIDs) {
      try {
        final response = await dio.put(
          '$_baseUrl/folders/$id',
          data: body,
          options: Options(headers: headers),
        );
        if (response.statusCode != 200) {
          log('Rename failed for $id');
          allSuccess = false;
        }
      } catch (e, stack) {
        log('rename error for $id: $e', stackTrace: stack);
        allSuccess = false;
      }
    }

    if (allSuccess) {
      Messenger.alertSuccess(
        fileIDs.length == 1
            ? 'Item renamed successfully'
            : '${fileIDs.length} items renamed successfully',
      );
    }
    return allSuccess;
  }

  Future<List<Rows>> fetchInsideFolders({
    int page = 1,
    int limit = 45,
    String? sortBy,
    required String fileId,
  }) async {
    try {
      final headers = await _getHeaders();
      if (headers == null) return [];

      final response = await dio.get(
        '$_baseUrl/folders/$fileId',
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
        },
      );

      final driveModel = DriveModel.fromJson(response.data);
      return driveModel.rows;
    } catch (e, stack) {
      log('fetchInsideFolders error: $e', stackTrace: stack);
      return [];
    }
  }

  Future<bool> organize({
    required List<String> fileIDs,
    required dynamic pickedColor,
  }) async {
    final headers = await _getHeaders();
    if (headers == null) return false;

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
        return true;
      } else {
        log('Failed to color folder(s): ${response.statusCode}');
        return false;
      }
    } catch (e, stack) {
      log('organized error: $e', stackTrace: stack);
      return false;
    }
  }

  Future<List<Rows>> fetchTrash({
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

      final response = await dio.get(
        '$_baseUrl/folders',
        options: Options(headers: headers),
        queryParameters: queryParams,
      );

      final driveModel = DriveModel.fromJson(response.data);
      return driveModel.rows;
    } catch (e, stack) {
      log('fetchTrash error: $e', stackTrace: stack);
      return [];
    }
  }

  Future<bool> starred({required List<String> fileIDs}) async {
    final headers = await _getHeaders();
    if (headers == null) return false;

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
        return true;
      } else {
        log('Failed to star folder(s): ${response.statusCode}');
        return false;
      }
    } catch (e, stack) {
      log('starred error: $e', stackTrace: stack);
      return false;
    }
  }

  Future<bool> moveToTrash({required List<String> fileIDs}) async {
    final headers = await _getHeaders();
    if (headers == null) return false;

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
        return true;
      } else {
        log('Failed to move to trash: ${response.statusCode}');
        return false;
      }
    } catch (e, stack) {
      log('moveToTrash error: $e', stackTrace: stack);
      return false;
    }
  }

  Future<bool> deletePermanently({required List<String> fileIDs}) async {
    final headers = await _getHeaders();
    if (headers == null) return false;

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
        return true;
      } else {
        log('Failed to permanently delete: ${response.statusCode}');
        return false;
      }
    } catch (e, stack) {
      log('deletePermanently error: $e', stackTrace: stack);
      return false;
    }
  }

  Future<bool> restoreAll({required List<String> fileIDs}) async {
    final headers = await _getHeaders();
    if (headers == null) return false;

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
        return true;
      } else {
        log('Failed to restore: ${response.statusCode}');
        return false;
      }
    } catch (e, stack) {
      log('restoreAll error: $e', stackTrace: stack);
      return false;
    }
  }
}
