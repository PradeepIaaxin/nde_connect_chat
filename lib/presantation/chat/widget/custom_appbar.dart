import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nde_email/presantation/chat/Socket/socket_service.dart';
import 'package:nde_email/presantation/chat/chat_%20userprofile_screen/user_profile_screen.dart';
import 'package:nde_email/presantation/widgets/chat_widgets/messager_Wifgets/ChateHomeMoreOptionsButton.dart';
import 'package:nde_email/presantation/widgets/chat_widgets/messager_Wifgets/SearchAppBar_Widget.dart'
    show SearchAppBar;
import 'package:nde_email/presantation/widgets/chat_widgets/messager_Wifgets/longpressappbar_widget.dart';
import 'package:nde_email/utils/const/consts.dart';
import 'package:nde_email/utils/reusbale/colour_utlis.dart';
import 'package:nde_email/utils/router/router.dart';
import 'package:nde_email/utils/spacer/spacer.dart';
import 'package:share_plus/share_plus.dart';

class CommonAppBarBuilder {
  static PreferredSizeWidget build({
    required BuildContext context,
    required bool showSearchAppBar,
    required bool isSelectionMode,
    required List<dynamic> selectedMessages,
    required VoidCallback toggleSelectionMode,
    required VoidCallback deleteSelectedMessages,
    required VoidCallback forwardSelectedMessages,
    required VoidCallback starSelectedMessages,
    required Function(Map<String, dynamic>) replyToMessage,
    required String profileAvatarUrl,
    required String convertionId,
    String? userName,
    String? firstname,
    String? lastname,
    String? lastSeen,
     required bool hasLeftGroup, 
    required String grpId,
    required String resvID,
    required bool grpChat,
    required List<String> groupMembers,
    required bool favouitre,
    required VoidCallback onSearchTap,
    required VoidCallback onCloseSearch,
  }) {
    if (showSearchAppBar) {
      return SearchAppBar(
        onBack: () {
          onCloseSearch();
        },
      );
    }

    if (isSelectionMode) {
      return LongPressAppBar(
        title: '${selectedMessages.length} selected',
        onBackPressed: hasLeftGroup == true ? null : toggleSelectionMode,
        onDeletePressed: hasLeftGroup == true ? null :   deleteSelectedMessages,
        onForwardPressed: hasLeftGroup == true ? null :  forwardSelectedMessages,
        onStarPressed: hasLeftGroup == true ? null :  starSelectedMessages,
        onReplayPressed:  selectedMessages.length == 1
            ? () => replyToMessage(selectedMessages.first)
            : null,
        additionalMenuItems: [
          PopupMenuItem(
            value: 'Share',
            child: const Text('Share'),
            onTap: () async {
              await Future.delayed(
                  const Duration(milliseconds: 300));
              log("All selected messages:\n${jsonEncode(selectedMessages)}");

              final textToShare =
              selectedMessages.map((message) {
                if (message['content']
                    ?.toString()
                    .trim()
                    .isNotEmpty ??
                    false) {
                  return message['content'];
                } else if (message['imageUrl']
                    ?.toString()
                    .trim()
                    .isNotEmpty ??
                    false) {
                  return message['imageUrl'];
                } else if (message['fileUrl']
                    ?.toString()
                    .trim()
                    .isNotEmpty ??
                    false) {
                  return "${message['fileName'] ?? 'Document'}:\n${message['fileUrl']}";
                } else {
                  return '';
                }
              }).join('\n\n');

              if (textToShare.trim().isNotEmpty) {
                Share.share(textToShare);
              } else {
                log("Nothing to share.");
              }
            },
          ),
        ],
      );
    }

    final initials = (userName != null &&
        userName.isNotEmpty)
        ? userName[0].toUpperCase()
        : 'U';

    final avatarColor =
    ColorUtil.getColorFromAlphabet(userName ?? "");

    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shadowColor: Colors.white,
      scrolledUnderElevation: 0.0,
      leadingWidth: 90,
      leading: Row(
        children: [
          IconButton(
            onPressed: (){
              if (Navigator.canPop(context)) {
  Navigator.pop(context);
}
            },
            icon: const Icon(Icons.arrow_back),
          ),
          GestureDetector(
            onTap: () {
              MyRouter.push(
                screen: UserProfileScreen(
                  profileAvatarUrl: profileAvatarUrl,
                  userName: firstname ?? "",
                  mailName: userName ?? "",
                  lastname: lastname,
                  conversionalId: convertionId,
                  grpId: grpId,
                  isGrp: grpChat,
                  reciverId: resvID,
                  favourite: favouitre,
                ),
              );
            },
            child: CircleAvatar(
              maxRadius: 20,
              backgroundColor: Colors.grey[300],
              child: profileAvatarUrl.isNotEmpty
                  ? ClipOval(
                child: Image.network(
                  profileAvatarUrl,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) {
                    return Container(
                      color: avatarColor,
                      alignment: Alignment.center,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              )
                  : Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: avatarColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      centerTitle: false,
      title: GestureDetector(
        onTap: () {
          MyRouter.push(
            screen: UserProfileScreen(
              profileAvatarUrl: profileAvatarUrl,
              userName: firstname ?? "",
              mailName: userName ?? "",
              lastname: lastname,
              conversionalId: convertionId,
              grpId: grpId,
              isGrp: grpChat,
              reciverId: resvID,
              favourite: favouitre,
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${firstname ?? ''} ${lastname ?? ''}",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            vSpace4,

            // 🔥 Presence + typing logic
            StreamBuilder<Map<String, dynamic>>(
              // we only care about rebuilds, not the data
              stream: SocketService().userStatusStream,
              builder: (context, statusSnapshot) {
                // Is this specific user online?
                final isUserOnline = SocketService().onlineUsers.contains(resvID);

             


                return StreamBuilder<Map<String, dynamic>>(
                  stream: SocketService().typingStream,
                  builder: (context, typingSnapshot) {
                    final typingMessage = typingSnapshot.data?['message'] as String? ?? '';
                    final isTyping = typingMessage.isNotEmpty;

                    if (isTyping) {
                      return Text(
                        typingMessage,
                        style: const TextStyle(
                          fontSize: 12,
                          color: chatColor,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }

                    // Group Chat Online Status
                    if (grpChat) {
                      final onlineCount = groupMembers
                          .where(
                              (id) => SocketService().onlineUsers.contains(id))
                          .length;
                      if (onlineCount > 0) {
                        return Text(
                          "$onlineCount online",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      } else {
                        return const Text(
                          "Tap here for group info",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        );
                      }
                    }

                    // Private Chat Online Status
                    if (isUserOnline) {
                      return const Text(
                        "Online",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    } else if ((lastSeen ?? '')
                        .isNotEmpty) {
                      return Text(
                     //   "Last seen: $lastSeen",
                        "Offline",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      );
                    } else {
                      return const Text(
                        "No activity",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      );
                    }
                  },
                );
              }
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => MyRouter.pop(context),
          icon: Icon(Icons.videocam_outlined,size: 28,),
        ),
        IconButton(
          onPressed: () => MyRouter.pop(context),
          icon: Icon(Icons.call_outlined),
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            MoreOptionsButton.showMainMenu(
              context,
              profileAvatarUrl: profileAvatarUrl,
              userName: firstname ?? "",
              mailName: userName ?? "",
              lastname: lastname ?? "",
              coverstionId: convertionId,
              grpId: grpId,
              resvId: resvID,
              grpChat: grpChat,
              favouite: favouitre,
              onSearchTap: onSearchTap,

              
            );
          },
        ),
      ],
    );
  }
}
