// import 'dart:io';

// class GroupMessageResponse {
//   final List<GroupMessageGroup> data;
//   final int total;
//   final int page;
//   final int limit;
//   final bool hasPreviousPage;
//   final bool hasNextPage;

//   GroupMessageResponse({
//     required this.data,
//     required this.total,
//     required this.page,
//     required this.limit,
//     required this.hasPreviousPage,
//     required this.hasNextPage,
//   });

//   factory GroupMessageResponse.fromJson(Map<String, dynamic> json) {
//     return GroupMessageResponse(
//       data: (json["data"] as List)
//           .map((group) => GroupMessageGroup.fromJson(group))
//           .toList(),
//       total: json["total"] ?? 0,
//       page: json["page"] ?? 1,
//       limit: json["limit"] ?? 50,
//       hasPreviousPage: json["hasPreviousPage"] ?? false,
//       hasNextPage: json["hasNextPage"] ?? false,
//     );
//   }

//   Map<String, dynamic> toJson() => {
//         "data": data.map((g) => g.toJson()).toList(),
//         "total": total,
//         "page": page,
//         "limit": limit,
//         "hasPreviousPage": hasPreviousPage,
//         "hasNextPage": hasNextPage,
//       };
// }

// class GroupMessageGroup {
//   final String label;
//   final List<GroupMessageModel> messages;

//   GroupMessageGroup({
//     required this.label,
//     required this.messages,
//   });

//   factory GroupMessageGroup.fromJson(Map<String, dynamic> json) {
//     return GroupMessageGroup(
//       label: json['label'] ?? "",
//       messages: (json['messages'] as List)
//           .map((m) => GroupMessageModel.fromJson(m))
//           .toList(),
//     );
//   }

//   Map<String, dynamic> toJson() => {
//         "label": label,
//         "messages": messages.map((m) => m.toJson()).toList(),
//       };
// }

// class GroupMessageModel {
//   final String id;
//   final User sender;
//   final dynamic receiver;
//   final String conversationId;
//   final bool isDeleted;
//   final List<Property> properties;
//   final String messageType;
//   final String? messageStatus;
//   final Map<String, dynamic>? reply;
//   final String messageId;
//   final bool fileWithText;
//   final String content;
//   final String? thumbnailKey;
//   final String contentType;
//   final String originalKey;
//   final String originalUrl;
//   final String thumbnailUrl;
//   final String mimeType;
//   final bool isForwarded;
//   final String userName;
//   final String fileName;
//   final bool isPinned;
//   final DateTime time;
//   final bool? isReplyMessage;
//   final bool? isStarred;

//   GroupMessageModel({
//     required this.id,
//     required this.sender,
//     this.receiver,
//     required this.conversationId,
//     required this.isDeleted,
//     required this.properties,
//     required this.messageType,
//     this.messageStatus,
//     this.reply,
//     required this.messageId,
//     required this.fileWithText,
//     required this.content,
//     this.thumbnailKey,
//     required this.contentType,
//     required this.originalKey,
//     required this.originalUrl,
//     required this.thumbnailUrl,
//     required this.mimeType,
//     required this.isForwarded,
//     required this.userName,
//     required this.fileName,
//     required this.isPinned,
//     required this.time,
//     this.isReplyMessage,
//     this.isStarred,
//   });

//   factory GroupMessageModel.fromJson(Map<String, dynamic> json) {
//     // Handle receiver which can be String or User object
//     dynamic receiver;
//     if (json['receiver'] != null) {
//       if (json['receiver'] is Map) {
//         receiver = User.fromJson(Map<String, dynamic>.from(json['receiver']));
//       } else {
//         receiver = json['receiver'].toString();
//       }
//     }

//     // Handle time parsing with fallback
//     DateTime parseTime(dynamic time) {
//       if (time == null) return DateTime.now();
//       if (time is DateTime) return time;
//       if (time is String) return DateTime.tryParse(time) ?? DateTime.now();
//       return DateTime.now();
//     }

