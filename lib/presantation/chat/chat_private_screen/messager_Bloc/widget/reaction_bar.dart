import 'package:flutter/material.dart';

class ReactionBar extends StatelessWidget {
  final Map<String, dynamic> message;
  final String currentUserId;
  final void Function(Map<String, dynamic> message, String emoji)? onReactionTap;
  final void Function(Map<String, dynamic> message, String emoji)? onOpenReactors;

  const ReactionBar({
    Key? key,
    required this.message,
    required this.currentUserId,
    this.onReactionTap,
    this.onOpenReactors,
  }) : super(key: key);

  List<Map<String, dynamic>> _extractReactions(dynamic raw) {
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
      if (userId == null || userId.isEmpty) continue;
      out.add({
        'emoji': emoji,
        'userId': userId,
        'user': user is Map ? Map<String, dynamic>.from(user) : null,
        'reacted_at': (m['reacted_at'] ?? m['createdAt'] ?? '').toString(),
      });
    }
    return out;
  }

  // simple built-in emoji set — adjust to match your UI
  static const List<String> defaultEmojis = ['👍','❤️','😂','😮','😢','👏'];

  void _openEmojiPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Wrap(
              spacing: 12,
              children: defaultEmojis.map((e) {
                return GestureDetector(
                  onTap: () {
                    Navigator.of(ctx).pop();
                    if (onReactionTap != null) onReactionTap!(message, e);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade100,
                    ),
                    child: Text(e, style: const TextStyle(fontSize: 22)),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final reactions = _extractReactions(message['reactions']);
    if (reactions.isEmpty) {
      // show nothing or show Add icon only — choose Add so user can react.
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: GestureDetector(
          onTap: () => _openEmojiPicker(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.add_reaction_outlined, size: 18),
          ),
        ),
      );
    }

    final reactionCounts = <String, int>{};
    final userReacted = <String, bool>{};

    for (final r in reactions) {
      final emoji = r['emoji'] as String;
      reactionCounts[emoji] = (reactionCounts[emoji] ?? 0) + 1;
      if (r['userId'] == currentUserId) {
        userReacted[emoji] = true;
      }
    }

    // detect if user has any reaction
    final myEmoji = userReacted.keys.isNotEmpty ? userReacted.keys.first : null;

    // build list of chips, optionally prefacing with Add if the user hasn't reacted
    final chips = <Widget>[];

    // If user hasn't reacted at all, show Add chip first
    if (myEmoji == null) {
      chips.add(
        GestureDetector(
          onTap: () => _openEmojiPicker(context),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add_reaction_outlined, size: 18),
          ),
        ),
      );
    }

    // reaction chips from counts
    chips.addAll(reactionCounts.entries.map((entry) {
      final emoji = entry.key;
      final count = entry.value;
      final isMyReaction = userReacted[emoji] ?? false;
      return GestureDetector(
        onTap: () {
          if (onOpenReactors != null) {
            onOpenReactors!(message, emoji);
            return;
          }
          _openEmojiPicker(context);
        },
        onLongPress: () {
          if (onReactionTap != null) onReactionTap!(message, emoji);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),

          child: Text('$emoji${count > 1 ? ' $count' : ''}', style: const TextStyle(fontSize: 14)),
        ),
      );
    }).toList());

    return Container(
      decoration: BoxDecoration(color:  Colors.blue[50],
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            spreadRadius: 0.5,blurRadius: 0.3
          )
        ]
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Wrap(spacing: 0, children: chips),
    );
  }


}
