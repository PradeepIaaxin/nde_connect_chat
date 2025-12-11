import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/model/contact_model.dart';
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/model/doc_links_model.dart';
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/model/online_user_model.dart';

class MediaRepository {
  MediaRepository();

  Future<Map<String, String>> _buildHeaders() async {
    final accessToken = await UserPreferences.getAccessToken();
    final defaultWorkspace = await UserPreferences.getDefaultWorkspace();
    return {
      'Authorization': 'Bearer $accessToken',
      'x-workspace': defaultWorkspace ?? "",
    };
  }

  Future<http.Response> _getRequest(String url) async {
    final headers = await _buildHeaders();
    return await http.get(Uri.parse(url), headers: headers);
  }

  Future<List<MediaItem>> fetchItems(String userId, String type) async {
    final url = Uri.parse(
        'https://api.nowdigitaleasy.com/wschat/v1/media/$userId?type=$type');

    try {
      final response = await _getRequest(url.toString())
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        log('[Media Fetch] ✅ Success: $type');

        final decoded = jsonDecode(response.body);
        final data = decoded['data'];
        log(data.toString());
        if (data is List) {
          return data
              .map<MediaItem>((json) => MediaItem.fromJson(json))
              .toList();
        } else {
          log('[Media Fetch] ⚠ Unexpected data format: $data');
          return [];
        }
      } else {
        log('[Media Fetch] ❌ HTTP ${response.statusCode}: ${response.reasonPhrase}');
        return [];
      }
    } catch (e, stack) {
      log('[Media Fetch] ❌ Error fetching $type items: $e');
      log(stack.toString());
      return [];
    }
  }

  Future<ContactModel> fetchContact(String userId) async {
    try {
      final url = 'https://api.nowdigitaleasy.com/wschat/v1/group/$userId';
      final response = await _getRequest(url);

      if (response.statusCode == 200 || response.statusCode == 201) {
        log(response.body.toString());
        return ContactModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(
            'Failed to fetch group contact: ${response.statusCode}');
      }
    } catch (e, stacktrace) {
      log("  Error in fetchContact: $e\n📍 $stacktrace");
      rethrow;
    }
  }

  Future<OnlineUserModel> fetchCommongrp(String receiverId) async {
    try {
      print(receiverId);
      final url =
          'https://api.nowdigitaleasy.com/wschat/v1/employees/$receiverId';
      final response = await _getRequest(url);
      print(url);

      if (response.statusCode == 200 || response.statusCode == 201) {
        log(response.body.toString());

        final parsed = OnlineUserModel.fromJson(jsonDecode(response.body));
        print(parsed);

        log(" ${parsed.sharedGroups.length} users");
        return parsed;
      } else {
        throw Exception('Failed to fetch common group: ${response.statusCode}');
      }
    } catch (e) {
      log("  Error in fetchCommongrp: $e");

      rethrow;
    }
  }

  Future<void> exitGroup(String grpId) async {
    try {
      final accessToken = await UserPreferences.getAccessToken();
      final defaultWorkspace = await UserPreferences.getDefaultWorkspace();

      final headers = {
        'Authorization': 'Bearer $accessToken',
        'x-workspace': defaultWorkspace ?? "",
        'Content-Type': 'application/json',
      };

      log("Exiting group: $grpId");

      final url = Uri.parse(
          'https://api.nowdigitaleasy.com/wschat/v1/group/leave/$grpId');

      final response = await http.post(url, headers: headers);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        log("✅ Successfully exited group: $responseData");
      } else {
        throw Exception(
            '❌ Failed to exit group. Status code: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      log("❌ Error in exitGroup: $e");
      rethrow;
    }
  }

  static Future<bool> removeUserFromGroup({
    required String groupId,
    required String userId,
  }) async {
    try {
      final accessToken = await UserPreferences.getAccessToken();
      final defaultWorkspace = await UserPreferences.getDefaultWorkspace();

      final headers = {
        'Authorization': 'Bearer $accessToken',
        'x-workspace': defaultWorkspace ?? "",
      };

      final url =
          'https://api.nowdigitaleasy.com/wschat/v1/group/$groupId/remove/user/$userId';
      final response = await http.post(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        log("✅ User removed from group");
        return true;
      }
      return false;
    } catch (e) {
      log("  Exception in removeUserFromGroup: $e");
      return false;
    }
  }

  //make Admin or not

  Future<void> updateAdmins({
    required String groupId,
    required List<Map<String, dynamic>> updates,
  }) async {
    try {
      final accessToken = await UserPreferences.getAccessToken();
      final defaultWorkspace = await UserPreferences.getDefaultWorkspace();

      final url = 'https://api.nowdigitaleasy.com/wschat/v1/group/admins';

      final body = jsonEncode({
        "groupId": groupId,
        "updates": updates,
      });
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'x-workspace': defaultWorkspace ?? "",
        'Content-Type': 'application/json',
      };

      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        log("✅ Admins updated successfully");
      }
    } catch (e, stacktrace) {
      log("❗ Error in updateAdmins: $e\n📍 $stacktrace");
      rethrow;
    }
  }

  //add favourite or remove

  Future<void> updateFavourite({
    required String targetId,
    required bool isFavourite,
  }) async {
    try {
      print(targetId);
      print(isFavourite);
      final accessToken = await UserPreferences.getAccessToken();
      final defaultWorkspace = await UserPreferences.getDefaultWorkspace();

      final url = 'https://api.nowdigitaleasy.com/wschat/v1/favourites';

      final body = jsonEncode({
        "targetId": targetId,
        "isFavourite": isFavourite,
      });

      print(body);

      final headers = {
        'Authorization': 'Bearer $accessToken',
        'x-workspace': defaultWorkspace ?? "",
        'Content-Type': 'application/json',
      };

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
      } else {
        log("❌ Failed with status: ${response.statusCode}");
        log("❌ Response body: ${response.body}");
      }
    } catch (e, stackTrace) {
      log("❌ Exception: $e");
      log("📍 StackTrace: $stackTrace");
    }
  }
}
