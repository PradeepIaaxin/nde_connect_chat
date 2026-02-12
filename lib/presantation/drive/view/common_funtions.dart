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

void showMoveToBinDialog(BuildContext context, VoidCallback onTap,String Name) {
  showDialog(
    context: context,
    barrierColor: Colors.black54, // dim background
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: Align(
          alignment: Alignment.center,
          child: Container(
            width: 350,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Move to Bin?",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "‘${Name.isEmpty?"File":Name}’ will be deleted forever after 30 days"
                      "Collaborators will lose access.",
                  maxLines: 2,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onTap();
                      },
                      child: const Text(
                        "Move to Bin",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

