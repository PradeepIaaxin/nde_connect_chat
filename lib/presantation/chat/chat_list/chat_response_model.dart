import 'dart:convert';

// JSON Parsing Functions
ChatListResponse authResponseFromJson(String str) =>
    ChatListResponse.fromJson(json.decode(str));

String authResponseToJson(ChatListResponse data) => json.encode(data.toJson());

// Main Classes
class ChatListResponse {
  List<String>? onlineUsers;
  List<Datu>? data;
  PaginationData? paginationData;

  ChatListResponse({
    this.onlineUsers,
    this.data,
    this.paginationData,
  });

  ChatListResponse copyWith({
    List<String>? onlineUsers,
    List<Datu>? data,
    PaginationData? paginationData,
  }) =>
      ChatListResponse(
        onlineUsers: onlineUsers ?? this.onlineUsers,
        data: data ?? this.data,
        paginationData: paginationData ?? this.paginationData,
      );

  factory ChatListResponse.fromJson(Map<String, dynamic> json) =>
      ChatListResponse(
        onlineUsers: (json["onlineUsers"] is List)
            ? List<String>.from(json["onlineUsers"]!.map((x) => x.toString()))
            : [],
        data: (json["data"] is List)
            ? List<Datu>.from(
                json["data"]!.map((x) => Datu.fromJson(x)),
              )
            : [],
        paginationData: json["paginationData"] != null
            ? PaginationData.fromJson(json["paginationData"])
            : null,
      );

  Map<String, dynamic> toJson() => {
        "onlineUsers": onlineUsers ?? [],
        "data": data?.map((x) => x.toJson()).toList() ?? [],
        "paginationData": paginationData?.toJson(),
      };
}

class Datu {
  String? id;
  bool? isGroupChat;
  String? lastMessageId;
  String? mimeType;
  String? contentType;
  String? fileName;
  String? lastMessage;
  DateTime? lastMessageTime;
  int? unreadCount;
  String? firstName;
  String? lastName;
  String? name;
  String? profilePic;
  String? datumId;
  String? lastMessageSender;
  String? conversationId;
  bool? isPinned;
  bool? isArchived;
  bool? isFavorites;
  String? groupName;
  String ? draftMessage;

  Datu(
      {this.id,
      this.isGroupChat,
      this.lastMessageId,
      this.mimeType,
      this.contentType,
      this.fileName,
      this.lastMessage,
      this.lastMessageTime,
      this.unreadCount,
      this.firstName,
      this.lastName,
      this.name,
      this.profilePic,
      this.datumId,
      this.lastMessageSender,
      this.conversationId,
      this.isPinned,
      this.isFavorites,
      this.isArchived,
      this.groupName, 
      this.draftMessage
      });

  Datu copyWith(
          {String? id,
          bool? isGroupChat,
          String? lastMessageId,
          String? mimeType,
          String? contentType,
          String? fileName,
          String? lastMessage,
          DateTime? lastMessageTime,
          int? unreadCount,
          String? firstName,
          String? lastName,
          String? name,
          String? profilePic,
          String? datumId,
          String? lastMessageSender,
          String? conversationId,
          bool? isPinned,
          bool? isArchived,
          bool? isFavorites,
          String? groupName, 
          String ? draftMessage
          }) =>
      Datu(
          id: id ?? this.id,
          isGroupChat: isGroupChat ?? this.isGroupChat,
          lastMessageId: lastMessageId ?? this.lastMessageId,
          mimeType: mimeType ?? this.mimeType,
          contentType: contentType ?? this.contentType,
          fileName: fileName ?? this.fileName,
          lastMessage: lastMessage ?? this.lastMessage,
          lastMessageTime: lastMessageTime ?? this.lastMessageTime,
          unreadCount: unreadCount ?? this.unreadCount,
          firstName: firstName ?? this.firstName,
          lastName: lastName ?? this.lastName,
          name: name ?? this.name,
          profilePic: profilePic ?? this.profilePic,
          datumId: datumId ?? this.datumId,
          lastMessageSender: lastMessageSender ?? this.lastMessageSender,
          conversationId: conversationId ?? this.conversationId,
          isPinned: isPinned ?? this.isPinned,
          isArchived: isArchived ?? this.isArchived,
          isFavorites: isFavorites ?? this.isFavorites,
          groupName: groupName ?? this.groupName, 
          draftMessage: draftMessage ?? this.draftMessage
          );

  factory Datu.fromJson(Map<String, dynamic> json) => Datu(
      id: json["_id"] ?? "",
      isGroupChat: json["is_group_chat"] ?? false,
      lastMessageId: json["lastMessageId"] ?? "",
      mimeType: json["mimeType"] ?? "",
      contentType: json["ContentType"] ?? "",
      fileName: json["fileName"] ?? "",
      lastMessage: json["lastMessage"] ?? "",
      lastMessageTime: json["lastMessageTime"] != null
          ? DateTime.tryParse(json["lastMessageTime"] ?? "")
          : null,
      unreadCount: json["unreadCount"] ?? 0,
      firstName: json["first_name"] ?? "",
      lastName: json["last_name"] ?? "",
      name: json["name"] ?? "",
      profilePic: json["profile_pic"] ?? "",
      datumId: json["id"] ?? "",
      lastMessageSender: json["lastMessageSender"] ?? "",
      conversationId: json['conversationId'] ?? "",
      isPinned: json['isPinned'] ?? false,
      isFavorites: json['favourites'] ?? false,
      isArchived: json['isArchived'] ?? false,
      groupName: json['groupName'] ?? "", 
      draftMessage: json['draftMessage']
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "is_group_chat": isGroupChat,
        "lastMessageId": lastMessageId,
        "mimeType": mimeType,
        "ContentType": contentType,
        "fileName": fileName,
        "lastMessage": lastMessage,
        "lastMessageTime": lastMessageTime?.toIso8601String(),
        "unreadCount": unreadCount,
        "first_name": firstName,
        "last_name": lastName,
        "name": name,
        "profile_pic": profilePic,
        "id": datumId,
        "lastMessageSender": lastMessageSender,
        "isPinned": isPinned,
        "isArchived": isArchived,
        "favourites": isFavorites,
        "groupName": groupName,
        'draftMessage': draftMessage,
      };
}

class PaginationData {
  int? totalDocs;
  int? page;
  int? limit;
  int? totalPages;
  int? nextPage;
  int? prevPage;

  PaginationData({
    this.totalDocs,
    this.page,
    this.limit,
    this.totalPages,
    this.nextPage,
    this.prevPage,
  });

  PaginationData copyWith({
    int? totalDocs,
    int? page,
    int? limit,
    int? totalPages,
    int? nextPage,
    int? prevPage,
  }) =>
      PaginationData(
        totalDocs: totalDocs ?? this.totalDocs,
        page: page ?? this.page,
        limit: limit ?? this.limit,
        totalPages: totalPages ?? this.totalPages,
        nextPage: nextPage ?? this.nextPage,
        prevPage: prevPage ?? this.prevPage,
      );

  factory PaginationData.fromJson(Map<String, dynamic> json) => PaginationData(
        totalDocs: json["totalDocs"] ?? 0,
        page: json["page"] ?? 0,
        limit: json["limit"] ?? 0,
        totalPages: json["totalPages"] ?? 0,
        nextPage: json["nextPage"],
        prevPage: json["prevPage"],
      );

  Map<String, dynamic> toJson() => {
        "totalDocs": totalDocs,
        "page": page,
        "limit": limit,
        "totalPages": totalPages,
        "nextPage": nextPage,
        "prevPage": prevPage,
      };
}
