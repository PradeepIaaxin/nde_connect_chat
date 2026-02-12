import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:nde_email/utils/imports/common_imports.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

class FilePreviewWidget extends StatefulWidget {
  final String? fileUrl;

  const FilePreviewWidget({super.key, required this.fileUrl});

  @override
  State<FilePreviewWidget> createState() => _FilePreviewWidgetState();
}

class _FilePreviewWidgetState extends State<FilePreviewWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  VideoPlayerController? _videoController;

  bool _isPlaying = false;
  bool _controlsVisible = true;
  Duration _videoPosition = Duration.zero;
  Duration _videoDuration = Duration.zero;

  late Future<void> _audioSetupFuture;

  @override
  void initState() {
    super.initState();
    if (widget.fileUrl != null) {

    }
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

  @override
  void dispose() {
    _audioPlayer.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  // ================= AUDIO =================

  Future<void> _setupAudioPlayer() async {
    if (widget.fileUrl != null &&
        _isAudio(_getFileExtension(widget.fileUrl!))) {
      await _audioPlayer.setUrl(widget.fileUrl!);

      _audioPlayer.playerStateStream.listen((state) {
        if (mounted) {
          setState(() => _isPlaying = state.playing);
        }
      });
    }
  }

  Widget _buildAudioPlayer() {
    return Center(
      child: FutureBuilder(
        future: _audioSetupFuture,
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoading();
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  _isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  size: 70,
                  color: Colors.blue,
                ),
                onPressed: () =>
                    _isPlaying ? _audioPlayer.pause() : _audioPlayer.play(),
              ),
              const SizedBox(height: 10),
              const Text("Tap to play audio"),
            ],
          );
        },
      ),
    );
  }

  // ================= VIDEO =================

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

  Widget _buildVideoPlayer() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return _buildLoading();
    }

    return GestureDetector(
      onTap: () => setState(() => _controlsVisible = !_controlsVisible),
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
    final isPlaying = _videoController!.value.isPlaying;
    return Container(
      color: Colors.black54,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Slider(
            value: _videoPosition.inSeconds
                .clamp(0, _videoDuration.inSeconds)
                .toDouble(),
            max: _videoDuration.inSeconds.toDouble() == 0
                ? 1
                : _videoDuration.inSeconds.toDouble(),
            onChanged: (v) =>
                _videoController!.seekTo(Duration(seconds: v.toInt())),
          ),
          IconButton(
            icon: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
            ),
            onPressed: () => isPlaying
                ? _videoController!.pause()
                : _videoController!.play(),
          ),
        ],
      ),
    );
  }

  // ================= PDF =================

  Widget _buildPdfPreview() {
    return  FutureBuilder<File>(
      future: _downloadFile(widget.fileUrl!, _getFileName(widget.fileUrl!)),
      builder: (context, snapshot) {

        if (snapshot.connectionState != ConnectionState.done) {
          return _buildLoading();
        }

        if (snapshot.hasError || snapshot.data == null) {
          return const Center(child: Text("Failed to load PDF"));
        }

        final file = snapshot.data!;

        return PDFView(
          filePath: file.path,
          enableSwipe: true,
          swipeHorizontal: false,
        );
      },
    );
  }

  // ================= IMAGE =================

  Widget _buildImagePreview() {
    return Container(
      color: Colors.black, // Optional (nice preview look)
      child: InteractiveViewer(
        minScale: 0.5,     // ✅ Zoom out limit
        maxScale: 5.0,     // ✅ Zoom in limit
        child: Center(
          child: CachedNetworkImage(
            imageUrl: widget.fileUrl!,
            fit: BoxFit.contain,
            placeholder: (_, __) => _buildLoading(),
            errorWidget: (_, __, ___) =>
            const Icon(Icons.broken_image, color: Colors.white, size: 80),
          ),
        ),
      ),
    );
  }



  // ================= OFFICE =================

  // Widget _buildOfficePreview() {
  //   final viewerUrl =
  //       "https://docs.google.com/gview?embedded=true&url=${Uri.encodeFull(widget.fileUrl!)}";
  //
  //   _webViewController ??= WebViewController()
  //     ..setJavaScriptMode(JavaScriptMode.unrestricted)
  //     ..loadRequest(Uri.parse(viewerUrl));
  //
  //   return Stack(
  //     children: [
  //       WebViewWidget(controller: _webViewController!),
  //       Positioned(
  //         bottom: 12,
  //         right: 12,
  //         child: FloatingActionButton(
  //           mini: true,
  //           onPressed: _openExternally,
  //           child: const Icon(Icons.open_in_new),
  //         ),
  //       )
  //     ],
  //   );
  // }
  Widget _buildOfficePreview() {
    final viewerUrl =
        "https://view.officeapps.live.com/op/embed.aspx?src=${Uri.encodeComponent(widget.fileUrl!)}";

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(viewerUrl));

    return WebViewWidget(controller: controller);
  }


  // ================= EXTERNAL =================

  Widget _buildExternalOpener() {
    return Center(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.open_in_new),
        label: const Text("Open File"),
        onPressed: _openExternally,
      ),
    );
  }

  Future<void> _openExternally() async {
    final file =
        await _downloadFile(widget.fileUrl!, _getFileName(widget.fileUrl!));

    await OpenFilex.open(file.path);
  }

  // ================= DOWNLOAD =================

  Future<File> _downloadFile(String url, String name) async {
    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/$name");

    if (await file.exists()) return file;

    final res = await http.get(
      Uri.parse(url),
      // 🔐 ADD AUTH HEADER IF NEEDED
      // headers: {"Authorization": "Bearer YOUR_TOKEN"},
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to download file");
    }

    await file.writeAsBytes(res.bodyBytes);
    return file;
  }

  // ================= HELPERS =================

  String _getFileExtension(String url) =>
      Uri.parse(url).path.split('.').last.toLowerCase();

  String _getFileName(String url) =>
      Uri.parse(url).pathSegments.last.split("?").first;

  bool _isImage(String ext) =>
      ['png', 'jpg', 'jpeg', 'gif', 'webp'].contains(ext);

  bool _isVideo(String ext) => ['mp4', 'mov', 'mkv', 'webm'].contains(ext);

  bool _isAudio(String ext) => ['mp3', 'wav', 'aac', 'ogg'].contains(ext);

  bool _isOffice(String ext) =>
      ['doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'csv', 'ods']
          .contains(ext);
  bool _isText(String ext) => ['txt', 'log', 'json', 'csv'].contains(ext);


  Widget _buildLoading() => const Center(child: CircularProgressIndicator());
  Widget _buildTextPreview() {
    return FutureBuilder<File>(
      future: _downloadFile(widget.fileUrl!, _getFileName(widget.fileUrl!)),
      builder: (context, snapshot) {

        if (snapshot.connectionState != ConnectionState.done) {
          return _buildLoading();
        }

        if (snapshot.hasError || snapshot.data == null) {
          return const Center(child: Text("Failed to load text file"));
        }

        final file = snapshot.data!;

        return FutureBuilder<String>(
          future: file.readAsString(),
          builder: (context, textSnapshot) {

            if (!textSnapshot.hasData) {
              return _buildLoading();
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                textSnapshot.data!,
                style: const TextStyle(fontSize: 16),
              ),
            );
          },
        );
      },
    );
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    if (widget.fileUrl == null || widget.fileUrl!.isEmpty) {
      return const Center(child: Text("No file"));
    }

    final ext = _getFileExtension(widget.fileUrl!);

    Widget child;

    if (_isImage(ext)) {
      child = _buildImagePreview();
    } else if (ext == "pdf") {
      child = _buildPdfPreview();
    } else if (_isVideo(ext)) {
      child = _buildVideoPlayer();
    } else if (_isAudio(ext)) {
      child = _buildAudioPlayer();
    }else if (_isText(ext)) {          // ✅ ADD THIS
      child = _buildTextPreview();
    }
    else if (_isOffice(ext)) {
      return _buildOfficePreview();
    } else {
      child = _buildExternalOpener();
    }

    return Container(
      color: Colors.white,
      child: Center(child: child),
    );
  }
}

// ================= SCREEN =================

class FilePreviewScreen extends StatelessWidget {
  final String fileUrl;
  final String? fileName;

  const FilePreviewScreen({super.key, required this.fileUrl,this.fileName});

  @override
  Widget build(BuildContext context) {
    log("fileUrl $fileUrl");
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          backgroundColor: Colors.white, title: Text(fileName!=null?fileName!:"File Preview")),
      body: FilePreviewWidget(fileUrl: fileUrl),
    );
  }
}
