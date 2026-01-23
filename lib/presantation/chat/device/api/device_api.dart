import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/presantation/chat/device/model/device_model.dart';

class FetchLinkedDeviceApi {
  Future<LinkedDeviceResponse> fetchLinkedDevices() async {
    String? accessToken = await UserPreferences.getAccessToken();
    String? defaultWorkspace = await UserPreferences.getDefaultWorkspace();

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception("Access token missing");
    }

    final url =
        'https://api.nowdigitaleasy.com/wschat/v1/device/linked-devices';
    log("Linked Device API URL: $url");

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'X-WorkSpace': defaultWorkspace ?? '',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        final linkedDevices = LinkedDeviceResponse.fromJson(data);

        log("Linked Devices Count: ${linkedDevices.devices.length}");

        return linkedDevices;
      } else if (response.statusCode == 401) {
        throw Exception("Unauthorized - Token Expired");
      } else {
        throw Exception("Failed to load devices: ${response.reasonPhrase}");
      }
    } catch (e) {
      throw Exception("Linked Device API Error: $e");
    }
  }
}
