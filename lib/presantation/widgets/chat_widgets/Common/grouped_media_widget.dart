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

    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildLayout(context),
      ),
    );
  }

  bool _isVideo(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.mp4') ||
        lower.contains('.mov') ||
        lower.contains('.mkv') ||
        lower.contains('.avi') ||
        lower.contains('.webm') ||
        lower.contains('video');
  }

  Widget _buildLayout(BuildContext context) {
    int count = mediaUrls.length;

    if (count == 1) {
      return _buildSingleMedia(context, 0);
    } else if (count == 2) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(width: 3, color: senderColor),
        ),
        child: Row(
          children: [
            Expanded(child: _buildSingleMedia(context, 0, height: 150)),
            const SizedBox(width: 0),
            Expanded(child: _buildSingleMedia(context, 1, height: 150)),
          ],
        ),
      );
    } else if (count == 3) {
      return Container(
        child: Column(
          children: [
            _buildSingleMedia(context, 0, height: 120, width: double.infinity),
            const SizedBox(height: 0),
            Row(
              children: [
                Expanded(child: _buildSingleMedia(context, 1, height: 100)),
                const SizedBox(width: 0),
                Expanded(child: _buildSingleMedia(context, 2, height: 100)),
              ],
            ),
          ],
        ),
      );
    } else {
      // 4 or more media - 2x2 grid with overflow count
      return Container(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildSingleMedia(context, 0, height: 100)),
                const SizedBox(width: 0),
                Expanded(child: _buildSingleMedia(context, 1, height: 100)),
              ],
            ),
            const SizedBox(height: 0),
            Row(
              children: [
                Expanded(child: _buildSingleMedia(context, 2, height: 100)),
                const SizedBox(width: 0),
                Expanded(
                  child: count > 4
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            _buildSingleMedia(context, 3, height: 100),
                            Positioned.fill(
                              child: Container(
                                color: Colors.black54,
                                child: Center(
                                  child: Text(
                                    "+${count - 4}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : _buildSingleMedia(context, 3, height: 100),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  Widget _buildSingleMedia(BuildContext context, int index,
      {double? height, double? width}) {
    final mediaPath = mediaUrls[index];
    final isLocal =
        mediaPath.startsWith('/') || mediaPath.startsWith('file://');
    final isVideo = _isVideo(mediaPath);

    return GestureDetector(
      onTap: () => onMediaTap?.call(index),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(width: 5, color: senderColor),
        ),
        height: height,
        width: width,
        child: isVideo
            ? _buildVideoThumbnail(mediaPath, isLocal)
            : _buildImage(mediaPath, isLocal),
      ),
    );
  }

  Widget _buildVideoThumbnail(String videoPath, bool isLocal) {
    return FutureBuilder<File?>(
      future: VideoThumbUtil.generateFromUrl(videoPath),
      builder: (context, snapshot) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Video thumbnail or placeholder
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.data != null)
              Image.file(
                snapshot.data!,
                fit: BoxFit.cover,
              )
            else if (snapshot.connectionState == ConnectionState.waiting)
              Container(
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              Container(
                color: Colors.grey[300],
                child: const Icon(Icons.videocam, color: Colors.grey, size: 40),
              ),
            // Play icon overlay
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(12),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildImage(String imagePath, bool isLocal) {
    return isLocal
        ? Image.file(
            File(imagePath.replaceFirst('file://', '')),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
          )
        : CachedNetworkImage(
            imageUrl: imagePath,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
          );
  }
}
