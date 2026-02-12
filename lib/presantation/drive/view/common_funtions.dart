import 'dart:developer';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:nde_email/presantation/drive/view/uploadtodrive.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

Future<File> downloadFile(String url, String name) async {
  final dir = await getTemporaryDirectory();
  final file = File("${dir.path}/$name");

  if (await file.exists()) return file;

  final res = await http.get(
    Uri.parse(url),
    // 🔐 ADD AUTH HEADER IF NEEDED
    // headers: {"Authorization": "Bearer YOUR_TOKEN"},
  );

  if (res.statusCode != 200) {
    throw Exception("Failed to download file");
  }

  await file.writeAsBytes(res.bodyBytes);
  return file;
}
String getFileName(String url) =>
    Uri.parse(url).pathSegments.last.split("?").first;
Future<void> openWithSystemApps(String fileUrl) async {
  final file =
  await downloadFile(fileUrl, getFileName(fileUrl));

  final result = await OpenFilex.open(file.path);

  log("OPEN RESULT = ${result.type}");
}

Future<void> openCamera(BuildContext context) async {
  final picker = ImagePicker();

  final XFile? photo = await picker.pickImage(
    source: ImageSource.camera,
    imageQuality: 85,          // compress like Drive
  );

  if (photo == null) return;

  _goToUploadScreen(context, photo);
}
Future<void> _goToUploadScreen(BuildContext context, XFile file) async {
  final bytes = await file.readAsBytes();

  final platformFile = PlatformFile(
    name: file.name,
    size: bytes.length,
    bytes: bytes,
  );

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => UploadToDriveScreen(
        selectedFiles: [platformFile],
        parentId: "",
      ),
    ),
  );
}