import 'package:flutter/material.dart';

class RepliedMessagePreview extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isSentByMe;

  const RepliedMessagePreview({
    super.key,
    required this.message,
    required this.isSentByMe,
  });

  @override
  Widget build(BuildContext context) {
    final replied = message['repliedMessage'] ?? {};
    final firstName = (replied['first_name'] ?? '').toString();
    final lastName = (replied['last_name'] ?? '').toString();
    final replyContent = (replied['replyContent'] ?? '').toString();
    final mimeType = (replied['mimeType'] ?? '').toString().toLowerCase();
    final fileName = (replied['fileName'] ?? '').toString();

    Widget _buildFileRow(IconData icon, Color color, String label) {
      return Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      );
    }

    Widget previewWidget;
    if (replyContent.isNotEmpty) {
      previewWidget = Text(
        replyContent,
        style: const TextStyle(fontSize: 12, color: Colors.black87),
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      );
    } else if (mimeType.contains('image')) {
      previewWidget = _buildFileRow(Icons.image, Colors.grey, "Image");
    } else if (mimeType.contains('pdf')) {
      previewWidget =
          _buildFileRow(Icons.picture_as_pdf, Colors.red, "PDF File");
    } else if (mimeType.contains('video')) {
      previewWidget = _buildFileRow(Icons.videocam, Colors.purple, "Video");
    } else if (mimeType.contains('audio')) {
      previewWidget = _buildFileRow(Icons.audiotrack, Colors.green, "Audio");
    } else if (mimeType.contains('application')) {
      previewWidget =
          _buildFileRow(Icons.insert_drive_file, Colors.blueGrey, "Document");
    } else if (fileName.isNotEmpty) {
      previewWidget = Row(
        children: [
          const Icon(Icons.attach_file, size: 16, color: Colors.grey),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              fileName,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    } else {
      previewWidget = const Text(
        "Unsupported message",
        style: TextStyle(fontSize: 12),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: isSentByMe ? Colors.blue : Colors.green,
            width: 4,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      margin: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$firstName $lastName".trim(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 2),
          previewWidget,
        ],
      ),
    );
  }
}
