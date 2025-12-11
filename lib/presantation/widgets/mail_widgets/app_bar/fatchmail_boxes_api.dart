import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:nde_email/presantation/login/login_screen.dart';
import 'package:nde_email/utils/router/router.dart';
import 'mailbox_model.dart';
import 'package:nde_email/data/base_url.dart';
import 'package:nde_email/data/token.dart';
import 'package:nde_email/data/mailboxid.dart';
import 'package:nde_email/data/respiratory.dart';

class FetchMailBoxesApi {
  Future<List<Mailbox>> fetchMailboxes() async {
    try {
      String? accessToken = await UserPreferences.getAccessToken();
      String? defaultWorkspace = await UserPreferences.getDefaultWorkspace();

      if (accessToken == null || accessToken.isEmpty) {
        await _handleUnauthorized();

        throw Exception('Access token is missing or expired');
      }

      final url = Uri.parse(
          '${ApiService.baseUrl}/user/mailboxes?specialuse=false&showhidden=false&counters=true&sizes=false');

      final response = await http.get(
        url,
        headers: {
          'Authorization':
              // "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI2NWViMTE1OWJkNWVlOTdiOGUyOGY2ZDIiLCJjdXJyZW5jeUNvZGUiOiJJTlIiLCJsb2NhbGUiOiJlbi1JTiIsInByb2ZpbGUiOm51bGwsImlhdCI6MTc0MzY2NjczMiwiZXhwIjoxNzQzNzUzMTMyfQ.LReMQa36HKNHx4E34qMnjjSUgSkTcnuU7nC9byebFOs",
              'Bearer $accessToken',
          'Content-Type': 'application/json',
          'X-WorkSpace': defaultWorkspace ?? '',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        List<dynamic>? mailboxData = data['data'] ?? data['finalMailboxData'];
        if (mailboxData == null || mailboxData.isEmpty) {
          throw Exception("Invalid response: No mailbox data found");
        }

        List<Mailbox> mailboxes = mailboxData.map((mailbox) {
          return Mailbox.fromJson(mailbox);
        }).toList();

        final draftsMailbox = mailboxes.firstWhere(
          (mailbox) => mailbox.name.toLowerCase() == 'drafts',
        );

        if (draftsMailbox.id.isNotEmpty) {
          await MailboxStorage.saveDraftsMailboxId(draftsMailbox.id);
          log("Saved Drafts Mailbox ID: ${draftsMailbox.id}");
        } else {
          log(" No drafts mailbox found!");
        }

        final archiveMailbox = mailboxes.firstWhere(
          (mailbox) => mailbox.name.toLowerCase() == 'archive',
        );

        if (archiveMailbox.id.isNotEmpty) {
          await MailboxStorage.saveArchiveMailboxId(archiveMailbox.id);
          log("Saved Archive Mailbox ID: ${archiveMailbox.id}");
        } else {
          log(" No archive mailbox found!");
        }

        final inbox = mailboxes.firstWhere(
          (mailbox) => mailbox.name.toLowerCase() == 'inbox',
        );

        if (inbox.id.isNotEmpty) {
          await MailboxStorage.saveInboxMailboxId(inbox.id);
          log("Saved Inbox Mailbox ID: ${inbox.id}");
        } else {
          log("No inbox mailbox found!");
        }

        return mailboxes;
      } else if (response.statusCode == 401) {
        MyRouter.pushRemoveUntil(screen: LoginScreen());
        throw Exception("jwt expired");
      } else {
        throw Exception(
            jsonDecode(response.body)['message'] ?? 'Unknown error');
      }
    } catch (e) {
      if (e.toString().contains("Failed host lookup")) {
        throw Exception("No internet connection");
      }
      throw Exception('Failed to fetch mailboxes: $e');
    }
  }

  Future<void> _handleUnauthorized() async {
    try {
      await UserPreferences.clearUser();
    } catch (e) {
      log("Error while clearing user data: $e");
    }
    log("Unauthorized access detected! Redirecting to login...");
    NavigationService.navigateToLogin();
  }
}
