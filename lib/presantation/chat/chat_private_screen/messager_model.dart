import 'dart:convert';
import 'dart:io';

class AuthResponse {
  final List<Datum> data;
  //final List<MessageModel> valueee;
  final int total;
  final int page;
  final int limit;
  final bool hasPreviousPage;
  final bool hasNextPage;

  AuthResponse({
    required this.data,
    // required this.valueee,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasPreviousPage,
    required this.hasNextPage,
  });

  AuthResponse copyWith({
    List<Datum>? data,
    int? total,
    int? page,
    int? limit,
    bool? hasPreviousPage,
    bool? hasNextPage,
  }) =>
      AuthResponse(
        data: data ?? this.data,
        // valueee: valueee ?? this.valueee,
        total: total ?? this.total,
        page: page ?? this.page,
        limit: limit ?? this.limit,
        hasPreviousPage: hasPreviousPage ?? this.hasPreviousPage,
        hasNextPage: hasNextPage ?? this.hasNextPage,
      );

  factory AuthResponse.fromRawJson(String str) =>
      AuthResponse.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        data: json["data"] != null && json["data"] is List
            ? (json["data"] as List)
                .where((item) => item is Map<String, dynamic>)
                .map((item) => Datum.fromJson(item as Map<String, dynamic>))
                .toList()
            : [],

        //List<Datum>.from(json["data"].map((x) => Datum.fromJson(x))),
        total: json["total"],
        page: json["page"],
        limit: json["limit"],
        hasPreviousPage: json["hasPreviousPage"],
        hasNextPage: json["hasNextPage"],
      );

  Map<String, dynamic> toJson() => {
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
        "total": total,
        "page": page,
        "limit": limit,
        "hasPreviousPage": hasPreviousPage,
        "hasNextPage": hasNextPage,
      };
}

class Message {
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
  final bool? isGroupMessage;
  final String? groupMessageId;

  Message({
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
    this.isGroupMessage,
    this.groupMessageId,
  });

  // Factory constructor to create a Message from a Map
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      messageId: json['messageId'] as String,
      senderId: json['senderId'] as String,
      receiverId: json['receiverId'] as String,
      message: json['message'] as String,
      time: DateTime.parse(json['time'] as String),
      messageStatus: json['messageStatus'] as String,
      imageUrl: json['imageUrl'] as String?,
      fileName: json['fileName'] as String?,
      fileUrl: json['fileUrl'] as String?,
      fileType: json['fileType'] as String?,
      isTemporary: json['isTemporary'] as bool?,
      localImagePath: json['localImagePath'] != null
          ? File(json['localImagePath'] as String)
          : null, // Optional
      isGroupMessage: json['is_group_message'] ?? json['isGroupMessage'],
      groupMessageId: json['group_message_id'] ?? json['groupMessageId'],
    );
  }

  // Method to convert Message to JSON
  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'time': time.toIso8601String(),
      'messageStatus': messageStatus,
      'imageUrl': imageUrl,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'isTemporary': isTemporary,
      'localImagePath': localImagePath?.path,
      'is_group_message': isGroupMessage,
      'group_message_id': groupMessageId,
    };
  }
}

class Datum {
  final String? id;
  final Sender? sender;
  final Receiver? receiver;
  final String? conversationId;
  final bool? isDeleted;
  final List<Property>? properties;
  final String? messageType;
  final bool? isStarred;
  final Reply? reply;
  final String? messageId;
  final bool? fileWithText;
  final String? content;
  final dynamic thumbNailKey;
  final String? ContentType;
  final String? originalKey;
  final String? originalUrl;
  final String? thumbnailUrl;
  final String? mimeType;
  final bool? isForwarded;
  final String? userName;
  final String? fileName;
  final bool? isPinned;
  final DateTime? time;
  final String? messageStatus;
  final bool? isReplyMessage;
  final List<Reaction>? reactions;
  final bool? isGroupMessage;
  final String? groupMessageId;

  Datum(
      {this.id,
      this.sender,
      this.receiver,
      this.conversationId,
      this.isDeleted,
      this.properties,
      this.messageType,
      this.isStarred,
      this.reply,
      this.messageId,
      this.fileWithText,
      this.content,
      this.thumbNailKey,
      this.ContentType,
      this.originalKey,
      this.originalUrl,
      this.thumbnailUrl,
      this.mimeType,
      this.isForwarded,
      this.userName,
      this.fileName,
      this.isPinned,
      this.time,
      this.messageStatus,
      this.isReplyMessage,
      this.reactions, 
      this.isGroupMessage,
      this.groupMessageId
      });

