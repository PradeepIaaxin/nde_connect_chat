import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:nde_email/utils/datetime/dateFormatter.dart';

class WhatsAppImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final List<String> senderNames;
  final List<String> sentTimes;
  final int initialIndex;

  const WhatsAppImageViewer({
    super.key,
    required this.imageUrls,
    required this.senderNames,
    required this.sentTimes,
    this.initialIndex = 0,
  });

  @override
  State<WhatsAppImageViewer> createState() => _WhatsAppImageViewerState();
}

class _WhatsAppImageViewerState extends State<WhatsAppImageViewer> {
  late PageController _pageController;
  int _currentIndex = 0;
  bool isDownloading = false;
  final Dio _dio = Dio();
  List<double> _downloadProgress = [];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _downloadProgress = List.filled(widget.imageUrls.length, 0.0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _dio.close();
    super.dispose();
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Check Android version
      if (await Permission.storage.isGranted) return true;

      // For Android 13+ we need photos permission for gallery access
      if (await Permission.photos.isGranted) return true;

      // Request the necessary permissions
      final status = await Permission.storage.request();
      if (status.isGranted) return true;

      // For Android 13+ (API 33+)
      if (await Permission.photos.request().isGranted) return true;

      // If permissions are permanently denied
      if (status.isPermanentlyDenied ||
          (await Permission.photos.isPermanentlyDenied)) {
        await openAppSettings();
        return false;
      }

      return false;
    } else if (Platform.isIOS) {
      // For iOS, we only need photos permission
      final status = await Permission.photos.request();
      return status.isGranted;
    }
    return true; // For other platforms
  }

  Future<void> _openDownloadedFile(String filePath) async {
    try {
      final result = await OpenFile.open(filePath);
      if (result.type != ResultType.done) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file: ${result.message}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open file')),
      );
    }
  }

  Future<void> _downloadImageToGallery(int index) async {
    if (isDownloading) return;

    setState(() {
      isDownloading = true;
      _downloadProgress[index] = 0.0;
    });

    try {
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission required to save images')),
        );
        return;
      }

      final url = widget.imageUrls[index];
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'NDE_$timestamp.jpg';
      final tempPath = '/storage/emulated/0/Download/$fileName';

      // Notify start
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Downloading image...')),
        );
      }

      // Download with live progress
      await _dio.download(
        url,
        tempPath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total);
            setState(() {
              _downloadProgress[index] = progress;
            });

            // Show % in snackbar
            if (mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Downloading: ${(progress * 100).toStringAsFixed(0)}%'),
                  duration: const Duration(milliseconds: 800),
                ),
              );
            }
          }
        },
      );

      // Save to Photos (Gallery)
      await GallerySaver.saveImage(tempPath, albumName: 'NDE Images');

      // Final notification
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Image saved to Photos'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'OPEN',
            onPressed: () {
              _openDownloadedFile(tempPath);
            },
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isDownloading = false;
          _downloadProgress[index] = 0.0;
        });
      }
    }
  }

  Future<void> _shareImage() async {
    final imageUrl = widget.imageUrls[_currentIndex];

    if (imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image to share')),
      );
      return;
    }

    try {
      // 1️⃣ Get image from cache or download if not cached
      final file = await DefaultCacheManager().getSingleFile(imageUrl);

      // 2️⃣ Share the cached file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Check out this image!',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing image: $e')),
      );
    }
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Image info'),
              onTap: () {
                Navigator.pop(context);
                _shareImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                // Implement delete functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.senderNames[_currentIndex],
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
            Text(
              DateFormatter.formatToReadableDate(
                  widget.sentTimes[_currentIndex]),
              style: const TextStyle(fontSize: 12, color: Colors.black),
            ),
          ],
        ),
        actions: [
          if (_downloadProgress[_currentIndex] > 0 &&
              _downloadProgress[_currentIndex] < 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    value: _downloadProgress[_currentIndex],
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: isDownloading
                  ? null
                  : () => _downloadImageToGallery(_currentIndex),
              tooltip: 'Download',
            ),
          IconButton(
            onPressed: _shareImage,
            icon: const Icon(Icons.share),
            tooltip: 'Share',
          ),
          IconButton(
            onPressed: _showMoreOptions,
            icon: const Icon(Icons.more_vert),
            tooltip: 'More options',
          ),
        ],
      ),
      body: Stack(
        children: [
          PageView.builder(
            itemCount: widget.imageUrls.length,
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) => GestureDetector(
              onDoubleTap: () {
                // Implement zoom functionality
              },
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: Center(
                  child: Hero(
                    tag: widget.imageUrls[index],
                    child: Image.network(
                      widget.imageUrls[index],
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Shimmer.fromColors(
                          baseColor: Colors.grey[800]!,
                          highlightColor: Colors.grey[600]!,
                          child: Container(
                            width: double.infinity,
                            height: double.infinity,
                            color: Colors.white,
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.broken_image,
                                size: 60, color: Colors.white),
                            const SizedBox(height: 16),
                            Text(
                              'Failed to load image',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.imageUrls.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.reply, color: Colors.black),
              tooltip: 'Reply',
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.thumb_up, color: Colors.black),
              tooltip: 'Like',
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.thumb_down, color: Colors.black),
              tooltip: 'Dislike',
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.emoji_emotions, color: Colors.black),
              tooltip: 'Add reaction',
            ),
          ],
        ),
      ),
    );
  }
}
