import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'login_req.dart';
import 'login_model.dart';
import 'package:nde_email/utils/snackbar/snackbar.dart';
import 'package:nde_email/domain/error_pages/mail_error_pages/custom_exception.dart';
import 'package:nde_email/data/respiratory.dart';

class Auth {
  Future<void> checkUserEmail(String email) async {
    final uri =
        Uri.parse('https://api.nowdigitaleasy.com/auth/v1/auth/user/$email');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 20));

      final statusCode = response.statusCode;
      final body = response.body;

      Map<String, dynamic> data;
      try {
        data = jsonDecode(body);
        // log(data.toString());
      } catch (e) {
        log(e.toString());
        throw DataFormatException("Invalid response format. Please try again.");
      }

      if (statusCode == 200) {
        Messenger.alertSuccess("Email verified successfully");
      } else if (statusCode == 404) {
        throw AuthException("Email not found. Please check and try again.");
      } else {
        log("Unexpected status code: $statusCode\nResponse: $body");
        throw UnknownException("Unexpected error occurred. Try again.");
      }
    } on SocketException {
      throw NetworkException("No internet connection.");
    } on TimeoutException {
      throw NetworkException(
          "Request timed out. Please check your connection.");
    } on DataFormatException catch (e) {
      log("Data format error: ${e.message}");
      rethrow;
    } catch (e, stackTrace) {
      if (e is AuthException ||
          e is NetworkException ||
          e is DataFormatException ||
          e is ServerException) {
        rethrow;
      } else {
        log("Unexpected error: $e", stackTrace: stackTrace);
        throw UnknownException("An unexpected error occurred: ${e.toString()}");
      }
    }
  }

  Future<UserModel> login(LoginRequestModel loginRequest) async {
    final uri = Uri.parse('https://api.nowdigitaleasy.com/auth/v1/auth/signin');

    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(loginRequest.toJson()),
          )
          .timeout(const Duration(seconds: 20));

      final statusCode = response.statusCode;
      final body = response.body;

      Map<String, dynamic> data;
      try {
        data = jsonDecode(body);
      } catch (_) {
        throw DataFormatException("Invalid response format. Please try again.");
      }

      if (statusCode == 200) {
        Messenger.alertSuccess("Logged in successfully");
        final user = UserModel.fromJson(data);
        await UserPreferences.saveUser(user);
        return user;
      } else if (statusCode == 400 || statusCode == 401) {
        throw AuthException(data["error"] ?? "Incorrect email or password.");
      } else if (statusCode >= 500) {
        throw ServerException("Server error. Please try again later.");
      } else {
        log("Unexpected status code: $statusCode\nResponse: $body");
        throw UnknownException("Unexpected error occurred. Try again.");
      }
    } on SocketException {
      throw NetworkException("No internet connection.");
    } on TimeoutException {
      throw NetworkException(
          "Request timed out. Please check your connection.");
    } on DataFormatException catch (e) {
      log("Data format error: ${e.message}");
      rethrow;
    } catch (e, stackTrace) {
      if (e is AuthException ||
          e is NetworkException ||
          e is DataFormatException ||
          e is ServerException) {
        rethrow;
      } else {
        log("Unexpected error: $e", stackTrace: stackTrace);
        throw UnknownException("An unexpected error occurred: ${e.toString()}");
      }
    }
  }
}