  Datum copyWith({
    String? id,
    Sender? sender,
    Receiver? receiver,
    String? conversationId,
    bool? isDeleted,
    List<Property>? properties,
    String? messageType,
    bool? isStarred,
    Reply? reply,
    String? messageId,
    bool? fileWithText,
    String? content,
    dynamic thumbNailKey,
    String? contentType,
    String? originalKey,
    String? originalUrl,
    String? thumbnailUrl,
    String? mimeType,
    bool? isForwarded,
    String? userName,
    String? fileName,
    bool? isPinned,
    DateTime? time,
    String? messageStatus,
    bool? isReplyMessage,
    List<Reaction>? reactions,
    bool? isGroupMessage, 
    String? groupMessageId,
  }) =>
      Datum(
          id: id ?? this.id,
          sender: sender ?? this.sender,
          receiver: receiver ?? this.receiver,
          conversationId: conversationId ?? this.conversationId,
          isDeleted: isDeleted ?? this.isDeleted,
          properties: properties ?? this.properties,
          messageType: messageType ?? this.messageType,
          isStarred: isStarred ?? this.isStarred,
          reply: reply ?? this.reply,
          messageId: messageId ?? this.messageId,
          fileWithText: fileWithText ?? this.fileWithText,
          content: content ?? this.content,
          thumbNailKey: thumbNailKey ?? this.thumbNailKey,
          ContentType: ContentType ?? this.ContentType,
          originalKey: originalKey ?? this.originalKey,
          originalUrl: originalUrl ?? this.originalUrl,
          thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
          mimeType: mimeType ?? this.mimeType,
          isForwarded: isForwarded ?? this.isForwarded,
          userName: userName ?? this.userName,
          fileName: fileName ?? this.fileName,
          isPinned: isPinned ?? this.isPinned,
          time: time ?? this.time,
          messageStatus: messageStatus ?? this.messageStatus,
          isReplyMessage: isReplyMessage ?? this.isReplyMessage,
          reactions: reactions ?? this.reactions, 
          isGroupMessage: isGroupMessage ?? this.isGroupMessage,
          groupMessageId: groupMessageId ?? this.groupMessageId,
          );

  factory Datum.fromRawJson(String str) => Datum.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Datum.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('is_group_message') ||
        json.containsKey('isGroupMessage')) {
      //log('🔍 Datum keys: ${json.keys.toList()}');
      //log('🔍 isGroupMessage value: ${json['is_group_message']} / ${json['isGroupMessage']}');
    }
    return Datum(
      id: json["_id"],
      sender: json["sender"] != null
          ? Sender.fromJson(Map<String, dynamic>.from(json["sender"]))
          : null,
      receiver: json["receiver"] != null
          ? Receiver.fromJson(Map<String, dynamic>.from(json["receiver"]))
          : null,
      conversationId: json["conversation_id"],
      isDeleted: json["is_deleted"],
      properties: json["properties"] != null
          ? List<Property>.from(json["properties"]
              .map((x) => Property.fromJson(Map<String, dynamic>.from(x))))
          : null,
      messageType: json["messageType"],
      isStarred: json["isStarred"],
      reply: json["reply"] != null
          ? Reply.fromJson(Map<String, dynamic>.from(json["reply"]))
          : null,
      messageId: json["message_id"],
      fileWithText: json["file_with_text"],
      content: json["content"],
      thumbNailKey: json["thumbNailKey"],
      ContentType: json["ContentType"],
      originalKey: json["originalKey"],
      originalUrl: json["originalUrl"],
      thumbnailUrl: json["thumbnailUrl"],
      mimeType: json["mimeType"],
      isForwarded: json["isForwarded"],
      userName: json["userName"],
      fileName: json["fileName"],
      isPinned: json["isPinned"],
  isGroupMessage: json['is_group_message'] ?? json['isGroupMessage'],
      groupMessageId: json['group_message_id']?.toString() ??
          json['groupMessageId']?.toString(),
      time: json["time"] != null ? DateTime.parse(json["time"]) : null,
      messageStatus: json["messageStatus"],
      isReplyMessage: json['isReplyMessage'],
      reactions: (json["reactions"] is List)
          ? (json["reactions"] as List)
              .where((x) => x is Map)
              .map(
                  (x) => Reaction.fromJson(Map<String, dynamic>.from(x as Map)))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        "_id": id,
        "sender": sender?.toJson(),
        "receiver": receiver?.toJson(),
        "conversation_id": conversationId,
        "is_deleted": isDeleted,
        "properties": properties != null
            ? List<dynamic>.from(properties!.map((x) => x.toJson()))
            : null,
        "messageType": messageType,
        "isStarred": isStarred,
        "reply": reply?.toJson(),
        "message_id": messageId,
        "file_with_text": fileWithText,
        "content": content,
        "thumbNailKey": thumbNailKey,
        "ContentType": ContentType,
        "originalKey": originalKey,
        "originalUrl": originalUrl,
        "thumbnailUrl": thumbnailUrl,
        "mimeType": mimeType,
        "isForwarded": isForwarded,
        "userName": userName,
        "fileName": fileName,
        "isPinned": isPinned,
        'is_group_message': isGroupMessage,
        'group_message_id': groupMessageId,
        "time": time?.toIso8601String(),
        "messageStatus": messageStatus,
        'isReplyMessage': isReplyMessage,
        "reactions": reactions != null
            ? List<dynamic>.from(reactions!.map((x) => x.toJson()))
            : null,
      };
}

