// import 'dart:convert';
// import 'dart:developer';
// import 'dart:io';

// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:http_parser/http_parser.dart' as MediaType;
// import 'package:mime/mime.dart';
// import 'package:path/path.dart';

// import '../../../data/respiratory.dart';
// import 'messager_model.dart';

// class MessagerApiService {
//   late final BuildContext context;

//   Future<AuthResponse> fetchMessages({
//     required String convoId,
//     required int page,
//     required int limit,
//   }) async {
//     final token = await UserPreferences.getAccessToken();
//     final defaultWorkspace = await UserPreferences.getDefaultWorkspace();

//     if (token == null || token.isEmpty) {
//       throw Exception('Authentication token not found. Please log in again.');
//     }

//     if (defaultWorkspace == null || defaultWorkspace.isEmpty) {
//       throw Exception('No default workspace found. Please select a workspace.');
//     }

//     const baseUrl = "https://d72779723a88.ngrok-free.app/v1/messages";
//     //'https://api.nowdigitaleasy.com/wschat/v1/messages';
//     final queryParams = {
//       'convoId': convoId,
//       'page': page.toString(),
//       'limit': 10.toString(),
//     };

//     final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);

//     final response = await http.get(
//       uri,
//       headers: {
//         'Authorization': 'Bearer $token',
//         'x-workspace': defaultWorkspace,
//         'Content-Type': 'application/json',
//       },
//     );

//     if (response.statusCode == 200) {
//       final responseData = jsonDecode(response.body) as Map<String, dynamic>;
//       log(responseData.toString());

//       return AuthResponse.fromJson(responseData);
//     } else {
//       log(response.reasonPhrase.toString());
//       throw Exception(
//           'Failed to load messages. Status Code: ${response.statusCode}');
//     }
//   }

//   String _normalizeMessageIdForApi(String messageId) {
//     if (messageId.isEmpty) return messageId;

//     // If we ever encoded synthetic ids like "forward_<realId>_<timestamp>",
//     // extract the real id.
//     if (messageId.startsWith('forward_')) {
//       final parts = messageId.split('_');
//       if (parts.length >= 3) {
//         return parts[1]; // the <realId> in the middle
//       }
//     }

//     // otherwise just return original
//     return messageId;
//   }

//   Future<void> reactionUpdated({
//     required String messageId,
//     required String emoji,
//     required String receiverId,
//     required String userId,
//     required String conversationId,
//   }) async {
//     try {
//       final token = await UserPreferences.getAccessToken();
//       final defaultWorkspace = await UserPreferences.getDefaultWorkspace();

//       if (token == null || token.isEmpty) {
//         throw Exception('Authentication token not found. Please log in again.');
//       }

//       if (defaultWorkspace == null || defaultWorkspace.isEmpty) {
//         throw Exception(
//             'No default workspace found. Please select a workspace.');
//       }

//       final roomId = generateRoomId(userId, receiverId);
//       print("Room ID: $roomId");

//       // ⭐ Normalize the messageId here so we NEVER send "forward_..."
//       final normalizedId = _normalizeMessageIdForApi(messageId);

//       const baseUrl = 'https://api.nowdigitaleasy.com/wschat/v1/messages/react';
//       final uri = Uri.parse(baseUrl);

//       final body = {
//         "conversationId": conversationId,
//         "messageId": normalizedId,
//         "emoji": emoji,
//         "roomId": roomId,
//       };

//       print("📤 sending payload $body");

//       final response = await http.post(
//         uri,
//         headers: {
//           'Authorization': 'Bearer $token',
//           'x-workspace': defaultWorkspace,
//           'Content-Type': 'application/json',
//         },
//         body: jsonEncode(body),
//       );

//       if (response.statusCode == 200) {
//         log('✅ Reaction updated successfully for message $normalizedId');
//       } else {
//         log('❌ Failed to update reaction: ${response.statusCode} - ${response.body}');
//       }
//     } catch (e) {
//       log("Error in reactionUpdated: $e");
//     }
//   }

//   Future<void> reactionRemove({
//     required String messageId,
//     required String receiverId,
//     required String userId,
//     required String conversationId,
//   }) async {
//     try {
//       final token = await UserPreferences.getAccessToken();
//       final defaultWorkspace = await UserPreferences.getDefaultWorkspace();
//       print("printing removing ");

