import '../../../../../utils/reusbale/common_import.dart';
import '../chat_private_screen/messager_Bloc/widget/VideoThumbUtil.dart';

class GroupRepliedMessagePreview extends StatefulWidget {
  final Map<String, dynamic> replied;
  final VoidCallback? onTap;
  final Map<String, dynamic> receiver;
  final bool isSender;

  final int? groupMediaLength;
  const GroupRepliedMessagePreview({
    super.key, 
    required this.replied,
    this.onTap,
    required this.receiver,
    required this.isSender,
    this.groupMediaLength,
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

    // Patch: treat "image_group" as images for grouped replies
    final bool isGroupedImage = contentType == "image_group";

    final bool isVideo = contentType == 'video' ||
        fileType.startsWith('video/') ||
        ['.mp4', '.mov', '.mkv', '.avi', '.webm']
            .any((ext) => mediaUrl.toLowerCase().contains(ext));

    final bool isImage = isGroupedImage ||
        contentType == 'image' ||
        fileType.startsWith('image/') ||
        ['.jpg', '.jpeg', '.png', '.gif', '.webp']
            .any((ext) => mediaUrl.toLowerCase().contains(ext));

    final bool isAudio = contentType == 'audio' ||
        fileType.startsWith('audio/') ||
        ['.mp3', '.wav', '.aac', '.m4a', '.flac', '.ogg', '.opus']
            .any((ext) => mediaUrl.toLowerCase().contains(ext));

    final bool isDocument = !isVideo &&
        !isImage &&
        !isAudio &&
        ((mediaUrl.isNotEmpty &&
                !RegExp(r'\.(jpg|jpeg|png|gif|webp|mp4|mov|avi|mkv|webm|mp3|wav|aac|m4a|flac|ogg|opus)(\?|$)')
                    .hasMatch(mediaUrl.toLowerCase())) ||
            (widget.replied['fileName'] != null &&
                widget.replied['fileName'].toString().isNotEmpty) ||
            (fileType.isNotEmpty &&
                !fileType.startsWith('image/') &&
                !fileType.startsWith('video/') &&
                !fileType.startsWith('audio/')) ||
            contentType == 'file' ||
            contentType == 'document');

    // Debug logging to identify MIME type issues
    if (widget.replied['fileName'] != null || mediaUrl.isNotEmpty) {
      //debugPrint(
          //'DEBUG GroupRepliedMessagePreview: contentType="$contentType", fileType="$fileType", fileName="${widget.replied['fileName']}", mediaUrl="$mediaUrl"');
      //debugPrint(
          //'DEBUG GroupRepliedMessagePreview: isVideo=$isVideo, isImage=$isImage, isAudio=$isAudio, isDocument=$isDocument');
    }

    if (replyContent.isEmpty && mediaUrl.isEmpty && !isAudio && !isDocument) {
      return const SizedBox.shrink();
    }

    Widget? buildThumb() {
      if (isImage && mediaUrl.startsWith('/')) {
        return Image.file(
          File(mediaUrl),
          fit: BoxFit.cover,
        );
      }

      /// ✅ IMAGE
      if (isImage) {
        return CachedNetworkImage(
          imageUrl: mediaUrl,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(color: Colors.grey.shade300),
          errorWidget: (_, __, ___) => Container(color: Colors.grey.shade400),
        );
      }

      if (isDocument) {
        return Container(
          color: Colors.grey.shade300,
          child: const Center(
            child: Icon(Icons.insert_drive_file, color: Colors.white, size: 20),
          ),
        );
      }

      if (isVideo) {
        return FutureBuilder<File?>(
          future: VideoThumbUtil.generateFromUrl(mediaUrl),
          builder: (context, snapshot) {
            final thumbFile = snapshot.data;
            if (thumbFile == null) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  color: Colors.black26,
                  child: const Center(
                    child: Icon(Icons.videocam, color: Colors.white, size: 16),
                  ),
                ),
              );
            }

            if (thumbFile.existsSync()) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.file(
                      thumbFile,
                      width: thumbSize,
                      height: thumbSize,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const Icon(
                    Icons.play_circle_fill,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              );
            }

            return Container(
              color: Colors.grey.shade300,
              child: const Center(
                child: Icon(Icons.videocam, color: Colors.white, size: 16),
              ),
            );
          },
        );
      }
      return null;
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 231, 235, 249),
          border: Border(left: BorderSide(color: Colors.blueAccent, width: 5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 5),
            Flexible(
              fit: FlexFit.loose,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (isVideo)
                    Text(
                      widget.groupMediaLength != null &&
                              widget.groupMediaLength! > 1
                          ? 'Video x ${widget.groupMediaLength}'
                          : 'Video',
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
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  else if (isImage)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            widget.groupMediaLength != null &&
                                    widget.groupMediaLength! > 1
                                ? 'Photo x ${widget.groupMediaLength}'
                                : 'Photo',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  else if (isDocument)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.insert_drive_file,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        const Flexible(
                          child: Text(
                            'Document',
                            style: TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      replyContent,
                      maxLines: 2,
                      style: const TextStyle(
                        overflow: TextOverflow.ellipsis,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            if ((isImage || isVideo) &&
                mediaUrl.isNotEmpty &&
                (widget.groupMediaLength ?? 0) <= 1) ...[
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
    );
  }
}