//     return GroupMessageModel(
//       id: json['_id']?.toString() ?? json['message_id']?.toString() ?? '',
//       sender: User.fromJson(Map<String, dynamic>.from(json['sender'] ?? {})),
//       receiver: receiver,
//       conversationId: json['conversation_id']?.toString() ?? '',
//       isDeleted: json['is_deleted'] as bool? ?? false,
//       properties: (json['properties'] as List<dynamic>? ?? [])
//           .map((e) => Property.fromJson(Map<String, dynamic>.from(e ?? {})))
//           .toList(),
//       messageType: json['messageType']?.toString() ?? '',
//       messageStatus: json['messageStatus']?.toString(),
//       reply: json['reply'] is Map
//           ? Map<String, dynamic>.from(json['reply'])
//           : null,
//       messageId: json['message_id']?.toString() ?? '',
//       fileWithText: json['file_with_text'] as bool? ?? false,
//       content: json['content']?.toString() ?? '', // Empty string fallback
//       thumbnailKey: json['thumbNailKey']?.toString(),
//       contentType: json['ContentType']?.toString() ?? '',
//       originalKey: json['originalKey']?.toString() ?? '',
//       originalUrl: json['originalUrl']?.toString() ?? '',
//       thumbnailUrl: json['thumbnailUrl']?.toString() ?? '',
//       mimeType: json['mimeType']?.toString() ?? '',
//       isForwarded: json['isForwarded'] as bool? ?? false,
//       userName: json['userName']?.toString() ?? '', // Empty string fallback
//       fileName: json['fileName']?.toString() ?? '', // Empty string fallback
//       isPinned: json['isPinned'] as bool? ?? false,
//       time: parseTime(json['time']),
//       isReplyMessage: json['isReplyMessage'] as bool?,
//       isStarred: json['isStarred'] as bool?,
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       '_id': id,
//       'sender': sender.toJson(),
//       'receiver': receiver is User ? (receiver as User).toJson() : receiver,
//       'conversation_id': conversationId,
//       'is_deleted': isDeleted,
//       'properties': properties.map((e) => e.toJson()).toList(),
//       'messageType': messageType,
//       'messageStatus': messageStatus,
//       'reply': reply,
//       'message_id': messageId,
//       'file_with_text': fileWithText,
//       'content': content,
//       'thumbNailKey': thumbnailKey,
//       'ContentType': contentType,
//       'originalKey': originalKey,
//       'originalUrl': originalUrl,
//       'thumbnailUrl': thumbnailUrl,
//       'mimeType': mimeType,
//       'isForwarded': isForwarded,
//       'userName': userName,
//       'fileName': fileName,
//       'isPinned': isPinned,
//       'time': time.toIso8601String(),
//       'isReplyMessage': isReplyMessage,
//       'isStarred': isStarred,
//     };
//   }
// }

// class User {
//   final String id;
//   final String firstName;
//   final String lastName;
//   final String email;
//   final String? profilePicPath;

//   User({
//     required this.id,
//     required this.firstName,
//     required this.lastName,
//     required this.email,
//     this.profilePicPath,
//   });

//   factory User.fromJson(Map<String, dynamic> json) {
//     return User(
//       id: json['_id']?.toString() ?? '',
//       firstName: json['first_name']?.toString() ?? '',
//       lastName: json['last_name']?.toString() ?? '',
//       email: json['email']?.toString() ?? '',
//       profilePicPath: json['profile_pic_path']?.toString(),
//     );
//   }
//   Map<String, dynamic> toJson() {
//     return {
//       '_id': id,
//       'first_name': firstName,
//       'last_name': lastName,
//       'email': email,
//       'profile_pic_path': profilePicPath,
//     };
//   }
// }

// class Property {
//   final String id;
//   final String? groupId;
//   final bool isAdmin;
//   final String memberId;
//   final String status;
//   final String conversationId;
//   final bool isRead;
//   final bool isDeleted;
//   final bool isEdited;
//   final DateTime sentTime;
//   final bool isStarred;
//   final bool isLiked;
//   final bool isPinned;
//   final String messageId;
//   final String typeOfUser;
//   final String workspaceId;
//   final DateTime createdAt;
//   final DateTime updatedAt;

//   Property({
//     required this.id,
//     required this.groupId,
//     required this.isAdmin,
//     required this.memberId,
//     required this.status,
//     required this.conversationId,
//     required this.isRead,
//     required this.isDeleted,
//     required this.isEdited,
//     required this.sentTime,
//     required this.isStarred,
//     required this.isLiked,
//     required this.isPinned,
//     required this.messageId,
//     required this.typeOfUser,
//     required this.workspaceId,
//     required this.createdAt,
//     required this.updatedAt,
//   });