class Reaction {
  final String emoji;
  final DateTime reactedAt;
  final ReactionUser user;

  Reaction({
    required this.emoji,
    required this.reactedAt,
    required this.user,
  });

  factory Reaction.fromJson(Map<String, dynamic> json) {
    return Reaction(
      emoji: json['emoji'] ?? '',
      reactedAt: DateTime.tryParse(json['reacted_at'] ?? '') ?? DateTime.now(),
      user: ReactionUser.fromJson(
        (json['user'] is Map)
            ? Map<String, dynamic>.from(json['user'])
            : <String, dynamic>{},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emoji': emoji,
      'reacted_at': reactedAt.toIso8601String(),
      'user': user.toJson(),
    };
  }
}

class ReactionUser {
  final String? id;
  final String? firstName;
  final String? lastName;

  ReactionUser({
    this.id,
    this.firstName,
    this.lastName,
  });

  factory ReactionUser.fromJson(Map<String, dynamic> json) {
    return ReactionUser(
      id: json['_id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'first_name': firstName,
      'last_name': lastName,
    };
  }
}

class Property {
  final String? id;
  final dynamic groupId;
  final bool? isAdmin;
  final String? memberId;
  final String? status;
  final String? conversationId;
  final bool? isRead;
  final bool? isDeleted;
  final bool? isEdited;
  final Time? time;
  final bool? isStarred;
  final bool? isLiked;
  final bool? isPinned;
  final String? messageId;
  final String? typeOfUser;
  final String? workspaceId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? v;

  Property({
    this.id,
    this.groupId,
    this.isAdmin,
    this.memberId,
    this.status,
    this.conversationId,
    this.isRead,
    this.isDeleted,
    this.isEdited,
    this.time,
    this.isStarred,
    this.isLiked,
    this.isPinned,
    this.messageId,
    this.typeOfUser,
    this.workspaceId,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  Property copyWith({
    String? id,
    dynamic groupId,
    bool? isAdmin,
    String? memberId,
    String? status,
    String? conversationId,
    bool? isRead,
    bool? isDeleted,
    bool? isEdited,
    Time? time,
    bool? isStarred,
    bool? isLiked,
    bool? isPinned,
    String? messageId,
    String? typeOfUser,
    String? workspaceId,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? v,
  }) =>
      Property(
        id: id ?? this.id,
        groupId: groupId ?? this.groupId,
        isAdmin: isAdmin ?? this.isAdmin,
        memberId: memberId ?? this.memberId,
        status: status ?? this.status,
        conversationId: conversationId ?? this.conversationId,
        isRead: isRead ?? this.isRead,
        isDeleted: isDeleted ?? this.isDeleted,
        isEdited: isEdited ?? this.isEdited,
        time: time ?? this.time,
        isStarred: isStarred ?? this.isStarred,
        isLiked: isLiked ?? this.isLiked,
        isPinned: isPinned ?? this.isPinned,
        messageId: messageId ?? this.messageId,
        typeOfUser: typeOfUser ?? this.typeOfUser,
        workspaceId: workspaceId ?? this.workspaceId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        v: v ?? this.v,
      );

  factory Property.fromRawJson(String str) =>
      Property.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Property.fromJson(Map<String, dynamic> json) => Property(
        id: json["_id"],
        groupId: json["group_id"],
        isAdmin: json["is_admin"],
        memberId: json["member_id"],
        status: json["status"],
        conversationId: json["conversation_id"],
        isRead: json["is_read"],
        isDeleted: json["is_deleted"],
        isEdited: json["is_edited"],
        time: json["time"] != null
            ? Time.fromJson(Map<String, dynamic>.from(json["time"]))
            : null,
        isStarred: json["is_starred"],
        isLiked: json["is_liked"],
        isPinned: json["is_pinned"],
        messageId: json["message_id"],
        typeOfUser: json["type_of_user"],
        workspaceId: json["workspace_id"],
        createdAt: json["createdAt"] != null
            ? DateTime.parse(json["createdAt"])
            : null,
        updatedAt: json["updatedAt"] != null
            ? DateTime.parse(json["updatedAt"])
            : null,
        v: json["__v"],
      );

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
        "time": time?.toJson(),
        "is_starred": isStarred,
        "is_liked": isLiked,
        "is_pinned": isPinned,
        "message_id": messageId,
        "type_of_user": typeOfUser,
        "workspace_id": workspaceId,
        "createdAt": createdAt?.toIso8601String(),
        "updatedAt": updatedAt?.toIso8601String(),
        "__v": v,
      };
}

class Time {
  final DateTime? sentTime;
  final DateTime? readTime;
  final DateTime? deliveredTime;

