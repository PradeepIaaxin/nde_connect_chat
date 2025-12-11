import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/presantation/mail/compose/upload_response_model.dart';

class AttachmentRepository {
  final Dio _dio = Dio();

  Future<String?> uploadAttachment(File file,
      {String contentDisposition = "attachment"}) async {
    String? accessToken = await UserPreferences.getAccessToken();
    String? defaultWorkspace = await UserPreferences.getDefaultWorkspace();

    if (accessToken == null || defaultWorkspace == null) {
      log("Missing access token or workspace");
      return null;
    }

    final String url =
        "https://api.nowdigitaleasy.com/mail/v1/user/attachment/upload";

    try {
      FormData formData = FormData.fromMap({
        "attachment": await MultipartFile.fromFile(
          file.path,
          filename: file.path.split("/").last,
        ),
        "contentDisposition": contentDisposition,
      });

      _dio.options.headers = {
        'Authorization': 'Bearer $accessToken',
        'X-WorkSpace': defaultWorkspace,
      };

      final response = await _dio.post(url, data: formData);

      dynamic data = response.data;

      if (data is String) {
        data = jsonDecode(data);
      }

      log(" Upload successful. Full response:");
      log(const JsonEncoder.withIndent('  ').convert(data));

      final uploadResponse = AttachmentUploadResponse.fromJson(data);

      log(" Attachment ID: ${uploadResponse.id}");
      return uploadResponse.id; // Return the attachment ID
    } catch (e) {
      log(" Upload error: $e");
      return null; // Return null if upload fails
    }
  }
}
