import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_editor_plus/options.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';
import 'package:nde_email/utils/imports/common_imports.dart';
import 'package:objectid/objectid.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../widgets/chat_widgets/messager_Wifgets/show_Bottom_Sheet.dart';
import '../MessagerEvent.dart';
import 'package:image/image.dart' as img;

import 'VideoPreviewScreen.dart';

class MediaPreviewScreen extends StatefulWidget {
  final List<XFile> files;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final bool isGroupChat;
  final bool? isDocument;
  final String? mediaContent;
  final String? duration;

  const MediaPreviewScreen({
    super.key,
    required this.files,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.isGroupChat,
    this.isDocument = false,
    this.mediaContent,
    this.duration,
  });

  @override
  State<MediaPreviewScreen> createState() => _MediaPreviewScreenState();
}

class _MediaPreviewScreenState extends State<MediaPreviewScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _captionController = TextEditingController();

  int _currentIndex = 0;
  bool _sending = false;
  late List<XFile> _files;

  @override
  void initState() {
    super.initState();
    _files = List.from(widget.files);
  }

  @override
  void dispose() {
    _captionController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ================= IMAGE EDIT =================
  Future<void> _pickMoreMedia() async {
    debugPrint("📸 Add tapped → mediaContent = ${widget.mediaContent}");

    List<XFile> newFiles = [];

    // ================= YOUR EXISTING LOGIC =================
    if (widget.mediaContent == "Gallery") {
      final images = await ImagePicker().pickMultiImage();
      if (images.isNotEmpty) newFiles.addAll(images);
    } else if (widget.mediaContent == "Video") {
      final videos = await ImagePicker().pickMultiVideo();
      if (videos.isNotEmpty) newFiles.addAll(videos);
    } else if (widget.mediaContent == "Camera") {
      final file = await ImagePicker().pickImage(source: ImageSource.camera);
      if (file != null) newFiles.add(file);
    } else if (widget.mediaContent == "Document") {
      final result = await FilePicker.platform.pickFiles();
      if (result?.files.single.path != null) {
        newFiles.add(XFile(result!.files.single.path!));
      }
    } else if (widget.mediaContent == "Audio") {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'aac', 'm4a', 'flac', 'ogg', 'opus'],
      );
      if (result?.files.single.path != null) {
        newFiles.add(XFile(result!.files.single.path!));
      }
    }

    // ================= CAMERA FALLBACK (KEY FIX) =================
    // If mediaContent is NULL or no condition matched → OPEN CAMERA
    if (newFiles.isEmpty) {
      debugPrint("📸 Fallback → Opening Camera");

      final cameraFile =
          await ImagePicker().pickImage(source: ImageSource.camera);

      if (cameraFile != null) {
        newFiles.add(cameraFile);
      }
    }

    // ================= ADD TO LIST =================
    if (newFiles.isNotEmpty) {
      setState(() {
        _files.addAll(newFiles);
      });
    }
  }

  Future<void> _editCurrentImage() async {
    final file = _files[_currentIndex];
    final mime = lookupMimeType(file.path) ?? '';

    if (!mime.startsWith("image/")) return;

    // ✅ Convert File → Uint8List (IMPORTANT)
    final bytes = await File(file.path).readAsBytes();

    final editedBytes = await Navigator.push<Uint8List?>(
      context,
      MaterialPageRoute(
        builder: (_) => ImageEditor(
          image: bytes,
          cropOption: const CropOption(reversible: false),
        ),
      ),
    );

    if (editedBytes == null || editedBytes.length < 1000) {
      debugPrint("❌ Editor returned invalid bytes");
      return;
    }

    // ✅ Save edited image as real PNG
    final dir = await getApplicationDocumentsDirectory();
    final newPath =
        "${dir.path}/edited_${DateTime.now().millisecondsSinceEpoch}.png";

    final decoded = img.decodeImage(editedBytes);
    if (decoded == null) {
      debugPrint("❌ decodeImage failed");
      return;
    }

    final pngBytes = img.encodePng(decoded);
    await File(newPath).writeAsBytes(pngBytes, flush: true);

    debugPrint("✅ Edited image saved: $newPath");

    setState(() {
      _files[_currentIndex] = XFile(newPath);
    });
  }

  // ================= DELETE CURRENT =================
  void _deleteCurrent() {
    setState(() {
      _files.removeAt(_currentIndex);
      if (_files.isEmpty) Navigator.pop(context);
      if (_currentIndex >= _files.length) _currentIndex = _files.length - 1;
    });
  }

  // ================= FILE TYPE CHECK =================
  bool _isAudio(XFile file) {
    final mime = lookupMimeType(file.path) ?? '';
    return mime.startsWith('audio/');
  }

  // ================= VALIDATE SIZE =================
  Future<bool> validateFileBeforeSend({
    required BuildContext context,
    required XFile file,
    double maxImageMb = 10,
    double maxVideoMb = 10,
    double maxAudioMb = 10,
    double maxDocMb = 10,
  }) async {
    final mime = lookupMimeType(file.path) ?? '';
    final fileSizeMb = File(file.path).lengthSync() / (1024 * 1024);

    String? error;

    if (mime.startsWith('image/') && fileSizeMb > maxImageMb) {
      error = 'Image too large: ${fileSizeMb.toStringAsFixed(1)} MB';
    } else if (mime.startsWith('video/') && fileSizeMb > maxVideoMb) {
      error = 'Video too large: ${fileSizeMb.toStringAsFixed(1)} MB';
    } else if (mime.startsWith('audio/') && fileSizeMb > maxAudioMb) {
      error = 'Audio too large: ${fileSizeMb.toStringAsFixed(1)} MB';
    } else if (!mime.startsWith('image/') &&
        !mime.startsWith('video/') &&
        !mime.startsWith('audio/') &&
        fileSizeMb > maxDocMb) {
      error = 'File too large: ${fileSizeMb.toStringAsFixed(1)} MB';
    }

    if (error != null) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("File too large"),
          content: Text(error ?? ""),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK")),
          ],
        ),
      );
      setState(() => _files.remove(file));
      return false;
    }

    return true;
  }

  // ================= SEND ALL =================
  Future<void> _sendAll() async {
    if (_sending) return;
    setState(() => _sending = true);

    final caption = _captionController.text.trim();
    final List<Map<String, dynamic>> localMessages = [];
    final groupMessageId = _files.length > 1 ? ObjectId().toString() : null;

    // Validate
    for (final file in List.from(_files)) {
      final valid = await validateFileBeforeSend(context: context, file: file);
      if (!valid) {
        setState(() => _sending = false);
        return;
      }
    }

    // Send
    for (final file in _files) {
      if (_isAudio(file)) {
        context.read<MessagerBloc>().add(
              SendAudioMessageEvent(
                senderId: widget.senderId,
                receiverId: widget.receiverId,
                audioPath: file.path,
                duration: widget.duration ?? "0",
                convoId: widget.conversationId,
                isRecord: false,
              ),
            );
        continue;
      }

      final msg = await ShowAltDialog.sendFile(
        context: context,
        file: file,
        conversationId: widget.conversationId,
        senderId: widget.senderId,
        receiverId: widget.receiverId,
        isGroupChat: widget.isGroupChat,
        isGroupMessage: _files.length > 1,
        groupMessageId: groupMessageId,
        caption: caption.isNotEmpty ? caption : null,
      );

      if (msg != null) localMessages.add(msg);
    }

    setState(() => _sending = false);
    Navigator.pop(context, localMessages);
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text("${_currentIndex + 1} / ${_files.length}",
            style: const TextStyle(color: Colors.white)),
        actions: [
          IconButton(
              icon: const Icon(Icons.edit), onPressed: _editCurrentImage),
          IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteCurrent),
          IconButton(icon: const Icon(Icons.add), onPressed: _pickMoreMedia),
        ],
      ),
      body: Stack(
        children: [
          // Gallery
          Positioned.fill(
            child: PhotoViewGallery.builder(
              pageController: _pageController,
              itemCount: _files.length,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              backgroundDecoration: const BoxDecoration(color: Colors.black),
              builder: (context, index) {
                final file = _files[index];
                final mime = lookupMimeType(file.path) ?? '';

                if (mime.startsWith('image/')) {
                  return PhotoViewGalleryPageOptions.customChild(
                    child: Image.file(
                      File(file.path),
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) {
                        debugPrint("❌ Broken image: ${file.path}");
                        return const Center(
                          child: Icon(Icons.broken_image,
                              color: Colors.red, size: 100),
                        );
                      },
                    ),
                  );
                }

                if (mime.startsWith('video/')) {
                  return PhotoViewGalleryPageOptions.customChild(
                    child: VideoPreviewScreen(file: File(file.path)),
                  );
                }

                return PhotoViewGalleryPageOptions.customChild(
                  child: Center(
                    child: Text(file.name,
                        style: const TextStyle(color: Colors.white)),
                  ),
                );
              },
            ),
          ),

          // Caption + Send
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.all(10),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _captionController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "Add caption...",
                          hintStyle: TextStyle(color: Colors.white70),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    FloatingActionButton(
                      mini: true,
                      backgroundColor: AppColors.primaryButton,
                      onPressed: _sendAll,
                      child: _sending
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Icon(Icons.send),
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
}
