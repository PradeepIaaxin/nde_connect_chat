import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/presantation/drive/model/folderinfo_model.dart';

class MyInfoRepository {
  final Dio dio;
  static const String _baseUrl = 'https://api.nowdigitaleasy.com/drive/v1';

  MyInfoRepository({Dio? dio}) : dio = dio ?? Dio();

  Future<FolderResponse?> fetchStarredFolders({
    int page = 1,
    int limit = 80,
    String? fileId,
  }) async {
    try {
      final String? accessToken = await UserPreferences.getAccessToken();
      final String? defaultWorkspace =
          await UserPreferences.getDefaultWorkspace();

      if (accessToken == null || defaultWorkspace == null) {
        log('  Missing authentication credentials');
        return null;
      }

      if (fileId == null || fileId.isEmpty) {
        log('  fileId is null or empty');
        return null;
      }

      final Map<String, String> headers = {
        'Authorization': 'Bearer $accessToken',
        'x-workspace': defaultWorkspace,
        'Content-Type': 'application/json',
      };

      final queryParams = {
        'page': page,
        'limit': limit,
      };

      final response = await dio.get(
        '$_baseUrl/files/details/$fileId',
        options: Options(headers: headers),
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        log(" Folder details fetched successfully");
        return FolderResponse.fromJson(response.data);
      } else {
        log('  Failed to fetch folder details: ${response.statusCode}');
        return null;
      }
    } on DioException catch (e) {
      print('  DioException: ${e.message}');
      return null;
    } catch (e) {
      print('  Unexpected error: $e');
      return null;
    }
  }
}
