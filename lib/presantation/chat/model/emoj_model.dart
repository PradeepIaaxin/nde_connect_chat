class MessageReaction {
  final String emoji;
  final DateTime reactedAt;
  final String messageId;
  final String conversationId;
  final User user;
  bool isRemoval; // Add this flag

  MessageReaction({
    required this.emoji,
    required this.reactedAt,
    required this.messageId,
    required this.conversationId,
    required this.user,
    this.isRemoval = false,
  });

  factory MessageReaction.fromMap(Map<String, dynamic> map) {
    return MessageReaction(
      emoji: map['emoji'] ?? '',
      reactedAt:
          DateTime.parse(map['reacted_at'] ?? DateTime.now().toIso8601String()),
      messageId: map['messageId'] ?? '',
      conversationId: map['conversationId'] ?? '',
      user: User(
        id: map['user']?['_id'] ?? '',
        firstName: map['user']?['first_name'] ?? '',
        lastName: map['user']?['last_name'] ?? '',
      ),
    );
  }
}

class User {
  final String id;
  final String firstName;
  final String lastName;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
  });
}

class UserReaction {
  final String id;
  final String firstName;
  final String lastName;

  UserReaction({
    required this.id,
    required this.firstName,
    required this.lastName,
  });

  factory UserReaction.fromMap(Map<String, dynamic> map) {
    return UserReaction(
      id: map['_id']?.toString() ?? map['userId']?.toString() ?? '',
      firstName:
          map['first_name']?.toString() ?? map['firstName']?.toString() ?? '',
      lastName:
          map['last_name']?.toString() ?? map['lastName']?.toString() ?? '',
    );
  }
}
