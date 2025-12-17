import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/presantation/chat/chat_contact_list/UserService.dart';
import 'package:nde_email/presantation/chat/chat_contact_list/user_data_model.dart';
import 'package:nde_email/presantation/chat/chat_contact_list/user_list_bloc.dart';
import 'package:nde_email/presantation/chat/chat_contact_list/user_list_event.dart';
import 'package:nde_email/presantation/chat/chat_contact_list/user_list_state.dart';
import 'package:nde_email/presantation/chat/chat_list/chat_api.dart';
import 'package:nde_email/presantation/chat/chat_list/chat_bloc.dart';
import 'package:nde_email/presantation/chat/chat_list/chat_event.dart';
import 'package:nde_email/presantation/chat/chat_list/chat_session_storage/chat_session.dart';

import 'package:nde_email/presantation/chat/chat_list/chat_state.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/MessagerBloc.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/MessagerEvent.dart';
import 'package:nde_email/presantation/chat/chat_list/chat_response_model.dart';
import 'package:nde_email/utils/const/consts.dart';
import 'package:nde_email/utils/reusbale/colour_utlis.dart';
import 'package:nde_email/utils/router/router.dart';

import '../../../chat/chat_private_screen/Private_Chat_Screen.dart';
import 'package:nde_email/presantation/chat/Socket/Socket_Service.dart';

import '../../../chat/chat_private_screen/localstorage/local_storage.dart';

class ForwardMessageScreen extends StatefulWidget {
  final List<dynamic> messages;
  final String currentUserId;
  final String conversionalid;
  final String username;

  const ForwardMessageScreen({
    super.key,
    required this.messages,
    required this.currentUserId,
    required this.conversionalid,
    required this.username,
  });

  @override
  State<ForwardMessageScreen> createState() => _ForwardMessageScreenState();
}

class _ForwardMessageScreenState extends State<ForwardMessageScreen> {
  List<ChatUserlist> allUsers = [];
  List<ChatUserlist> filteredUsers = [];
  List<ChatUserlist> selectedUsers = [];
  List<Datu> frequentlyContactedChats = [];
  late UserListBloc userListBloc;
  late SocketService socketService;
  @override
  void initState() {
    super.initState();
    frequentlyContactedChats = ChatSessionStorage.getChatList();
    socketService = SocketService();
  }

  // --- Helper: Save optimistic message into LocalChatStorage ---
  Future<void> _saveOptimisticMessage(
      String convoId, Map<String, dynamic> optimisticMsg) async {
    try {
      final existing = LocalChatStorage.loadMessages(convoId) ?? [];
      final combined = [...existing, optimisticMsg];
      LocalChatStorage.saveMessages(convoId, combined);
    } catch (e) {
      log("Error saving optimistic message: $e");
    }
  }

  // Replace optimistic message id with server message id (reconcile)
  Future<void> _replaceOptimisticWithServerId(
    String convoId,
    String localId,
    String serverMessageId,
  ) async {
    try {
      final existing = LocalChatStorage.loadMessages(convoId) ?? [];
      var changed = false;

      final updated = existing.map<Map<String, dynamic>>((m) {
        if ((m['message_id'] ?? '') == localId) {
          changed = true;
          final copy = Map<String, dynamic>.from(m);
          copy['message_id'] = serverMessageId;
          copy['messageStatus'] = 'delivered';
          return copy;
        }
        return Map<String, dynamic>.from(m);
      }).toList();

      if (changed) {
        LocalChatStorage.saveMessages(convoId, updated);
      } else {
        // ❌ don’t create a blank message that loses content
        log(
          "⚠️ Did not find optimistic message $localId to replace. "
          "Skipping placeholder creation for $serverMessageId.",
        );
        LocalChatStorage.saveMessages(convoId, existing);
      }
    } catch (e) {
      log("Error reconciling optimistic message: $e");
    }
  }

  // Mark optimistic message as failed
  Future<void> _markOptimisticAsFailed(String convoId, String localId) async {
    try {
      final existing = LocalChatStorage.loadMessages(convoId) ?? [];
      var changed = false;
      final updated = existing.map<Map<String, dynamic>>((m) {
        if ((m['message_id'] ?? '') == localId) {
          changed = true;
          final copy = Map<String, dynamic>.from(m);
          copy['messageStatus'] = 'failed';
          return copy;
        }
        return Map<String, dynamic>.from(m);
      }).toList();

      if (changed) LocalChatStorage.saveMessages(convoId, updated);
    } catch (e) {
      log("Error marking optimistic message failed: $e");
    }
  }

