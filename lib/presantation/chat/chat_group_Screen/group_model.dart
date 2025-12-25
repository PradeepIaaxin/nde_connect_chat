import 'dart:io';
import 'package:equatable/equatable.dart';

/// ===============================
///   PAGINATION RESPONSE MODEL
/// ===============================
class GroupMessageResponse extends Equatable {
  final List<GroupMessageGroup> data;
  final int total;
  final int page;
  final int limit;
  final bool hasPreviousPage;
  final bool hasNextPage;

  const GroupMessageResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasPreviousPage,
    required this.hasNextPage,
  });

  factory GroupMessageResponse.empty() {
    return const GroupMessageResponse(
      data: [],
      total: 0,
      page: 1,
      limit: 20,
      hasPreviousPage: false,
      hasNextPage: false,
    );
  }

  /// ✅ SAFE JSON PARSING (NO CRASH)
  factory GroupMessageResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];

    final List<GroupMessageGroup> groups =
        rawData is List
            ? rawData
                .whereType<Map<String, dynamic>>()
                .map((g) => GroupMessageGroup.fromJson(g))
                .toList()
            : [];

    return GroupMessageResponse(
      data: groups,
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 50,
      hasPreviousPage: json['hasPreviousPage'] ?? false,
      hasNextPage: json['hasNextPage'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'data': data.map((g) => g.toJson()).toList(),
        'total': total,
        'page': page,
        'limit': limit,
        'hasPreviousPage': hasPreviousPage,
        'hasNextPage': hasNextPage,
      };

  @override
  List<Object?> get props => [page, total, data.length, hasNextPage];
}

/// ===============================
///        GROUPED MODEL
/// ===============================
class GroupMessageGroup {
  final String label;
  final List<GroupMessageModel> messages;

  GroupMessageGroup({
    required this.label,
    required this.messages,
  });

  /// ✅ SAFE – messages CAN BE NULL
  factory GroupMessageGroup.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'];

    final List<GroupMessageModel> parsedMessages =
        rawMessages is List
            ? rawMessages
                .whereType<Map<String, dynamic>>()
                .map((m) => GroupMessageModel.fromJson(m))
                .toList()
            : [];

    return GroupMessageGroup(
      label: json['label']?.toString() ?? '',
      messages: parsedMessages,
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'messages': messages.map((m) => m.toJson()).toList(),
      };
}

/// ===============================
///       MAIN MESSAGE MODEL
/// ===============================
class GroupMessageModel {
  final String id;
  final User sender;
  final dynamic receiver;
  final String conversationId;
  final bool isDeleted;
  final List<Property> properties;
  final String messageType;
  final String? messageStatus;
  final Map<String, dynamic>? reply;
  final String messageId;
  final bool fileWithText;
  final String content;
  final String? thumbnailKey;
  final String contentType;
  final String originalKey;
  final String originalUrl;
  final String thumbnailUrl;
  final String mimeType;
  final bool isForwarded;
  final String userName;
  final String fileName;
  final bool isPinned;
  final DateTime time;
  final bool? isReplyMessage;
  final bool? isStarred;
  final List<dynamic>? reactions;

  GroupMessageModel({
    required this.id,
    required this.sender,
    this.receiver,
    required this.conversationId,
    required this.isDeleted,
    required this.properties,
    required this.messageType,
    this.messageStatus,
    this.reply,
    required this.messageId,
    required this.fileWithText,
    required this.content,
    this.thumbnailKey,
    required this.contentType,
    required this.originalKey,
    required this.originalUrl,
    required this.thumbnailUrl,
    required this.mimeType,
    required this.isForwarded,
    required this.userName,
    required this.fileName,
    required this.isPinned,
    required this.time,
    this.isReplyMessage,
    this.isStarred,
    this.reactions,
  });

  /// ✅ NORMALIZED TIME (LIKE PRIVATE CHAT)
  DateTime get createdTime => time;

