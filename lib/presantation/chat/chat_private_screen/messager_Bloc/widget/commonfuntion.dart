import 'package:nde_email/presantation/widgets/chat_widgets/Common/grouped_media_viewer.dart';

List<GroupMediaItem> buildConversationMedia(
  List<Map<String, dynamic>> allMessages,
) {
  final List<GroupMediaItem> media = [];

  for (final msg in allMessages) {
    final String? imageUrl = msg['imageUrl'] ?? msg['originalUrl'];
    final String? fileUrl = msg['fileUrl'];
    final String fileType = (msg['fileType'] ?? '').toLowerCase();

    final bool isVideo =
        fileType.startsWith('video/') ||
        (fileUrl?.endsWith('.mp4') ?? false) ||
        (fileUrl?.endsWith('.mov') ?? false);

    if (isVideo && fileUrl != null && fileUrl.isNotEmpty) {
      media.add(
        GroupMediaItem(
          previewUrl: msg['localThumbPath'] ?? fileUrl,
          mediaUrl: fileUrl,
          isVideo: true,
        ),
      );
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      media.add(
        GroupMediaItem(
          previewUrl: imageUrl,
          mediaUrl: imageUrl,
          isVideo: false,
        ),
      );
    }
  }

  return media;
}