//   factory Property.fromJson(Map<String, dynamic> json) {
//     return Property(
//       id: json['_id']?.toString() ?? '',
//       groupId: json['group_id']?.toString(),
//       isAdmin: json['is_admin'] ?? false,
//       memberId: json['member_id']?.toString() ?? '',
//       status: json['status']?.toString() ?? '',
//       conversationId: json['conversation_id']?.toString() ?? '',
//       isRead: json['is_read'] ?? false,
//       isDeleted: json['is_deleted'] ?? false,
//       isEdited: json['is_edited'] ?? false,
//       sentTime:
//           DateTime.tryParse(json['time']?['sent_time'] ?? '') ?? DateTime.now(),
//       isStarred: json['is_starred'] ?? false,
//       isLiked: json['is_liked'] ?? false,
//       isPinned: json['is_pinned'] ?? false,
//       messageId: json['message_id']?.toString() ?? '',
//       typeOfUser: json['type_of_user']?.toString() ?? '',
//       workspaceId: json['workspace_id']?.toString() ?? '',
//       createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
//       updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       '_id': id,
//       'group_id': groupId,
//       'is_admin': isAdmin,
//       'member_id': memberId,
//       'status': status,
//       'conversation_id': conversationId,
//       'is_read': isRead,
//       'is_deleted': isDeleted,
//       'is_edited': isEdited,
//       'time': {'sent_time': sentTime.toIso8601String()},
//       'is_starred': isStarred,
//       'is_liked': isLiked,
//       'is_pinned': isPinned,
//       'message_id': messageId,
//       'type_of_user': typeOfUser,
//       'workspace_id': workspaceId,
//       'createdAt': createdAt.toIso8601String(),
//       'updatedAt': updatedAt.toIso8601String(),
//     };
//   }
// }

// class GrpMessage {
//   final String messageId;
//   final String senderId;
//   final String receiverId;
//   final String message;
//   final DateTime time;
//   final String messageStatus;
//   final String? imageUrl;
//   final String? fileName;
//   final String? fileUrl;
//   final String? fileType;

//   final bool? isTemporary;
//   final File? localImagePath;

//   GrpMessage({
//     required this.messageId,
//     required this.senderId,
//     required this.receiverId,
//     required this.message,
//     required this.time,
//     required this.messageStatus,
//     this.imageUrl,
//     this.fileName,
//     this.fileUrl,
//     this.fileType,
//     this.isTemporary,
//     this.localImagePath,
//   });

//   // Factory constructor to create a Message from a Map
//   factory GrpMessage.fromJson(Map<String, dynamic> json) {
//     return GrpMessage(
//       messageId: json['messageId'] as String,
//       senderId: json['senderId'] as String,
//       receiverId: json['receiverId'] as String,
//       message: json['message'] as String,
//       time: DateTime.parse(json['time'] as String),
//       messageStatus: json['messageStatus'] as String,
//       imageUrl: json['imageUrl'] as String?,
//       fileName: json['fileName'] as String?,
//       fileUrl: json['fileUrl'] as String?,
//       fileType: json['fileType'] as String?,
//       isTemporary: json['isTemporary'] as bool?,
//       localImagePath: json['localImagePath'] != null
//           ? File(json['localImagePath'] as String)
//           : null, // Optional
//     );
//   }

