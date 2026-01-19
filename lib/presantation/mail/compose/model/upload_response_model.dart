class AttachmentUploadResponse {
  final String message;
  final String filename;
  final String contentType;
  final String encoding;
  final String contentTransferEncoding;
  final String contentDisposition;
  final String content;
  final String id;

  AttachmentUploadResponse({
    required this.message,
    required this.filename,
    required this.contentType,
    required this.encoding,
    required this.contentTransferEncoding,
    required this.contentDisposition,
    required this.content,
    required this.id,
  });

  factory AttachmentUploadResponse.fromJson(Map<String, dynamic> json) {
    return AttachmentUploadResponse(
      message: json['message'] ?? '',
      filename: json['filename'] ?? '',
      contentType: json['contentType'] ?? '',
      encoding: json['encoding'] ?? '',
      contentTransferEncoding: json['contentTransferEncoding'] ?? '',
      contentDisposition: json['contentDisposition'] ?? '',
      content: json['content'] ?? '',
      id: json['id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'message': message,
        'filename': filename,
        'contentType': contentType,
        'encoding': encoding,
        'contentTransferEncoding': contentTransferEncoding,
        'contentDisposition': contentDisposition,
        'content': content,
        'id': id,
      };
}
