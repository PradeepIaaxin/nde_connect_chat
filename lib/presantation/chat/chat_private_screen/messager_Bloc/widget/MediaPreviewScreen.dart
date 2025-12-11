import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:objectid/objectid.dart';

import '../../../../widgets/chat_widgets/messager_Wifgets/show_Bottom_Sheet.dart';
import 'VideoPreviewScreen.dart';

class MediaPreviewScreen extends StatefulWidget {
  final List<XFile> files;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final bool isGroupChat;

  const MediaPreviewScreen({
    super.key,
    required this.files,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.isGroupChat,
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
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.files.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (context, index) {
          final f = widget.files[index];
          return _buildPreviewFor(f);
        },
      ),

      // 👇 WhatsApp-like Send FAB at bottom
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _sending ? null : _sendAll,
        icon: _sending
            ?  SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        )
            : const Icon(Icons.send),
        label: Text(_sending ? "Sending..." : "Send"),
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(50))),
      ),
    );
  }

  Widget _buildPreviewFor(XFile file) {
    final mime = lookupMimeType(file.path) ?? '';
    final isImage = mime.startsWith('image/');
    final isVideo = mime.startsWith('video/');

    if (isImage) {
      return Center(
        child: Image.file(
          File(file.path),
          fit: BoxFit.contain,
        ),
      );
    }

    if (isVideo) {
      // reuse your existing full-screen video player
      return VideoPreviewScreen(file: File(file.path));
    }

    // document / audio etc.
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

  // Future<void> _sendAll() async {
  //   setState(() => _sending = true);
  //
  //   final localMessages = <Map<String, dynamic>>[];
  //   final groupMessageId =
  //   widget.files.length > 1 ? ObjectId().toString() : null;
  //
  //   for (final f in widget.files) {
  //     final msg = await ShowAltDialog.sendFile(
  //       context: context,
  //       file: f,
  //       conversationId: widget.conversationId,
  //       senderId: widget.senderId,
  //       receiverId: widget.receiverId,
  //       isGroupChat: widget.isGroupChat,
  //       isGroupMessage: widget.files.length > 1,
  //       groupMessageId: groupMessageId,
  //     );
  //     if (msg != null) localMessages.add(msg);
  //   }
  //
  //   setState(() => _sending = false);
  //
  //   // Pop back to chat, delivering the messages we created
  //   Navigator.of(context).pop(localMessages);
  // }
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
        // ✅ group any media when more than one selected
        isGroupMessage: widget.files.length > 1,
        groupMessageId: groupMessageId,
      );

      if (msg != null) {
        localMessages.add(msg);
      }
    }

    setState(() => _sending = false);
    Navigator.of(context).pop(localMessages);
  }

}
