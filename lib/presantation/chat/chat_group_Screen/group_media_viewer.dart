import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/VideoThumbUtil.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../chat_private_screen/messager_Bloc/widget/VideoPlayerScreen.dart';

class GroupedMediaViewer extends StatefulWidget {
  final List<String> mediaUrls;
  final int initialIndex;

  const GroupedMediaViewer({
    super.key,
    required this.mediaUrls,
    this.initialIndex = 0,
  });

  @override
  State<GroupedMediaViewer> createState() => _GroupedMediaViewerState();
}

class _GroupedMediaViewerState extends State<GroupedMediaViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
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

  void _openMedia(int index) {
    final mediaUrl = widget.mediaUrls[index];
    if (_isVideo(mediaUrl)) {
      // Open video player
      final isNetwork =
          mediaUrl.startsWith('http://') || mediaUrl.startsWith('https://');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoPlayerScreen(
            path: mediaUrl,
            isNetwork: isNetwork,
          ),
        ),
      );
    }
    // Images are already displayed in PhotoView, so no action needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "${_currentIndex + 1} / ${widget.mediaUrls.length}",
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PhotoViewGallery.builder(
              scrollPhysics: const BouncingScrollPhysics(),
              builder: (BuildContext context, int index) {
                final mediaUrl = widget.mediaUrls[index];
                final isVideo = _isVideo(mediaUrl);

                if (isVideo) {
                  // Show video thumbnail with play button for videos
                  return PhotoViewGalleryPageOptions.customChild(
                    child: GestureDetector(
                      onTap: () => _openMedia(index),
                      child: FutureBuilder<File?>(
                        future: VideoThumbUtil.generateFromUrl(mediaUrl),
                        builder: (context, snapshot) {
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              if (snapshot.connectionState ==
                                      ConnectionState.done &&
                                  snapshot.data != null)
                                Image.file(
                                  snapshot.data!,
                                  fit: BoxFit.contain,
                                )
                              else if (snapshot.connectionState ==
                                  ConnectionState.waiting)
                                const Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.white),
                                )
                              else
                                Container(
                                  color: Colors.grey[800],
                                  child: const Icon(Icons.videocam,
                                      color: Colors.grey, size: 60),
                                ),
                              // Play icon overlay
                              Center(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(20),
                                  child: const Icon(
                                    Icons.play_arrow,
                                    color: Colors.white,
                                    size: 50,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    initialScale: PhotoViewComputedScale.contained,
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 2,
                  );
                } else {
                  // Show image with PhotoView for images
                  return PhotoViewGalleryPageOptions(
                    imageProvider: CachedNetworkImageProvider(mediaUrl),
                    initialScale: PhotoViewComputedScale.contained,
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 2,
                  );
                }
              },
              itemCount: widget.mediaUrls.length,
              loadingBuilder: (context, event) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              backgroundDecoration: const BoxDecoration(color: Colors.black),
              pageController: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          ),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.mediaUrls.length,
              itemBuilder: (context, index) {
                final mediaUrl = widget.mediaUrls[index];
                final isVideo = _isVideo(mediaUrl);

                return GestureDetector(
                  onTap: () {
                    _pageController.jumpToPage(index);
                  },
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      border: _currentIndex == index
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                    ),
                    child: Stack(
                      children: [
                        // Thumbnail
                        if (isVideo)
                          FutureBuilder<File?>(
                            future: VideoThumbUtil.generateFromUrl(mediaUrl),
                            builder: (context, snapshot) {
                              if (snapshot.data != null) {
                                return Image.file(
                                  snapshot.data!,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                );
                              }
                              return Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[800],
                                child: const Icon(Icons.videocam,
                                    color: Colors.grey),
                              );
                            },
                          )
                        else
                          CachedNetworkImage(
                            imageUrl: mediaUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        // Play icon for videos
                        if (isVideo)
                          Positioned.fill(
                            child: Center(
                              child: Icon(
                                Icons.play_circle_outline,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
