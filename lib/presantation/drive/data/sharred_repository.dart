import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/presantation/drive/model/shared/sharred_model.dart';
import 'package:nde_email/presantation/drive/model/trash/trashfilemodel.dart';
import 'package:nde_email/utils/snackbar/snackbar.dart';

class SharedRepository {
  final Dio dio;
  static const String _baseUrl = 'https://api.nowdigitaleasy.com/drive/v1';

  SharedRepository({Dio? dio}) : dio = dio ?? Dio();

  Future<FolderResponse?> fetchStarredFolders({
    required int page,
    required int limit,
    String? sortBy,
  }) async {
    try {
      final accessToken = await UserPreferences.getAccessToken();
      final defaultWorkspace = await UserPreferences.getDefaultWorkspace();

      if (accessToken == null || defaultWorkspace == null) {
        throw Exception('Missing authentication credentials');
      }

      final headers = {
        'Authorization': 'Bearer $accessToken',
        'x-workspace': defaultWorkspace,
        'Content-Type': 'application/json',
      };

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

      final response = await dio.get(
        '$_baseUrl/shares',
        options: Options(headers: headers),
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return FolderResponse.fromJson(response.data);
      } else {
        log('Failed to load starred folders: ${response.statusCode}');
        return null;
      }
    } catch (e, st) {
      log('fetchStarredFolders error: $e', stackTrace: st);
      return null;
    }
  }

  Future<bool> reName({
    required List<String> fileIDs,
    required String editedName,
  }) async {
    try {
      final accessToken = await UserPreferences.getAccessToken();
      final defaultWorkspace = await UserPreferences.getDefaultWorkspace();

      if (accessToken == null || defaultWorkspace == null) {
        Messenger.alertError('Missing authentication credentials');
        return false;
      }

      final headers = {
        'Authorization': 'Bearer $accessToken',
        'x-workspace': defaultWorkspace,
        'Content-Type': 'application/json',
      };

      final body = {'name': editedName};

      for (final id in fileIDs) {
        try {
          final response = await dio.put(
            '$_baseUrl/folders/$id',
            data: body,
            options: Options(headers: headers),
          );

          if (response.statusCode != 200) {
            log("Rename failed for $id: ${response.statusCode}");

            return false;
          }
        } on DioException catch (e) {
          log("DioException on reName($id): ${e.message}");

          return false;
        }
      }

      // Success Snackbar
      if (fileIDs.length == 1) {
        Messenger.alertSuccess('Item renamed successfully.');
      } else {
        Messenger.alertSuccess('${fileIDs.length} items renamed successfully.');
      }

      return true;
    } catch (e, st) {
      log('reName error: $e', stackTrace: st);

      return false;
    }
  }

  Future<TrashResponseModel?> fetchTrash({
    int page = 1,
    int limit = 80,
    String? sortBy,
  }) async {
    try {
      final accessToken = await UserPreferences.getAccessToken();
      final defaultWorkspace = await UserPreferences.getDefaultWorkspace();

      if (accessToken == null || defaultWorkspace == null) {
        throw Exception('Missing authentication credentials');
      }

      final headers = {
        'Authorization': 'Bearer $accessToken',
        'x-workspace': defaultWorkspace,
        'Content-Type': 'application/json',
      };

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

      if (response.statusCode == 200) {
        return TrashResponseModel.fromJson(response.data);
      } else {
        log('fetchTrash failed: ${response.statusCode}');
        return null;
      }
    } catch (e, st) {
      log('fetchTrash error: $e', stackTrace: st);
      return null;
    }
  }

  Future<FolderResponse?> starred({required List<String> fileIDs}) async {
    try {
      final accessToken = await UserPreferences.getAccessToken();
      final defaultWorkspace = await UserPreferences.getDefaultWorkspace();

      if (accessToken == null || defaultWorkspace == null) {
        Messenger.alertError('Missing authentication credentials');
        return null;
      }

      final headers = {
        'Authorization': 'Bearer $accessToken',
        'x-workspace': defaultWorkspace,
        'Content-Type': 'application/json',
      };

      final body = {'fileId': fileIDs};

      final response = await dio.put(
        '$_baseUrl/star',
        options: Options(headers: headers),
        data: body,
      );

      if (response.statusCode == 200) {
        Messenger.alertSuccess(
          fileIDs.length == 1
              ? 'Item starred successfully'
              : '${fileIDs.length} items starred',
        );
        return FolderResponse.fromJson(response.data);
      } else {
        log('Failed to update starred folders: ${response.statusCode}');
        return null;
      }
    } catch (e, st) {
      log('starred error: $e', stackTrace: st);

      return null;
    }
  }

  Future<bool> moveToTrash({required List<String> fileIDs}) async {
    try {
      final accessToken = await UserPreferences.getAccessToken();
      final defaultWorkspace = await UserPreferences.getDefaultWorkspace();

      if (accessToken == null || defaultWorkspace == null) {
        Messenger.alertError('Missing authentication credentials');
        return false;
      }

      final headers = {
        'Authorization': 'Bearer $accessToken',
        'x-workspace': defaultWorkspace,
        'Content-Type': 'application/json',
      };

      final response = await dio.put(
        '$_baseUrl/folders?bin=trash',
        data: {'fileId': fileIDs},
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        Messenger.alertSuccess(
          fileIDs.length == 1
              ? 'Item moved to trash'
              : '${fileIDs.length} items moved to trash',
        );
        return true;
      } else {
        return false;
      }
    } catch (e, st) {
      log('moveToTrash error: $e', stackTrace: st);

      return false;
    }
  }

  Future<bool> deletePermanently({required List<String> fileIDs}) async {
    try {
      final accessToken = await UserPreferences.getAccessToken();
      final defaultWorkspace = await UserPreferences.getDefaultWorkspace();

      if (accessToken == null || defaultWorkspace == null) {
        Messenger.alertError('Missing authentication credentials');
        return false;
      }

      final headers = {
        'Authorization': 'Bearer $accessToken',
        'x-workspace': defaultWorkspace,
        'Content-Type': 'application/json',
      };

      final response = await dio.put(
        '$_baseUrl/folders/permanent',
        data: {'fileId': fileIDs},
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        Messenger.alertSuccess(
          fileIDs.length == 1
              ? 'Item deleted permanently'
              : '${fileIDs.length} items deleted permanently',
        );
        return true;
      } else {
        return false;
      }
    } catch (e, st) {
      log('deletePermanently error: $e', stackTrace: st);

      return false;
    }
  }

  Future<bool> restoreAll({required List<String> fileIDs}) async {
    try {
      final accessToken = await UserPreferences.getAccessToken();
      final defaultWorkspace = await UserPreferences.getDefaultWorkspace();

      if (accessToken == null || defaultWorkspace == null) {
        Messenger.alertError('Missing authentication credentials');
        return false;
      }

      final headers = {
        'Authorization': 'Bearer $accessToken',
        'x-workspace': defaultWorkspace,
        'Content-Type': 'application/json',
      };

      final response = await dio.put(
        '$_baseUrl/folders?bin=restore',
        data: {'fileId': fileIDs},
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        Messenger.alertSuccess(
          fileIDs.length == 1
              ? 'Item restored'
              : '${fileIDs.length} items restored',
        );
        return true;
      } else {
        return false;
      }
    } catch (e, st) {
      log('restoreAll error: $e', stackTrace: st);

      return false;
    }
  }
}
