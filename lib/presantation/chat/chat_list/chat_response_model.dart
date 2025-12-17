import 'dart:convert';

// JSON Parsing Functions
ChatListResponse authResponseFromJson(String str) =>
    ChatListResponse.fromJson(json.decode(str));

String authResponseToJson(ChatListResponse data) => json.encode(data.toJson());

// -------------------------------
// MAIN RESPONSE MODEL
// -------------------------------
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
            ? List<Datu>.from(json["data"]!.map((x) => Datu.fromJson(x)))
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

// -------------------------------
// DATU MODEL
// -------------------------------
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
  String? draftMessage;

  /// ⭐ NEW FIELD — ALL MEMBERS OF GROUP
  List<String>? participants;

  /// ⭐ NEW FIELD — ACTIVE/ONLINE MEMBERS
  List<String>? onlineParticipants;

  Datu({
    this.id,
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
    this.draftMessage,
    this.participants,
    this.onlineParticipants,
  });

  Datu copyWith({
    String? id,
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
    String? draftMessage,
    List<String>? participants,
    List<String>? onlineParticipants,
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
        draftMessage: draftMessage ?? this.draftMessage,
        participants: participants ?? this.participants,
        onlineParticipants: onlineParticipants ?? this.onlineParticipants,
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
            ? DateTime.tryParse(json["lastMessageTime"])
            : null,
        unreadCount: json["unreadCount"] ?? 0,

        firstName: json["first_name"] ?? "",
        lastName: json["last_name"] ?? "",
        name: json["name"] ?? "",
        profilePic: json["profile_pic"] ?? "",
        datumId: json["id"] ?? "",
        lastMessageSender: json["lastMessageSender"] ?? "",
        conversationId: json["conversationId"] ?? "",
        isPinned: json["isPinned"] ?? false,
        isFavorites: json["favourites"] ?? false,
        isArchived: json["isArchived"] ?? false,
        groupName: json["groupName"] ?? "",
        draftMessage: json["draftMessage"],

      /// ⭐ PARTICIPANTS LIST
        participants: json["participants"] != null
            ? List<String>.from(json["participants"].map((x) {
                if (x is Map) {
                  return (x["_id"] ?? x["id"] ?? x["userId"] ?? "").toString();
                }
                return x.toString();
              }))
            : [],

        /// ⭐ ONLINE PARTICIPANTS LIST
        onlineParticipants: json["onlineParticipants"] != null
            ? List<String>.from(json["onlineParticipants"].map((x) {
                if (x is Map) {
                  return (x["_id"] ?? x["id"] ?? x["userId"] ?? "").toString();
                }
                return x.toString();
              }))
            : [],
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
        "conversationId": conversationId,
        "isPinned": isPinned,
        "isArchived": isArchived,
        "favourites": isFavorites,
        "groupName": groupName,
        "draftMessage": draftMessage,

        "participants": participants ?? [],
        "onlineParticipants": onlineParticipants ?? [],
      };
}

// -------------------------------
// PAGINATION MODEL
// -------------------------------
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

  factory PaginationData.fromJson(Map<String, dynamic> json) =>
      PaginationData(
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