  Time({
    this.sentTime,
    this.readTime,
    this.deliveredTime,
  });

  Time copyWith({
    DateTime? sentTime,
    DateTime? readTime,
    DateTime? deliveredTime,
  }) =>
      Time(
        sentTime: sentTime ?? this.sentTime,
        readTime: readTime ?? this.readTime,
        deliveredTime: deliveredTime ?? this.deliveredTime,
      );

  factory Time.fromRawJson(String str) => Time.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Time.fromJson(Map<String, dynamic> json) => Time(
        sentTime: json["sent_time"] != null
            ? DateTime.parse(json["sent_time"])
            : null,
        readTime: json["read_time"] != null
            ? DateTime.parse(json["read_time"])
            : null,
        deliveredTime: json["delivered_time"] != null
            ? DateTime.parse(json["delivered_time"])
            : null,
      );

  Map<String, dynamic> toJson() => {
        "sent_time": sentTime?.toIso8601String(),
        "read_time": readTime?.toIso8601String(),
        "delivered_time": deliveredTime?.toIso8601String(),
      };
}

class Receiver {
  final String? id;
  final String? adminId;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? password;
  final String? phoneNumber;
  final bool? isArchived;
  final String? address;
  final String? locale;
  final String? countryCode;
  final String? country;
  final String? currencyCode;
  final bool? isSuspended;
  final String? status;
  final String? userType;
  final String? companyName;
  final String? city;
  final String? pincode;
  final String? state;
  final String? gstin;
  final String? gender;
  final dynamic profilePicName;
  final String? profilePicPath;
  final dynamic ipAddress;
  final DateTime? dateOfBirth;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? v;
  final String? otp;
  final String? profilePicKey;
  final String? mailAppEmail;
  final DateTime? lastOnline;
  final String? profile;
  final dynamic companyId;
  final dynamic branchId;
  final dynamic departmentId;
  final dynamic employeeCompanyId;
  final dynamic nickName;
  final dynamic joiningDate;
  final dynamic mobileToken;
  final dynamic desktopToken;

  Receiver({
    this.id,
    this.adminId,
    this.firstName,
    this.lastName,
    this.email,
    this.password,
    this.phoneNumber,
    this.isArchived,
    this.address,
    this.locale,
    this.countryCode,
    this.country,
    this.currencyCode,
    this.isSuspended,
    this.status,
    this.userType,
    this.companyName,
    this.city,
    this.pincode,
    this.state,
    this.gstin,
    this.gender,
    this.profilePicName,
    this.profilePicPath,
    this.ipAddress,
    this.dateOfBirth,
    this.createdAt,
    this.updatedAt,
    this.v,
    this.otp,
    this.profilePicKey,
    this.mailAppEmail,
    this.lastOnline,
    this.profile,
    this.companyId,
    this.branchId,
    this.departmentId,
    this.employeeCompanyId,
    this.nickName,
    this.joiningDate,
    this.mobileToken,
    this.desktopToken,
  });

