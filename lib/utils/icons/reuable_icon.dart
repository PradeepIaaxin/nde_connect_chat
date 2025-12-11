import 'package:flutter/material.dart';
import 'package:nde_email/presantation/drive/model/shared/sharred_model.dart';

/// Builds MIME type icon or folder image
Widget buildMimeIcon(FolderItem folder) {
  final type = folder.type.toLowerCase();
  final mimeType = folder.mimetype?.toLowerCase() ?? '';

  // ✅ Folder icon
  if (type == 'folder') {
    return Image.asset(
      'assets/images/folder.png',
      height: 20,
      width: 20,
      fit: BoxFit.cover,
    );
  }

  // ✅ File icons based on MIME type
  if (mimeType.contains('pdf')) {
    return Image.asset('assets/images/pdf.png',
        height: 20, width: 20, fit: BoxFit.cover);
  } else if (mimeType.contains('image')) {
    return Image.asset('assets/images/image.png',
        height: 20, width: 20, fit: BoxFit.cover);
  } else if (mimeType.contains('video')) {
    return Image.asset('assets/images/video.png',
        height: 20, width: 20, fit: BoxFit.cover);
  } else if (mimeType.contains('audio')) {
    return Image.asset('assets/images/headphones.png',
        height: 20, width: 20, fit: BoxFit.cover);
  } else if (mimeType.contains('msword') ||
      mimeType.contains('officedocument.word') ||
      mimeType.contains('docx')) {
    return Image.asset('assets/images/word.png',
        height: 20, width: 20, fit: BoxFit.cover);
  } else if (mimeType.contains('excel') || mimeType.contains('spreadsheet')) {
    return Image.asset('assets/images/sheets.png',
        height: 20, width: 20, fit: BoxFit.cover);
  } else if (mimeType.contains('presentation') ||
      mimeType.contains('powerpoint') ||
      mimeType.contains('slides')) {
    return Image.asset('assets/images/slides.png',
        height: 20, width: 20, fit: BoxFit.cover);
  } else if (mimeType.contains('zip') ||
      mimeType.contains('.zip') ||
      mimeType.contains('rar') ||
      mimeType.contains('compressed')) {
    return Image.asset('assets/images/zip.png',
        height: 20, width: 20, fit: BoxFit.cover);
  } else {
    return Image.asset('assets/images/folder.png',
        height: 20, width: 20, fit: BoxFit.cover);
  }
}
