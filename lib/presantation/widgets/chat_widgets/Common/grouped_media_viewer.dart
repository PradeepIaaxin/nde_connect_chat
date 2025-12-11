import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../../../chat/chat_private_screen/messager_Bloc/widget/VideoPlayerScreen.dart';
import '../../../chat/chat_private_screen/messager_Bloc/widget/VideoThumbUtil.dart';



class GroupedMediaWidget extends StatelessWidget {
  final List<GroupMediaItem> media;
  final bool isSentByMe;
  final String time;

  /// called only for **images**; index is within `media` list
  final void Function(int index)? onImageTap;
  final String messageStatus;
  final Widget Function(String status)? buildStatusIcon;

  const GroupedMediaWidget({
    super.key,
    required this.media,
    required this.isSentByMe,
    required this.time,
    this.onImageTap,
    required this.messageStatus,          // 👈 NEW
    this.buildStatusIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) return const SizedBox.shrink();

    final total = media.length;
    final displayCount = total <= 4 ? total : 4;

    return Align(
      alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
            left: isSentByMe ? 60 : 0, right: !isSentByMe ? 60 : 0),
        decoration: BoxDecoration(
            color: isSentByMe
                ? AppColors.primaryButton.withValues(alpha: 0.2)
                : Colors.grey.shade400,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.primaryButton.withValues(alpha: 0.3), width: 8)
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 1, // perfect square like WhatsApp
              child: GridView.builder(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2x2 grid
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
                itemCount: displayCount,
                itemBuilder: (context, index) {
                  final isOverflowTile =
                      index == 3 && total > 4; // last tile shows +N
                  final item = media[index];

                  if (isOverflowTile) {
                    final remaining = total - 3; // WhatsApp behaviour (+3)
                    return _buildOverflowTile(item, remaining);
                  }

                  return Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: _buildNormalTile(context, index, item),
                  );
                },
              ),
            ),

            // time at bottom-right (like your screenshot)
            Positioned(
              right: 10,
              bottom: 6,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                  if (isSentByMe && buildStatusIcon != null) ...[
                    const SizedBox(width: 4),
                    buildStatusIcon!(messageStatus),   // 👈 ticks here
                  ],
                ],
              ),
            ),          ],
        ),
      ),
    );
  }

  Widget _buildNormalTile(BuildContext context,
      int index,
      GroupMediaItem item,) {
    return GestureDetector(
      onTap: () {
        onImageTap?.call(index);
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildThumbForMedia(item),
          if (item.isVideo)
            const Icon(
              Icons.play_circle_fill,
              size: 32,
              color: Colors.white,
            ),
        ],
      ),
    );
  }

  Widget _buildOverflowTile(GroupMediaItem item, int remainingCount) {
    return Stack(
      alignment: Alignment.center,
      children: [
        _buildThumbForMedia(item),
        Container(color: Colors.black45),
        Text(
          '+$remainingCount',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildThumbForMedia(GroupMediaItem item) {
    // If previewUrl is empty -> show placeholder (image is not ready yet)
    if (item.previewUrl.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          color: Colors.grey.shade300,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    // IMAGE preview (network or local file)
    if (!item.isVideo) {
      if (item.previewUrl.startsWith('http')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: item.previewUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            placeholder: (c, _) => Container(color: Colors.grey.shade300),
            errorWidget: (c, _, __) =>
                Container(
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.broken_image, color: Colors.white70),
                ),
          ),
        );
      } else {
        // local file path
        final f = File(item.previewUrl);
        if (f.existsSync()) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(f, fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity),
          );
        } else {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              color: Colors.grey.shade300,
              child: const Center(
                  child: Icon(Icons.broken_image, color: Colors.white70)),
            ),
          );
        }
      }
    }

    // VIDEO preview: use FutureBuilder thumbnail generation
    return FutureBuilder<File?>(
      future: VideoThumbUtil.generateFromUrl(item.mediaUrl),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(color: Colors.black26,
                child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2))),
          );
        }

        final file = snap.data;
        if (file != null && file.existsSync()) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(file, fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity),
          );
        }

        // fallback to previewUrl (if available) or generic placeholder
        if (item.previewUrl.isNotEmpty) {
          if (item.previewUrl.startsWith('http')) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: item.previewUrl,
                fit: BoxFit.cover,
                placeholder: (c, _) => Container(color: Colors.black26),
                errorWidget: (c, _, __) =>
                    Container(color: Colors.black,
                        child: const Icon(
                            Icons.videocam, color: Colors.white70)),
              ),
            );
          } else {
            final f2 = File(item.previewUrl);
            if (f2.existsSync()) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(f2, fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity),
              );
            }
          }
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            color: Colors.black,
            child: const Icon(Icons.videocam, color: Colors.white54, size: 36),
          ),
        );
      },
    );
  }
}
class GroupMediaItem {
  final String previewUrl; // thumbnail / small image used in grid
  final String mediaUrl;   // actual media (image or video) used when opening
  final bool isVideo;

  GroupMediaItem({
    required this.previewUrl,
    required this.mediaUrl,
    required this.isVideo,
  });
}


