import '../../../../../utils/reusbale/common_import.dart';
import '../chat_private_screen/messager_Bloc/widget/VideoThumbUtil.dart';

class GroupRepliedMessagePreview extends StatefulWidget {
  final Map<String, dynamic> replied;
  final VoidCallback? onTap;
  final Map<String, dynamic> receiver;
  final bool isSender;
  final int? groupMediaLength;
  final bool? hasMixedMedia;

  const GroupRepliedMessagePreview({
    super.key,
    required this.replied,
    this.onTap,
    required this.receiver,
    required this.isSender,
    this.groupMediaLength,
    this.hasMixedMedia,
  });

  @override
  State<GroupRepliedMessagePreview> createState() =>
      _GroupRepliedMessagePreviewState();
}

class _GroupRepliedMessagePreviewState
    extends State<GroupRepliedMessagePreview> {
  @override
  Widget build(BuildContext context) {
    const double thumbSize = 42;

    final replyContent =
        (widget.replied['replyContent'] ?? widget.replied['content'] ?? '')
            .toString();

    String mediaUrl = widget.replied['originalUrl']?.toString() ?? '';
    if (mediaUrl.isEmpty) {
      mediaUrl = widget.replied['imageUrl']?.toString() ?? '';
    }
    if (mediaUrl.isEmpty) {
      mediaUrl = widget.replied['fileUrl']?.toString() ?? '';
    }

    final String fileType = (widget.replied['mimeType'] ??
            widget.replied['fileType'] ??
            widget.replied['mimetype'] ??
            '')
        .toString()
        .toLowerCase();

    final String contentType =
        (widget.replied['ContentType'] ?? widget.replied['contentType'] ?? '')
            .toString()
            .toLowerCase();

    final bool isGroupedImage = contentType == "image_group";
    final bool isGroupedVideo = contentType == "video_group";

    final String fileName =
        (widget.replied['fileName'] ?? widget.replied['filename'] ?? '')
            .toString()
            .toLowerCase();

    final bool isVideo = isGroupedVideo ||
        contentType == 'video' ||
        fileType.startsWith('video/') ||
        ['.mp4', '.mov', '.mkv', '.avi', '.webm']
            .any((ext) => mediaUrl.toLowerCase().contains(ext)) ||
        ['.mp4', '.mov', '.mkv', '.avi', '.webm']
            .any((ext) => fileName.endsWith(ext));

    final bool isImage = isGroupedImage ||
        contentType == 'image' ||
        fileType.startsWith('image/') ||
        ['.jpg', '.jpeg', '.png', '.gif', '.webp']
            .any((ext) => mediaUrl.toLowerCase().contains(ext)) ||
        ['.jpg', '.jpeg', '.png', '.gif', '.webp']
            .any((ext) => fileName.endsWith(ext));

    final bool isAudio = contentType == 'audio' ||
        fileType.startsWith('audio/') ||
        ['.mp3', '.wav', '.aac', '.m4a']
            .any((ext) => mediaUrl.toLowerCase().contains(ext)) ||
        ['.mp3', '.wav', '.aac', '.m4a'].any((ext) => fileName.endsWith(ext));

    // Refined isDocument: explicitly exclude if we detected other types
    final bool isDocument = !isVideo &&
        !isImage &&
        !isAudio &&
        (contentType == 'file' ||
            contentType == 'document' ||
            // Also treat generic empty types as document if they have a non-media filename
            (contentType.isEmpty &&
                fileName.isNotEmpty &&
                ![
                  '.jpg',
                  '.jpeg',
                  '.png',
                  '.gif',
                  '.webp',
                  '.mp4',
                  '.mov',
                  '.mkv',
                  '.avi',
                  '.webm',
                  '.mp3',
                  '.wav',
                  '.aac',
                  '.m4a'
                ].any((ext) => fileName.endsWith(ext))));

    if (replyContent.isEmpty &&
        mediaUrl.isEmpty &&
        !isAudio &&
        !isDocument &&
        !isImage &&
        !isVideo) {
      return const SizedBox.shrink();
    }

    // ---------------- THUMB ----------------

    Widget? buildThumb() {
      if (isImage && mediaUrl.startsWith('/')) {
        return Image.file(File(mediaUrl), fit: BoxFit.cover);
      }

      if (isImage) {
        return CachedNetworkImage(
          imageUrl: mediaUrl,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(color: Colors.grey.shade300),
          errorWidget: (_, __, ___) => Container(color: Colors.grey.shade400),
        );
      }

      if (isVideo) {
        return FutureBuilder<File?>(
          future: VideoThumbUtil.generateFromUrl(mediaUrl),
          builder: (context, snapshot) {
            final thumbFile = snapshot.data;

            if (thumbFile != null && thumbFile.existsSync()) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  Image.file(
                    thumbFile,
                    width: thumbSize,
                    height: thumbSize,
                    fit: BoxFit.cover,
                  ),
                  const Icon(Icons.play_circle_fill,
                      color: Colors.white, size: 20),
                ],
              );
            }

            return Container(
              color: Colors.black26,
              child: const Center(
                child: Icon(Icons.videocam, color: Colors.white, size: 16),
              ),
            );
          },
        );
      }

      if (isDocument) {
        return Container(
          color: Colors.grey.shade300,
          child: const Center(
            child: Icon(Icons.insert_drive_file, color: Colors.white, size: 18),
          ),
        );
      }

      return null;
    }

    // ---------------- MAIN ----------------

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6, top: 6, left: 4, right: 4),
        padding: const EdgeInsets.only(right: 2, top: 5, bottom: 5, left: 3),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 231, 235, 249),
          border: const Border(
            left: BorderSide(color: Colors.blueAccent, width: 5),
          ),
          borderRadius: BorderRadius.circular(8),
        ),

        /// ❗ only change here: let text shrink when needed
        child: IntrinsicWidth(
          child: Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /// -------- TEXT SIDE --------
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: thumbSize),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.isSender
                              ? 'You'
                              : (widget.replied['senderName'] ??
                                      widget.replied['userName'] ??
                                      widget.replied['first_name'] ??
                                      widget.replied['replyToUser'] ??
                                      'Unknown User')
                                  .toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (widget.hasMixedMedia == true &&
                            widget.groupMediaLength != null &&
                            widget.groupMediaLength! > 1)
                          Text(
                            'Media x ${widget.groupMediaLength}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          )
                        else if (isVideo)
                          Text(
                            widget.groupMediaLength != null &&
                                    widget.groupMediaLength! > 1
                                ? 'Video x ${widget.groupMediaLength}'
                                : 'Video',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          )
                        else if (isAudio)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.music_note,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  widget.replied['duration'] != null
                                      ? 'Audio (${widget.replied['duration']})'
                                      : 'Audio',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          )
                        else if (isImage)
                          Text(
                            widget.groupMediaLength != null &&
                                    widget.groupMediaLength! > 1
                                ? 'Photo x ${widget.groupMediaLength}'
                                : 'Photo',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          )
                        else if (isDocument)
                          const Text(
                            'Document',
                            style: TextStyle(fontSize: 12),
                          )
                        else
                          Text(
                            replyContent,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              /// -------- THUMB --------
              if ((isImage || isVideo) &&
                  mediaUrl.isNotEmpty &&
                  (widget.groupMediaLength ?? 0) <= 1 &&
                  widget.hasMixedMedia != true) ...[
                const SizedBox(width: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    width: thumbSize,
                    height: thumbSize,
                    child: buildThumb(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}