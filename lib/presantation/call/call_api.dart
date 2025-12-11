import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:nde_email/data/respiratory.dart';

import 'package:nde_email/presantation/call/call_model.dart';

Future<List<CallHistory>> fetchCallHistory() async {
  String? accessToken = await UserPreferences.getAccessToken();
  String? defaultWorkspace = await UserPreferences.getDefaultWorkspace();

  final uri =
      Uri.parse('https://api.nowdigitaleasy.com/meet/v1/meeting/call/history');

  final headers = {
    'Authorization': 'Bearer $accessToken',
    'x-workspace': defaultWorkspace ?? '',
    'Content-Type': 'application/json',
  };

  final response = await http.get(uri, headers: headers);

  if (response.statusCode == 200) {
    final Map<String, dynamic> decoded = json.decode(response.body);
    final List<dynamic> resultList = decoded['result'];
    log(resultList.toString());
    return resultList.map((item) => CallHistory.fromJson(item)).toList();
  } else {
    throw Exception('Failed to load call history: ${response.statusCode}');
  }
}
