import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/VideoThumbUtil.dart';
import '../../../../../utils/reusbale/common_import.dart';

class RepliedMessagePreview extends StatefulWidget {
  final Map<String, dynamic> replied;
  final VoidCallback? onTap;
  final Map<String, dynamic> receiver;
  final bool isSender;
  final int? groupMediaLength;

  const RepliedMessagePreview(
      {super.key,
      required this.replied,
      this.onTap,
      required this.receiver,
      required this.isSender,
      this.groupMediaLength});

  @override
  State<RepliedMessagePreview> createState() => _RepliedMessagePreviewState();
}

class _RepliedMessagePreviewState extends State<RepliedMessagePreview> {
  Widget? trailingThumb;
  @override
  Widget build(BuildContext context) {
    const double thumbSize = 70;
    final replyContent =
        (widget.replied['replyContent'] ?? widget.replied['content'] ?? '')
            .toString();

    final mediaUrl = widget.replied['originalUrl'] ??
        widget.replied['imageUrl'] ??
        widget.replied['fileUrl'] ??
        '';

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

    final bool isVideo = contentType == 'video' ||
        fileType.startsWith('video/') ||
        ['.mp4', '.mov', '.mkv', '.avi', '.webm']
            .any((ext) => mediaUrl.toLowerCase().contains(ext));

    final bool isImage = contentType == 'image' ||
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

    if (replyContent.isEmpty && mediaUrl.isEmpty && !isAudio && !isDocument) {
      return const SizedBox.shrink();
    }

    print("urrrrrrrrrrrrrr $mediaUrl");
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
            child: Icon(Icons.insert_drive_file, color: Colors.white),
          ),
        );
      }

      if (isVideo) {
        trailingThumb = SizedBox(
          width: thumbSize,
          height: thumbSize,
          child: FutureBuilder<File?>(
            future: VideoThumbUtil.generateFromUrl(mediaUrl),
            builder: (context, snapshot) {
              final thumbFile = snapshot.data;
              if (thumbFile == null) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    color: Colors.black26,
                    child: Center(
                      child: Container(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                );
              }

              if (thumbFile != null && thumbFile.existsSync()) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
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
                      size: 28,
                    ),
                  ],
                );
              }

              return Text("hiii");
            },
          ),
        );
      }
      return trailingThumb;
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.only(right: 20, top: 5, bottom: 5),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 231, 235, 249),
          border: Border(left: BorderSide(color: Colors.blueAccent, width: 5)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 8),
            Flexible(
              fit: FlexFit.loose,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.isSender
                        ? 'You'
                        : '${widget.receiver['first_name'] ?? ''} ${widget.receiver['last_name'] ?? ''}',
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
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            if ((isImage || isVideo) && mediaUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 42,
                  height: 42,
                  child: buildThumb(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}