//       if (token == null || token.isEmpty) {
//         throw Exception('Authentication token not found. Please log in again.');
//       }

//       if (defaultWorkspace == null || defaultWorkspace.isEmpty) {
//         throw Exception(
//             'No default workspace found. Please select a workspace.');
//       }

//       final roomId = generateRoomId(userId, receiverId);
//       print("Room ID: $roomId");

//       // ⭐ Normalize here as well
//       final normalizedId = _normalizeMessageIdForApi(messageId);

//       const baseUrl =
//           'https://api.nowdigitaleasy.com/wschat/v1/messages/remove/react';
//       final uri = Uri.parse(baseUrl);

//       final body = {
//         "conversationId": conversationId,
//         "messageId": normalizedId,
//         "roomId": roomId,
//       };

//       print("📤 sending payload (remove) $body");

//       final response = await http.post(
//         uri,
//         headers: {
//           'Authorization': 'Bearer $token',
//           'x-workspace': defaultWorkspace,
//           'Content-Type': 'application/json',
//         },
//         body: jsonEncode(body),
//       );

//       if (response.statusCode == 200) {
//         log('✅ Reaction removed successfully for message $normalizedId');
//       } else {
//         log('❌ Failed to remove reaction: ${response.statusCode} - ${response.body}');
//       }
//     } catch (e) {
//       log("Error in reactionRemove: $e");
//     }
//   }

//   String generateRoomId(String senderId, String receiverId) {
//     final ids = [senderId, receiverId];
//     ids.sort();
//     return ids.join('_');
//   }

//   Future<void> uploadFile({
//     required File file,
//     required void Function(int progress) onProgress,
//     required void Function(dynamic data) onSuccess,
//     required void Function(String error) onError,
//   }) async {
//     final dio = Dio();

//     // Get file details
//     final fileName = basename(file.path);
//     final mimeType = lookupMimeType(file.path);
//     final mediaType =
//         mimeType != null ? MediaType.MediaType.parse(mimeType) : null;

//     // Print MIME type separately
//     log("🔍 Detected MIME type: $mimeType");

//     // Fetch token and workspace
//     final token = await UserPreferences.getAccessToken();
//     final workspace = await UserPreferences.getDefaultWorkspace();

//     // Print file and authentication details
//     log("📦 Starting upload...");
//     log("📁 File path: ${file.path}");
//     log("📎 File name: $fileName");
//     log("🪪 Token: $token");
//     log("🧭 Workspace: $workspace");

//     // Create form data
//     final formData = FormData.fromMap({
//       'file': await MultipartFile.fromFile(
//         file.path,
//         filename: fileName,
//         contentType: mediaType,
//       ),
//     });

//     try {
//       // Send the file via POST request
//       final response = await dio.post(
//         'https://api.nowdigitaleasy.com/wschat/v1/messages/upload/file',
//         data: formData,
//         options: Options(headers: {
//           'Authorization': 'Bearer $token',
//           'x-workspace': workspace,
//         }),
//         onSendProgress: (sent, total) {
//           final progress = ((sent / total) * 100).toInt();
//           // Print upload progress separately
//           log("📤 Upload progress: $progress%");
//           onProgress(progress);
//         },
//       );

//       // Print response status separately
//       log(" Response status: ${response.statusCode}");

//       if (response.statusCode == 200) {
//         // Print individual response data elements
//         log("  Response data received successfully!");
//         final responseData = response.data;

//         onSuccess(responseData);
//       } else {
//         final error = "Upload failed with status: ${response.statusCode}";
//         log("  $error");
//         onError(error);
//       }
//     } catch (e) {
//       // Print any exceptions separately
//       log("  Upload exception: $e");
//       onError(e.toString()); // Pass exception to onError
//     }
//   }
// }

import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as MediaType;
import 'package:mime/mime.dart';
import 'package:path/path.dart';

import '../../../data/respiratory.dart';
import 'messager_model.dart';

class MessagerApiService {
  late final BuildContext context;

  /// =============================
  ///   FETCH GROUPED MESSAGES
  /// =============================

  Future<MessageListResponse> fetchMessages({
    required String convoId,
    required int page,
    required int limit,
  }) async {
    final token = await UserPreferences.getAccessToken();
    final defaultWorkspace = await UserPreferences.getDefaultWorkspace();

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found. Please log in again.');
    }