  Receiver copyWith({
    String? id,
    String? adminId,
    String? firstName,
    String? lastName,
    String? email,
    String? password,
    String? phoneNumber,
    bool? isArchived,
    String? address,
    String? locale,
    String? countryCode,
    String? country,
    String? currencyCode,
    bool? isSuspended,
    String? status,
    String? userType,
    String? companyName,
    String? city,
    String? pincode,
    String? state,
    String? gstin,
    String? gender,
    dynamic profilePicName,
    String? profilePicPath,
    dynamic ipAddress,
    DateTime? dateOfBirth,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? v,
    String? otp,
    String? profilePicKey,
    String? mailAppEmail,
    DateTime? lastOnline,
    String? profile,
    dynamic companyId,
    dynamic branchId,
    dynamic departmentId,
    dynamic employeeCompanyId,
    dynamic nickName,
    dynamic joiningDate,
    dynamic mobileToken,
    dynamic desktopToken,
  }) =>
      Receiver(
        id: id ?? this.id,
        adminId: adminId ?? this.adminId,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        email: email ?? this.email,
        password: password ?? this.password,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        isArchived: isArchived ?? this.isArchived,
        address: address ?? this.address,
        locale: locale ?? this.locale,
        countryCode: countryCode ?? this.countryCode,
        country: country ?? this.country,
        currencyCode: currencyCode ?? this.currencyCode,
        isSuspended: isSuspended ?? this.isSuspended,
        status: status ?? this.status,
        userType: userType ?? this.userType,
        companyName: companyName ?? this.companyName,
        city: city ?? this.city,
        pincode: pincode ?? this.pincode,
        state: state ?? this.state,
        gstin: gstin ?? this.gstin,
        gender: gender ?? this.gender,
        profilePicName: profilePicName ?? this.profilePicName,
        profilePicPath: profilePicPath ?? this.profilePicPath,
        ipAddress: ipAddress ?? this.ipAddress,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        v: v ?? this.v,
        otp: otp ?? this.otp,
        profilePicKey: profilePicKey ?? this.profilePicKey,
        mailAppEmail: mailAppEmail ?? this.mailAppEmail,
        lastOnline: lastOnline ?? this.lastOnline,
        profile: profile ?? this.profile,
        companyId: companyId ?? this.companyId,
        branchId: branchId ?? this.branchId,
        departmentId: departmentId ?? this.departmentId,
        employeeCompanyId: employeeCompanyId ?? this.employeeCompanyId,
        nickName: nickName ?? this.nickName,
        joiningDate: joiningDate ?? this.joiningDate,
        mobileToken: mobileToken ?? this.mobileToken,
        desktopToken: desktopToken ?? this.desktopToken,
      );

  factory Receiver.fromRawJson(String str) =>
      Receiver.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Receiver.fromJson(Map<String, dynamic> json) => Receiver(
        id: json["_id"],
        adminId: json["adminId"],
        firstName: json["first_name"],
        lastName: json["last_name"],
        email: json["email"],
        password: json["password"],
        phoneNumber: json["phone_number"],
        isArchived: json["is_archived"],
        address: json["address"],
        locale: json["locale"],
        countryCode: json["country_code"],
        country: json["country"],
        currencyCode: json["currencyCode"],
        isSuspended: json["isSuspended"],
        status: json["status"],
        userType: json["userType"],
        companyName: json["companyName"],
        city: json["city"],
        pincode: json["pincode"],
        state: json["state"],
        gstin: json["gstin"],
        gender: json["gender"],
        profilePicName: json["profile_pic_name"],
        profilePicPath: json["profile_pic_path"],
        ipAddress: json["ip_Address"],
        dateOfBirth: json["dateOfBirth"] != null
            ? DateTime.parse(json["dateOfBirth"])
            : null,
        createdAt: json["createdAt"] != null
            ? DateTime.parse(json["createdAt"])
            : null,
        updatedAt: json["updatedAt"] != null
            ? DateTime.parse(json["updatedAt"])
            : null,
        v: json["__v"],
        otp: json["otp"],
        profilePicKey: json["profile_pic_key"],
        mailAppEmail: json["mail_app_email"],
        lastOnline: json["lastOnline"] != null
            ? DateTime.parse(json["lastOnline"])
            : null,
        profile: json["profile"],
        companyId: json["company_id"],
        branchId: json["branch_id"],
        departmentId: json["department_id"],
        employeeCompanyId: json["employee_company_id"],
        nickName: json["nick_name"],
        joiningDate: json["joining_date"],
        mobileToken: json["mobile_token"],
        desktopToken: json["desktop_token"],
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "adminId": adminId,
        "first_name": firstName,
        "last_name": lastName,
        "email": email,
        "password": password,
        "phone_number": phoneNumber,
        "is_archived": isArchived,
        "address": address,
        "locale": locale,
        "country_code": countryCode,
        "country": country,
        "currencyCode": currencyCode,
        "isSuspended": isSuspended,
        "status": status,
        "userType": userType,
        "companyName": companyName,
        "city": city,
        "pincode": pincode,
        "state": state,
        "gstin": gstin,
        "gender": gender,
        "profile_pic_name": profilePicName,
        "profile_pic_path": profilePicPath,
        "ip_Address": ipAddress,
        "dateOfBirth": dateOfBirth?.toIso8601String(),
        "createdAt": createdAt?.toIso8601String(),
        "updatedAt": updatedAt?.toIso8601String(),
        "__v": v,
        "otp": otp,
        "profile_pic_key": profilePicKey,
        "mail_app_email": mailAppEmail,
        "lastOnline": lastOnline?.toIso8601String(),
        "profile": profile,
        "company_id": companyId,
        "branch_id": branchId,
        "department_id": departmentId,
        "employee_company_id": employeeCompanyId,
        "nick_name": nickName,
        "joining_date": joiningDate,
        "mobile_token": mobileToken,
        "desktop_token": desktopToken,
      };
}

class Reply {
  String? id;
  String? userId;
  String? firstName;
  String? lastName;
  String? fileName;
  String? replyUrl;
  ContentType? contentType;
  String? replyContent;

