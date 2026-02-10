import 'package:flutter/material.dart';

import 'dart:developer' show log;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/presantation/chat/Socket/Socket_Service.dart';

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
import 'package:nde_email/presantation/chat/chat_list/chat_response_model.dart';
import 'package:nde_email/utils/const/consts.dart';
import 'package:nde_email/utils/reusbale/colour_utlis.dart';
import 'package:nde_email/utils/router/router.dart';

import '../../../chat/chat_private_screen/Private_Chat_Screen.dart';

import '../../../chat/chat_private_screen/localstorage/local_storage.dart';

class ForwardMessageScreen extends StatefulWidget {
  final List<Map<String, dynamic>> messages;
  final String currentUserId;
  final String conversionalid;
  final String username;
  final bool? isForward;
  const ForwardMessageScreen({
    super.key,
    required this.messages,
    required this.currentUserId,
    required this.conversionalid,
    required this.username,
    this.isForward = false,
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
  final List<Map<String, dynamic>> optimisticMessagesForUI = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    frequentlyContactedChats = ChatSessionStorage.getChatList();
    socketService = SocketService();
    log("messagesssssss ${widget.messages}");
    log("isForwardsssssssss ${widget.isForward}");
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isUserSelected(ChatUserlist user) {
    return selectedUsers.any((u) {
      if (user.conversationId != null &&
          user.conversationId!.isNotEmpty &&
          u.conversationId != null &&
          u.conversationId!.isNotEmpty) {
        return u.conversationId == user.conversationId;
      }
      return u.userId == user.userId;
    });
  }

  // --- Helper: Save optimistic message into LocalChatStorage ---
  // Future<void> _saveOptimisticMessage(
  //     String convoId, Map<String, dynamic> optimisticMsg) async {
  //   try {
  //     final existing = LocalChatStorage.loadMessages(convoId) ?? [];
  //     final combined = [...existing, optimisticMsg];
  //     LocalChatStorage.saveMessages(convoId, combined);
  //   } catch (e) {
  //     log("Error saving optimistic message: $e");
  //   }
  // }
  Future<void> _saveOptimisticMessage(
    String convoId,
    Map<String, dynamic> msg,
  ) async {
    final existing = LocalChatStorage.loadMessages(convoId) ?? [];

    final exists = existing.any(
      (m) =>
          m['message_id'] == msg['message_id'] ||
          (m['forwardFingerprint'] != null &&
              m['forwardFingerprint'] == msg['forwardFingerprint']),
    );

    if (exists) return; // 🚫 prevent duplicate

    LocalChatStorage.saveMessages(convoId, [...existing, msg]);
  }

  // Replace optimistic message id with server message id (reconcile)
  Future<void> _replaceOptimisticWithServerId(
    String convoId,
    String localId,
    String serverMessageId,
  ) async {
    try {
      final existing = LocalChatStorage.loadMessages(convoId) ?? [];
      bool replaced = false;

      final updated = existing.map<Map<String, dynamic>>((m) {
        if (m['message_id'] == localId) {
          replaced = true;

          return {
            ...m,

            // 🔑 real server id
            'message_id': serverMessageId,

            // 🔥 IMPORTANT: clear optimistic flags
            'isOptimistic': false,
            'forwardFingerprint': null,

            // normalize status
            'messageStatus': 'sent',
            'status': 'sent',

            // keep media intact
            'imageUrl': m['imageUrl'],
            'fileUrl': m['fileUrl'],
            'originalUrl': m['originalUrl'],
          };
        }
        return m;
      }).toList();

      if (replaced) {
        await LocalChatStorage.saveMessages(convoId, updated);
      } else {
        log(
          '⚠️ Optimistic message not found for localId=$localId, '
          'serverId=$serverMessageId',
        );
      }
    } catch (e, st) {
      log('❌ replaceOptimisticWithServerId failed: $e\n$st');
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
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.white,
          title: Text(selectedUsers.isEmpty
              ? "Forward message to"
              : "${selectedUsers.length} selected"),
        ),
        body: Column(
          children: [
            // Search bar
            SafeArea(
              bottom: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.grey.shade100,
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),

                      /// 🔍 SEARCH ICON
                      Icon(
                        Icons.search,
                        size: 20,
                        color: Colors.grey.shade600,
                      ),

                      const SizedBox(width: 10),

                      /// ✏️ TEXT FIELD
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) {
                            setState(() {
                              _searchQuery =
                                  _searchController.text.toLowerCase();
                            });
                          },
                          textAlignVertical: TextAlignVertical.center,
                          style: const TextStyle(
                            fontSize: 14.5,
                            height: 1.2,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Search name or number',
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 14.5,
                              height: 1.2,
                            ),
                            border: InputBorder.none,
                            isCollapsed: true,
                          ),
                        ),
                      ),

                      /// ❌ CLEAR BUTTON
                      if (_searchController.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                            FocusScope.of(context).unfocus();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(
                              Icons.close,
                              size: 20,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            // Content
            Expanded(
              child: BlocBuilder<ChatListBloc, ChatListState>(
                builder: (context, chatState) {
                  if (chatState is ChatListLoaded) {
                    //   ChatSessionStorage.saveChatList(chatState.chats);
                    frequentlyContactedChats = ChatSessionStorage.getChatList();
                  }

                  return BlocBuilder<UserListBloc, UserListState>(
                    builder: (context, userState) {
                      List<Widget> children = [];

                      if (frequentlyContactedChats.isNotEmpty) {
                        // Filter to show only groups
                        var groupChats = frequentlyContactedChats
                            .where((chat) => chat.isGroupChat == true)
                            .toList();

                        // Apply search filter to groups
                        if (_searchQuery.isNotEmpty) {
                          groupChats = groupChats.where((chat) {
                            final name = (chat.name ?? chat.groupName ?? "")
                                .toLowerCase();
                            return name.contains(_searchQuery);
                          }).toList();
                        }

                        if (groupChats.isNotEmpty) {
                          children.add(_sectionTitle("Groups"));

                          children.addAll(groupChats.map((chat) {
                            final isSelected = selectedUsers.any((u) {
                              // Prefer conversationId if available
                              if (chat.id != null &&
                                  chat.id!.isNotEmpty &&
                                  u.conversationId != null &&
                                  u.conversationId!.isNotEmpty) {
                                return u.conversationId == chat.id;
                              }

                              // Fallback to userId
                              return u.userId == chat.datumId;
                            });

                            final user = ChatUserlist(
                              id: chat.id, // conversation id
                              userId: chat.datumId ?? "", // actual user id
                              firstName: chat.name ?? "Unknown",
                              lastName: chat.lastName ?? "",
                              email: chat.name ?? "",
                              conversationId:
                                  chat.id ?? "", // convoId for this chat
                              profilePic: chat.profilePic ?? "",
                            );

                            return _buildUserTile(user, isSelected,
                                isGroup: true);
                          }));
                        }
                      }

                      children.add(_sectionTitle("Contacts"));

                      if (userState is UserListLoaded) {
                        allUsers = userState.userListResponse.data;

                        // Apply search filter to users
                        var usersToDisplay = List<ChatUserlist>.from(allUsers);
                        if (_searchQuery.isNotEmpty) {
                          usersToDisplay = usersToDisplay.where((user) {
                            final firstName =
                                (user.firstName ?? "").toLowerCase();
                            final lastName =
                                (user.lastName ?? "").toLowerCase();
                            final email = (user.email ?? "").toLowerCase();
                            final fullName =
                                "$firstName $lastName".toLowerCase();

                            return firstName.contains(_searchQuery) ||
                                lastName.contains(_searchQuery) ||
                                fullName.contains(_searchQuery) ||
                                email.contains(_searchQuery);
                          }).toList();
                        }

                        children.addAll(usersToDisplay.map((user) {
                          final isSelected = selectedUsers.any((u) {
                            // 1️⃣ Prefer conversationId if available
                            if (user.conversationId != null &&
                                user.conversationId!.isNotEmpty &&
                                u.conversationId != null &&
                                u.conversationId!.isNotEmpty) {
                              return u.conversationId == user.conversationId;
                            }

                            // 2️⃣ Fallback to userId
                            return u.userId == user.userId;
                          });

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
            ),
          ],
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

                  final socket = socketService; // ✅ CORRECT
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
                        log("receiverId>unknown. $receiverId");
                        failures.add(receiverId ?? 'unknown');
                        continue;
                      }

                      // For each message to forward
                      for (final message in widget.messages) {
                        final originalMessageId =
                            message["message_id"]?.toString() ?? "";
                        if (originalMessageId.isEmpty) continue;
                        final String? imageUrl =
                            message['originalUrl'] ?? message['imageUrl'];
                        final String? fileUrl =
                            message['fileUrl'] ?? message['originalUrl'];
                        final String? fileType = message['mimeType'] ??
                            message['fileType'] ??
                            message['mimeType'];
                        final String? originalKey =
                            message['originalKey'] ?? message['originalKey'];
                        final String? mimeType = message['mimeType'] ?? "";
                        final bool isVideo = (fileType
                                    ?.toLowerCase()
                                    .startsWith('video/') ??
                                false) ||
                            (fileUrl?.toLowerCase().endsWith('.mp4') ??
                                false) ||
                            (fileUrl?.toLowerCase().endsWith('.mov') ?? false);

                        final content = (message["content"] ?? "").toString();
                        final fileName = message['fileName']?.toString();
                        final contentType = message['contentType'] ??
                            message['ContentType'] ??
                            (isVideo
                                ? 'video'
                                : imageUrl != null
                                    ? 'image'
                                    : 'text');

                        // use a TEMP id only for UI, NOT forward_...
                        final localId =
                            'temp_${DateTime.now().microsecondsSinceEpoch}_${receiverId}';

                        final forwardFingerprint =
                            '${originalMessageId}_${receiverId}';

                        final optimisticMessage = {
                          // 🔑 TEMP LOCAL ID (only for UI)
                          'message_id': localId,

                          // 📝 CONTENT
                          'content': content,
                          'contentType': contentType,

                          // 👤 USERS
                          'senderId': widget.currentUserId,
                          'receiverId': receiverId,
                          'sender': {
                            '_id': widget.currentUserId,
                            'first_name': widget.username,
                          },
                          'receiver': {
                            '_id': receiverId,
                          },

                          // 🎥 MEDIA (SAFE + NORMALIZED)
                          'imageUrl': imageUrl,
                          'originalUrl': imageUrl ?? fileUrl,
                          'fileUrl': fileUrl,
                          'fileName': fileName,
                          'fileType': fileType,
                          'isVideo': isVideo,

                          // ⏳ STATUS
                          'messageStatus': 'sent',
                          'status': 'sent',
                          'time': DateTime.now().toIso8601String(),

                          // ⚡ OPTIMISTIC FLAGS
                          'isOptimistic': true,
                          'forwardFingerprint': forwardFingerprint,

                          // 🔁 FORWARD META
                          'isForwarded': true,
                          'original_message_id': originalMessageId,
                          'forwardedFrom': widget.currentUserId,

                          // 🛡 SAFETY FLAGS
                          'isReplyMessage': false,

                          // 🚫 DO NOT SET GROUPING HERE
                          // ❌ 'group_message_id'
                          // ❌ 'is_grouped_message'
                        };

                        //optimisticMessagesForUI.add(optimisticMessage);
                        print("foewardddd ${widget.isForward}");
                        print("mimeType ${mimeType}");
                        // widget.isForward!
                        //     ? null
                        //     : await _saveOptimisticMessage(
                        //         targetConvoId!, optimisticMessage);

                        // Now call socket forward for this single receiver
                        final imageToSend =
                            (imageUrl != null && imageUrl.isNotEmpty)
                                ? imageUrl
                                : null;

                        final results = await socket.forwardMessage(
                          originalKey: originalKey,
                          mimeType: mimeType,
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
                          image: imageToSend,
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
                    //   Navigator.of(context).pop();
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
                    print(
                        " lastTarget.conversationId ${lastTarget.conversationId}");
                    print(" lastTarget.userId ${lastTarget.userId}");
                    print(" lastTarget.userId ${lastTarget.userId}");
                    print(" lastTarget.firstName ${lastTarget.firstName}");
                    print(" lastTarget.lastName ${lastTarget.lastName}");
                    print(" lastTarget.lastName ${lastTarget.lastName}");
                    log("Optimistic UI messages: ${optimisticMessagesForUI.length}");

                    Navigator.of(context).pop();
                    MyRouter.pushReplace(
                      screen: PrivateChatScreen(
                          initialMessages: optimisticMessagesForUI,
                          key: ValueKey(lastTarget.conversationId),
                          convoId: lastTarget.conversationId ?? "",
                          datumId: lastTarget.userId,
                          receiverId: lastTarget.userId,
                          firstname: lastTarget.firstName,
                          lastname: lastTarget.lastName,
                          userName:
                              "${lastTarget.firstName} ${lastTarget.lastName}",
                          profileAvatarUrl: "",
                          grpChat: false,
                          favourite: false,
                          lastSeen: '',
                          sharedFiles: []),
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

  Widget _buildUserTile(ChatUserlist user, bool isSelected,
      {bool isGroup = false}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedUsers.removeWhere((u) {
              if (user.conversationId != null &&
                  user.conversationId!.isNotEmpty &&
                  u.conversationId != null &&
                  u.conversationId!.isNotEmpty) {
                return u.conversationId == user.conversationId;
              }
              return u.userId == user.userId;
            });
          } else {
            selectedUsers.add(user);
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
          subtitle: isGroup ? null : Text(user.email),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(
        text,
        style: const TextStyle(color: chatColor, fontWeight: FontWeight.w800),
      ),
    );
  }
}