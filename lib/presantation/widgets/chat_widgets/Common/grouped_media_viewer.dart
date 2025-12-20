import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';
import 'package:nde_email/utils/const/consts.dart';
import 'package:swipe_to/swipe_to.dart';
import '../../../chat/chat_private_screen/messager_Bloc/widget/VideoThumbUtil.dart';

class GroupedMediaWidget extends StatelessWidget {
  final List<GroupMediaItem> media;
  final bool isSentByMe;
  final String time;
  final void Function(int index)? onImageTap;
  final String messageStatus;
  final Widget Function(String status)? buildStatusIcon;
  final void Function()? onForwardTap;
  final GestureDragUpdateCallback? onRightSwipe;
  final bool? isHighlighted;
  final String? messageId;

  const GroupedMediaWidget(
      {super.key,
      required this.media,
      required this.isSentByMe,
      required this.time,
      this.onImageTap,
      required this.messageStatus,
      this.buildStatusIcon,
      this.onForwardTap, // ✅ ADD
      this.onRightSwipe,
      this.messageId,
      this.isHighlighted = false});

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
       print("isHighlighted $isHighlighted");
    return SwipeTo(
      animationDuration: const Duration(milliseconds: 650),
      iconOnRightSwipe: Icons.reply,
      iconColor: Colors.grey.shade600,
      iconSize: 24.0,
      offsetDx: 0.3,
      swipeSensitivity: 5,
      onRightSwipe: onRightSwipe,
      child: AnimatedContainer(
      key: ValueKey(messageId),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(vertical: 2),
        color: isHighlighted!
            ? Colors.blueAccent.withValues(alpha: 0.1)
            : Colors.transparent,
        child: Align(
          alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                margin: EdgeInsets.only(
                  left: isSentByMe ? 60 : 0,
                  right: isSentByMe ? 8 : 60,
                  bottom: 8,
                ),
                width: bubbleWidth,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: isSentByMe
                        ? const Radius.circular(18)
                        : const Radius.circular(18),
                    topRight: isSentByMe
                        ? const Radius.circular(18)
                        : const Radius.circular(18),
                    bottomLeft:
                        isSentByMe ? const Radius.circular(18) : Radius.zero,
                    bottomRight:
                        isSentByMe ? Radius.zero : const Radius.circular(16),
                  ),
                  border: Border.all(
                      color: isSentByMe ? senderColor : receiverColor,
                      width: 2),
                  color: isSentByMe ? senderColor : receiverColor,
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
                      decoration: BoxDecoration(
                        color: isSentByMe ? senderColor : receiverColor,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            time,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.black),
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
              Positioned(
                top: 0,
                bottom: 0,
                left: isSentByMe ? 25 : screenWidth * 0.58,
                right: isSentByMe ? null : -52,
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: onForwardTap,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white,
                        child: Image.asset(
                          "assets/images/forward.png",
                          height: 20,
                          width: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
            color: isSentByMe ? senderColor : receiverColor, // divider line
          ),
          Expanded(child: _tile(context, 1)),
        ],
      );
    }

    if (count == 3) {
      return Row(
        children: [
          Expanded(child: _tile(context, 0)),
          Container(
            width: 4,
            color: isSentByMe ? senderColor : receiverColor, // divider line
          ),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _tile(context, 1)),
                Container(
                  height: 4,
                  color:
                      isSentByMe ? senderColor : receiverColor, // divider line
                ),
                Expanded(child: _tile(context, 2)),
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
              Container(
                width: 4,
                color: isSentByMe ? senderColor : receiverColor, // divider line
              ),
              Expanded(child: _tile(context, 1)),
            ],
          ),
        ),
        Container(
          height: 4,
          color: isSentByMe ? senderColor : receiverColor, // divider line
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _tile(context, 2)),
              Container(
                width: 4,
                color: isSentByMe ? senderColor : receiverColor, // divider line
              ),
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _tile(context, 3),
                    if (media.length > 4)
                      GestureDetector(
                        onTap: () => onImageTap?.call(0),
                        child: Container(
                          color: Colors.black54,
                          alignment: Alignment.center,
                          child: Text(
                            '+${4}',
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
            tag: '${item.mediaUrl}_$index',
            child: _thumb(item),
          ),
          if (item.isVideo)
            Center(
              child: Icon(
                Icons.play_circle_fill,
                size: 36,
                color: Colors.grey.shade300,
              ),
            ),
        ],
      ),
    );
  }

  bool _isLocalPath(String url) {
    return url.startsWith('/') || url.startsWith('file://');
  }

  Widget _thumb(GroupMediaItem item) {
    // ---------- IMAGE ----------
    if (!item.isVideo) {
      final String url = item.previewUrl;

      // ✅ LOCAL IMAGE
      if (_isLocalPath(url)) {
        return Image.file(
          File(url.replaceFirst('file://', '')),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
        );
      }

      // ✅ NETWORK IMAGE
      return ClipRRect(
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(color: Colors.grey.shade300),
          errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
        ),
      );
    }

    // ---------- VIDEO ----------
    return FutureBuilder<File?>(
      future: VideoThumbUtil.generateFromUrl(item.mediaUrl),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.done &&
            snap.hasData &&
            snap.data!.existsSync()) {
          return Image.file(
            snap.data!,
            fit: BoxFit.cover,
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
