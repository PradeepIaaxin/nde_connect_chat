import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/GroupChatScreen.dart';
import 'package:nde_email/presantation/chat/chat_list/chat_response_model.dart';
import 'package:nde_email/presantation/chat/chat_list/chat_subtitle_widget.dart';
import 'package:nde_email/presantation/chat/chat_list/chat_trailing_widget.dart';
import 'package:nde_email/presantation/chat/widget/profile_avatar.dart';
import 'package:nde_email/presantation/chat/widget/profile_dialog.dart';
import 'package:nde_email/utils/datetime/text_utils.dart';

import '../chat_ userprofile_screen/User_Profile_Screen.dart';
import '../chat_private_screen/Private_Chat_Screen.dart';

class ChatListTile extends StatelessWidget {
  final Datu chat;
  final int index;
  final bool isSelected;
  final bool isOnline;
  final Color chatColor;
  final String profileAvatarUrl;
  final String profileAvatar;
  final String displayName;
  final String? typingText;

  const ChatListTile({
    super.key,
    required this.chat,
    required this.index,
    required this.isSelected,
    required this.isOnline,
    required this.chatColor,
    required this.profileAvatarUrl,
    required this.profileAvatar,
    required this.displayName,
    this.typingText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isSelected ? chatColor.withOpacity(0.3) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        leading: _buildLeading(context),
        title: _buildTitle(),
        subtitle: typingText != null
            ? _buildTypingSubtitle()
            : ChatSubtitle(chat: chat),
        trailing: ChatTrailing(chat: chat),
      ),
    );
  }

  Widget _buildTypingSubtitle() {
    return Text(
      typingText!,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 13,
        color: Colors.green,
        fontStyle: FontStyle.italic,
      ),
    );
  }
  // ------------------ Leading (Avatar + Status) ------------------

  Widget _buildLeading(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () => _showProfileDialog(context),
          child: Hero(
            transitionOnUserGestures: true,
            tag:
                'prouuufile_hero_archive1_${chat.id ?? ""}_${chat.lastMessageId ?? ""}_$index',
            child: ProfileAvatar(
              imageUrl: profileAvatarUrl,
              name: profileAvatar,
              size: 48,
            ),
          ),
        ),

        // Online indicator
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFF7F7F7),
                  width: 2,
                ),
              ),
            ),
          ),

        // Selected check
        if (isSelected)
          Positioned(
            right: -4,
            top: 30,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: chatColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
      ],
    );
  }

  // ------------------ Title ------------------

  Widget _buildTitle() {
    return Text(
      TextUtils.capitalizeWords(displayName),
      //   displayName.(),
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: Colors.black,
      ),
    );
  }

  // ------------------ Profile Dialog ------------------

  void _showProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => ProfileDialog(
        tag: 'p00rofile_hero_profiledialog_${chat.id}',
        imageUrl: profileAvatarUrl,
        fallbackText: profileAvatar,
        userName: chat.firstName ?? "",
        groupName: chat.name ?? "",
        actions: [
          /// ✅ OPEN CHAT SCREEN
          ProfileAction(
            icon: Icons.chat,
            label: 'Chat',
            onTap: () {
              Navigator.pop(context); // close dialog

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => chat.isGroupChat == true
                      ? GroupChatScreen(
                          groupName: chat.name ?? 'Group Chat',
                          groupAvatarUrl: profileAvatarUrl,
                          groupMembers: chat.participants?.cast<String>() ?? [],
                          currentUserId: "", // pass real userId
                          conversationId: chat.id ?? "",
                          datumId: chat.datumId ?? "",
                          grpChat: true,
                          favorite: chat.isFavourite ?? false,
                          groupId: chat.groupId,
                        )
                      : PrivateChatScreen(
                          userName: displayName,
                          profileAvatarUrl: profileAvatarUrl,
                          sharedFiles: const [],
                          lastSeen: chat.lastMessageTime?.toString() ?? "",
                          convoId: chat.id ?? "",
                          datumId: chat.datumId,
                          firstname: chat.firstName,
                          receiverId: chat.reciverId,
                          grpChat: false,
                          lastname: chat.lastName,
                          favourite: chat.isFavourite ?? false,
                        ),
                ),
              );
            },
          ),

          /// ✅ CALL (ADD YOUR SCREEN)
          ProfileAction(
            icon: Icons.call,
            label: 'Call',
            onTap: () {
              Navigator.pop(context);
              debugPrint("Call tapped ${chat.id}");
            },
          ),

          /// ✅ VIDEO CALL
          ProfileAction(
            icon: Icons.videocam,
            label: 'Video',
            onTap: () {
              Navigator.pop(context);
              debugPrint("Video tapped ${chat.id}");
            },
          ),

          /// ✅ OPEN PROFILE / INFO SCREEN
          ProfileAction(
            icon: Icons.info,
            label: 'Info',
            onTap: () {
              log(chat.toString());
              Navigator.pop(context);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserProfileScreen(
                    profileAvatarUrl: chat.isGroupChat == true
                        ? chat.profilePic ?? ""
                        : chat.profilePic ?? "",
                    userName: chat.isGroupChat == true
                        ? chat.name ?? "Group"
                        : chat.firstName ?? "",
                    mailName:
                        chat.isGroupChat == true ? "" : chat.lastName ?? "",
                    lastname:
                        chat.isGroupChat == true ? "" : chat.lastName ?? "",
                    conversionalId: chat.conversationId ?? "",
                    grpId: chat.groupId,
                    isGrp: chat.isGroupChat ?? false,
                    reciverId:
                        chat.isGroupChat == true ? "" : chat.reciverId ?? "",
                    favourite: chat.isFavourite ?? false,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
