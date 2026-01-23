import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';
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
  final TextEditingController _captionController = TextEditingController();
  int _currentIndex = 0;
  bool _sending = false;

  @override
  void dispose() {
    _captionController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true, // ✅ Allow keyboard to push up content
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "${_currentIndex + 1} / ${widget.files.length}",
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryButton,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.files.length} items',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),

      body: Stack(
        children: [
          // 🖼️ The Gallery Area
          Positioned.fill(
            child: PhotoViewGallery.builder(
              pageController: _pageController,
              itemCount: widget.files.length,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              backgroundDecoration: const BoxDecoration(color: Colors.black),
              builder: (context, index) {
                final file = widget.files[index];
                final mime = lookupMimeType(file.path) ?? '';
                final isImage = mime.startsWith('image/');
                final isVideo = mime.startsWith('video/');

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

                if (isVideo) {
                  return PhotoViewGalleryPageOptions.customChild(
                    child: Hero(
                      tag: 'preview_${file.path}',
                      child: VideoPreviewScreen(file: File(file.path)),
                    ),
                  );
                }

                return PhotoViewGalleryPageOptions.customChild(
                  child: _documentPreview(file),
                );
              },
            ),
          ),

          // 📝 Caption Input Field (Bottom)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color:
                  Colors.black.withOpacity(0.6), // Semi-transparent background
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _captionController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: "Add a caption...",
                            hintStyle: TextStyle(color: Colors.white70),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                          minLines: 1,
                          maxLines: 5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FloatingActionButton(
                      mini: true,
                      backgroundColor: AppColors.primaryButton,
                      child: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.white),
                      onPressed: _sending ? null : _sendAll,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _documentPreview(XFile file) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.insert_drive_file, size: 64, color: Colors.white),
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

  Future<void> _sendAll() async {
    setState(() => _sending = true);
    final caption = _captionController.text.trim(); // Capture caption

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
        caption: caption.isNotEmpty ? caption : null, // ✅ Pass caption
      );
      log('Created message: ${msg?.toString()}');
      debugPrint('MSG STATUS: ${msg?['messageStatus']}');

      if (msg != null) localMessages.add(msg);
    }

    setState(() => _sending = false);

    // Return the messages with localImagePath for immediate display
    Navigator.of(context).pop(localMessages);
  }
}
