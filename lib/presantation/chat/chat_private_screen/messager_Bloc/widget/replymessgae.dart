import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/VideoThumbUtil.dart';

import '../../../../../utils/reusbale/common_import.dart';
import 'VideoCacheService.dart';

class RepliedMessagePreview extends StatefulWidget {
  final Map<String, dynamic> replied;
  final VoidCallback? onTap;
  final Map<String, dynamic> receiver;
  final bool isSender;

  const RepliedMessagePreview({
    super.key,
    required this.replied,
    this.onTap,
    required this.receiver,
    required this.isSender,
  });

  @override
  State<RepliedMessagePreview> createState() => _RepliedMessagePreviewState();
}

class _RepliedMessagePreviewState extends State<RepliedMessagePreview> {
  late Map<String, dynamic> _replied;

  @override
  void initState() {
    super.initState();
    _replied = Map<String, dynamic>.from(widget.replied);
  }

  Widget? trailingThumb;
  @override
  Widget build(BuildContext context) {
    const double thumbSize = 70;
    final replyContent =
        (_replied['replyContent'] ?? _replied['content'] ?? '').toString();

    final fileName = (_replied['fileName'] ?? '').toString().toLowerCase();

    final mediaUrl = (_replied['replyUrl'] ??
            _replied['thumbnailUrl'] ??
            _replied['fileUrl'] ??
            '')
        .toString();

    final bool isVideo =
        fileName.endsWith('.mp4') || mediaUrl.toLowerCase().contains('.mp4');

    final bool isImage = fileName.endsWith('.jpg') ||
        fileName.endsWith('.jpeg') ||
        fileName.endsWith('.png') ||
        mediaUrl.toLowerCase().contains('.jpg') ||
        mediaUrl.toLowerCase().contains('.png');

    if (replyContent.isEmpty && mediaUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    print("urrrrrrrrrrrrrr $mediaUrl");
    Widget? buildThumb() {
      /// ✅ IMAGE
      if (isImage) {
        return CachedNetworkImage(
          imageUrl: mediaUrl,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(color: Colors.grey.shade300),
          errorWidget: (_, __, ___) => Container(color: Colors.grey.shade400),
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
              print("thummmm $trailingThumb");
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    const Text(
                      'Video',
                      style: TextStyle(fontSize: 12),
                    )
                  else if (isImage)
                    const Text(
                      'Photo',
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
