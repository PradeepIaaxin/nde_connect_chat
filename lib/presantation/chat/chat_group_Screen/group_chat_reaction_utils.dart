class GroupChatReactionUtils {
  static List<Map<String, dynamic>> extractReactions(dynamic raw) {
    final List<Map<String, dynamic>> out = [];

    if (raw is! List) return out;

    for (final e in raw) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);

      final emoji = m['emoji']?.toString();
      if (emoji == null || emoji.trim().isEmpty) continue;

      String? userId = m['userId']?.toString();
      final user = m['user'];

      if ((userId == null || userId.isEmpty) && user is Map) {
        userId = (user['_id'] ?? user['id'] ?? user['userId'])?.toString();
      }

      if ((userId == null || userId.isEmpty) && user is String) {
        userId = user;
      }

      if (userId == null || userId.isEmpty) {
        userId = "unknown";
      }

      out.add({
        'emoji': emoji,
        'userId': userId,
        'user': user is Map ? Map<String, dynamic>.from(user) : null,
        'reacted_at': (m['reacted_at'] ?? m['createdAt'] ?? '').toString(),
      });
    }

    return out;
  }
}
