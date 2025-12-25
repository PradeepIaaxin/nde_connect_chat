import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/VideoCacheService.dart';
import 'package:nde_email/utils/const/consts.dart';
import 'package:nde_email/presantation/widgets/chat_widgets/Common/whatsapp_swipe_to_reply.dart';

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
      this.onForwardTap,
      this.onRightSwipe,
      this.messageId,
      this.isHighlighted = false});

  static const double _statusBarHeight = 20;

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;

    // ✅ WhatsApp-like bubble width
    final double bubbleWidth =
        screenWidth < 600 ? screenWidth * 0.72 : screenWidth * 0.5;

    final visibleCount = media.length > 4 ? 4 : media.length;

    return SwipeToReply(
      onReply: () =>
          onRightSwipe?.call(DragUpdateDetails(globalPosition: Offset.zero)),
      child: AnimatedContainer(
        key: ValueKey(messageId),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(vertical: 2),
        color: isHighlighted!
            ? Colors.blueAccent.withValues(alpha: 0.3)
            : Colors.transparent,
        child: Align(
          alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                margin: EdgeInsets.only(
                  left: isSentByMe ? 60 : 0,
                  right: isSentByMe ? 1 : 60,
                  bottom: 8,
                ),
                width: bubbleWidth,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft:
                        isSentByMe ? const Radius.circular(18) : Radius.zero,
                    bottomRight:
                        isSentByMe ? Radius.zero : const Radius.circular(16),
                  ),
                  border: Border.all(
                      color: isSentByMe ? senderColor : receiverColor,
                      width: 5),
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
                  ],
                ),
              ),
              Positioned(
                height: _statusBarHeight,
                top: 260,
                left: 265,
                child: Row(
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
        return 2 / 2;
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
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
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
                              '+${media.length - 3}',
                              style: TextStyle(
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

    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      child: GestureDetector(
        onTap: () => onImageTap?.call(index),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: '${item.mediaUrl}_${messageId}_$index',
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
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(url.replaceFirst('file://', '')),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
            ),
            // Show loader if status is 'sending'
            if (messageStatus.toLowerCase() == 'sending')
              Center(child: _buildWhatsAppLoader()),
          ],
        );
      }

      // ✅ NETWORK IMAGE
      return ClipRRect(
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          progressIndicatorBuilder: (_, __, downloadProgress) => Container(
            color: Colors.grey.shade200,
            child: Center(
              child: _buildWhatsAppLoader(progress: downloadProgress.progress),
            ),
          ),
          errorWidget: (_, __, ___) => Container(
            color: Colors.grey.shade200,
            child: const Center(
              child: Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    // ---------- VIDEO ----------
    return FutureBuilder<File?>(
      future: VideoCacheService.instance.getThumbnailFuture(item.mediaUrl),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.done &&
            snap.hasData &&
            snap.data!.existsSync()) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                snap.data!,
                fit: BoxFit.cover,
              ),
              // Show loader if status is 'sending'
              if (messageStatus.toLowerCase() == 'sending')
                Center(child: _buildWhatsAppLoader()),
            ],
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

  Widget _buildWhatsAppLoader({double? progress}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.black38,
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          const Icon(
            Icons.stop,
            color: Colors.white,
            size: 18,
          ),
        ],
      ),
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