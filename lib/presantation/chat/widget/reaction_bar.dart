import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef ReactionEventCallback = void Function();

void showReactionsDialog({
  required BuildContext context,
  required String messageId,
  required List<Map> reactions,
  required String currentUserId,
  required String conversationId,
  required String receiverId,
  String firstName = "",
  String lastName = "",
  required ReactionEventCallback onRemoveReaction,
  required ReactionEventCallback onAddReaction,
}) {
  final Map<String, List<Map>> grouped = {};
  for (var r in reactions) {
    final emoji = r['emoji'] ?? '';
    if (emoji.isNotEmpty) {
      grouped.putIfAbsent(emoji, () => []).add(r);
    }
  }

  final totalReactions = reactions.length;
  String selectedEmoji = '';

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          final filteredReactions =
              selectedEmoji.isEmpty ? reactions : grouped[selectedEmoji] ?? [];

          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "$totalReactions Reactions",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Emoji filter bar
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      _buildEmojiFilterChip(
                        label: "All",
                        isSelected: selectedEmoji.isEmpty,
                        onTap: () => setState(() => selectedEmoji = ''),
                      ),
                      ...grouped.entries.map((entry) {
                        return _buildEmojiFilterChip(
                          label: "${entry.key} ${entry.value.length}",
                          isSelected: selectedEmoji == entry.key,
                          onTap: () =>
                              setState(() => selectedEmoji = entry.key),
                        );
                      }),
                    ],
                  ),
                ),
                const Divider(height: 16),

                // List of users
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredReactions.length,
                    itemBuilder: (context, index) {
                      final reaction = filteredReactions[index];
                      final user = reaction['user'] ?? {};
                      final userName = user['name'] ??
                          "${user['first_name'] ?? ''} ${user['last_name'] ?? ''}"
                              .trim();
                      final isCurrentUser =
                          (user['_id'] ?? reaction['userId']) == currentUserId;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[300],
                          child: Text(
                            userName.isNotEmpty
                                ? userName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                        title: Text(
                          userName.isEmpty ? "Unknown User" : userName,
                        ),
                        subtitle: Text(
                          isCurrentUser ? "Tap to remove" : "Tap to react",
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Text(
                          reaction['emoji'] ?? '',
                          style: const TextStyle(fontSize: 20),
                        ),
                        onTap: () {
                          Navigator.pop(context);

                          final myReaction = reactions.firstWhere(
                            (r) =>
                                (r['user']?['_id'] ?? r['userId']) ==
                                currentUserId,
                            orElse: () => <String, dynamic>{},
                          );

                          final hasMyReaction = myReaction.isNotEmpty;

                          if (isCurrentUser) {
                            onRemoveReaction();
                          } else {
                            if (hasMyReaction &&
                                myReaction['emoji'] != reaction['emoji']) {
                              onRemoveReaction();
                            }
                            onAddReaction();
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Widget _buildEmojiFilterChip({
  required String label,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
    ),
  );
}