    if (defaultWorkspace == null || defaultWorkspace.isEmpty) {
      throw Exception('No default workspace found. Please select a workspace.');
    }

    const baseUrl = 'https://api.nowdigitaleasy.com/wschat/v1/messages';
    //"https://10ba71d4f797.ngrok-free.app/v1/messages";

    final queryParams = {
      'convoId': convoId,
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'x-workspace': defaultWorkspace,
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      // log("📩 API RESPONSE: $responseData");
      print("responseee $responseData}");

      /// 🔥 Updated return
      return MessageListResponse.fromJson(responseData);
    } else {
      log(response.reasonPhrase.toString());
      throw Exception(
          'Failed to load messages. Status Code: ${response.statusCode}');
    }
  }

  /// =============================
  ///  NORMALIZE MESSAGE IDs
  /// =============================

  String _normalizeMessageIdForApi(String messageId) {
    if (messageId.isEmpty) return messageId;

    if (messageId.startsWith('forward_')) {
      final parts = messageId.split('_');
      if (parts.length >= 3) {
        return parts[1];
      }
    }

    return messageId;
  }

  /// =============================
  ///       ADD REACTION
  /// =============================

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

      final roomId = generateRoomId(userId, receiverId);
      final normalizedId = _normalizeMessageIdForApi(messageId);

      const baseUrl = 'https://api.nowdigitaleasy.com/wschat/v1/messages/react';

      final body = {
        "conversationId": conversationId,
        "messageId": normalizedId,
        "emoji": emoji,
        "roomId": roomId,
      };

      log('📡 reactionUpdated → POST $baseUrl');
      log('📦 body = $body');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'x-workspace': defaultWorkspace ?? "",
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
      log('📤 reactionUpdated body: $body');
      log('📥 reactionUpdated status: ${response.statusCode}');
      log('📥 reactionUpdated response: ${response.body}');

      log('📥 reactionUpdated status=${response.statusCode}');
      log('📥 reactionUpdated body=${response.body}');

      if (response.statusCode != 200) {
        log('❌ Backend rejected reaction');
      }
    } catch (e) {
      log("❌ Error in reactionUpdated: $e");
    }
  }

  /// =============================
  ///   REMOVE REACTION
  /// =============================

  Future<void> reactionRemove({
    required String messageId,
    required String receiverId,
    required String userId,
    required String conversationId,
  })
  async {
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
      final normalizedId = _normalizeMessageIdForApi(messageId);

      const baseUrl =
          'https://api.nowdigitaleasy.com/wschat/v1/messages/remove/react';

      final body = {
        "conversationId": conversationId,
        "messageId": normalizedId,
        "roomId": roomId,
      };

      final response = await http.post(
        Uri.parse(baseUrl),
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
        log('❌ Failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      log("Error in reactionRemove: $e");
    }
  }

  /// =============================
  ///     ROOM ID GENERATOR
  /// =============================

  String generateRoomId(String senderId, String receiverId) {
    final ids = [senderId, receiverId]..sort();
    return ids.join('_');
  }

  /// =============================
  ///        FILE UPLOAD
  /// =============================

  Future<void> uploadFile({
    required File file,
    required void Function(int progress) onProgress,
    required void Function(dynamic data) onSuccess,
    required void Function(String error) onError,
  }) async
  {
    final dio = Dio();

    final fileName = basename(file.path);
    final mimeType = lookupMimeType(file.path);
    final mediaType =
        mimeType != null ? MediaType.MediaType.parse(mimeType) : null;

    log("🔍 Detected MIME: $mimeType");

    final token = await UserPreferences.getAccessToken();
    final workspace = await UserPreferences.getDefaultWorkspace();

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: fileName,
        contentType: mediaType,
      ),
    });
print("formData ${formData}");
    try {
      final response = await dio.post(
        'https://api.nowdigitaleasy.com/wschat/v1/messages/upload/file',
        data: formData,
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'x-workspace': workspace,
        }),
        onSendProgress: (sent, total) {
          final progress = ((sent / total) * 100).toInt();
          onProgress(progress);
        },
      );
      print("formDatasss ${response}");

      if (response.statusCode == 200) {
        onSuccess(response.data);
      } else {
        onError("Upload failed: ${response.statusCode}");
      }
    } catch (e) {
      onError(e.toString());
      print("erross :${e.toString()}");
    }
  }
}
