import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/presantation/drive/model/recent/recent_model.dart';
import 'package:nde_email/utils/snackbar/snackbar.dart';

class RecentRepo {
  final Dio dio;
  static const String _baseUrl = 'https://api.nowdigitaleasy.com/drive/v1';

  RecentRepo({Dio? dio}) : dio = dio ?? Dio();

  Future<List<RecentModel>> fetchStarredFolders({
    required int page,
    required int limit,
    String? sortBy,
  }) async {
    try {
      log("Fetching starred folders");

      final accessToken = await UserPreferences.getAccessToken();
      final defaultWorkspace = await UserPreferences.getDefaultWorkspace();

      if (accessToken == null || defaultWorkspace == null) {
        throw Exception('Missing authentication credentials');
      }

      final response = await dio.get(
        '$_baseUrl/folders',
        options: Options(headers: {
          'Authorization': 'Bearer $accessToken',
          'x-workspace': defaultWorkspace,
          'Content-Type': 'application/json',
        }),
        queryParameters: {
          'page': page,
          'limit': limit,
          'sortBy': 'updatedAt',
          'order': 'asc',
          'home': true,
          'type': 'file',
        },
      );

      final json = response.data;
      if (json is Map<String, dynamic>) {
        final rows = json['rows'];
        if (rows is List) {
          return rows.map((e) => RecentModel.fromJson(e)).toList();
        }
      }

      throw Exception('Invalid response format');
    } catch (e, stack) {
      log('fetchStarredFolders error: $e', stackTrace: stack);
      return [];
    }
  }

  Future<List<RecentModel>> fetchingupdatedFolders({
    int page = 1,
    int limit = 60,
    String? sortBy,
    required String fileID,
  }) async {
    try {
      if (fileID.isEmpty) throw Exception("fileID is required");

      final accessToken = await UserPreferences.getAccessToken();
      final defaultWorkspace = await UserPreferences.getDefaultWorkspace();
      if (accessToken == null || defaultWorkspace == null) {
        throw Exception('Missing authentication credentials');
      }

      final response = await dio.get(
        '$_baseUrl/folders/$fileID',
        options: Options(headers: {
          'Authorization': 'Bearer $accessToken',
          'x-workspace': defaultWorkspace,
          'Content-Type': 'application/json',
        }),
        queryParameters: {
          'page': page,
          'limit': limit,
          'sortBy': 'updatedAt',
          'order': sortBy ?? 'asc',
          'home': true,
          'type': 'file',
        },
      );

      final json = response.data;
      if (json is Map<String, dynamic>) {
        final rows = json['rows'];
        if (rows is List) {
          return rows.map((e) => RecentModel.fromJson(e)).toList();
        }
      }

      throw Exception('Invalid response format');
    } catch (e, stack) {
      log('fetchingupdatedFolders error: $e', stackTrace: stack);
      return [];
    }
  }

  Future<List<RecentModel>> fetchinsideFolders({
    int page = 1,
    int limit = 80,
    String? sortBy,
    required String fileId,
  }) async {
    try {
      if (fileId.isEmpty) throw Exception("fileId is required");

      final accessToken = await UserPreferences.getAccessToken();
      final defaultWorkspace = await UserPreferences.getDefaultWorkspace();

      if (accessToken == null || defaultWorkspace == null) {
        throw Exception('Missing authentication credentials');
      }

      final response = await dio.get(
        '$_baseUrl/folders/$fileId',
        options: Options(headers: {
          'Authorization': 'Bearer $accessToken',
          'x-workspace': defaultWorkspace,
          'Content-Type': 'application/json',
        }),
        queryParameters: {
          'page': page,
          'limit': limit,
          'sortBy': 'updatedAt',
          'order': sortBy ?? 'asc',
          'home': true,
          'type': 'file',
        },
      );

      final json = response.data;
      if (json is Map<String, dynamic>) {
        final rows = json['rows'];
        if (rows is List) {
          return rows.map((e) => RecentModel.fromJson(e)).toList();
        }
      }

      throw Exception('Invalid response format');
    } catch (e, stack) {
      log('fetchinsideFolders error: $e', stackTrace: stack);
      return [];
    }
  }

