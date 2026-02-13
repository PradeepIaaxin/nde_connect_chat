import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';

class MailImageViewer extends StatefulWidget {
  final File file;
  final String fileName;

  const MailImageViewer(
      {super.key, required this.file, required this.fileName});

  @override
  State<MailImageViewer> createState() => _MailImageViewerState();
}

class _MailImageViewerState extends State<MailImageViewer> {
  bool _showUI = true;

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    super.dispose();
  }

  void _toggleUI() {
    setState(() {
      _showUI = !_showUI;
      if (_showUI) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
            overlays: SystemUiOverlay.values);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _showUI
          ? AppBar(
              backgroundColor: Colors.black.withValues(alpha: 0.5),
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text(
                widget.fileName,
                style: const TextStyle(color: Colors.white),
              ),
            )
          : null,
      body: GestureDetector(
        onTap: _toggleUI,
        child: Center(
          child: PhotoView(
            imageProvider: FileImage(widget.file),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
          ),
        ),
      ),
    );
  }
}
