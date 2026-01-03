import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nde_email/bridge_generated.dart/api.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/group_model.dart';
import 'package:path/path.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart' as MediaType;
import 'dart:convert';
import '../../../data/respiratory.dart';

class GrpMessagerApiService {
  late final BuildContext context;

//   Future<GroupMessageResponse> fetchMessages({
//   required String convoId,
//   required int page,
//   required int limit,
// }) async {
//   final token = await UserPreferences.getAccessToken();
//   final workspace = await UserPreferences.getDefaultWorkspace();

//   const baseUrl = 'https://api.nowdigitaleasy.com/wschat/v1/messages';

//   final uri = Uri.parse(baseUrl).replace(queryParameters: {
//     'convoId': convoId,
//     'page': page.toString(),
//     'limit': limit.toString(),
//   });

//   final response = await http.get(
//     uri,
//     headers: {
//       'Authorization': 'Bearer $token',
//       'x-workspace': workspace ?? '',
//       'Content-Type': 'application/json',
//     },
//   );

//   if (response.statusCode != 200) {
//     throw Exception('Failed to fetch group messages');
//   }

//   return GroupMessageResponse.fromJson(jsonDecode(response.body));
// }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return 'Today';
    if (d == yesterday) return 'Yesterday';

    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  Future<GroupMessageResponse> fetchMessages({
    required String convoId,
    required int page,
    required int limit,
  }) async {
    final token = await UserPreferences.getAccessToken();
    final workspace = await UserPreferences.getDefaultWorkspace();

    const baseUrl = 'https://api.nowdigitaleasy.com/wschat/v1/messages';

    final uri = Uri.parse(baseUrl).replace(queryParameters: {
      'convoId': convoId,
      'page': page.toString(),
      'limit': limit.toString(),
    });

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'x-workspace': workspace ?? '',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch group messages');
    }

    final jsonData = jsonDecode(response.body);

    // ==================================================
    // 🔥 SNAPSHOT FLOW (SAME AS PRIVATE CHAT)
    // ==================================================
    if (jsonData['snapshot'] != null) {
      final snapshotBase64 = jsonData['snapshot'];
      log('📥 Group Snapshot received');

      await resetGlobalDoc();

      final jsonString =
          await decodeMessageSnapshot(snapshotBase64: snapshotBase64);

      final decoded = jsonDecode(jsonString);

      final Map messageMap = decoded['messages'] ?? {};
      final List<GroupMessageModel> flat = [];

      for (final entry in messageMap.entries) {
        flat.add(
          GroupMessageModel.fromJson(
            Map<String, dynamic>.from(entry.value),
          ),
        );
      }

      // sort by time (oldest → newest)
      flat.sort((a, b) => a.time.compareTo(b.time));

      // group by date label
      final grouped = _groupMessagesByDate(flat);

      return GroupMessageResponse(
        data: grouped,
        total: flat.length,
        page: 1,
        limit: limit,
        hasPreviousPage: false,
        hasNextPage: flat.length >= limit,
      );
    }

