import 'package:flutter/material.dart';
import 'package:nde_email/presantation/chat/chat_list/chat_response_model.dart';


class ChatSubtitle extends StatelessWidget {
  final Datu chat;
  final Color textColor;

  const ChatSubtitle({
    super.key,
    required this.chat,
    this.textColor = Colors.black45,
  });

  @override
  Widget build(BuildContext context) {
    // Draft message
    if (chat.draftMessage?.isNotEmpty == true) {
      return RichText(
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          children: [
            const TextSpan(
              text: 'Draft: ',
              style: TextStyle(
                fontSize: 14,
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: chat.draftMessage!,
              style: TextStyle(fontSize: 14, color: textColor),
            ),
          ],
        ),
      );
    }

    // Image
    if (chat.contentType == "image") {
      return _iconText(
        Icons.image,
        'Image',
      );
    }

    // File / PDF
    if (chat.contentType == "file" ||
        (chat.mimeType?.contains("pdf") ?? false)) {
      return Row(
        children: [
          Icon(Icons.insert_drive_file, size: 16, color: textColor),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              chat.fileName?.isNotEmpty == true
                  ? chat.fileName!
                  : "Document",
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, color: textColor),
            ),
          ),
        ],
      );
    }

    // Audio
    if (chat.contentType == "audio") {
      return _iconText(Icons.mic, 'Audio');
    }

    // Video
    if (chat.contentType == "video") {
      return _iconText(Icons.videocam, 'Video');
    }

    // Text message
    return Text(
      chat.lastMessage?.isNotEmpty == true
          ? chat.lastMessage!
          : "No message",
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 14, color: textColor),
    );
  }

  Widget _iconText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: textColor),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 14, color: textColor),
        ),
      ],
    );
  }
}