  Reply({
    this.id,
    this.userId,
    this.firstName,
    this.lastName,
    this.fileName,
    this.replyUrl,
    this.contentType,
    this.replyContent,
  });

  factory Reply.fromJson(Map<String, dynamic> json) => Reply(
    id: json["id"],
    userId: json["userId"]!,
    firstName:json["first_name"]!,
    lastName: json["last_name"]!,
    fileName: json["fileName"],
    replyUrl: json["replyUrl"],
    contentType: json["ContentType"]!,
    replyContent: json["replyContent"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "userId":userId,
    "first_name":firstName,
    "last_name": lastName,
    "fileName": fileName,
    "replyUrl": replyUrl,
    "ContentType":contentType,
    "replyContent": replyContent,
  };
}

class MessageListResponse {
  final List<MessageGroup> data;
  final int total;
  final int page;
  final int limit;
  final bool hasPreviousPage;
  final bool hasNextPage;
  final List<dynamic> onlineParticipants;

  MessageListResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasPreviousPage,
    required this.hasNextPage,
    required this.onlineParticipants,
  });

  factory MessageListResponse.fromJson(Map<String, dynamic> json) {
    return MessageListResponse(
      data: (json["data"] as List)
          .map((group) => MessageGroup.fromJson(group))
          .toList(),
      total: json["total"] ?? 0,
      page: json["page"] ?? 1,
      limit: json["limit"] ?? 20,
      hasPreviousPage: json["hasPreviousPage"] ?? false,
      hasNextPage: json["hasNextPage"] ?? false,
      onlineParticipants: json["onlineParticipants"] ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
        "total": total,
        "page": page,
        "limit": limit,
        "hasPreviousPage": hasPreviousPage,
        "hasNextPage": hasNextPage,
        "onlineParticipants": onlineParticipants,
      };
}


class MessageGroup {
  final String label;
  final List<Datum> messages;

  MessageGroup({
    required this.label,
    required this.messages,
  });

  factory MessageGroup.fromJson(Map<String, dynamic> json) {
    return MessageGroup(
      label: json["label"] ?? "",
      messages:
          (json["messages"] as List).map((msg) => Datum.fromJson(msg)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        "label": label,
        "messages": List<dynamic>.from(messages.map((x) => x.toJson())),
      };
}


class Sender {
  final String? id;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? profilePicPath;

  Sender({
    this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.profilePicPath,
  });

  Sender copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? profilePicPath,
  }) =>
      Sender(
        id: id ?? this.id,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        email: email ?? this.email,
        profilePicPath: profilePicPath ?? this.profilePicPath,
      );

  factory Sender.fromRawJson(String str) => Sender.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Sender.fromJson(Map<String, dynamic> json) => Sender(
        id: json["_id"],
        firstName: json["first_name"],
        lastName: json["last_name"],
        email: json["email"],
        profilePicPath: json["profile_pic_path"],
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "first_name": firstName,
        "last_name": lastName,
        "email": email,
        "profile_pic_path": profilePicPath,
      };
}
