import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nde_email/utils/snackbar/snackbar.dart';
import 'package:open_file/open_file.dart';
import 'package:photo_view/photo_view.dart';
import 'package:path_provider/path_provider.dart';
import 'package:nde_email/data/base_url.dart';
import 'package:nde_email/data/respiratory.dart';
import 'package:http/http.dart' as http;


class AttachmentWidget extends StatefulWidget {
  final dynamic attachment;
  final String mailboxId;
  final String messageId;

  const AttachmentWidget({
    super.key,
    required this.attachment,
    required this.mailboxId,
    required this.messageId,
  });

  @override
  State<AttachmentWidget> createState() => _AttachmentWidgetState();
}

class _AttachmentWidgetState extends State<AttachmentWidget> {
  IconData _getFileIcon(String ext) {
    switch (ext) {
      case "pdf":
        return Icons.picture_as_pdf;
      case "doc":
      case "docx":
        return Icons.description;
      case "xls":
      case "xlsx":
        return Icons.table_chart;
      case "txt":
        return Icons.article;
      case "ppt":
      case "pptx":
        return Icons.slideshow;
      case "mp3":
      case "wav":
        return Icons.audiotrack;
      case "mp4":
      case "avi":
      case "mov":
        return Icons.movie;
      case "zip":
      case "rar":
        return Icons.archive;
      case "jpg":
      case "jpeg":
      case "png":
      case "gif":
      case "bmp":
      case "webp":
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileIconColor(String ext) {
    switch (ext) {
      case "pdf":
        return Colors.red;
      case "doc":
      case "docx":
        return Colors.blue;
      case "xls":
      case "xlsx":
        return Colors.green;
      case "txt":
        return Colors.grey;
      case "ppt":
      case "pptx":
        return Colors.deepOrange;
      case "mp3":
      case "wav":
        return Colors.purple;
      case "mp4":
      case "avi":
      case "mov":
        return Colors.deepPurple;
      case "zip":
      case "rar":
        return Colors.brown;
      case "jpg":
      case "jpeg":
      case "png":
      case "gif":
      case "bmp":
      case "webp":
        return Colors.teal;
      default:
        return Colors.blueGrey;
    }
  }

  Future<void> _downloadFileFromBuffer(String fileName,
      {bool forceRedownload = false}) async {
    try {
      final accessToken = await UserPreferences.getAccessToken();
      final workspaceId = await UserPreferences.getDefaultWorkspace();

      if (accessToken == null || workspaceId == null) {
        throw Exception("Access token or workspace ID not found");
      }

      final directory = await getExternalStorageDirectory();
      if (directory == null) throw Exception("Cannot access external storage");

      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      final isImage = ["jpg", "jpeg", "png", "gif", "bmp", "webp"]
          .contains(fileName.split('.').last.toLowerCase());

      if (await file.exists() && !forceRedownload) {
        if (isImage) {
        
          _showImagePreview(file);
        } else {
         
          await OpenFile.open(filePath);
        }
        return;
      }

      if (await file.exists() && forceRedownload) {
       
        if (isImage) {
          bool? redownload = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("File Already Exists"),
              content: Text("Do you want to re-download or open '$fileName'?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Open"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Re-Download"),
                ),
              ],
            ),
          );

          if (redownload == false) {
            _showImagePreview(
                file); 
            return;
          }
        } else {
     
          await OpenFile.open(filePath);
        }
      }

  
      final downloadUrl =
          "${ApiService.baseUrl}/user/attachment/${widget.attachment.id}/mailboxes/${widget.mailboxId}/messages/${widget.messageId}";

      final response = await http.get(
        Uri.parse(downloadUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'X-WorkSpace': workspaceId,
          'Accept': 'application/octet-stream',
        },
      );

      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        Messenger.alertSuccess('Downloaded to: $filePath');

        if (isImage) {
          _showImagePreview(file);
        } else {
          await OpenFile.open(filePath); 
        }
      } else {
        Messenger.alert(msg: 'Failed to download: ${response.statusCode}');
      }
    } catch (e) {
      Messenger.alert(msg: 'Error : ${e.toString()}');
    }
  }


  void _showImagePreview(File file) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Container(
          width: double.infinity,
          height: 400,
          child: PhotoView(
            imageProvider: FileImage(file),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.attachment.filename ?? "attachment";
    final fileExtension =
        fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
    final icon = _getFileIcon(fileExtension);
    final iconColor = _getFileIconColor(fileExtension);

    return Container(
      width: 180,
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 24, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () =>
                  _downloadFileFromBuffer(fileName, forceRedownload: false),
              child: Text(
                fileName,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _downloadFileFromBuffer(fileName,
                forceRedownload: true), 
            child: const Icon(Icons.download, color: Colors.blue),
          ),
        ],
      ),
    );
  }
}
