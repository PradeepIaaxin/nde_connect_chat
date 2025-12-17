import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../widgets/chat_widgets/Common/grouped_media_viewer.dart';
import 'VideoPlayerScreen.dart';

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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} / ${widget.items.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PhotoViewGallery.builder(
        pageController: _controller,
        itemCount: widget.items.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        builder: (context, index) {
          final item = widget.items[index];

          // 🎥 VIDEO
          if (item.isVideo) {
            return PhotoViewGalleryPageOptions.customChild(
              child: Center(
                child: VideoPlayerScreen(
                  path: item.mediaUrl,
                  isNetwork: item.mediaUrl.startsWith('http'),
                  isVideo: true,
                ),
              ),
            );
          }

          // 🖼 IMAGE (ZOOM ENABLED)
          return PhotoViewGalleryPageOptions(
            heroAttributes: PhotoViewHeroAttributes(
              tag: item.mediaUrl, // must match grid hero
            ),
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
}
