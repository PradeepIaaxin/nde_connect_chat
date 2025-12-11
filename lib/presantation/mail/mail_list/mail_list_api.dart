import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:nde_email/data/respiratory.dart';
import 'mail_list_model.dart';
// import 'mail_list.req.dart';
// import 'package:nde_email/domain/user_model/mailbox_model_req.dart';
import 'package:nde_email/data/mailboxid.dart';
import 'package:nde_email/data/token.dart';
import 'package:nde_email/data/base_url.dart';
import 'package:shared_preferences/shared_preferences.dart';

class fetchMailListapi {
  Future<MailListResponse> fetchMailList(String mailboxId,
      {String? cursor}) async {
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
      'limit=50',
      'page=2',
      'metaData=true',
      'threadCounters=true',
      'includeHeaders=message-id',
      if (cursor != null && cursor.isNotEmpty) 'next=$cursor',
    ].join('&');

    final url = '$baseUrl?$queryParameters';

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

        log('Mail List Fetched: ${response.body}');
        log('Next Cursor: ${mailListResponse.nextCursor}');

        return mailListResponse;
      } else if (response.statusCode == 401) {
        await _handleUnauthorized();
        throw Exception("Unauthorized access, logging out...");
      } else {
        throw Exception('Failed to fetch mail list: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error fetching mail list: $e');
    }
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
        log(" Messages deleted successfully!");
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

  Future<bool> moveToArchive(List<int> mailIds, String mailboxId) async {
    if (mailIds.isEmpty) {
      log("Error: No emails selected to archive!");
      return false;
    }

    String? accessToken = await UserPreferences.getAccessToken();
    String? defaultWorkspace = await UserPreferences.getDefaultWorkspace();
    String? archiveMailboxId = await MailboxStorage.getArchiveMailboxId();

    if (archiveMailboxId == null) {
      log("Error: Archive mailbox ID not found!");
      return false;
    }

    final url = Uri.parse(
      "${ApiService.baseUrl}/user/message/move/mailboxes/$mailboxId?all=false",
    );

    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
        "X-WorkSpace": defaultWorkspace ?? '',
      },
      body: jsonEncode({
        "messageIds": mailIds,
        "moveTo": archiveMailboxId,
      }),
    );

    log("Response Status Code: ${response.statusCode}");
    log("Response Body: ${response.body}");

    if (response.statusCode == 200) {
      log("Emails moved to archive successfully.");
      return true;
    } else {
      log("Error: Failed to move emails to archive.");
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

      // log('Filtered Mail API Response: ${response.body}');

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
        log("Filtered mails count: ${mails.length}");
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
