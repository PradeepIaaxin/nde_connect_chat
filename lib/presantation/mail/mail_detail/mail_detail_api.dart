import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nde_email/data/respiratory.dart';
// import 'mail_list.req.dart';
// import 'package:nde_email/domain/user_model/mailbox_model_req.dart';
// import 'package:nde_email/data/mailboxid.dart';
import 'package:nde_email/data/token.dart';
import 'package:nde_email/data/base_url.dart';
import 'mail_detail_model.dart';

class fatchdetailmailapi {
  Future<MailDetailModel> fetchMailDetail(
      String messageId, String mailboxId) async {
    String? accessToken = await UserPreferences.getAccessToken();
    String? defaultWorkspace = await UserPreferences.getDefaultWorkspace();
    if (accessToken == null || accessToken.isEmpty) {
      _handleUnauthorized();
      throw Exception('Access token is missing or expired');
    }

    final response = await http.get(
      Uri.parse(
          '${ApiService.baseUrl}/user/message/$mailboxId/mailbox/$messageId?markAsSeen=true'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'X-WorkSpace': defaultWorkspace ?? '',
      },
    );

    if (response.statusCode == 200) {
      return MailDetailModel.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 401) {
      _handleUnauthorized();
      throw Exception("Unauthorized access, logging out...");
    } else {
      NavigationService.navigateToLogin();
      throw Exception('Failed to fetch mail details');
    }
  }

  void _handleUnauthorized() async {
    await UserPreferences.clearUser();
    NavigationService.navigateToLogin();
  }
}