  // Try to extract the real message id from socket.forwardMessage() result
  String? _extractServerMessageId(dynamic result) {
    if (result == null) return null;

    if (result is Map<String, dynamic>) {
      // 1) result["message"]["_id"]
      final msg = result['message'];
      if (msg is Map && msg['_id'] != null) {
        return msg['_id'].toString();
      }

      // 2) direct result["messageId"] or result["id"]
      if (result['messageId'] != null) {
        return result['messageId'].toString();
      }
      if (result['id'] != null) {
        return result['id'].toString();
      }

      // 3) nested result["data"]["message"]["_id"]
      final data = result['data'];
      if (data is Map) {
        final msg2 = data['message'];
        if (msg2 is Map && msg2['_id'] != null) {
          return msg2['_id'].toString();
        }
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) {
            userListBloc = UserListBloc(userService: UserService());
            userListBloc.add(FetchUserList(page: 1, limit: 100));
            return userListBloc;
          },
        ),
        BlocProvider(
          create: (_) => ChatListBloc(
              apiService: ChatListApiService(), socketService: socketService)
            ..add(FetchChatList(page: 1, limit: 80)),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(selectedUsers.isEmpty
              ? "Forward to..."
              : "${selectedUsers.length} selected"),
          actions: [IconButton(onPressed: () {}, icon: Icon(Icons.search))],
        ),
        body: BlocBuilder<ChatListBloc, ChatListState>(
          builder: (context, chatState) {
            if (chatState is ChatListLoaded) {
           //   ChatSessionStorage.saveChatList(chatState.chats);
              frequentlyContactedChats = ChatSessionStorage.getChatList();
            }

            return BlocBuilder<UserListBloc, UserListState>(
              builder: (context, userState) {
                List<Widget> children = [];

                if (frequentlyContactedChats.isNotEmpty) {
                  children.add(_sectionTitle("Frequently contacted"));
                  final displayedChats = frequentlyContactedChats.length > 4
                      ? frequentlyContactedChats.sublist(0, 4)
                      : frequentlyContactedChats;

                  children.addAll(displayedChats.map((chat) {
                    final isSelected = selectedUsers.any((u) =>
                        u.conversationId == chat.id ||
                        u.userId == chat.datumId);

                    final user = ChatUserlist(
                      id: chat.id, // conversation id
                      userId: chat.datumId ?? "", // actual user id
                      firstName: chat.name ?? "Unknown",
                      lastName: chat.lastName ?? "",
                      email: chat.name ?? "",
                      conversationId: chat.id ?? "", // convoId for this chat
                      profilePic: chat.profilePic ?? "",
                    );

                    return _buildUserTile(user, isSelected);
                  }));
                }

                children.add(_sectionTitle("People"));

                if (userState is UserListLoaded) {
                  allUsers = userState.userListResponse.data;
                  if (filteredUsers.isEmpty) {
                    filteredUsers = List.from(allUsers);
                  }

                  children.addAll(filteredUsers.map((user) {
                    final isSelected = selectedUsers.any((u) =>
                        u.userId == user.userId ||
                        u.conversationId == user.conversationId);
                    return _buildUserTile(user, isSelected);
                  }));
                }

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: children,
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: selectedUsers.isNotEmpty
            ? FloatingActionButton(
                onPressed: () async {
                  // Show progress dialog
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) =>
                        const Center(child: CircularProgressIndicator()),
                  );

                  final socket = SocketService();
                  final failures = <String>[];
                  final successes = <String>[];
                  final defaultWorkspace =
                      await UserPreferences.getDefaultWorkspace() ?? "";

                  try {
                    // For each selected recipient
                    for (final target in selectedUsers) {
                      final receiverId = target.userId;
                      final targetConvoId = target.conversationId;
                      if (receiverId == null ||
                          receiverId.isEmpty ||
                          targetConvoId == null ||
                          targetConvoId.isEmpty) {
                        failures.add(receiverId ?? 'unknown');
                        continue;
                      }

                      // For each message to forward
                      for (final message in widget.messages) {
                        final originalMessageId =
                            message["message_id"]?.toString() ?? "";
                        if (originalMessageId.isEmpty) continue;

                        final content = (message["content"] ?? "").toString();
                        final fileName = message['fileName']?.toString();
                        final imageUrl = (message['imageUrl'] ?? "").toString();
                        final contentType =
                            (message['contentType'] ?? 'text').toString();
                        // use a TEMP id only for UI, NOT forward_...
                        final localId =
                            'temp_${DateTime.now().millisecondsSinceEpoch}';

                        final optimisticMessage = {
                          'message_id': localId,
                          'content': content,
                          'sender': {'_id': widget.currentUserId},
                          'receiver': {'_id': receiverId},
                          'messageStatus': 'pending',
                          'time': DateTime.now().toIso8601String(),
                          'imageUrl': imageUrl,
                          'fileName': fileName,
                          'fileUrl': imageUrl.isNotEmpty ? imageUrl : null,
                          'isForwarded': true,
                          'original_message_id':
                              originalMessageId, // ⬅️ keep link to original
                        };

                        // Save optimistic message first so recipient screen shows it immediately
                        await _saveOptimisticMessage(
                            targetConvoId!, optimisticMessage);

                        // Now call socket forward for this single receiver
                        final results = await socket.forwardMessage(
                          senderId: widget.currentUserId,
                          receiverIds: [receiverId],
                          originalMessageId: originalMessageId,
                          messageContent: content,
                          conversationId: targetConvoId!,
                          workspaceId: defaultWorkspace,
                          isGroupChat: false,
                          currentUserInfo: {
                            "id": widget.currentUserId,
                            "name": widget.username,
                          },
                          image: imageUrl.isNotEmpty ? imageUrl : null,
                          fileName: fileName,
                          contentType: contentType,
                        );
                        final result =
                            (results.isNotEmpty) ? results.first : null;
                        final ok = result != null && result['success'] == true;

// 🔍 Extract real message id created by backend
                        final serverMsgId = _extractServerMessageId(result);

                        if (ok &&
                            serverMsgId != null &&
                            serverMsgId.isNotEmpty) {
                          successes.add(receiverId);

                          // Replace temp_id with real `_id` from backend
                          await _replaceOptimisticWithServerId(
                              targetConvoId!, localId, serverMsgId);
                        } else if (ok) {
                          successes.add(receiverId);

                          // fallback → still replace but with temp id (not ideal but avoids crash)
                          await _replaceOptimisticWithServerId(
                              targetConvoId!, localId, localId);
                        } else {
                          failures.add(receiverId);

                          // mark optimistic as failed
                          await _markOptimisticAsFailed(
                              targetConvoId!, localId);
                        }

                        await Future.delayed(const Duration(milliseconds: 40));
                      } // end messages loop
                    } // end targets loop

                    // Close progress dialog
                    Navigator.of(context).pop();
                    // Show summary
                    // if (failures.isEmpty) {
                    //   ScaffoldMessenger.of(context).showSnackBar(
                    //     SnackBar(content: Text("Message forwarded to ${successes.length} recipient(s).")),
                    //   );
                    // } else {
                    //   ScaffoldMessenger.of(context).showSnackBar(
                    //     SnackBar(content: Text("Forward failed for ${failures.length} recipient(s).")),
                    //   );
                    // }

                    // Finally navigate to last selected user's chat
                    final lastTarget = selectedUsers.last;
                    MyRouter.pushReplacement(
                      screen: PrivateChatScreen(
                        convoId: lastTarget.conversationId ?? "",
                        profileAvatarUrl: "",
                        userName:
                            "${lastTarget.firstName} ${lastTarget.lastName}",
                        lastSeen: "",
                        datumId: lastTarget.userId,
                        firstname: lastTarget.firstName,
                        lastname: lastTarget.lastName,
                        grpChat: false,
                        favourite: false,
                      ),
                    );
                  } catch (e) {
                    // Close progress dialog if still open
                    try {
                      Navigator.of(context).pop();
                    } catch (_) {}
                    log("Error forwarding messages from UI: $e");
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Error forwarding messages")));
                  }
                },
                backgroundColor: chatColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(Icons.send, color: Colors.white),
              )
            : null,
      ),
    );
  }

  Widget _buildUserTile(ChatUserlist user, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedUsers.removeWhere((u) => u.userId == user.userId);
            log(" id : ${user.id}");
            log("conversional id : ${user.conversationId}");
            log(" id : ${user.id}");
          } else {
            selectedUsers.add(user);
            log(" id : ${user.id}");
            log("conversional id : ${user.conversationId}");
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? chatColor.withOpacity(0.2) : Colors.transparent,
        ),
        child: ListTile(
          leading: Stack(
            children: [
              CircleAvatar(
                backgroundColor: ColorUtil.getColorFromAlphabet(
                    (user.firstName.isNotEmpty ? user.firstName : "U")[0]),
                child: Text(
                  (user.firstName.isNotEmpty ? user.firstName[0] : 'U')
                      .toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              if (isSelected)
                const Positioned(
                  right: 0,
                  bottom: 0,
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: chatColor,
                    child: Icon(Icons.check, size: 16, color: Colors.white),
                  ),
                ),
            ],
          ),
          title: Text('${user.firstName} ${user.lastName}'),
          subtitle: Text(user.email),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(
        text,
        style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w800),
      ),
    );
  }
}
