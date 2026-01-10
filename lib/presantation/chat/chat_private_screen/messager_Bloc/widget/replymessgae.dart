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
    log("REPLIED DATA => ${widget.replied}");
    log("REPLIED DATAs => ${widget.groupMediaLength}");
    const double thumbSize = 70;
    final replyContent =
        (widget.replied['replyContent'] ?? widget.replied['content'] ?? '')
            .toString();

    final fileName =
        (widget.replied['fileName'] ?? '').toString().toLowerCase();

    final mediaUrl = widget.replied['originalUrl'] ??
        widget.replied['imageUrl'] ??
        widget.replied['fileUrl'] ??
        '';
    final bool isGrouped = widget.replied['is_grouped_message'] == true &&
        widget.replied['group_message_id'] != null;

    final bool isVideo =
        fileName.endsWith('.mp4') || mediaUrl.toLowerCase().contains('.mp4');
    final bool isGroupedMedia = isGrouped &&
        widget.groupMediaLength != null &&
        widget.groupMediaLength! > 1;

    final bool isImage = fileName.endsWith('.jpg') ||
        fileName.endsWith('.jpeg') ||
        fileName.endsWith('.png') ||
        mediaUrl.toLowerCase().contains('.jpg') ||
        mediaUrl.toLowerCase().contains('.png');

    final bool isAudio = fileName.endsWith('.mp3') ||
        fileName.endsWith('.aac') ||
        fileName.endsWith('.wav') ||
        fileName.endsWith('.m4a') ||
        (widget.replied['mimeType'] ?? '').toString().contains('audio');

    if (widget.replied.isEmpty) {
      return const SizedBox.shrink();
    }

    print("urrrrrrrrrrrrrr $mediaUrl");
    Widget buildThumb() {
      /// 🎥 VIDEO FIRST
      if (isVideo) {
        return SizedBox(
          width: thumbSize,
          height: thumbSize,
          child: FutureBuilder<File?>(
            future: VideoThumbUtil.generateFromUrl(mediaUrl),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        snapshot.data!,
                        width: thumbSize,
                        height: thumbSize,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const Icon(Icons.play_circle_fill,
                        color: Colors.white, size: 28),
                  ],
                );
              }

              return Container(
                width: thumbSize,
                height: thumbSize,
                color: Colors.black26,
              );
            },
          ),
        );
      }

      /// 🖼 IMAGE LOCAL
      if (mediaUrl.startsWith('/')) {
        return Image.file(File(mediaUrl), fit: BoxFit.cover);
      }

      /// 🌐 IMAGE NETWORK
      if (isImage) {
        return CachedNetworkImage(
          imageUrl: mediaUrl,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(color: Colors.grey.shade300),
          errorWidget: (_, __, ___) => Container(color: Colors.grey.shade400),
        );
      }

      return const SizedBox.shrink();
    }
    Widget buildReplyText() {
      final text = replyContent.toLowerCase();

      if (text.contains('photo')) {
        return Row(
          children: [
            const Icon(Icons.image, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(replyContent, style: const TextStyle(fontSize: 12)),
          ],
        );
      }

      if (text.contains('video')) {
        return Row(
          children: [
            const Icon(Icons.videocam, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(replyContent, style: const TextStyle(fontSize: 12)),
          ],
        );
      }

      if (text.contains('media')) {
        return Row(
          children: [
            const Icon(Icons.collections, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(replyContent, style: const TextStyle(fontSize: 12)),
          ],
        );
      }

      if (isAudio) {
        return Row(
          children: const [
            Icon(Icons.music_note, size: 16, color: Colors.grey),
            SizedBox(width: 4),
            Text("Audio", style: TextStyle(fontSize: 12)),
          ],
        );
      }

      return Text(
        replyContent,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12),
      );
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.only(right: 10, top: 5, bottom: 5),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 231, 235, 249),
            border:
                Border(left: BorderSide(color: Colors.blueAccent, width: 5)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // LEFT TEXT
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 10),
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
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      if (isGroupedMedia)
                        Row(
                          children: [
                            Icon(isVideo ? Icons.videocam : Icons.image,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              replyContent,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        )
                      else if (isVideo)
                        const Text("Video", style: TextStyle(fontSize: 12))
                      else if (isAudio)
                          Row(
                            children: const [
                              Icon(Icons.music_note, size: 16, color: Colors.grey),
                              SizedBox(width: 4),
                              Text("Audio", style: TextStyle(fontSize: 12)),
                            ],
                          )
                        else if (isImage)
                            const Text("Photo", style: TextStyle(fontSize: 12))
                          else
                            buildReplyText(),

                    ],
                  ),
                ),
              ),

              // RIGHT THUMB
              if ((isGroupedMedia || isImage || isVideo) && mediaUrl.isNotEmpty)
                isGroupedMedia?SizedBox(): Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      width: 42,
                      height: 42,
                      child: buildThumb(),
                    ),
                  ),
                ),
            ],
          )),
    );
  }
}
