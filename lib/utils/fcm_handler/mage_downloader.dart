import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

Future<String?> downloadProfileImage(String url) async {
  try {
    final response = await Dio().get(url,
        options: Options(responseType: ResponseType.bytes));

    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg");
    await file.writeAsBytes(response.data);
    return file.path;
  } catch (e) {
    print("❌ Image download failed: $e");
    return null;
  }
}
