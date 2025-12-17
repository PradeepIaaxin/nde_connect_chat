import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:objectid/objectid.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../../../../widgets/chat_widgets/messager_Wifgets/show_Bottom_Sheet.dart';
import 'VideoPreviewScreen.dart';

class MediaPreviewScreen extends StatefulWidget {
  final List<XFile> files;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final bool isGroupChat;
  final bool? isDocument;

  const MediaPreviewScreen({
    super.key,
    required this.files,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.isGroupChat,
    this.isDocument = false,
  });

  @override
  State<MediaPreviewScreen> createState() => _MediaPreviewScreenState();
}

class _MediaPreviewScreenState extends State<MediaPreviewScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _sending = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "${_currentIndex + 1} / ${widget.files.length}",
          style: const TextStyle(color: Colors.white),
        ),
      ),

      body: PhotoViewGallery.builder(
        pageController: _pageController,
        itemCount: widget.files.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        backgroundDecoration: const BoxDecoration(color: Colors.black),

        builder: (context, index) {
          final file = widget.files[index];
          final mime = lookupMimeType(file.path) ?? '';
          final isImage = mime.startsWith('image/');
          final isVideo = mime.startsWith('video/');

          /// 📄 DOCUMENT PREVIEW
          if (widget.isDocument == true) {
            return PhotoViewGalleryPageOptions.customChild(
              child: _documentPreview(file),
            );
          }

          /// 🖼 IMAGE PREVIEW (ZOOM + HERO)
          if (isImage) {
            return PhotoViewGalleryPageOptions(
              heroAttributes: PhotoViewHeroAttributes(
                tag: 'preview_${file.path}',
              ),
              imageProvider: FileImage(File(file.path)),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 3,
            );
          }

          /// 🎬 VIDEO PREVIEW (UNCHANGED)
          if (isVideo) {
            return PhotoViewGalleryPageOptions.customChild(
              child: Hero(
                tag: 'preview_${file.path}',
                child: VideoPreviewScreen(file: File(file.path)),
              ),
            );
          }

          /// FALLBACK
          return PhotoViewGalleryPageOptions.customChild(
            child: _documentPreview(file),
          );
        },
      ),

      /// 🟢 SEND BUTTON
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _sending ? null : _sendAll,
        icon: _sending
            ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Icon(Icons.send),
        label: Text(_sending ? "Sending..." : "Send"),
        backgroundColor: Colors.green,
        shape: const StadiumBorder(),
      ),
    );
  }

  /// 📄 DOCUMENT UI
  Widget _documentPreview(XFile file) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.insert_drive_file,
              size: 64, color: Colors.white),
          const SizedBox(height: 8),
          Text(
            file.name,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 🚀 SEND LOGIC (UNCHANGED)
  Future<void> _sendAll() async {
    setState(() => _sending = true);

    final List<Map<String, dynamic>> localMessages = [];
    final groupMessageId =
    widget.files.length > 1 ? ObjectId().toString() : null;

    for (final file in widget.files) {
      final msg = await ShowAltDialog.sendFile(
        context: context,
        file: file,
        conversationId: widget.conversationId,
        senderId: widget.senderId,
        receiverId: widget.receiverId,
        isGroupChat: widget.isGroupChat,
        isGroupMessage: widget.files.length > 1,
        groupMessageId: groupMessageId,
      );

      if (msg != null) localMessages.add(msg);
    }

    setState(() => _sending = false);
    Navigator.of(context).pop(localMessages);
  }
}