    // ==================================================
    // 🔁 NORMAL REST FLOW (FALLBACK)
    // ==================================================
    return GroupMessageResponse.fromJson(jsonData);
  }

  List<GroupMessageGroup> _groupMessagesByDate(
    List<GroupMessageModel> messages,
  ) {
    final Map<String, List<GroupMessageModel>> map = {};

    for (final msg in messages) {
      final date = DateTime(
        msg.time.year,
        msg.time.month,
        msg.time.day,
      );

      final label = _formatDate(date);

      map.putIfAbsent(label, () => []);
      map[label]!.add(msg);
    }

    return map.entries
        .map((e) => GroupMessageGroup(label: e.key, messages: e.value))
        .toList();
  }

  // Future<GroupMessageResponse> fetchMessages({
  //   required String convoId,
  //   required int page,
  //   required int limit,
  // }) async {
  //   final token = await UserPreferences.getAccessToken();
  //   final defaultWorkspace = await UserPreferences.getDefaultWorkspace();

  //   if (token == null || token.isEmpty) {
  //     throw Exception('Authentication token not found. Please log in again.');
  //   }

  //   if (defaultWorkspace == null || defaultWorkspace.isEmpty) {
  //     throw Exception('No default workspace found. Please select a workspace.');
  //   }

  //   const baseUrl = 'https://api.nowdigitaleasy.com/wschat/v1/messages';
  //   final queryParams = {
  //     'convoId': convoId,
  //     'page': page.toString(),
  //     'limit': limit.toString(),
  //   };

  //   final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);

  //   final response = await http.get(
  //     uri,
  //     headers: {
  //       'Authorization': 'Bearer $token',
  //       'x-workspace': defaultWorkspace,
  //       'Content-Type': 'application/json',
  //     },
  //   );

  //   if (response.statusCode == 200) {
  //     final responseData = jsonDecode(response.body) as Map<String, dynamic>;
  //     log("📦 API RAW RESPONSE KEYS: ${responseData.keys}");
  //     log("📄 API page=${responseData['page']}");
  //     log("📊 API total=${responseData['total']}");
  //     log("📦 API data length=${(responseData['data'] as List).length}");

  //     // log('API Response: ${responseData.toString()}');
  //     return GroupMessageResponse.fromJson(responseData);
  //   } else {
  //     throw Exception(
  //         'Failed to load messages. Status Code: ${response.statusCode}');
  //   }
  // }

  Future<Map<String, dynamic>> fetchGroupDetails(String groupId) async {
    final token = await UserPreferences.getAccessToken();
    final defaultWorkspace = await UserPreferences.getDefaultWorkspace();

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found.');
    }

    final uri =
        Uri.parse('https://api.nowdigitaleasy.com/wschat/v1/group/$groupId');

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'x-workspace': defaultWorkspace ?? '',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load group details: ${response.statusCode}');
    }
  }

  Future<void> uploadFile({
    required File file,
    required void Function(int progress) onProgress,
    required void Function(dynamic data) onSuccess,
    required void Function(String error) onError,
  }) async {
    final dio = Dio();

    // Get file details
    final fileName = basename(file.path);
    final mimeType = lookupMimeType(file.path);
    final mediaType =
        mimeType != null ? MediaType.MediaType.parse(mimeType) : null;

    // Print MIME type separately
    log("🔍 Detected MIME type: $mimeType");

    // Fetch token and workspace
    final token = await UserPreferences.getAccessToken();
    final workspace = await UserPreferences.getDefaultWorkspace();

    // Print file and authentication details
    log("📦 Starting upload...");
    log("📁 File path: ${file.path}");
    log("📎 File name: $fileName");
    log("🪪 Token: $token");
    log("🧭 Workspace: $workspace");

    // Create form data
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: fileName,
        contentType: mediaType,
      ),
    });

    try {
      // Send the file via POST request
      final response = await dio.post(
        'https://api.nowdigitaleasy.com/wschat/v1/messages/upload/file',
        data: formData,
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'x-workspace': workspace,
        }),
        onSendProgress: (sent, total) {
          final progress = ((sent / total) * 100).toInt();
          // Print upload progress separately
          log("📤 Upload progress: $progress%");
          onProgress(progress);
        },
      );

      // Print response status separately
      log(" Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        // Print individual response data elements
        log("  Response data received successfully!");
        final responseData = response.data;

        onSuccess(responseData);
      } else {
        final error = "Upload failed with status: ${response.statusCode}";
        log("  $error");
        onError(error);
      }
    } catch (e) {
      // Print any exceptions separately
      log("  Upload exception: $e");
      onError(e.toString()); // Pass exception to onError
    }
  }

  String generateRoomId(String senderId, String receiverId) {
    final ids = [senderId, receiverId];
    ids.sort();
    return ids.join('_');
  }

  String _normalizeMessageIdForApi(String messageId) {
    if (messageId.isEmpty) return messageId;

    // If we ever encoded synthetic ids like "forward_<realId>_<timestamp>",
    // extract the real id.
    if (messageId.startsWith('forward_')) {
      final parts = messageId.split('_');
      if (parts.length >= 3) {
        return parts[1]; // the <realId> in the middle
      }
    }

    // otherwise just return original
    return messageId;
  }

  Future<Map<String, dynamic>?> checkPermission({required String grpId}) async {
    try {
      final token = await UserPreferences.getAccessToken();
      final defaultWorkspace = await UserPreferences.getDefaultWorkspace();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found. Please log in again.');
      }

      if (defaultWorkspace == null || defaultWorkspace.isEmpty) {
        throw Exception(
            'No default workspace found. Please select a workspace.');
      }

      final uri = Uri.parse(
        'https://api.nowdigitaleasy.com/wschat/v1/group/permissions/$grpId',
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'x-workspace': defaultWorkspace,
          'Content-Type': 'application/json',
        },
      );

      log("📥 Status Code: ${response.statusCode}");
      log("📨 Response Body: ${response.body}");

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 403) {
        final data = jsonDecode(response.body);
        log('✅ Parsed Response: $data');
        return data;
      } else {
        log("❌ Failed to fetch permissions. Status Code: ${response.statusCode}");
        return null;
      }
    } catch (e, stackTrace) {
      log("❗ Permission check exception: $e\n$stackTrace");
      return null;
    }
  }

  Future<void> reactionUpdated({
    required String messageId,
    required String emoji,
    required String receiverId,
    required String userId,
    required String conversationId,
  }) async {
    try {
      final token = await UserPreferences.getAccessToken();
      final defaultWorkspace = await UserPreferences.getDefaultWorkspace();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found. Please log in again.');
      }

      if (defaultWorkspace == null || defaultWorkspace.isEmpty) {
        throw Exception(
            'No default workspace found. Please select a workspace.');
      }

      final roomId = generateRoomId(userId, receiverId);
      print("Room ID: $roomId");

      // ⭐ Normalize the messageId here so we NEVER send "forward_..."
      final normalizedId = _normalizeMessageIdForApi(messageId);

      const baseUrl = 'https://api.nowdigitaleasy.com/wschat/v1/messages/react';
      final uri = Uri.parse(baseUrl);

      final body = {
        "conversationId": conversationId,
        "messageId": normalizedId,
        "emoji": emoji,
        "roomId": roomId,
      };

      print("📤 sending payload $body");

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'x-workspace': defaultWorkspace,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        log('✅ Reaction updated successfully for message $normalizedId');
      } else {
        log('❌ Failed to update reaction: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      log("Error in reactionUpdated: $e");
    }
  }

  Future<void> reactionRemove({
    required String messageId,
    required String receiverId,
    required String userId,
    required String conversationId,
  }) async {
    try {
      final token = await UserPreferences.getAccessToken();
      final defaultWorkspace = await UserPreferences.getDefaultWorkspace();
      print("printing removing ");

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found. Please log in again.');
      }

      if (defaultWorkspace == null || defaultWorkspace.isEmpty) {
        throw Exception(
            'No default workspace found. Please select a workspace.');
      }

      final roomId = generateRoomId(userId, receiverId);
      print("Room ID: $roomId");

      // ⭐ Normalize here as well
      final normalizedId = _normalizeMessageIdForApi(messageId);

      const baseUrl =
          'https://api.nowdigitaleasy.com/wschat/v1/messages/remove/react';
      final uri = Uri.parse(baseUrl);

      final body = {
        "conversationId": conversationId,
        "messageId": normalizedId,
        "roomId": roomId,
      };

      print("📤 sending payload (remove) $body");

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'x-workspace': defaultWorkspace,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        log('✅ Reaction removed successfully for message $normalizedId');
      } else {
        log('❌ Failed to remove reaction: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      log("Error in reactionRemove: $e");
    }
  }
}
