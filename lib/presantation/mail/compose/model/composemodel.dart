enum ComposeAction {
  reply,
  replyAll,
  forward,
}




class UploadedAttachment {
  final String? id;
  final String fileName;
  final String filePath;
  final bool isInline;
  final String? mimeType;

  UploadedAttachment({
    this.id,
    required this.fileName,
    required this.filePath,
    required this.isInline,
    this.mimeType,
  });
}
