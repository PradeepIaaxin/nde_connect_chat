import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/VideoCacheService.dart';
import 'package:nde_email/utils/datetime/date_time_utils.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';

import '../../../../widgets/chat_widgets/Common/grouped_media_viewer.dart';
import 'VideoPlayerScreen.dart';

// class MixedMediaViewer extends StatefulWidget {
//   final List<GroupMediaItem> items;
//   final int initialIndex;
//
//   const MixedMediaViewer({
//     super.key,
//     required this.items,
//     this.initialIndex = 0,
//   });
//
//   @override
//   State<MixedMediaViewer> createState() => _MixedMediaViewerState();
// }
//
// class _MixedMediaViewerState extends State<MixedMediaViewer> {
//   late final PageController _controller;
//   late final ScrollController _scrollController;
//   late int _currentIndex;
//   bool _showUI = true;
//
//   @override
//   void initState() {
//     super.initState();
//
//     // 🛡️ Safe initialization
//     if (widget.items.isEmpty) {
//       _currentIndex = 0;
//     } else {
//       _currentIndex = widget.initialIndex.clamp(0, widget.items.length - 1);
//     }
//
//     _controller = PageController(initialPage: _currentIndex);
//     _scrollController = ScrollController();
//
//     // After first frame, scroll to the initial index thumbnail
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (widget.items.isEmpty) {
//         if (mounted) Navigator.pop(context); // 🚨 Auto-close if no media
//         return;
//       }
//       _scrollToIndex(_currentIndex);
//     });
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     _scrollController.dispose();
//     // Restore status bar when leaving
//     SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
//         overlays: SystemUiOverlay.values);
//     super.dispose();
//   }
//
//   void _toggleUI() {
//     setState(() {
//       _showUI = !_showUI;
//       if (_showUI) {
//         SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
//             overlays: SystemUiOverlay.values);
//       } else {
//         SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
//       }
//     });
//   }
//
//   String _formatDateTime(String? timeStr) {
//     if (timeStr == null || timeStr.isEmpty) return '';
//     try {
//       final dt = DateTime.parse(timeStr);
//       return DateTimeUtils.formatMessageTime(dt);
//     } catch (e) {
//       return '';
//     }
//   }
//
//   void _scrollToIndex(int index) {
//     if (!_scrollController.hasClients) return;
//     const double itemWidth = 78.0;
//
//     final double screenWidth = MediaQuery.of(context).size.width;
//     final double targetOffset =
//         (index * itemWidth) + (itemWidth / 2) - (screenWidth / 2) + 10;
//     // +10 for the ListView horizontal padding
//
//     final double maxScroll = _scrollController.position.maxScrollExtent;
//     final double finalOffset = targetOffset.clamp(0.0, maxScroll);
//
//     _scrollController.animateTo(
//       finalOffset,
//       duration: const Duration(milliseconds: 300),
//       curve: Curves.easeInOut,
//     );
//   }
//
//   // ==========================================================
//   // MAIN BUILD
//   // ==========================================================
//   @override
//   @override
//   Widget build(BuildContext context) {
//     // 🛡️ Guard against empty list
//     if (widget.items.isEmpty) return const SizedBox();
//
//     final currentItem = widget.items[_currentIndex];
//
//     return Scaffold(
//       backgroundColor: Colors.black,
//       extendBodyBehindAppBar: true,
//       appBar: _showUI
//           ? AppBar(
//               backgroundColor: Colors.black.withOpacity(0.4),
//               elevation: 0,
//               iconTheme: const IconThemeData(color: Colors.white),
//               titleSpacing: 0,
//               title: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text(
//                     currentItem.senderName ?? 'Media',
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 18,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   if (currentItem.time != null)
//                     Text(
//                       _formatDateTime(currentItem.time),
//                       style: const TextStyle(
//                         color: Colors.white70,
//                         fontSize: 13,
//                         fontWeight: FontWeight.w400,
//                       ),
//                     ),
//                 ],
//               ),
//             )
//           : null,
//       body: Stack(
//         children: [
//           _buildGallery(),
//           if (_showUI) _buildBottomThumbnails(),
//         ],
//       ),
//     );
//   }
//
//   // ==========================================================
//   // GALLERY VIEW
//   // ==========================================================
//   Widget _buildGallery() {
//     return GestureDetector(
//       onTap: _toggleUI,
//       child: PhotoViewGallery.builder(
//         pageController: _controller,
//         itemCount: widget.items.length,
//         onPageChanged: (i) {
//           setState(() => _currentIndex = i);
//           _scrollToIndex(i);
//         },
//         backgroundDecoration: const BoxDecoration(color: Colors.black),
//         builder: (context, index) {
//           final item = widget.items[index];
//
//           // 🎥 VIDEO PAGE
//           if (item.isVideo) {
//             return PhotoViewGalleryPageOptions.customChild(
//               disableGestures: true,
//               child: Center(
//                 child: VideoPlayerScreen(
//                   path: item.mediaUrl,
//                   isNetwork: item.mediaUrl.startsWith('http'),
//                   isVideo: true,
//                 ),
//               ),
//             );
//           }
//
//           // 🖼 IMAGE PAGE (ZOOMABLE)
//           return PhotoViewGalleryPageOptions(
//             heroAttributes: PhotoViewHeroAttributes(tag: item.mediaUrl),
//             imageProvider: item.mediaUrl.startsWith('http')
//                 ? CachedNetworkImageProvider(item.mediaUrl)
//                 : FileImage(File(item.mediaUrl)) as ImageProvider,
//             minScale: PhotoViewComputedScale.contained,
//             maxScale: PhotoViewComputedScale.covered * 3,
//           );
//         },
//       ),
//     );
//   }
//
//   // ==========================================================
//   // BOTTOM THUMBNAILS STRIP
//   // ==========================================================
//   Widget _buildBottomThumbnails() {
//     const double thumbSize = 60;
//     const double borderSize = 3;
//
//     return Positioned(
//       bottom: 12,
//       left: 0,
//       right: 0,
//       child: SizedBox(
//         height: 78,
//         child: ListView.builder(
//           controller: _scrollController,
//           scrollDirection: Axis.horizontal,
//           padding: const EdgeInsets.symmetric(horizontal: 10),
//           itemCount: widget.items.length,
//           itemBuilder: (context, index) {
//             final item = widget.items[index];
//             final bool isSelected = index == _currentIndex;
//
//             return GestureDetector(
//               onTap: () {
//                 _controller.animateToPage(
//                   index,
//                   duration: const Duration(milliseconds: 280),
//                   curve: Curves.easeOutCubic,
//                 );
//               },
//               child: AnimatedContainer(
//                 duration: const Duration(milliseconds: 220),
//                 curve: Curves.easeOut,
//                 margin: const EdgeInsets.symmetric(horizontal: 6),
//                 padding: const EdgeInsets.all(borderSize),
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(
//                     color: isSelected ? Colors.green : Colors.transparent,
//                     width: borderSize,
//                   ),
//                 ),
//                 child: Transform.scale(
//                   scale: isSelected ? 1.08 : 1.0, // 🔥 smooth zoom
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(6),
//                     child: SizedBox(
//                       width: thumbSize,
//                       height: thumbSize,
//                       child: Stack(
//                         alignment: Alignment.center,
//                         children: [
//                           _buildThumbnail(item),
//                           if (item.isVideo)
//                             const Icon(
//                               Icons.play_circle_fill,
//                               color: Colors.white,
//                               size: 22,
//                             ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
//
//   // ==========================================================
//   // THUMBNAIL BUILDER (IMAGE + VIDEO)
//   // ==========================================================
//   Widget _buildThumbnail(GroupMediaItem item) {
//     const double size = 60;
//
//     // 🖼 IMAGE THUMB
//     if (!item.isVideo) {
//       return item.mediaUrl.startsWith('http')
//           ? CachedNetworkImage(
//               imageUrl: item.mediaUrl,
//               width: size,
//               height: size,
//               fit: BoxFit.cover,
//               placeholder: (_, __) => Container(color: Colors.grey.shade300),
//               errorWidget: (_, __, ___) =>
//                   Container(color: Colors.grey.shade400),
//             )
//           : Image.file(
//               File(item.mediaUrl),
//               width: size,
//               height: size,
//               fit: BoxFit.cover,
//             );
//     }
//
//     // 🎥 VIDEO THUMB
//     return FutureBuilder<File?>(
//       future: VideoCacheService.instance.getThumbnailFuture(item.mediaUrl),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Container(
//             width: size,
//             height: size,
//             color: Colors.black26,
//           );
//         }
//
//         if (snapshot.hasData && snapshot.data != null) {
//           return Image.file(
//             snapshot.data!,
//             width: size,
//             height: size,
//             fit: BoxFit.cover,
//           );
//         }
//
//         return Container(
//           width: size,
//           height: size,
//           color: Colors.black,
//           alignment: Alignment.center,
//           child: const Icon(
//             Icons.videocam,
//             color: Colors.white,
//             size: 18,
//           ),
//         );
//       },
//     );
//   }
// }
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
  late final ScrollController _scrollController;
  late int _currentIndex;
  bool _showUI = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: _currentIndex);
    _scrollController = ScrollController();

    // After first frame, scroll to the initial index thumbnail
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToIndex(_currentIndex);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
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

  void _scrollToIndex(int index) {
    if (!_scrollController.hasClients) return;
    const double itemWidth = 78.0;

    final double screenWidth = MediaQuery.of(context).size.width;
    final double targetOffset =
        (index * itemWidth) + (itemWidth / 2) - (screenWidth / 2) + 10;
    // +10 for the ListView horizontal padding

    final double maxScroll = _scrollController.position.maxScrollExtent;
    final double finalOffset = targetOffset.clamp(0.0, maxScroll);

    _scrollController.animateTo(
      finalOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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
        onPageChanged: (i) {
          setState(() => _currentIndex = i);
          _scrollToIndex(i);
        },
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        builder: (context, index) {
          final item = widget.items[index];

          // 🎥 VIDEO PAGE
          if (item.isVideo) {
            return PhotoViewGalleryPageOptions.customChild(
              disableGestures: true,
              child: Center(
                child: InlineVideoPlayer(
                  path: item.mediaUrl,
                  isNetwork: item.mediaUrl.startsWith('http'),
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
          controller: _scrollController,
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

class InlineVideoPlayer extends StatefulWidget {
  final String path;
  final bool isNetwork;

  const InlineVideoPlayer({
    super.key,
    required this.path,
    required this.isNetwork,
  });

  @override
  State<InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<InlineVideoPlayer> {
  late VideoPlayerController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();

    _controller = widget.isNetwork
        ? VideoPlayerController.networkUrl(Uri.parse(widget.path))
        : VideoPlayerController.file(File(widget.path));

    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() => _ready = true);
      _controller.play();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const CircularProgressIndicator();

    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: VideoPlayer(_controller),
    );
  }
}
