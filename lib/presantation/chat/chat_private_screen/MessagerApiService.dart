import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as MediaType;
import 'package:mime/mime.dart';
import 'package:nde_email/bridge_generated.dart/api.dart';
import 'package:path/path.dart';

import '../../../data/respiratory.dart';
import 'messager_model.dart';

class MessagerApiService {
  late final BuildContext context;

  /// =============================
  ///   FETCH GROUPED MESSAGES
  /// =============================
  ///
  ///

  Future<List<Datum>> fetchMessages({
    required String convoId,
    required int page,
    required int limit,
  }) async {
    final token = await UserPreferences.getAccessToken();
    final workspace = await UserPreferences.getDefaultWorkspace();

    const baseUrl = 'https://api.nowdigitaleasy.com/wschat/v1/messages';

    final uri = Uri.parse(baseUrl).replace(queryParameters: {
      "convoId": convoId,
      "page": page.toString(),
      "limit": limit.toString(),
    });

    final response = await http.get(
      uri,
      headers: {
        "Authorization": "Bearer $token",
        "x-workspace": workspace ?? "",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to fetch messages");
    }

    final jsonData = jsonDecode(response.body);
    // log(jsonData.toString());

    // ================= SNAPSHOT FLOW =================
    if (jsonData["snapshot"] != null) {
      final snapshotBase64 = jsonData["snapshot"];
      log("📥 Snapshot received");

      await resetGlobalDoc();

      final jsonString =
          await decodeMessageSnapshot(snapshotBase64: snapshotBase64);

      final decoded = jsonDecode(jsonString);
     // log("🧪 RAW SNAPSHOT JSON → $decoded");

      final Map messageMap = decoded["messages"] ?? {};
      final List<Datum> flat = [];

      for (final entry in messageMap.entries) {
        flat.add(Datum.fromJson(Map<String, dynamic>.from(entry.value)));
      }

      // sort like web
      flat.sort((a, b) {
        final at = DateTime.tryParse(a.created_at) ?? DateTime(1970);
        final bt = DateTime.tryParse(b.created_at) ?? DateTime(1970);
        return at.compareTo(bt);
      });

      //log("✅ Parsed messages from snapshot → ${flat.length}");
      return flat;
    }

    // ================= NORMAL REST FLOW (fallback) =================
    final List groups = jsonData["data"] ?? [];
    final List<Datum> flat = [];

    for (final g in groups) {
      final msgs = g["messages"] ?? [];
      for (final m in msgs) {
        flat.add(Datum.fromJson(m));
      }
    }

    return flat;
  }

  // Future<MessageListResponse> fetchMessages({
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

  //   const baseUrl =
  //   //'https://api.nowdigitaleasy.com/wschat/v1/messages';
  //   "https://945067be4009.ngrok-free.app/v1/messages";

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
  //     // log("📩 API RESPONSE: $responseData");
  //     log("responseee $responseData}");

  //     /// 🔥 Updated return
  //     return MessageListResponse.fromJson(responseData);
  //   } else {
  //     log(response.reasonPhrase.toString());
  //     throw Exception(
  //         'Failed to load messages. Status Code: ${response.statusCode}');
  //   }
  // }

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
  }) async {
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