//   // Method to convert Message to JSON
//   Map<String, dynamic> toJson() {
//     return {
//       'messageId': messageId,
//       'senderId': senderId,
//       'receiverId': receiverId,
//       'message': message,
//       'time': time.toIso8601String(),
//       'messageStatus': messageStatus,
//       'imageUrl': imageUrl,
//       'fileName': fileName,
//       'fileUrl': fileUrl,
//       'fileType': fileType,
//       'isTemporary': isTemporary,
//       'localImagePath': localImagePath?.path,
//     };
//   }
// }

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
    return GroupMessageResponse(
      data: [],
      total: 0,
      page: 1,
      limit: 20,
      hasNextPage: false,
      hasPreviousPage: false,
    );
  }

  factory GroupMessageResponse.fromJson(Map<String, dynamic> json) {
    return GroupMessageResponse(
      data: (json["data"] as List)
          .map((g) => GroupMessageGroup.fromJson(g))
          .toList(),
      total: json["total"] ?? 0,
      page: json["page"] ?? 1,
      limit: json["limit"] ?? 50,
      hasPreviousPage: json["hasPreviousPage"] ?? false,
      hasNextPage: json["hasNextPage"] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        "data": data.map((g) => g.toJson()).toList(),
        "total": total,
        "page": page,
        "limit": limit,
        "hasPreviousPage": hasPreviousPage,
        "hasNextPage": hasNextPage,
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

  factory GroupMessageGroup.fromJson(Map<String, dynamic> json) {
    return GroupMessageGroup(
      label: json['label'] ?? "",
      messages: (json['messages'] as List)
          .map((m) => GroupMessageModel.fromJson(m))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        "label": label,
        "messages": messages.map((m) => m.toJson()).toList(),
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

  factory GroupMessageModel.fromJson(Map<String, dynamic> json) {
    /// Receiver can be string OR user object
    dynamic receiver;
    if (json['receiver'] != null) {
      if (json['receiver'] is Map) {
        receiver = User.fromJson(Map<String, dynamic>.from(json['receiver']));
      } else {
        receiver = json['receiver'].toString();
      }
    }

    DateTime parseTime(dynamic t) {
      if (t == null) return DateTime.now();
      if (t is String) {
        return DateTime.tryParse(t) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return GroupMessageModel(
      id: json['_id']?.toString() ?? json['message_id']?.toString() ?? "",
      sender: User.fromJson(Map<String, dynamic>.from(json['sender'] ?? {})),
      receiver: receiver,
      conversationId: json['conversation_id']?.toString() ?? "",
      isDeleted: json['is_deleted'] ?? false,
      properties: (json['properties'] as List? ?? [])
          .map((e) => Property.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      messageType: json['messageType']?.toString() ?? "",
      messageStatus: json['messageStatus']?.toString(),
      reply: json['reply'] is Map
          ? Map<String, dynamic>.from(json['reply'])
          : null,
      messageId: json['message_id']?.toString() ?? "",
      fileWithText: json['file_with_text'] ?? false,
      content: json['content']?.toString() ?? "",
      thumbnailKey: json['thumbNailKey']?.toString(),
      contentType: json['ContentType']?.toString() ?? "",
      originalKey: json['originalKey']?.toString() ?? "",
      originalUrl: json['originalUrl']?.toString() ?? "",
      thumbnailUrl: json['thumbnailUrl']?.toString() ?? "",
      mimeType: json['mimeType']?.toString() ?? "",
      isForwarded: json['isForwarded'] ?? false,
      userName: json['userName']?.toString() ?? "",
      fileName: json['fileName']?.toString() ?? "",
      isPinned: json['isPinned'] ?? false,
      time: parseTime(json['time']),
      isReplyMessage: json['isReplyMessage'],
      isStarred: json['isStarred'],
      reactions: json['reactions'] as List<dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        "_id": id,
        "sender": sender.toJson(),
        "receiver": receiver is User ? (receiver as User).toJson() : receiver,
        "conversation_id": conversationId,
        "is_deleted": isDeleted,
        "properties": properties.map((e) => e.toJson()).toList(),
        "messageType": messageType,
        "messageStatus": messageStatus,
        "reply": reply,
        "message_id": messageId,
        "file_with_text": fileWithText,
        "content": content,
        "thumbNailKey": thumbnailKey,
        "ContentType": contentType,
        "originalKey": originalKey,
        "originalUrl": originalUrl,
        "thumbnailUrl": thumbnailUrl,
        "mimeType": mimeType,
        "isForwarded": isForwarded,
        "userName": userName,
        "fileName": fileName,
        "isPinned": isPinned,
        "time": time.toIso8601String(),
        "isReplyMessage": isReplyMessage,
        "isStarred": isStarred,
        "reactions": reactions,
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

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id']?.toString() ?? "",
      firstName: json['first_name']?.toString() ?? "",
      lastName: json['last_name']?.toString() ?? "",
      email: json['email']?.toString() ?? "",
      profilePicPath: json['profile_pic_path']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        "_id": id,
        "first_name": firstName,
        "last_name": lastName,
        "email": email,
        "profile_pic_path": profilePicPath,
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

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['_id'] ?? "",
      groupId: json['group_id']?.toString(),
      isAdmin: json['is_admin'] ?? false,
      memberId: json['member_id']?.toString() ?? "",
      status: json['status']?.toString() ?? "",
      conversationId: json['conversation_id']?.toString() ?? "",
      isRead: json['is_read'] ?? false,
      isDeleted: json['is_deleted'] ?? false,
      isEdited: json['is_edited'] ?? false,
      sentTime:
          DateTime.tryParse(json['time']?['sent_time'] ?? "") ?? DateTime.now(),
      isStarred: json['is_starred'] ?? false,
      isLiked: json['is_liked'] ?? false,
      isPinned: json['is_pinned'] ?? false,
      messageId: json['message_id']?.toString() ?? "",
      typeOfUser: json['type_of_user']?.toString() ?? "",
      workspaceId: json['workspace_id']?.toString() ?? "",
      createdAt: DateTime.tryParse(json['createdAt'] ?? "") ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? "") ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        "_id": id,
        "group_id": groupId,
        "is_admin": isAdmin,
        "member_id": memberId,
        "status": status,
        "conversation_id": conversationId,
        "is_read": isRead,
        "is_deleted": isDeleted,
        "is_edited": isEdited,
        "time": {"sent_time": sentTime.toIso8601String()},
        "is_starred": isStarred,
        "is_liked": isLiked,
        "is_pinned": isPinned,
        "message_id": messageId,
        "type_of_user": typeOfUser,
        "workspace_id": workspaceId,
        "createdAt": createdAt.toIso8601String(),
        "updatedAt": updatedAt.toIso8601String(),
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