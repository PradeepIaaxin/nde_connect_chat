import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/utils/reusbale/common_import.dart';
import '../model/mail_list_model.dart';
import 'package:nde_email/data/mailboxid.dart';
import 'package:nde_email/data/token.dart';
import 'package:nde_email/data/base_url.dart';

class FetchMailListapi {
  Future<MailListResponse> fetchMailList(
    String mailboxId, {
    String? cursor,
    int limit = 20, 
  }) async {
    String? accessToken = await UserPreferences.getAccessToken();
    String? defaultWorkspace = await UserPreferences.getDefaultWorkspace();

    log("Mail ID inside the API: $mailboxId");

    if (accessToken == null || accessToken.isEmpty) {
      await _handleUnauthorized();
      throw Exception('Access token is missing or expired');
    }

    final baseUrl = '${ApiService.baseUrl}/user/mailboxes/$mailboxId';

    final queryParameters = [
      'order=desc',
      'limit=$limit', 
      'metaData=true',
      'threadCounters=true',
      'includeHeaders=message-id',
      if (cursor != null && cursor.isNotEmpty) 'next=$cursor',
    ].join('&');

    final url = '$baseUrl?$queryParameters';

    log("📡 API URL → $url");

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'X-WorkSpace': defaultWorkspace ?? '',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final mailListResponse = MailListResponse.fromJson(data);

        log('📥 Mail List Fetched');
        log('Next Cursor: ${mailListResponse.nextCursor}');

        return mailListResponse;
      } else if (response.statusCode == 401) {
        await _handleUnauthorized();
        throw Exception("Unauthorized access, logging out...");
      } else {
        throw Exception(
          'Failed to fetch mail list: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching mail list: $e');
    }
  }

  // Future<MailListResponse> fetchMailList(String mailboxId,
  //     {String? cursor}) async {
  //   String? accessToken = await UserPreferences.getAccessToken();
  //   String? defaultWorkspace = await UserPreferences.getDefaultWorkspace();
  //   log("Mail ID inside the API: $mailboxId");

  //   if (accessToken == null || accessToken.isEmpty) {
  //     await _handleUnauthorized();
  //     throw Exception('Access token is missing or expired');
  //   }

  //   final baseUrl = '${ApiService.baseUrl}/user/mailboxes/$mailboxId';
  //   final queryParameters = [
  //     'order=desc',
  //     'limit=50',
  //     'metaData=true',
  //     'threadCounters=true',
  //     'includeHeaders=message-id',
  //     if (cursor != null && cursor.isNotEmpty) 'next=$cursor',
  //   ].join('&');

  //   final url = '$baseUrl?$queryParameters';
  //   log(url.toString());

  //   try {
  //     final response = await http.get(
  //       Uri.parse(url),
  //       headers: {
  //         'Authorization': 'Bearer $accessToken',
  //         'X-WorkSpace': defaultWorkspace ?? '',
  //       },
  //     );

  //     if (response.statusCode == 200) {
  //       final Map<String, dynamic> data = json.decode(response.body);
  //       final mailListResponse = MailListResponse.fromJson(data);

  //       log('Mail List Fetched: ${response.body}');
  //       log('Next Cursor: ${mailListResponse.nextCursor}');

  //       return mailListResponse;
  //     } else if (response.statusCode == 401) {
  //       await _handleUnauthorized();
  //       throw Exception("Unauthorized access, logging out...");
  //     } else {
  //       throw Exception('Failed to fetch mail list: ${response.reasonPhrase}');
  //     }
  //   } catch (e) {
  //     throw Exception('Error fetching mail list: $e');
  //   }
  // }

  Future<bool> moveMail({
    required List<int> mailIds,
    required String sourceMailboxId,
    required String targetMailboxId,
  }) async {
    if (mailIds.isEmpty) {
      log("❌ No mail IDs provided");
      return false;
    }

    final accessToken = await UserPreferences.getAccessToken();
    final workspace = await UserPreferences.getDefaultWorkspace();

    final messageIds = mailIds.map((id) => id.toString()).toList();

    final url = Uri.parse(
      "${ApiService.baseUrl}/user/message/move/mailboxes/$sourceMailboxId?all=false",
    );

    final payload = {
      "moveTo": targetMailboxId,
      "messageIds": messageIds,
    };

    log("📤 MOVE PAYLOAD: ${jsonEncode(payload)}");

    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
        "X-WorkSpace": workspace ?? '',
      },
      body: jsonEncode(payload),
    );

    log("📥 Status: ${response.statusCode}");
    log("📥 Body: ${response.body}");

    return response.statusCode == 200;
  }

  Future<void> _handleUnauthorized() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await UserPreferences.clearUser();
    await prefs.setBool(UserPreferences.isLoggedInKey, false);

    log("🚀 Unauthorized access detected! Logging out...");

    Future.microtask(() {
      NavigationService.navigatorKey.currentState
          ?.pushNamedAndRemoveUntil('/CarouselScreen', (route) => false);
    });
  }

  Future<bool> deleteMessage(String mailboxId, List<int> mailIds) async {
    try {
      String? accessToken = await UserPreferences.getAccessToken();
      String? defaultWorkspace = await UserPreferences.getDefaultWorkspace();

      if (accessToken == null || accessToken.isEmpty) {
        _handleUnauthorized();
        return Future.error('Access token is missing, logging out...');
      }

      final String apiUrl =
          '${ApiService.baseUrl}/user/message/bulk/$mailboxId?all=false';

      log("🗑️ Deleting Messages: $mailIds");
      log("🌍 API URL: $apiUrl");

      final response = await http.delete(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'X-WorkSpace': defaultWorkspace ?? '',
        },
        body: jsonEncode({"messageIds": mailIds}),
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        _handleUnauthorized();
        return Future.error("Unauthorized access, logging out...");
      } else {
        log("API Error: ${response.body}");
        return Future.error(
            'Failed to delete messages. Status code: ${response.statusCode}');
      }
    } catch (e) {
      log(" Error deleting message: $e");
      return Future.error('Error deleting message: $e');
    }
  }

  Future<bool> moveToArchive(List<int> mailIds, String sourceMailboxId) async {
    if (mailIds.isEmpty) {
      log("❌ Error: No emails selected to archive!");
      return false;
    }

    final accessToken = await UserPreferences.getAccessToken();
    final defaultWorkspace = await UserPreferences.getDefaultWorkspace();
    final archiveMailboxId = await MailboxStorage.getArchiveMailboxId();

    if (archiveMailboxId == null || archiveMailboxId.isEmpty) {
      log("❌ Error: Archive mailbox ID not found!");
      return false;
    }

    /// ✅ Convert int → string
    final messageIds = mailIds.map((id) => id.toString()).toList();

    final url = Uri.parse(
      "${ApiService.baseUrl}/user/message/move/mailboxes/$sourceMailboxId?all=false",
    );

    log("📤 MOVE PAYLOAD: ${jsonEncode({
          "moveTo": archiveMailboxId,
          "messageIds": messageIds,
        })}");

    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
        "X-WorkSpace": defaultWorkspace ?? '',
      },
      body: jsonEncode({
        "moveTo": archiveMailboxId,
        "messageIds": messageIds,
      }),
    );

    log("📥 Response Status Code: ${response.statusCode}");
    log("📥 Response Body: ${response.body}");

    if (response.statusCode == 200) {
      return true;
    } else {
      log("❌ Failed to move emails");
      return false;
    }
  }

  Future<bool> revertFromArchive({
    required List<int> mailIds,
    required String archiveMailboxId,
  }) async {
    String? accessToken = await UserPreferences.getAccessToken();
    String? defaultWorkspace = await UserPreferences.getDefaultWorkspace();

    final url = "${ApiService.baseUrl}/user/archive/revert/$archiveMailboxId";

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
          "X-WorkSpace": defaultWorkspace ?? "",
        },
        body: jsonEncode({
          "messageIds": mailIds,
        }),
      );

      if (response.statusCode == 200) {
        log("✅ Archive revert success: ${response.body}");
        return true;
      } else {
        log("❌ Archive revert failed: ${response.body}");
        return false;
      }
    } catch (e) {
      log("❌ Archive revert error: $e");
      return false;
    }
  }

  Future<List<GMMailModels>> fetchFilteredMails(String filter) async {
    try {
      String? accessToken = await UserPreferences.getAccessToken();
      String? defaultWorkspace = await UserPreferences.getDefaultWorkspace();

      if (accessToken == null || defaultWorkspace == null) {
        throw Exception('Missing token or workspace');
      }

      final uri = Uri.parse(
          'https://api.nowdigitaleasy.com/mail/v1/user/message/filter?filter=$filter');

      final response = await http.get(uri, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
        "X-WorkSpace": defaultWorkspace,
      });

      if (response.statusCode == 200) {
        final jsonMap = json.decode(response.body);

        //  Fixed here: `results` is directly a list
        final items = jsonMap['results'];
        if (items == null || items is! List) {
          log("Data is null or not a list");
          return [];
        }

        final mails = items
            .map<GMMailModels>((item) => GMMailModels.fromJson(item))
            .toList();
        // log("Filtered mails count: ${mails.length}");

        return mails;
      } else {
        throw Exception('Failed to load mails');
      }
    } catch (e) {
      log("Error fetching filtered mails: $e");
      throw Exception('Error: $e');
    }
  }
}
