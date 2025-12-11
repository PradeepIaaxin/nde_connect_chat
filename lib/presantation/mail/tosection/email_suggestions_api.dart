import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:nde_email/data/respiratory.dart';
import 'email_suggestions_model.dart';

class MailRepository {
  final String baseUrl = "https://search.nowdigitaleasy.com";

  Future<List<User>> fetchEmailSuggestions(String query) async {
    try {
      final String? token = await UserPreferences.getMeiliTenantToken();

      if (token == null) {
        throw Exception('Meili Tenant Token not found');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/indexes/userIndex/search'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "q": query,
          "limit": 8,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final searchResponse = SearchResponse.fromJson(data);

        return searchResponse.hits; // Return List<User>
      } else {
        throw Exception(
            'Failed to load suggestions. Status: ${response.statusCode}');
      }
    } catch (e) {
      log('Error: $e');
      throw Exception('Error fetching suggestions');
    }
  }
}
