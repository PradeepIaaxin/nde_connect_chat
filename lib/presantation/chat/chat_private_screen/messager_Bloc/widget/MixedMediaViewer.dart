import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/VideoCacheService.dart';
import 'package:nde_email/utils/datetime/date_time_utils.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../widgets/chat_widgets/Common/grouped_media_viewer.dart';
import 'VideoPlayerScreen.dart';
import 'VideoThumbUtil.dart';

class MixedMediaViewer extends StatefulWidget {
  final List<GroupMediaItem> items;
  final int initialIndex;

  const MixedMediaViewer({
    super.key,
    required this.items,
    this.initialIndex = 0,
  });

  @override
  State<MixedMediaViewer> createState() => _MixedMediaViewerState();
}

class _MixedMediaViewerState extends State<MixedMediaViewer> {
  late final PageController _controller;
  late int _currentIndex;
  bool _showUI = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: _currentIndex);
    // Hide status bar for immersive experience initially if needed,
    // but usually we show UI first.
  }

  @override
  void dispose() {
    _controller.dispose();
    // Restore status bar when leaving
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    super.dispose();
  }

  void _toggleUI() {
    setState(() {
      _showUI = !_showUI;
      if (_showUI) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
            overlays: SystemUiOverlay.values);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      }
    });
  }

  String _formatDateTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(timeStr);
      return DateTimeUtils.formatMessageTime(dt);
    } catch (e) {
      return '';
    }
  }

  // ==========================================================
  // MAIN BUILD
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    final currentItem = widget.items[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _showUI
          ? AppBar(
              backgroundColor: Colors.black.withOpacity(0.4),
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              titleSpacing: 0,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentItem.senderName ?? 'Media',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (currentItem.time != null)
                    Text(
                      _formatDateTime(currentItem.time),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
              ),
            )
          : null,
      body: Stack(
        children: [
          _buildGallery(),
          if (_showUI) _buildBottomThumbnails(),
        ],
      ),
    );
  }

  // ==========================================================
  // GALLERY VIEW
  // ==========================================================
  Widget _buildGallery() {
    return GestureDetector(
      onTap: _toggleUI,
      child: PhotoViewGallery.builder(
        pageController: _controller,
        itemCount: widget.items.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        builder: (context, index) {
          final item = widget.items[index];

          // 🎥 VIDEO PAGE
          if (item.isVideo) {
            return PhotoViewGalleryPageOptions.customChild(
              disableGestures: true,
              child: Center(
                child: VideoPlayerScreen(
                  path: item.mediaUrl,
                  isNetwork: item.mediaUrl.startsWith('http'),
                  isVideo: true,
                ),
              ),
            );
          }

          // 🖼 IMAGE PAGE (ZOOMABLE)
          return PhotoViewGalleryPageOptions(
            heroAttributes: PhotoViewHeroAttributes(tag: item.mediaUrl),
            imageProvider: item.mediaUrl.startsWith('http')
                ? CachedNetworkImageProvider(item.mediaUrl)
                : FileImage(File(item.mediaUrl)) as ImageProvider,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 3,
          );
        },
      ),
    );
  }

  // ==========================================================
  // BOTTOM THUMBNAILS STRIP
  // ==========================================================
  Widget _buildBottomThumbnails() {
    const double thumbSize = 60;
    const double borderSize = 3;

    return Positioned(
      bottom: 12,
      left: 0,
      right: 0,
      child: SizedBox(
        height: 78,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          itemCount: widget.items.length,
          itemBuilder: (context, index) {
            final item = widget.items[index];
            final bool isSelected = index == _currentIndex;

            return GestureDetector(
              onTap: () {
                _controller.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                padding: const EdgeInsets.all(borderSize),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.green : Colors.transparent,
                    width: borderSize,
                  ),
                ),
                child: Transform.scale(
                  scale: isSelected ? 1.08 : 1.0, // 🔥 smooth zoom
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      width: thumbSize,
                      height: thumbSize,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          _buildThumbnail(item),
                          if (item.isVideo)
                            const Icon(
                              Icons.play_circle_fill,
                              color: Colors.white,
                              size: 22,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ==========================================================
  // THUMBNAIL BUILDER (IMAGE + VIDEO)
  // ==========================================================
  Widget _buildThumbnail(GroupMediaItem item) {
    const double size = 60;

    // 🖼 IMAGE THUMB
    if (!item.isVideo) {
      return item.mediaUrl.startsWith('http')
          ? CachedNetworkImage(
              imageUrl: item.mediaUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: Colors.grey.shade300),
              errorWidget: (_, __, ___) =>
                  Container(color: Colors.grey.shade400),
            )
          : Image.file(
              File(item.mediaUrl),
              width: size,
              height: size,
              fit: BoxFit.cover,
            );
    }

    // 🎥 VIDEO THUMB
    return FutureBuilder<File?>(
      future: VideoCacheService.instance.getThumbnailFuture(item.mediaUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: size,
            height: size,
            color: Colors.black26,
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return Image.file(
            snapshot.data!,
            width: size,
            height: size,
            fit: BoxFit.cover,
          );
        }

        return Container(
          width: size,
          height: size,
          color: Colors.black,
          alignment: Alignment.center,
          child: const Icon(
            Icons.videocam,
            color: Colors.white,
            size: 18,
          ),
        );
      },
    );
  }
}