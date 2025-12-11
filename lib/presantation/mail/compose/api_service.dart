import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/data/mailboxid.dart';
import 'package:nde_email/data/token.dart';

class ApiService {
  static const String baseUrl = 'https://api.nowdigitaleasy.com/mail/v1';

  void _handleUnauthorized() async {
    await UserPreferences.clearUser();
    NavigationService.navigateToLogin();
  }

  Future<String> getSenderEmail() async {
    String? accessToken = await UserPreferences.getAccessToken();
    String? defaultWorkspace = await UserPreferences.getDefaultWorkspace();
    if (accessToken == null) {
      NavigationService.navigateToLogin();
      throw Exception('Access token is missing');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/user/mail/name'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'X-WorkSpace': defaultWorkspace ?? '',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data['address'] ?? '';
    } else if (response.statusCode == 401) {
      _handleUnauthorized();
      throw Exception("Unauthorized access, logging out...");
    } else {
      NavigationService.navigateToLogin();
      throw Exception('Failed to fetch sender email');
    }
  }

  Future<int?> saveDraft(
      String mailboxId, Map<String, dynamic> draftData) async {
    String? accessToken = await UserPreferences.getAccessToken();
    String? defaultWorkspace = await UserPreferences.getDefaultWorkspace();

    if (accessToken == null) {
      NavigationService.navigateToLogin();
      throw Exception('Access token is missing');
    }

    final String url = "$baseUrl/user/message";

    final Map<String, dynamic> body = {
      "mailbox": mailboxId,
      "emailData": draftData,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $accessToken',
          'X-WorkSpace': defaultWorkspace ?? '',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData["success"] == true) {
          return responseData["message"]["id"];
        }
      } else if (response.statusCode == 401) {
        _handleUnauthorized();
        throw Exception("Unauthorized access, logging out...");
      }
      return null;
    } catch (e) {
      throw Exception("Failed to save draft: $e");
    }
  }

  Future<bool> sendEmail({
    required String fromEmail,
    required String to,
    required String subject,
    required String body,
    String? ccEmail,
    String? bccEmail,
  }) async {
    try {
      String? accessToken = await UserPreferences.getAccessToken();
      String? defaultWorkspace = await UserPreferences.getDefaultWorkspace();

      if (accessToken == null || accessToken.isEmpty) {
        _handleUnauthorized();
        return Future.error('Access token is missing, logging out...');
      }

      log("🔑 Access Token: $accessToken");
      log("🏢 Workspace ID: $defaultWorkspace");

      String? mailboxId = await MailboxStorage.getDraftsMailboxId();
      if (mailboxId == null || mailboxId.isEmpty) {
        return Future.error("Drafts mailbox ID is missing.");
      }
      log("📩 Drafts Mailbox ID: $mailboxId");

      final currentDateTime = DateTime.now().toUtc().toIso8601String();

      final payload = {
        "mailbox": mailboxId,
        "emailData": {
          "date": currentDateTime,
          "draft": true,
          "from": {"name": "", "address": fromEmail},
          "to": to
              .split(",")
              .map((email) => {"name": "", "address": email.trim()})
              .toList(),
          "cc": (ccEmail?.isNotEmpty ?? false)
              ? ccEmail!
                  .split(",")
                  .map((email) => {"name": "", "address": email.trim()})
                  .toList()
              : [],
          "bcc": (bccEmail?.isNotEmpty ?? false)
              ? bccEmail!
                  .split(",")
                  .map((email) => {"name": "", "address": email.trim()})
                  .toList()
              : [],
          "subject": subject,
          "text": body,
          "html": "<p>${body.replaceAll('\n', '<br>')}</p>",
        }
      };

      log("📤 Sending Email Payload: ${jsonEncode(payload)}");

      final String apiUrl =
          '$baseUrl/user/mail/submit/draft/$mailboxId?deleteFiles=true';
      log("🌍 API URL: $apiUrl");

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'X-WorkSpace': defaultWorkspace ?? '',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        //log(" API Response: $responseBody");

        if (responseBody['success'] == true &&
            responseBody['message'] == 'mail sent') {
          log("📩  Email sent successfully!");
          return true;
        } else {
          return Future.error('Unexpected API response: $responseBody');
        }
      } else if (response.statusCode == 401) {
        _handleUnauthorized();
        return Future.error("Unauthorized access, logging out...");
      } else {
        log("  API Error: ${response.body}");
        return Future.error(
            'Failed to send email. Status code: ${response.statusCode}');
      }
    } catch (e) {
      log("🚨 Error sending email: $e");
      return Future.error('Error sending email: $e');
    }
  }
}