  Future<List<RecentModel>> fetchTrash({
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

      final response = await dio.get(
        '$_baseUrl/folders',
        options: Options(headers: {
          'Authorization': 'Bearer $accessToken',
          'x-workspace': defaultWorkspace,
          'Content-Type': 'application/json',
        }),
        queryParameters: {
          'page': page,
          'limit': limit,
          'sortBy': sortBy ?? 'updatedAt',
          'order': 'asc',
          'home': true,
          'type': 'file',
          'deletedAt': true,
        },
      );

      final json = response.data;
      if (json is Map<String, dynamic>) {
        final rows = json['rows'];
        if (rows is List) {
          return rows.map((e) => RecentModel.fromJson(e)).toList();
        }
      }

      throw Exception('Invalid response format');
    } catch (e, stack) {
      log('fetchTrash error: $e', stackTrace: stack);
      return [];
    }
  }

  Future<void> starred({required List<String> fileIDs}) async {
    try {
      final accessToken = await UserPreferences.getAccessToken();
      final defaultWorkspace = await UserPreferences.getDefaultWorkspace();

      if (accessToken == null || defaultWorkspace == null) {
        throw Exception('Missing authentication credentials');
      }

      final response = await dio.put(
        '$_baseUrl/star',
        data: {'fileId': fileIDs},
        options: Options(headers: {
          'Authorization': 'Bearer $accessToken',
          'x-workspace': defaultWorkspace,
          'Content-Type': 'application/json',
        }),
      );

      if (response.statusCode == 200) {
        Messenger.alertSuccess(fileIDs.length == 1
            ? 'Item starred successfully'
            : '${fileIDs.length} items starred successfully');
      } else {
        throw Exception('Failed to star folder(s)');
      }
    } catch (e, stack) {
      log('starred error: $e', stackTrace: stack);
    }
  }

  Future<void> moveToTrash({required List<String> fileIDs}) async {
    try {
      final accessToken = await UserPreferences.getAccessToken();
      final defaultWorkspace = await UserPreferences.getDefaultWorkspace();

      if (accessToken == null || defaultWorkspace == null) {
        throw Exception('Missing authentication credentials');
      }

      final response = await dio.put(
        '$_baseUrl/folders?bin=trash',
        data: {'fileId': fileIDs},
        options: Options(headers: {
          'Authorization': 'Bearer $accessToken',
          'x-workspace': defaultWorkspace,
          'Content-Type': 'application/json',
        }),
      );

      if (response.statusCode == 200) {
        Messenger.alertSuccess(fileIDs.length == 1
            ? 'Item moved to trash'
            : '${fileIDs.length} items moved to trash');
      } else {
        throw Exception('Failed to move to trash');
      }
    } catch (e, stack) {
      log('moveToTrash error: $e', stackTrace: stack);
    }
  }

  Future<void> deletePermanetly({required List<String> fileIDs}) async {
    try {
      final accessToken = await UserPreferences.getAccessToken();
      final defaultWorkspace = await UserPreferences.getDefaultWorkspace();

      if (accessToken == null || defaultWorkspace == null) {
        throw Exception('Missing authentication credentials');
      }

      final response = await dio.put(
        '$_baseUrl/folders/permanent',
        data: {'fileId': fileIDs},
        options: Options(headers: {
          'Authorization': 'Bearer $accessToken',
          'x-workspace': defaultWorkspace,
          'Content-Type': 'application/json',
        }),
      );

      if (response.statusCode == 200) {
        Messenger.alertSuccess(fileIDs.length == 1
            ? 'Item deleted permanently'
            : '${fileIDs.length} items deleted permanently');
      } else {
        throw Exception('Failed to delete permanently');
      }
    } catch (e, stack) {
      log('deletePermanetly error: $e', stackTrace: stack);
    }
  }

  Future<void> restoreAll({required List<String> fileIDs}) async {
    try {
      final accessToken = await UserPreferences.getAccessToken();
      final defaultWorkspace = await UserPreferences.getDefaultWorkspace();

      if (accessToken == null || defaultWorkspace == null) {
        throw Exception('Missing authentication credentials');
      }

      final response = await dio.put(
        '$_baseUrl/folders?bin=restore',
        data: {'fileId': fileIDs},
        options: Options(headers: {
          'Authorization': 'Bearer $accessToken',
          'x-workspace': defaultWorkspace,
          'Content-Type': 'application/json',
        }),
      );

      if (response.statusCode == 200) {
        Messenger.alertSuccess(fileIDs.length == 1
            ? 'Item restored successfully'
            : '${fileIDs.length} items restored successfully');
      } else {
        throw Exception('Failed to restore folder(s)');
      }
    } catch (e, stack) {
      log('restoreAll error: $e', stackTrace: stack);
    }
  }
}
