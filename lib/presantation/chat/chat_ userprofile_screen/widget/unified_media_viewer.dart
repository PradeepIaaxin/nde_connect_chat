import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/model/doc_links_model.dart';

class UnifiedMediaViewer extends StatefulWidget {
  final List<MediaItem> items;
  final int initialIndex;

  const UnifiedMediaViewer({
    super.key,
    required this.items,
    required this.initialIndex,
  });

  @override
  State<UnifiedMediaViewer> createState() => _UnifiedMediaViewerState();
}

class _UnifiedMediaViewerState extends State<UnifiedMediaViewer> {
  late PageController _pageController;
  VideoPlayerController? _videoController;

  int _currentIndex = 0;
  bool _showControls = true;
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _enterFullscreen();
    _setupMedia(_currentIndex);
  }

  void _enterFullscreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _exitFullscreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  bool _isVideo(MediaItem item) {
    return item.meta?.mimeType?.startsWith('video') == true;
  }

  Future<void> _setupMedia(int index) async {
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;

    final item = widget.items[index];

    if (_isVideo(item) && item.originalUrl != null) {
      _videoController =
          VideoPlayerController.networkUrl(Uri.parse(item.originalUrl!));

      await _videoController!.initialize();
      _videoController!.play();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _exitFullscreen();
    _videoController?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  void _handleVerticalDrag(double dy) {
    setState(() => _dragOffset += dy);
    if (_dragOffset.abs() > 120) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragUpdate: (d) => _handleVerticalDrag(d.delta.dy),
        onVerticalDragEnd: (_) => _dragOffset = 0,
        child: Stack(
          children: [
            /// 🔁 MEDIA SWIPE
            PageView.builder(
              controller: _pageController,
              itemCount: widget.items.length,
              onPageChanged: (index) {
                _currentIndex = index;
                _setupMedia(index);
              },
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final isVideo = _isVideo(item);

                /// 🎥 VIDEO
                if (isVideo) {
                  if (_videoController == null ||
                      !_videoController!.value.isInitialized) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  return GestureDetector(
                    onTap: _toggleControls,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio:
                            _videoController!.value.aspectRatio,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            VideoPlayer(_videoController!),

                            if (_showControls &&
                                !_videoController!.value.isPlaying)
                              const Icon(
                                Icons.play_circle_fill,
                                size: 72,
                                color: Colors.white,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                /// 🖼 IMAGE
                return GestureDetector(
                  onTap: _toggleControls,
                  onDoubleTap: () {},
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Center(
                      child: Image.network(
                        item.originalUrl ?? '',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                );
              },
            ),

            /// ❌ CLOSE BUTTON
            if (_showControls)
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                child: IconButton(
                  icon: const Icon(Icons.close,
                      color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

            /// 🎞 VIDEO PROGRESS
            if (_showControls &&
                _videoController != null &&
                _videoController!.value.isInitialized)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: VideoProgressIndicator(
                  _videoController!,
                  allowScrubbing: true,
                  colors: VideoProgressColors(
                    playedColor: Colors.white,
                    bufferedColor: Colors.white54,
                    backgroundColor: Colors.white24,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
