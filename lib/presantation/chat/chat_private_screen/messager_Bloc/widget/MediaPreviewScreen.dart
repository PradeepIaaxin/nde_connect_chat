import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';
import 'package:objectid/objectid.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../widgets/chat_widgets/messager_Wifgets/show_Bottom_Sheet.dart';
import '../MessagerBloc.dart';
import '../MessagerEvent.dart';
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
                      onPressed: _sending ? null : _sendAll,
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
  bool _isAudio(XFile file) {
    final mime = lookupMimeType(file.path) ?? '';
    return mime.startsWith('audio/');
  }

  Future<void> _sendAll() async {
    setState(() => _sending = true);
    final caption = _captionController.text.trim();
    log("hhhhhhhhhhhh55555555");
    final List<Map<String, dynamic>> localMessages = [];
    final groupMessageId =
    widget.files.length > 1 ? ObjectId().toString() : null;
    log("hhhhhhhhhhhh");
    for (final file in widget.files) {
      // 🔥 AUDIO FILE FLOW
      log("hhhhhhhhhhhhaudioooooooooooo");
      if (_isAudio(file)) {
        final audioFile = File(file.path);
        final int fakeDuration = 0; // optional – you can calculate later

        // Dispatch audio event directly
        context.read<MessagerBloc>().add(
          SendAudioMessageEvent(
            senderId: widget.senderId,
            receiverId: widget.receiverId,
            audioPath: audioFile.path,
            duration: fakeDuration.toString(),
            convoId: widget.conversationId,
          ),
        );

        continue; // skip sendFile()
      }

      // 🖼️ IMAGE / VIDEO / DOCUMENT FLOW
      final msg = await ShowAltDialog.sendFile(
        context: context,
        file: file,
        conversationId: widget.conversationId,
        senderId: widget.senderId,
        receiverId: widget.receiverId,
        isGroupChat: widget.isGroupChat,
        isGroupMessage: widget.files.length > 1,
        groupMessageId: groupMessageId,
        caption: caption.isNotEmpty ? caption : null,
      );

      if (msg != null) localMessages.add(msg);
    }

    setState(() => _sending = false);

    Navigator.of(context).pop(localMessages);
  }

}
