import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/data/base_url.dart';
import 'package:nde_email/presantation/drive/model/search_model/search_model.dart';
import 'package:nde_email/presantation/drive/model/send/send_model.dart';

class FoldersRepository {
  final Dio dio;

  FoldersRepository({Dio? dio}) : dio = dio ?? Dio();

  Future<Map<String, String>> _buildHeaders({bool isMeili = false}) async {
    final String? accessToken = isMeili
        ? await UserPreferences.getMeiliTenantToken()
        : await UserPreferences.getAccessToken();
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

  Future<void> moveFolderToTrash(String folderId) async {
    try {
      final headers = await _buildHeaders();

      final response = await dio.put(
        '${DriveService.baseUrl}/folders/',
        options: Options(headers: headers),
        queryParameters: {'bin': 'trash'},
        data: {
          'fileId': [folderId]
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to move folder to trash');
      }

      log('Folder moved to trash: $folderId');
    } catch (e) {
      log('Error moving folder to trash: $e');
      rethrow;
    }
  }

  Future<void> toggleStar(String fileId, {bool? starred}) async {
    try {
      final headers = await _buildHeaders();

      final response = await dio.put(
        '${DriveService.baseUrl}/star/',
        options: Options(headers: headers),
        data: {
          'fileId': [fileId],
          'starred': starred,
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to toggle star');
      }

      log('Toggled star for file: $fileId');
    } catch (e) {
      log('Error toggling star: $e');
      rethrow;
    }
  }

  Future<void> renameFolder(String folderId, String newName) async {
    try {
      final headers = await _buildHeaders();

      final response = await dio.put(
        '${DriveService.baseUrl}/folders/$folderId',
        options: Options(headers: headers),
        data: {'name': newName},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to rename folder');
      }

      log('Folder renamed: $folderId -> $newName');
    } catch (e) {
      log('Error renaming folder: $e');
      rethrow;
    }
  }

  Future<void> downloadFile(String fileId) async {
    try {
      final headers = await _buildHeaders();

      final response = await dio.post(
        '${DriveService.baseUrl}/download',
        options: Options(headers: headers, responseType: ResponseType.bytes),
        data: {
          'fileId': [fileId]
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to download file');
      }

      log('File downloaded: $fileId');
    } catch (e) {
      log('Error downloading file: $e');
      rethrow;
    }
  }

  Future<void> organized({
    required List<String> fileIDs,
    required String pickedColor,
  }) async {
    try {
      final headers = await _buildHeaders();

      final response = await dio.post(
        'https://api.nowdigitaleasy.com/drive/v1/organize',
        options: Options(headers: headers),
        data: {
          'fileId': fileIDs,
          'color': pickedColor,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to organize folders');
      }

      log('Folders organized with color $pickedColor');
    } catch (e) {
      log('Error organizing folders: $e');
      rethrow;
    }
  }

  Future<SendData> getShareDetails(String fileId) async {
    try {
      final headers = await _buildHeaders();

      final response = await dio.get(
        '${DriveService.baseUrl}/shares/$fileId',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        return SendData.fromJson(response.data);
      } else {
        throw Exception('Failed to fetch share details');
      }
    } catch (e) {
      log('Error fetching share details: $e');
      rethrow;
    }
  }

  Future<List<UserSearchResult>> searchUsers(String query) async {
    try {
      final headers = await _buildHeaders(isMeili: true);

      final response = await dio.post(
        'https://search.nowdigitaleasy.com/indexes/userIndex/search',
        options: Options(headers: headers),
        data: {'q': query},
      );

      if (response.statusCode == 200) {
        final hits = response.data['hits'] as List;
        return hits.map((json) => UserSearchResult.fromJson(json)).toList();
      } else {
        throw Exception('Search failed');
      }
    } catch (e) {
      log('Error searching users: $e');
      rethrow;
    }
  }

  Future<void> shareFileWithUsers({
    required String fileId,
    required List<String> emails,
    required String permission,
    required bool notify,
    required String message,
  }) async {
    try {
      final headers = await _buildHeaders();

      final response = await dio.post(
        '${DriveService.baseUrl}/shares',
        options: Options(headers: headers),
        data: {
          "fileId": [fileId],
          "sharewith": emails,
          "permission": permission,
          "notifi": notify,
          "message": message,
        },
      );

      if (response.statusCode != 200) {
        throw Exception(response.data['message'] ?? 'Failed to share file');
      }

      log('File shared with users: $emails');
    } catch (e) {
      log('Error sharing file: $e');
      rethrow;
    }
  }

  Future<void> moveFileToFolder({
    required List<String> fileId,
    required String destinationId,
  }) async {
    try {
      final headers = await _buildHeaders();

      final response = await dio.put(
        '${DriveService.baseUrl}/folders/relocate',
        options: Options(headers: headers),
        data: {
          "fileId": fileId,
          "parentId": destinationId,
        },
      );

      if (response.statusCode != 200) {
        throw Exception(response.data['message'] ?? 'Failed to move file');
      }

      log('Files moved to folder: $destinationId');
    } catch (e) {
      log('Error moving file to folder: $e');
      rethrow;
    }
  }
}
