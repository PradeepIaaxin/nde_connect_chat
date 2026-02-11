import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/videocacheservice.dart';

import 'package:nde_email/presantation/widgets/chat_widgets/Common/message_caption.dart';

class GroupedMediaWidget extends StatelessWidget {
  final List<String> mediaUrls;
  final Function(int index)? onMediaTap;
  final String? caption;
  final bool isSentByMe;
  final String time;
  final String messageStatus;
  final String? searchText;
  final bool isHighlighted;

  const GroupedMediaWidget({
    super.key,
    required this.mediaUrls,
    this.onMediaTap,
    this.caption,
    this.isSentByMe = false,
    this.time = '',
    this.messageStatus = '',
    this.searchText,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    if (mediaUrls.isEmpty) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;

    // WhatsApp-like bubble width
    final double bubbleWidth =
        screenWidth < 600 ? screenWidth * 0.65 : screenWidth * 0.5;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      color: isHighlighted
          ? Colors.blueAccent.withValues(alpha: 0.3)
          : Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: bubbleWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildLayout(context),
            ),
            if (caption != null && caption!.isNotEmpty && caption != "null")
              MessageCaption(
                content: caption!,
                time: time,
                isSentByMe: isSentByMe,
                messageStatus: messageStatus,
                searchText: searchText,
              ),
          ],
        ),
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
        aspectRatio: 5 / 5,
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
        aspectRatio: 5 / 5,
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
      aspectRatio: 5 / 5,
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
                        GestureDetector(
                          onTap: () => onMediaTap?.call(3),
                          child: Container(
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
    if (index >= mediaUrls.length) return const SizedBox.shrink();

    final path = mediaUrls[index];
    final isVideo = _isVideo(path);
    final isLocal = path.startsWith('/') || path.startsWith('file://');

    return GestureDetector(
      onTap: () => onMediaTap?.call(index),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(width: 0.5, color: Colors.white),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            isVideo ? _buildVideoThumbnail(path) : _buildImage(path, isLocal),
            if (isVideo)
              Center(
                child: Icon(
                  Icons.play_circle_fill,
                  size: 36,
                  color: Colors.grey.shade300,
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
      future: VideoCacheService.instance.getThumbnailFuture(videoPath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData &&
            snapshot.data!.existsSync()) {
          return Image.file(
            snapshot.data!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          );
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
            width: double.infinity,
            height: double.infinity,
          )
        : CachedNetworkImage(
            imageUrl: imagePath,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            placeholder: (_, __) => Container(color: Colors.grey.shade200),
            errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
          );
  }
}
