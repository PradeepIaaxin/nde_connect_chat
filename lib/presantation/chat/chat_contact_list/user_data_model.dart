class UserListResponse {
  final List<String> onlineUsers;
  final List<ChatUserlist> data;
  final int total;
  final int page;
  final int limit;
  final bool hasPreviousPage;
  final bool hasNextPage;
  final String profilePic;

  UserListResponse({
    required this.onlineUsers,
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasPreviousPage,
    required this.hasNextPage,
    required this.profilePic,
  });

  factory UserListResponse.fromJson(Map<String, dynamic> jsonData) {
    return UserListResponse(
      onlineUsers: List<String>.from(jsonData['onlineUsers'] ?? []),
      data: List<ChatUserlist>.from(
        (jsonData['data'] ?? []).map((x) => ChatUserlist.fromJson(x)),
      ),
      total: jsonData['total'] ?? 0,
      page: jsonData['page'] ?? 1,
      limit: jsonData['limit'] ?? 0,
      hasPreviousPage: jsonData['hasPreviousPage'] ?? false,
      hasNextPage: jsonData['hasNextPage'] ?? false,
      profilePic: jsonData['profile_pic'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'onlineUsers': onlineUsers,
      'data': data.map((x) => x.toJson()).toList(),
      'total': total,
      'page': page,
      'limit': limit,
      'hasPreviousPage': hasPreviousPage,
      'hasNextPage': hasNextPage,
      'profile_pic': profilePic,
    };
  }
}

class ChatUserlist {
  final String? id;
  final String userId;
  final String lastName;
  final String firstName;
  final String email;
  final String? conversationId;
  final String profilePic;

  ChatUserlist({
    this.id,
    required this.userId,
    required this.lastName,
    required this.firstName,
    required this.email,
    this.conversationId,
    required this.profilePic,
  });

  factory ChatUserlist.fromJson(Map<String, dynamic> json) {
    return ChatUserlist(
      id: json["_id"] ?? "",
      userId: json['userId'] ?? "",
      lastName: json['lastName'] ?? "",
      firstName: json['firstName'] ?? "",
      email: json['email'] ?? "",
      conversationId: json['conversationId'] ?? "",
      profilePic: json['profile_pic'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      'userId': userId,
      'lastName': lastName,
      'firstName': firstName,
      'email': email,
      'conversationId': conversationId,
      'profile_pic': profilePic, 
    };
  }

  // Needed for proper selection in UI
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ChatUserlist && other.userId == userId;

  @override
  int get hashCode => userId.hashCode;
}
