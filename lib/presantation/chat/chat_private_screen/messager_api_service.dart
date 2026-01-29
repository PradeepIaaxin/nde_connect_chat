import 'dart:developer';
import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as MediaType;
import 'package:mime/mime.dart';
import 'package:nde_email/bridge_generated.dart/api.dart';
import 'package:path/path.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/respiratory.dart';
import 'messager_model.dart';

class MessagerApiService {
  late final BuildContext context;

  Future<List<Datum>> fetchMessages({
    required String convoId,
    required int page,
    required int limit,
  }) async {
    try {
      final token = await UserPreferences.getAccessToken();
      final workspace = await UserPreferences.getDefaultWorkspace();

      if (token == null || workspace == null) {
        throw Exception('Authentication required');
      }

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
          "x-workspace": workspace,
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode != 200 ||
          response.statusCode != 201 ||
          response.statusCode != 204) {
        log(response.statusCode.toString());
      }

      final jsonData = jsonDecode(response.body);
      log('📥 Raw response keys: ${jsonData.keys.toList()}');

      // ================= SNAPSHOT FLOW (LORRO DOC) =================
      if (jsonData["snapshot"] != null) {
        final snapshotBase64 = jsonData["snapshot"];
        log("📥 Snapshot received for $convoId (page $page)");

        try {
          // Reset global doc and decode snapshot
          await resetGlobalDoc();
          final jsonString =
              await decodeMessageSnapshot(snapshotBase64: snapshotBase64);

          log('🧪 Decoded snapshot length: ${jsonString.length} chars');

          final decoded = jsonDecode(jsonString);
          log('🔍 Snapshot keys: ${decoded["messages"]}');

          final Map? messagesMap = decoded["messages"];
          if (messagesMap == null) {
            log('⚠️ No messages key in snapshot');
            return [];
          }

          log('📊 Snapshot messages count: ${messagesMap.length}');

          final List<Datum> flat = [];

          // Iterate through LORRO document entries
          for (final entry in messagesMap.entries) {
            try {
              final rawValue = entry.value;

              // Ensure it's a Map
              Map<String, dynamic> messageMap;
              if (rawValue is Map) {
                messageMap = Map<String, dynamic>.from(rawValue);
              } else if (rawValue is String) {
                // Try to decode if it's a JSON string
                messageMap = Map<String, dynamic>.from(jsonDecode(rawValue));
              } else {
                log('⚠️ Skipping non-Map entry: ${entry.key}');
                continue;
              }

              // Log for debugging
              if (flat.isEmpty) {
                log('🔍 First message structure:');
                // messageMap.forEach((key, value) {
                //   log('   $key: $value (${value.runtimeType})');
                // });
              }

              // Convert to Datum
              final datum = Datum.fromJson(messageMap);
              // log(datum.toRawJson());
              flat.add(datum);
            } catch (e, st) {
              log('❌ Failed to parse message ${entry.key}: $e\n$st');
            }
          }

          // Sort chronologically (oldest to newest) - LIKE WEB
          flat.sort((a, b) {
            try {
              final at = DateTime.tryParse(a.created_at) ?? DateTime(1970);
              final bt = DateTime.tryParse(b.created_at) ?? DateTime(1970);
              return at.compareTo(bt);
            } catch (e) {
              return 0;
            }
          });

          log('✅ Snapshot: Successfully loaded ${flat.length} messages');
          return flat;
        } catch (e, st) {
          log('❌ Snapshot decode/parse failed: $e\n$st');
          log('🔄 Falling back to normal REST flow');
        }
      }

      // ================= NORMAL REST FLOW (fallback) =================
      log('🔄 Using normal REST flow');
      final List groups = jsonData["data"] ?? [];
      final List<Datum> flat = [];

      for (final g in groups) {
        try {
          final msgs = g["messages"] ?? [];
          for (final m in msgs) {
            try {
              final datum = Datum.fromJson(m);
              flat.add(datum);
            } catch (e) {
              log('⚠️ Failed to parse message in group: $e');
            }
          }
        } catch (e) {
          log('⚠️ Error processing group: $e');
        }
      }

      log('📊 Normal flow: Loaded ${flat.length} messages');
      return flat;
    } catch (e, st) {
      log('❌ fetchMessages error: $e\n$st');
      rethrow;
    }
  }

  Future<Map<String, String>> refreshAttachmentUrls(List<String> keys) async {
    final token = await UserPreferences.getAccessToken();
    final workspace = await UserPreferences.getDefaultWorkspace();

    final res = await http.post(
      Uri.parse(
          "https://api.nowdigitaleasy.com/wschat/v1/messages/attachments/refresh-urls"),
      headers: {
        "Authorization": "Bearer $token",
        "x-workspace": workspace ?? "",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "originalKeys": keys,
        "profilePic": false,
      }),
    );

    final data = jsonDecode(res.body);

    return Map<String, String>.from(data["urls"]);
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

Future<void> makePhoneCall(String phoneNumber) async {
  final Uri url = Uri.parse('tel:$phoneNumber');

  if (await canLaunchUrl(url)) {
    await launchUrl(url);
  } else {
    throw 'Could not launch $url';
  }
}