  factory GroupMessageModel.fromJson(Map<String, dynamic> json) {
    dynamic receiver;
    if (json['receiver'] != null) {
      receiver = json['receiver'] is Map
          ? User.fromJson(Map<String, dynamic>.from(json['receiver']))
          : json['receiver'].toString();
    }

    DateTime parseTime(dynamic t) {
      if (t is String) return DateTime.tryParse(t) ?? DateTime.now();
      return DateTime.now();
    }

    return GroupMessageModel(
      id: json['_id']?.toString() ?? json['message_id']?.toString() ?? '',
      sender: User.fromJson(Map<String, dynamic>.from(json['sender'] ?? {})),
      receiver: receiver,
      conversationId: json['conversation_id']?.toString() ?? '',
      isDeleted: json['is_deleted'] ?? false,
      properties: (json['properties'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((e) => Property.fromJson(e))
          .toList(),
      messageType: json['messageType']?.toString() ?? '',
      messageStatus: json['messageStatus']?.toString(),
      reply: json['reply'] is Map ? Map<String, dynamic>.from(json['reply']) : null,
      messageId: json['message_id']?.toString() ?? '',
      fileWithText: json['file_with_text'] ?? false,
      content: json['content']?.toString() ?? '',
      thumbnailKey: json['thumbNailKey']?.toString(),
      contentType: json['ContentType']?.toString() ?? '',
      originalKey: json['originalKey']?.toString() ?? '',
      originalUrl: json['originalUrl']?.toString() ?? '',
      thumbnailUrl: json['thumbnailUrl']?.toString() ?? '',
      mimeType: json['mimeType']?.toString() ?? '',
      isForwarded: json['isForwarded'] ?? false,
      userName: json['userName']?.toString() ?? '',
      fileName: json['fileName']?.toString() ?? '',
      isPinned: json['isPinned'] ?? false,
      time: parseTime(json['time']),
      isReplyMessage: json['isReplyMessage'],
      isStarred: json['isStarred'],
      reactions: json['reactions'] is List ? json['reactions'] : [],
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'sender': sender.toJson(),
        'receiver': receiver is User ? receiver.toJson() : receiver,
        'conversation_id': conversationId,
        'is_deleted': isDeleted,
        'properties': properties.map((e) => e.toJson()).toList(),
        'messageType': messageType,
        'messageStatus': messageStatus,
        'reply': reply,
        'message_id': messageId,
        'file_with_text': fileWithText,
        'content': content,
        'thumbNailKey': thumbnailKey,
        'ContentType': contentType,
        'originalKey': originalKey,
        'originalUrl': originalUrl,
        'thumbnailUrl': thumbnailUrl,
        'mimeType': mimeType,
        'isForwarded': isForwarded,
        'userName': userName,
        'fileName': fileName,
        'isPinned': isPinned,
        'time': time.toIso8601String(),
        'isReplyMessage': isReplyMessage,
        'isStarred': isStarred,
        'reactions': reactions,
      };
}

/// ===============================
///              USER
/// ===============================
class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? profilePicPath;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.profilePicPath,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['_id']?.toString() ?? '',
        firstName: json['first_name']?.toString() ?? '',
        lastName: json['last_name']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        profilePicPath: json['profile_pic_path']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'profile_pic_path': profilePicPath,
      };
}

/// ===============================
///        PROPERTIES INSIDE MSG
/// ===============================
class Property {
  final String id;
  final String? groupId;
  final bool isAdmin;
  final String memberId;
  final String status;
  final String conversationId;
  final bool isRead;
  final bool isDeleted;
  final bool isEdited;
  final DateTime sentTime;
  final bool isStarred;
  final bool isLiked;
  final bool isPinned;
  final String messageId;
  final String typeOfUser;
  final String workspaceId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Property({
    required this.id,
    required this.groupId,
    required this.isAdmin,
    required this.memberId,
    required this.status,
    required this.conversationId,
    required this.isRead,
    required this.isDeleted,
    required this.isEdited,
    required this.sentTime,
    required this.isStarred,
    required this.isLiked,
    required this.isPinned,
    required this.messageId,
    required this.typeOfUser,
    required this.workspaceId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Property.fromJson(Map<String, dynamic> json) => Property(
        id: json['_id']?.toString() ?? '',
        groupId: json['group_id']?.toString(),
        isAdmin: json['is_admin'] ?? false,
        memberId: json['member_id']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        conversationId: json['conversation_id']?.toString() ?? '',
        isRead: json['is_read'] ?? false,
        isDeleted: json['is_deleted'] ?? false,
        isEdited: json['is_edited'] ?? false,
        sentTime:
            DateTime.tryParse(json['time']?['sent_time'] ?? '') ?? DateTime.now(),
        isStarred: json['is_starred'] ?? false,
        isLiked: json['is_liked'] ?? false,
        isPinned: json['is_pinned'] ?? false,
        messageId: json['message_id']?.toString() ?? '',
        typeOfUser: json['type_of_user']?.toString() ?? '',
        workspaceId: json['workspace_id']?.toString() ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'group_id': groupId,
        'is_admin': isAdmin,
        'member_id': memberId,
        'status': status,
        'conversation_id': conversationId,
        'is_read': isRead,
        'is_deleted': isDeleted,
        'is_edited': isEdited,
        'time': {'sent_time': sentTime.toIso8601String()},
        'is_starred': isStarred,
        'is_liked': isLiked,
        'is_pinned': isPinned,
        'message_id': messageId,
        'type_of_user': typeOfUser,
        'workspace_id': workspaceId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}


/// =======================================
///  TEMP MESSAGE FOR IMMEDIATE UI DISPLAY
/// =======================================
class GrpMessage {
  final String messageId;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime time;
  final String messageStatus;
  final String? imageUrl;
  final String? fileName;
  final String? fileUrl;
  final String? fileType;
  final bool? isTemporary;
  final File? localImagePath;

  GrpMessage({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.time,
    required this.messageStatus,
    this.imageUrl,
    this.fileName,
    this.fileUrl,
    this.fileType,
    this.isTemporary,
    this.localImagePath,
  });

  factory GrpMessage.fromJson(Map<String, dynamic> json) {
    return GrpMessage(
      messageId: json['messageId'],
      senderId: json['senderId'],
      receiverId: json['receiverId'],
      message: json['message'],
      time: DateTime.parse(json['time']),
      messageStatus: json['messageStatus'],
      imageUrl: json['imageUrl'],
      fileName: json['fileName'],
      fileUrl: json['fileUrl'],
      fileType: json['fileType'],
      isTemporary: json['isTemporary'],
      localImagePath:
          json['localImagePath'] != null ? File(json['localImagePath']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        "messageId": messageId,
        "senderId": senderId,
        "receiverId": receiverId,
        "message": message,
        "time": time.toIso8601String(),
        "messageStatus": messageStatus,
        "imageUrl": imageUrl,
        "fileName": fileName,
        "fileUrl": fileUrl,
        "fileType": fileType,
        "isTemporary": isTemporary,
        "localImagePath": localImagePath?.path,
      };
}
