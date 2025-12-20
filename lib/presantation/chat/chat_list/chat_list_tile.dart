import 'package:flutter/material.dart';
import 'package:nde_email/presantation/chat/chat_list/chat_response_model.dart';
import 'package:nde_email/presantation/chat/chat_list/chat_subtitle_widget.dart';
import 'package:nde_email/presantation/chat/chat_list/chat_trailing_widget.dart';
import 'package:nde_email/presantation/chat/widget/profile_avatar.dart';
import 'package:nde_email/presantation/chat/widget/profile_dialog.dart';
import 'package:nde_email/utils/datetime/text_utils.dart';
import 'package:nde_email/utils/reusbale/colour_utlis.dart';

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
            child: CircleAvatar(
                radius: 24,
                backgroundColor: profileAvatarUrl.isEmpty
                    ? ColorUtil.getColorFromAlphabet(profileAvatar)
                    : Colors.transparent,
                child: ProfileAvatar(
                  imageUrl: profileAvatarUrl,
                  name: chat.name,
                  size: 48,
                )),
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
          ProfileAction(icon: Icons.chat, label: 'Chat', onTap: () {}),
          ProfileAction(icon: Icons.call, label: 'Call', onTap: () {}),
          ProfileAction(icon: Icons.videocam, label: 'Video', onTap: () {}),
          ProfileAction(icon: Icons.info, label: 'Info', onTap: () {}),
        ],
      ),
    );
  }
}
