import 'package:flutter/material.dart';
import 'package:nde_email/presantation/drive/common/hexa_color.dart';

Widget buildIcon({
  required String? type,
  required String? mimeType,
  String? colortype,
  double size = 24,
}) {
  final typeLower = type?.toLowerCase().trim();
  final mimeLower = mimeType?.toLowerCase().trim() ?? '';

  if (typeLower == 'folder') {
    return Image.asset(
      "assets/images/folder.png",
      height: size,
      width: size,
      color: (colortype != null && colortype.isNotEmpty)
          ? ColorUtils.fromHex(colortype)
          : Colors.amber,
    );
  }

  // Word Document
  if (mimeLower.contains('msword') ||
      mimeLower.contains('officedocument.word') ||
      mimeLower.contains('.doc') ||
      mimeLower.contains('.docx') ||
      mimeLower.contains('ndocx')) {
    return Image.asset('assets/images/word.png',
        height: size + 6, width: size + 6);
  }

  // Excel
  if (mimeLower.contains('excel') ||
      mimeLower.contains('spreadsheet') ||
      mimeLower.contains('.xls') ||
      mimeLower.contains('.xlsx')) {
    return Image.asset('assets/images/sheets.png', height: size, width: size);
  }

  // PowerPoint
  if (mimeLower.contains('presentation') ||
      mimeLower.contains('powerpoint') ||
      mimeLower.contains('slides') ||
      mimeLower.contains('.ppt') ||
      mimeLower.contains('.pptx')) {
    return Image.asset('assets/images/sheets.png', height: size, width: size);
  }

  // PDF
  if (mimeLower.contains('pdf')) {
    return Image.asset('assets/images/pdf.png', height: size, width: size);
  }

  // Images
  if (mimeLower.contains('image') ||
      mimeLower.contains('.png') ||
      mimeLower.contains('.jpg') ||
      mimeLower.contains('.jpeg') ||
      mimeLower.contains('.gif') ||
      mimeLower.contains('.bmp')) {
    return Image.asset('assets/images/image.png', height: size, width: size);
  }

  // Video
  if (mimeLower.contains('video') ||
      mimeLower.contains('.mp4') ||
      mimeLower.contains('.mov') ||
      mimeLower.contains('.avi')) {
    return Image.asset('assets/images/video.png', height: size, width: size);
  }

  // Audio
  if (mimeLower.contains('audio') ||
      mimeLower.contains('.mp3') ||
      mimeLower.contains('.wav')) {
    return Image.asset('assets/images/headphones.png',
        height: size, width: size);
  }

  // Text
  if (mimeLower.contains('text') ||
      mimeLower.contains('plain') ||
      mimeLower.contains('.txt')) {
    return Image.asset('assets/images/text.png', height: size, width: size);
  }

  // Compressed
  if (mimeLower.contains('zip') ||
      mimeLower.contains('rar') ||
      mimeLower.contains('file') ||
      mimeLower.contains('7z') ||
      mimeLower.contains('compressed')) {
    return Image.asset('assets/images/pdf.png',
        height: size + 6, width: size + 6);
  }

  // Default fallback
  return Image.asset('assets/images/image.png', height: size, width: size);
}
