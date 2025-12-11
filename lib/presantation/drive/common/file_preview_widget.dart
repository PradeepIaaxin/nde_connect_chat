import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:nde_email/utils/reusbale/common_import.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

class FilePreviewWidget extends StatefulWidget {
  final String? fileUrl;

  const FilePreviewWidget({super.key, required this.fileUrl});

  @override
  State<FilePreviewWidget> createState() => _FilePreviewWidgetState();
}

class _FilePreviewWidgetState extends State<FilePreviewWidget> {
  // Make WebViewController nullable
  WebViewController? _webViewController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  VideoPlayerController? _videoController;

  // Track the audio player state
  bool _isPlaying = false;
  // Track video controls visibility
  bool _controlsVisible = true;
  Duration _videoPosition = Duration.zero;
  Duration _videoDuration = Duration.zero;

  // Add state variables to manage async operations more efficiently
  late Future<void> _audioSetupFuture;

  @override
  void initState() {
    super.initState();

    _audioSetupFuture = _setupAudioPlayer();
    _setupVideoPlayer();
  }

  @override
  void didUpdateWidget(covariant FilePreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fileUrl != oldWidget.fileUrl) {
      _disposeAllControllers();
      _audioSetupFuture = _setupAudioPlayer();
      _setupVideoPlayer();
    }
  }

  void _disposeAllControllers() {
    _audioPlayer.stop();
    _videoController?.dispose();
    _videoController = null;
  }

  Future<void> _setupAudioPlayer() async {
    if (widget.fileUrl != null &&
        _isAudio(_getFileExtension(widget.fileUrl!))) {
      await _audioPlayer.setUrl(widget.fileUrl!);

      _audioPlayer.playerStateStream.listen((state) {
        if (state.playing != _isPlaying) {
          setState(() {
            _isPlaying = state.playing;
          });
        }
      });
    }
  }

  void _setupVideoPlayer() {
    if (widget.fileUrl != null &&
        _isVideo(_getFileExtension(widget.fileUrl!))) {
      _videoController =
          VideoPlayerController.networkUrl(Uri.parse(widget.fileUrl!))
            ..initialize().then((_) {
              if (mounted) {
                setState(() {
                  _videoDuration = _videoController!.value.duration;
                });
              }
              _videoController!.play();
            });

      _videoController!.addListener(() {
        if (mounted) {
          setState(() {
            _videoPosition = _videoController!.value.position;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fileUrl == null || widget.fileUrl!.trim().isEmpty) {
      return _buildNoContent();
    }

    final ext = _getFileExtension(widget.fileUrl!);

    if (_isImage(ext)) {
      return _buildImagePreview();
    } else if (ext == 'pdf') {
      return _buildPdfPreview();
    } else if (_isVideo(ext)) {
      return _buildVideoPlayer();
    } else if (_isAudio(ext)) {
      return _buildAudioPlayer();
    } else if (_isOfficeDocument(ext)) {
      // Initialize or reuse WebViewController here
      if (_webViewController == null ||
          _webViewController?.currentUrl() != widget.fileUrl) {
        final viewerUrl =
            'https://docs.google.com/gview?embedded=true&url=${Uri.encodeFull(widget.fileUrl!)}';
        _webViewController = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadRequest(Uri.parse(viewerUrl));
      }
      return WebViewWidget(controller: _webViewController!);
    }

    return _buildErrorWidget("Unsupported file type.");
  }

  Widget _buildImagePreview() {
    return CachedNetworkImage(
      imageUrl: widget.fileUrl!,
      fit: BoxFit.contain,
      placeholder: (context, url) => _buildLoadingIndicator(),
      errorWidget: (context, url, error) {
        return _buildImageFallback();
      },
    );
  }

  Widget _buildImageFallback() {
    return FutureBuilder<Uint8List>(
      future: _downloadBytes(widget.fileUrl!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingIndicator();
        }
        if (snapshot.hasData) {
          return Image.memory(snapshot.data!);
        }
        return _buildErrorWidget('Failed to load image');
      },
    );
  }

  Widget _buildPdfPreview() {
    return FutureBuilder<File>(
      future: _downloadFile(widget.fileUrl!, 'temp.pdf'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingIndicator();
        }
        if (snapshot.hasError || snapshot.data == null) {
          return _buildErrorWidget('Failed to load PDF');
        }
        return PDFView(
          filePath: snapshot.data!.path,
          enableSwipe: true,
          swipeHorizontal: false,
        );
      },
    );
  }

  Widget _buildVideoPlayer() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return _buildLoadingIndicator();
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _controlsVisible = !_controlsVisible;
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
          if (_controlsVisible)
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildVideoControls(),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoControls() {
    final bool isPlaying = _videoController!.value.isPlaying;

    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildVideoProgressBar(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon:
                    const Icon(Icons.replay_10, color: Colors.white, size: 36),
                onPressed: () {
                  _videoController!.seekTo(
                    _videoController!.value.position -
                        const Duration(seconds: 10),
                  );
                },
              ),
              IconButton(
                icon: Icon(
                  isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  color: Colors.white,
                  size: 48,
                ),
                onPressed: () {
                  setState(() {
                    if (isPlaying) {
                      _videoController!.pause();
                    } else {
                      _videoController!.play();
                    }
                  });
                },
              ),
              IconButton(
                icon:
                    const Icon(Icons.forward_10, color: Colors.white, size: 36),
                onPressed: () {
                  _videoController!.seekTo(
                    _videoController!.value.position +
                        const Duration(seconds: 10),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVideoProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Text(
            _formatDuration(_videoPosition),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          Expanded(
            child: Slider(
              value: _videoPosition.inSeconds.toDouble(),
              min: 0.0,
              max: _videoDuration.inSeconds.toDouble(),
              onChanged: (value) {
                _videoController!.seekTo(Duration(seconds: value.toInt()));
              },
              activeColor: Colors.red,
              inactiveColor: Colors.white54,
            ),
          ),
          Text(
            _formatDuration(_videoDuration),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildAudioPlayer() {
    return FutureBuilder<void>(
      future: _audioSetupFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingIndicator();
        }
        if (snapshot.hasError) {
          return _buildErrorWidget("Failed to load audio");
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  _isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  size: 48,
                  color: Colors.blueAccent,
                ),
                onPressed: () {
                  if (_isPlaying) {
                    _audioPlayer.pause();
                  } else {
                    _audioPlayer.play();
                  }
                },
              ),
              const SizedBox(width: 16),
              const Text('Tap to play audio', style: TextStyle(fontSize: 16)),
            ],
          ),
        );
      },
    );
  }

  Future<File> _downloadFile(String url, String filename) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        return file;
      } else {
        throw Exception("HTTP ${response.statusCode}");
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Uint8List> _downloadBytes(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception("Image download failed with ${response.statusCode}");
    }
  }

  String _getFileExtension(String url) {
    try {
      return Uri.parse(url).path.split('.').last.toLowerCase();
    } catch (_) {
      return '';
    }
  }

  bool _isImage(String ext) =>
      ['png', 'jpg', 'jpeg', 'gif', 'bmp', 'webp'].contains(ext);

  bool _isOfficeDocument(String ext) =>
      ['doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx'].contains(ext);

  bool _isVideo(String ext) => ['mp4', 'mov', 'webm', 'mkv'].contains(ext);

  bool _isAudio(String ext) => ['mp3', 'wav', 'aac', 'ogg'].contains(ext);

  Widget _buildLoadingIndicator() =>
      const Center(child: CircularProgressIndicator());

  Widget _buildNoContent() => const Center(
        child:
            Text("No content available", style: TextStyle(color: Colors.grey)),
      );

  Widget _buildErrorWidget(String message) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(color: Colors.red)),
          ],
        ),
      );
}

class FilePreviewScreen extends StatelessWidget {
  final String fileUrl;

  const FilePreviewScreen({super.key, required this.fileUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("File Preview"),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.comment, color: Colors.black),
            onPressed: () {},
          )
        ],
      ),
      body: Center(child: FilePreviewWidget(fileUrl: fileUrl)),
    );
  }
}
