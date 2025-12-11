import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import 'CustomAppBar_Widget.dart';
import 'buttombarWigate.dart';

class ImageMessageWidget extends StatelessWidget {
  final String fileUrl;
  final String lastSendTime;

  const ImageMessageWidget({
    super.key,
    required this.fileUrl,
    required this.lastSendTime,
  });

  @override
  Widget build(BuildContext context) {
    // Validate the fileUrl
    if (fileUrl.isEmpty || !_isValidUrl(fileUrl)) {
      return _buildErrorWidget();
    }

    return GestureDetector(
      onTap: () => _openFullScreenImage(context, fileUrl),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          fileUrl,
          width: 287,
          height: 165,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorWidget();
          },
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: 287,
      height: 165,
      color: Colors.grey[300],
      child: const Icon(Icons.broken_image, color: Colors.red),
    );
  }

  bool _isValidUrl(String url) {
    Uri? uri = Uri.tryParse(url);
    return uri != null && uri.hasScheme && uri.host.isNotEmpty;
  }

  void _openFullScreenImage(BuildContext context, String url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: CustomAppBarWidget(lastSendTime: lastSendTime),
          body: PhotoViewGallery.builder(
            itemCount: 1,
            builder: (context, index) => PhotoViewGalleryPageOptions(
              imageProvider: NetworkImage(url),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2.0,
              errorBuilder: (context, error, stackTrace) {
                return _buildErrorWidget();
              },
            ),
            scrollPhysics: const BouncingScrollPhysics(),
            backgroundDecoration: const BoxDecoration(
              color: Colors.black,
            ),
          ),
          bottomNavigationBar: BottomBarWidget(
            onReplyPressed: () {
              log('Reply Pressed');
            },
            onEmojiPressed: () {
              log('Emoji Pressed');
            },
          ),
        ),
      ),
    );
  }
}
