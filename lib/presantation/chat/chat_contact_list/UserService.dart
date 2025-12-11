import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:nde_email/data/respiratory.dart';

class UserService {
  final Dio _dio = Dio();

  Future<Map<String, dynamic>> getUserList({
    required int page,
    required int limit,
  }) async {
    try {
      final String? accessToken = await UserPreferences.getAccessToken();
      final String? defaultWorkspace =
          await UserPreferences.getDefaultWorkspace();

      if (accessToken == null) {
        throw Exception('Access token is null');
      }

      const String baseUrl = 'https://api.nowdigitaleasy.com/wschat/v1';
      final String url = '$baseUrl/employees?page=$page&limit=$limit';

      final Map<String, String> headers = {
        'Authorization': 'Bearer $accessToken',
        'x-workspace': defaultWorkspace ?? "",
        'Content-Type': 'application/json',
      };

      final response = await _dio.get(url, options: Options(headers: headers));

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
      //  log('User list fetched successfully: $data');

        return {
          'onlineUsers': data['onlineUsers'] ?? <String>[],
          'data': data['data'] ?? <dynamic>[],
          'total': data['total'] ?? 0,
          'page': data['page'] ?? page,
          'limit': data['limit'] ?? limit,
          'hasPreviousPage': data['hasPreviousPage'] ?? false,
          'hasNextPage': data['hasNextPage'] ?? false,
          'profile_pic': data['profile_pic'] ?? "",
        };
      } else {
        throw Exception(
            'Failed to load users: Status code ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error fetching users: $e');
    }
  }
}
