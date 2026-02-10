import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/privat_common_funtions/privat_chat_funtions_2.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/privat_common_funtions/privat_chat_funtions_4.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/privat_common_funtions/privat_chat_funtions_5.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/privat_common_funtions/privat_chat_funtions_6.dart';
import '../../../../../../main.dart';
import '../../MessagerBloc.dart';
import '../../MessagerEvent.dart';
import '../../message_handler.dart';

Future<void> showReactionsBottomSheet({
  required Map<String, dynamic> message,
  required String initialEmoji,
  required List<Map<String, dynamic>> dbMessages,
  required List<Map<String, dynamic>> messages,
  required List<Map<String, dynamic>> socketMessages,
  required List<Map<String, dynamic>> allMessages,
  required BuildContext context,
  required  DateTime Function(dynamic) parseTime,
  required String currentUserId,
  required  MessagerBloc messagerBloc,
  required String convoId,
  required String firstname,
  required String lastname,
  required String receiverId,
  required ValueNotifier<List<Map<String, dynamic>>> messagesNotifier,
  required void Function(void Function()) setState,
  required bool Function(Map<String, dynamic>)
  hasReplyForMessage,
}) async {


  // helper to build normalized reactions list for a message object
  List<Map<String, dynamic>> _normalizeFromMap(Map<String, dynamic> msg) {
    final List<Map<String, dynamic>> out = [];
    if (msg['reactions'] is! List) return out;
    for (final r in (msg['reactions'] as List)) {
      if (r is! Map) continue;
      final mm = Map<String, dynamic>.from(r);
      final emoji = (mm['emoji'] ?? '').toString();
      if (emoji.isEmpty) continue;
      String? userId = mm['userId']?.toString();
      final user = mm['user'];
      if ((userId == null || userId.isEmpty) && user is Map) {
        userId = (user['_id'] ?? user['id'] ?? user['userId'])?.toString();
      }
      if (userId == null || userId.isEmpty) continue;
      out.add({
        'emoji': emoji,
        'userId': userId,
        'user': user is Map ? Map<String, dynamic>.from(user) : null,
        'reacted_at': (mm['reacted_at'] ?? mm['createdAt'] ?? '').toString(),
      });
    }
    return out;
  }

  // default emoji set (change if you want)
  const List<String> pickerEmojis = [
    '👍',
    '❤️',
    '😂',
    '😮',
    '😢',
    '👏',
    '🔥',
    '🎉',
    '🤝',
    '💯'
  ];

  // first build the initial normalized list
  List<Map<String, dynamic>> allReacts = _normalizeFromMap(message);
  if (allReacts.isEmpty) {
    // you might still want to show the sheet with just Add button. For now, return.
    return;
  }

  // group builder (returns grouped map)
  Map<String, List<Map<String, dynamic>>> buildGroupedFromList(
      List<Map<String, dynamic>> list) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final r in list) {
      final e = r['emoji'] as String;
      grouped.putIfAbsent(e, () => []).add(r);
    }
    return grouped;
  }

  // show sheet
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      // local UI state inside sheet
      bool showEmojiPicker = false;
      Map<String, List<Map<String, dynamic>>> grouped =
          buildGroupedFromList(allReacts);
      final emojis = grouped.keys.toList();
      String selectedEmoji = emojis.contains(initialEmoji)
          ? initialEmoji
          : (emojis.isNotEmpty
              ? emojis.first
              : (initialEmoji.isNotEmpty ? initialEmoji : pickerEmojis.first));

      // function to attempt to refresh `message` from current combined store
      void refreshFromStore(StateSetter setStateSB) {
        try {
          final id = (message['message_id'] ??
                  message['messageId'] ??
                  message['id'] ??
                  '')
              .toString();
          if (id.isNotEmpty) {
            final latest = getCombinedMessages(
                    dbMessages: dbMessages,
                    messages: messages,
                    socketMessages: socketMessages,
                    parseTime: parseTime,
                    hasReplyForMessage: hasReplyForMessage)
                .firstWhere((m) {
              final mid = (m['message_id'] ?? m['messageId'] ?? m['id'] ?? '')
                  .toString();
              return mid == id;
            }, orElse: () => message);
            // rebuild normalized list and grouped
            allReacts = _normalizeFromMap(latest);
            grouped = buildGroupedFromList(allReacts);
            final newEmojis = grouped.keys.toList();
            if (!newEmojis.contains(selectedEmoji) && newEmojis.isNotEmpty) {
              selectedEmoji = newEmojis.first;
            }
            setStateSB(() {}); // rebuild sheet
          } else {
            // no id: just keep what we have
            setStateSB(() {});
          }
        } catch (_) {
          // ignore and keep current values
          setStateSB(() {});
        }
      }

      return StatefulBuilder(builder: (ctx2, setStateSB) {
        final reactors = grouped[selectedEmoji] ?? [];

        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: showEmojiPicker
                  ? MediaQuery.of(context).size.height * 0.45
                  : MediaQuery.of(context).size.height * 0.30,
            ),
            padding: const EdgeInsets.only(top: 8, bottom: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // drag handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4)),
                ),

                // TOP: emoji chips (Add first)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  child: Row(
                    children: [
                      // Add chip (always visible)
                      GestureDetector(
                        onTap: () {
                          setStateSB(() {
                            showEmojiPicker = !showEmojiPicker;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: showEmojiPicker
                                ? Colors.green.withOpacity(0.12)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.emoji_emotions_outlined, size: 18),
                              SizedBox(width: 6),
                              Text('Add',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // existing reaction chips (scrollable)
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: grouped.keys.map((e) {
                              final cnt = grouped[e]?.length ?? 0;
                              final isSelected = e == selectedEmoji;
                              return GestureDetector(
                                onTap: () {
                                  setStateSB(() {
                                    selectedEmoji = e;
                                    showEmojiPicker =
                                        false; // hide picker if open
                                  });
                                },
                                child: Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.greenAccent.withOpacity(0.3)
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: isSelected
                                            ? Colors.green
                                            : Colors.grey.shade300),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(e,
                                          style: const TextStyle(fontSize: 18)),
                                      const SizedBox(width: 6),
                                      Text('$cnt',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // optionally show emoji picker panel inside sheet
                if (showEmojiPicker) ...[
                  Divider(
                    height: 1,
                    color: Colors.grey.shade200,
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: pickerEmojis.map((emo) {
                        return GestureDetector(
                          onTap: () async {
                            // user selected an emoji to add/change their reaction:
                            try {
                              // call your existing handler which handles add/change/remove logic
                              handleReactionTap(
                                  message: message,
                                  emoji: emo,
                                  currentUserId: currentUserId,
                                  messagerBloc: messagerBloc,
                                  convoId:convoId,
                                  receiverId:receiverId ?? "",
                                  firstname: firstname ?? "",
                                  lastname:lastname ?? "",
                                  setState: setState,
                                  allMessages: allMessages,
                                  messagesNotifier:
                                      messagesNotifier); // existing logic
                              Navigator.pop(context);
                            } catch (e) {
                              debugPrint(
                                  'Error while handling reaction pick: $e');
                            }

                            // hide picker and refresh sheet lists
                            setStateSB(() {
                              showEmojiPicker = false;
                            });

                            // give a tiny delay to allow local updates to settle, then refresh the grouped list
                            await Future.delayed(
                                const Duration(milliseconds: 120));
                            refreshFromStore(setStateSB);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.grey.shade100,
                            ),
                            child:
                                Text(emo, style: const TextStyle(fontSize: 22)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],

                Divider(
                  height: 1,
                  color: Colors.grey.shade200,
                ),

                // header: "X reactions"
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text('${grouped[selectedEmoji]?.length ?? 0} reactions',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Close')),
                    ],
                  ),
                ),

                Divider(
                  height: 1,
                  color: Colors.grey.shade200,
                ),

                // reactors list
                Expanded(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: reactors.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (c, i) {
                      final r = reactors[i];
                      final user = r['user'];
                      String userId = '';
                      String firstName = '';
                      String lastName = '';
                      String? avatarUrl;

                      if (user is Map) {
                        userId =
                            (user['_id'] ?? user['id'] ?? user['userId'] ?? '')
                                .toString();

                        firstName =
                            (user['first_name'] ?? user['firstName'] ?? '')
                                .toString();

                        lastName = (user['last_name'] ?? user['lastName'] ?? '')
                            .toString();

                        avatarUrl = user['avatar']?.toString();
                      } else {
                        userId = (r['userId'] ?? '').toString();
                      }

                      final displayName =
                          firstName.isNotEmpty ? firstName : userId;
                      final normalized = normalizeReactionUser(
                        r,
                        currentUserId,
                        firstname ?? '',
                       lastname ?? '',
                      );

                      final isMe = normalized['id'] == currentUserId;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: normalized['avatar'] != null &&
                                  normalized['avatar']!.isNotEmpty
                              ? NetworkImage(normalized['avatar']!)
                              : null,
                          child: avatarUrl == null || avatarUrl.isEmpty
                              ? Text(
                                  firstName.isNotEmpty
                                      ? firstName
                                          .trim()
                                          .characters
                                          .first
                                          .toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                        title: Text(isMe ? 'You' : normalized['name']!),
                        subtitle: isMe
                            ? const Text('Tap to remove',
                                style: TextStyle(fontSize: 12))
                            : null,
                        trailing: isMe
                            ? TextButton(
                                onPressed: () async {
                                  Navigator.of(ctx).pop(); // close sheet
                                  final msgId = (message['message_id'] ??
                                          message['messageId'] ??
                                          '')
                                      .toString();
                                  if (msgId.isEmpty) return;

                                  // optimistic local removal of current user's reaction
                                  updateLocalReactions(
                                      targetMessageId: msgId,
                                      newEmoji: null,
                                      currentUserId: currentUserId,
                                      firstname:firstname ?? "",
                                      lastname:lastname ?? "",
                                      convoId:convoId,
                                      setState: setState,
                                      allMessages: allMessages,
                                      messagesNotifier:
                                          messagesNotifier); // remove my reaction locally
                                  final apiMessageId =
                                      normalizeMessageIdForApi(msgId);

                                  // dispatch your RemoveReaction event
                                  messagerBloc.add(RemoveReaction(
                                    messageId: apiMessageId,
                                    conversationId:convoId,
                                    emoji: selectedEmoji,
                                    userId: currentUserId,
                                    receiverId:receiverId ?? "",
                                    firstName:firstname ?? "",
                                    lastName: lastname ?? "",
                                  ));
                                },
                                child: const Text('Remove',
                                    style: TextStyle(color: Colors.red)),
                              )
                            : null,
                        onTap: () {
                          // optional: open user profile
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      });
    },
  );
}

String? getMessageSenderId(Map<String, dynamic> message, String currentUserId) {
  if (message.isEmpty) return null;

  // Try multiple fields in order of priority
  String? senderId;

  // 1. Check direct senderId field
  senderId = message['senderId']?.toString();
  if (senderId != null && senderId.isNotEmpty) return senderId;

  // 2. Check 'from' field
  senderId = message['from']?.toString();
  if (senderId != null && senderId.isNotEmpty) return senderId;

  // 3. Check sender object
  if (message['sender'] is Map) {
    final sender = message['sender'] is Map
        ? Map<String, dynamic>.from(message['sender'])
        : <String, dynamic>{};

    senderId = sender['_id']?.toString() ??
        sender['id']?.toString() ??
        sender['userId']?.toString();
    if (senderId != null && senderId.isNotEmpty) return senderId;
  }

  // 4. Check if it's a temp message (always from current user)
  final msgId = (message['message_id'] ?? '').toString();
  if (msgId.startsWith('temp_') || msgId.startsWith('forward_')) {
    return currentUserId;
  }

  return null;
}

List<Map<String, dynamic>> mergeReactions({
  List<Map<String, dynamic>>? local,
  List<Map<String, dynamic>>? incoming,
}) {
  final Map<String, Map<String, dynamic>> byUser = {};

  void addList(List<Map<String, dynamic>>? list) {
    if (list == null) return;
    for (final r in list) {
      if (r == null || r is! Map) continue;
      final uid = (r['userId'] ?? r['user']?['_id'])?.toString() ?? '';
      final emoji = r['emoji']?.toString() ?? '';
      if (uid.isEmpty || emoji.isEmpty) continue;
      // Keep the most recent incoming attributes but prefer incoming when duplicate
      byUser[uid] = {
        'emoji': emoji,
        'userId': uid,
        'user':
            r['user'] is Map ? Map<String, dynamic>.from(r['user']) : r['user'],
        'reacted_at': (r['reacted_at'] ?? r['createdAt'] ?? '').toString(),
      };
    }
  }

  // local first so incoming can overwrite if needed (server is source-of-truth)
  addList(local);
  addList(incoming);

  return byUser.values.toList();
}

String generateMessageKey({
  required Map<String, dynamic> msg,
  required MessageHandler? messageHandler,
  required String currentUserId,
  required String convoId,
}) {
  ensureMessageHandler(messageHandler, currentUserId, convoId);
  return messageHandler!.generateMessageKey(msg);
}

bool isSameDay(DateTime? d1, DateTime? d2) {
  if (d1 == null || d2 == null) return false;
  return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
}

void ensureMessageHandler(
    MessageHandler? messageHandler, String currentUserId, String convoId) {
  messageHandler ??=
      MessageHandler(currentUserId: currentUserId, convoId: convoId);
}

void sendReadReceipts({
  required List<String> messageIds,
  required List<Map<String, dynamic>> dbMessages,
  required List<Map<String, dynamic>> messages,
  required List<Map<String, dynamic>> socketMessages,
  required DateTime Function(dynamic) parseTime,
  required bool Function(Map<String, dynamic>) hasReplyForMessage,
  required String currentUserId,
  required String datumId,
  required String convoId,
  required void Function({bool isInitialLoad}) updateNotifier,
  required void Function() scheduleSaveMessages,
  required Set<String> alreadyRead,
}) {
  //log("🟢 _sendReadReceipts called with: $messageIds");

  // helper: try to find message locally by id
  Map<String, dynamic>? _findLocalMessageById(String id) {
    if (id.trim().isEmpty) return null;
    final combined = getCombinedMessages(
        dbMessages: dbMessages,
        messages: messages,
        socketMessages: socketMessages,
        parseTime: parseTime,
        hasReplyForMessage: hasReplyForMessage);
    try {
      return combined.firstWhere((m) {
        final mid =
            (m['message_id'] ?? m['messageId'] ?? m['id'])?.toString() ?? '';
        return mid == id;
      }, orElse: () => <String, dynamic>{});
    } catch (_) {
      return null;
    }
  }

  // keep unique & non-empty
  final uniqueAll = messageIds
      .where((id) => id.trim().isNotEmpty && !alreadyRead.contains(id))
      .toSet()
      .toList();

  // Defensive filter: only mark/read/send receipts for messages that are
  // actually from the OTHER user (not messages sent by currentUser).
  final unique = <String>[];
  for (final id in uniqueAll) {
    final msg = _findLocalMessageById(id);
    final senderId = (msg != null && msg.isNotEmpty)
        ? (msg['senderId'] ?? msg['sender']?['_id'] ?? msg['sender'])
            ?.toString()
        : null;

    // If we have a local message and senderId equals currentUserId then skip it.
    if (senderId != null && senderId == currentUserId) {
      log("⚠️ Skipping local marking as read for my own message id: $id");
      continue;
    }

    // If we don't have the message locally, it's safer to keep sending the
    // receipt to server (server might know it), but avoid marking locally.
    // You can choose to include it in the outgoing socket call or not;
    // here we include it (so server gets receipt) but we avoid local marking.
    unique.add(id);
  }

  //log("🟢 unique read IDs after filter: $unique");

  if (unique.isEmpty) {
    //log("ℹ️ _sendReadReceipts: nothing to send (empty after filter).");
    return;
  }

  // remember we already sent these
  alreadyRead.addAll(unique);

  // Locally mark read only for messages we can locate & that are NOT ours
  for (final id in unique) {
    final msg = _findLocalMessageById(id);
    final senderId = (msg != null && msg.isNotEmpty)
        ? (msg['senderId'] ?? msg['sender']?['_id'] ?? msg['sender'])
            ?.toString()
        : null;

    if (senderId != null && senderId != currentUserId) {
      // log("🔵 Locally marking message as read: $id");
      updateMessageStatus(
          messageId: id,
          localMark: true,
          status: 'read',
          messages: messages,
          socketMessages: socketMessages,
          updateNotifier: updateNotifier,
          scheduleSaveMessages: scheduleSaveMessages,
          dbMessages: dbMessages);
    } else {
      log("ℹ️ Not locally marking (not found or message is mine): $id");
    }
  }

  final computedRoomId =
      socketService.generateRoomId(currentUserId, datumId ?? '');
  socketService.sendReadReceipts(
    messageIds: unique,
    conversationId:convoId,
    roomId: computedRoomId,
  );
}

Map<String, String?> normalizeReactionUser(
    Map<String, dynamic> reaction,
    String currentUserId,
    String currentUserFirstName,
    String currentUserLastName,
    )
{
  final user = reaction['user'];

  String userId = '';
  String displayName = '';
  String? avatar;

  if (user is Map) {
    userId = (user['_id'] ?? user['id'] ?? user['userId'] ?? '').toString();

    displayName = (user['first_name'] ??
        user['firstName'] ??
        user['name'] ??
        user['email'] ??
        '')
        .toString();

    avatar = user['avatar']?.toString();
  } else {
    userId =
        (reaction['userId'] ?? reaction['senderId'] ?? reaction['id'] ?? '')
            .toString();
  }

  // 🔥 CURRENT USER OVERRIDE (MOST IMPORTANT)
  if (userId == currentUserId) {
    displayName = '${currentUserFirstName} ${currentUserLastName}'.trim();
  }

  final initial = displayName.isNotEmpty
      ? displayName.trim().characters.first.toUpperCase()
      : '?';

  return {
    'id': userId,
    'name': displayName,
    'initial': initial,
    'avatar': avatar,
  };
}
