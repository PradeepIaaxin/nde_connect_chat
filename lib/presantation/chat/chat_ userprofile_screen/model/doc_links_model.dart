class MediaItem {
  final String id;
  final Sender sender;
  final bool hasFullLink;
  final bool hasBareLink;
  final bool hasEmailLink;
  final List<dynamic> fullLinks;
  final List<dynamic> bareLinks;
  final List<dynamic> emailLinks;
  final MetaData? meta;
  final String content;
  final String messageType;
  final String? thumbnailKey;
  final String? thumbnailImageUrl;
  final String? createdAt;
  final String? originalKey;
  final String? contentType;
  final String? originalUrl;

  MediaItem({
    required this.id,
    required this.sender,
    required this.hasFullLink,
    required this.hasBareLink,
    required this.hasEmailLink,
    required this.fullLinks,
    required this.bareLinks,
    required this.emailLinks,
    this.meta,
    required this.content,
    required this.messageType,
    this.thumbnailKey,
    this.thumbnailImageUrl,
    this.createdAt,
    this.originalKey,
    this.contentType,
    this.originalUrl,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['_id'] ?? '',
      sender: Sender.fromJson(json['sender'] ?? {}),
      hasFullLink: json['hasFullLink'] ?? false,
      hasBareLink: json['hasBareLink'] ?? false,
      hasEmailLink: json['hasEmailLink'] ?? false,
      fullLinks: json['fullLinks'] is List ? json['fullLinks'] : [],
      bareLinks: json['bareLinks'] is List ? json['bareLinks'] : [],
      emailLinks: json['emailLinks'] is List ? json['emailLinks'] : [],
      meta: json['meta'] != null ? MetaData.fromJson(json['meta']) : null,
      content: json['content'] ?? '',
      messageType: json['message_type'] ?? '',
      thumbnailKey: json['thumbnail_key'],
      thumbnailImageUrl: json['thumbnail_image_url'],
      createdAt: json['createdAt'],
      originalKey: json['originalKey'],
      contentType: json['ContentType'],
      originalUrl: json['originalUrl'],
    );
  }
}

class Sender {
  final String id;
  final String firstName;

  Sender({
    required this.id,
    required this.firstName,
  });

  factory Sender.fromJson(Map<String, dynamic> json) {
    return Sender(
      id: json['_id'] ?? '',
      firstName: json['first_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'first_name': firstName,
    };
  }
}

class MetaData {
  final String? mimeType;
  final String? originalFilename;
  final String? fileName;
  final String? messageType;
  final String? originalKey;
  final int? size;

  MetaData({
    this.mimeType,
    this.originalFilename,
    this.fileName,
    this.messageType,
    this.originalKey,
    this.size,
  });

  factory MetaData.fromJson(Map<String, dynamic> json) {
    return MetaData(
      mimeType: json['mimeType'],
      originalFilename: json['originalFilename'],
      fileName: json['fileName'],
      messageType: json['messageType'],
      originalKey: json['original_key'],
      size: json['size'],
    );
  }
}
