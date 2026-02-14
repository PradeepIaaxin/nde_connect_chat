enum ComposeAction {
  reply,
  replyAll,
  forward,
}

class UploadedAttachment {
  final String? id;
  final String fileName;
  final String? filePath; // Changed to nullable
  final bool isInline;
  final String? mimeType;

  UploadedAttachment({
    this.id,
    required this.fileName,
    this.filePath, // Changed to optional
    required this.isInline,
    this.mimeType,
  });
}
