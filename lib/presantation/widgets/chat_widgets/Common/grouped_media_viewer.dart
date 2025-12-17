import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';
import '../../../chat/chat_private_screen/messager_Bloc/widget/VideoThumbUtil.dart';

class GroupedMediaWidget extends StatelessWidget {
  final List<GroupMediaItem> media;
  final bool isSentByMe;
  final String time;
  final void Function(int index)? onImageTap;
  final String messageStatus;
  final Widget Function(String status)? buildStatusIcon;

  const GroupedMediaWidget({
    super.key,
    required this.media,
    required this.isSentByMe,
    required this.time,
    this.onImageTap,
    required this.messageStatus,
    this.buildStatusIcon,
  });

  static const double _statusBarHeight = 26;
  static const double _radius = 14;

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;

    // ✅ WhatsApp-like bubble width
    final double bubbleWidth =
        screenWidth < 600 ? screenWidth * 0.72 : screenWidth * 0.5;

    final visibleCount = media.length > 4 ? 4 : media.length;

    return Align(
      alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isSentByMe ? 60 : 8,
          right: isSentByMe ? 8 : 60,
          bottom: 8,
        ),
        width: bubbleWidth,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(color: Colors.blue, width: 2),
          color: Colors.grey.shade300,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🔹 MEDIA AREA
            AspectRatio(
              aspectRatio: _aspectRatio(visibleCount),
              child: _buildMediaLayout(context, visibleCount),
            ),

            // 🔹 STATUS BAR
            Container(
              height: _statusBarHeight,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    time,
                    style: const TextStyle(fontSize: 11, color: Colors.white),
                  ),
                  if (isSentByMe && buildStatusIcon != null) ...[
                    const SizedBox(width: 4),
                    buildStatusIcon!(messageStatus),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------- Aspect Ratios -----------------

  double _aspectRatio(int count) {
    switch (count) {
      case 1:
        return 1;
      case 2:
        return 2 / 1;
      case 3:
        return 3 / 2;
      default:
        return 1;
    }
  }

  // ----------------- Layout -----------------

  Widget _buildMediaLayout(BuildContext context, int count) {
    if (count == 1) {
      return _tile(context, 0);
    }

    if (count == 2) {
      return Row(
        children: [
          Expanded(child: _tile(context, 0)),
           Container(
        width: 4,
        color: Colors.blue, // divider line
      ),
          Expanded(child: _tile(context, 1)),
        ],
      );
    }

    if (count == 3) {
      return Row(
        children: [
          Expanded(child: _tile(context, 0)),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _tile(context, 1)),
               Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _tile(context, 2),
                    if (media.length > 2)
                      GestureDetector(   onTap: () => onImageTap?.call(0),
                        child: Container(
                          color: Colors.black54,
                          alignment: Alignment.center,
                          child: Text(
                            '+${media.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
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
      );
    }

    // 4+
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _tile(context, 0)),
              Expanded(child: _tile(context, 1)),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _tile(context, 2)),
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _tile(context, 3),
                    if (media.length > 4)
                      GestureDetector(   onTap: () => onImageTap?.call(0),
                        child: Container(
                          color: Colors.black54,
                          alignment: Alignment.center,
                          child: Text(
                            '+${media.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
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
    );
  }

  // ----------------- Tile -----------------

  Widget _tile(BuildContext context, int index) {
    final item = media[index];

    return GestureDetector(
      onTap: () => onImageTap?.call(index),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: item.mediaUrl,
            child: _thumb(item),
          ),
          if (item.isVideo)
            const Center(
              child: Icon(Icons.play_circle_fill,
                  size: 36, color: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _thumb(GroupMediaItem item) {
    if (!item.isVideo) {
      return CachedNetworkImage(
        imageUrl: item.previewUrl,
        fit: BoxFit.cover,
      );
    }

    return FutureBuilder<File?>(
      future: VideoThumbUtil.generateFromUrl(item.mediaUrl),
      builder: (_, snap) {
        if (snap.hasData && snap.data!.existsSync()) {
          return Image.file(snap.data!, fit: BoxFit.cover);
        }
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      },
    );
  }
}

class GroupMediaItem {
  final String previewUrl;
  final String mediaUrl;
  final bool isVideo;

  GroupMediaItem({
    required this.previewUrl,
    required this.mediaUrl,
    required this.isVideo,
  });
}
