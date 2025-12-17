import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/VideoThumbUtil.dart';
import 'package:nde_email/utils/const/consts.dart';

class GroupedMediaWidget extends StatelessWidget {
  final List<String> mediaUrls;
  final Function(int index)? onMediaTap;

  const GroupedMediaWidget({
    super.key,
    required this.mediaUrls,
    this.onMediaTap,
  });

  @override
  Widget build(BuildContext context) {
    if (mediaUrls.isEmpty) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;

    // WhatsApp-like bubble width
    final double bubbleWidth =
        screenWidth < 600 ? screenWidth * 0.72 : screenWidth * 0.5;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: bubbleWidth),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(),
      ),
    );
  }

  // --------------------------------------------------

  Widget _buildLayout(BuildContext context) {
    final count = mediaUrls.length;

    if (count == 1) {
      return AspectRatio(
        aspectRatio: 1,
        child: _mediaTile(context, 0),
      );
    }

    if (count == 2) {
      return AspectRatio(
        aspectRatio: 2 / 1,
        child: Row(
          children: [
            Expanded(child: _mediaTile(context, 0)),
            const SizedBox(width: 2),
            Expanded(child: _mediaTile(context, 1)),
          ],
        ),
      );
    }

    if (count == 3) {
      return AspectRatio(
        aspectRatio: 3 / 2,
        child: Row(
          children: [
            Expanded(child: _mediaTile(context, 0)),
            const SizedBox(width: 2),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: _mediaTile(context, 1)),
                  const SizedBox(height: 2),
                  Expanded(child: _mediaTile(context, 2)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 4 or more
    return AspectRatio(
      aspectRatio: 1,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _mediaTile(context, 0)),
                const SizedBox(width: 2),
                Expanded(child: _mediaTile(context, 1)),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _mediaTile(context, 2)),
                const SizedBox(width: 2),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _mediaTile(context, 3),
                      if (mediaUrls.length > 4)
                        Container(
                          color: Colors.black54,
                          alignment: Alignment.center,
                          child: Text(
                            '+${mediaUrls.length - 4}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------

  Widget _mediaTile(BuildContext context, int index) {
    final path = mediaUrls[index];
    final isVideo = _isVideo(path);
    final isLocal = path.startsWith('/') || path.startsWith('file://');

    return GestureDetector(
      onTap: () => onMediaTap?.call(index),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(width: 2, color: senderColor),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            isVideo
                ? _buildVideoThumbnail(path)
                : _buildImage(path, isLocal),
            if (isVideo)
              const Center(
                child: Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                  size: 36,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------

  bool _isVideo(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.avi') ||
        lower.contains('video');
  }

  Widget _buildVideoThumbnail(String videoPath) {
    return FutureBuilder<File?>(
      future: VideoThumbUtil.generateFromUrl(videoPath),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.file(snapshot.data!, fit: BoxFit.cover);
        }
        return Container(
          color: Colors.black26,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(strokeWidth: 2),
        );
      },
    );
  }

  Widget _buildImage(String imagePath, bool isLocal) {
    return isLocal
        ? Image.file(
            File(imagePath.replaceFirst('file://', '')),
            fit: BoxFit.cover,
          )
        : CachedNetworkImage(
            imageUrl: imagePath,
            fit: BoxFit.cover,
            placeholder: (_, __) =>
                Container(color: Colors.grey.shade200),
            errorWidget: (_, __, ___) =>
                const Icon(Icons.broken_image),
          );
  }
}
