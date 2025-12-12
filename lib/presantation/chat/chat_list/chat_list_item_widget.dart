import 'package:flutter/material.dart';
import 'package:nde_email/presantation/chat/chat_list/chat_response_model.dart';
import 'package:nde_email/presantation/chat/widget/profile_avatar.dart';
import 'package:nde_email/utils/reusbale/colour_utlis.dart';
import 'package:nde_email/utils/datetime/date_time_utils.dart';
import 'package:nde_email/utils/const/consts.dart';

class ChatListTileReusable extends StatelessWidget {
  final Datu chat;
  final bool isSelected;
  final bool isOnline;

  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onAvatarTap;

  const ChatListTileReusable({
    super.key,
    required this.chat,
    required this.isSelected,
    required this.isOnline,
    required this.onTap,
    required this.onLongPress,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final profileAvatarUrl =
        chat.profilePic?.isNotEmpty == true ? chat.profilePic! : '';
    final profileAvatar = profileAvatarUrl.isEmpty
        ? (chat.name?.isNotEmpty == true ? chat.name![0].toUpperCase() : 'U')
        : profileAvatarUrl;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        color: isSelected ? chatColor.withOpacity(0.3) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              // Avatar
              GestureDetector(
                onTap: onAvatarTap,
                child: Hero(
                  transitionOnUserGestures: true,
                  tag: "uiui_${chat.id}",
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: profileAvatarUrl.isEmpty
                        ? ColorUtil.getColorFromAlphabet(profileAvatar)
                        : Colors.transparent,
                    child: ProfileAvatar(
                      imageUrl: profileAvatarUrl,
                      name: profileAvatar,
                      size: 48,
                    ),
                  ),
                ),
              ),

              // Online Indicator
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
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),

              // Selected Tick
              if (isSelected)
                Positioned(
                  right: -4,
                  top: 30,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: chatColor,
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.check, size: 14, color: Colors.white),
                  ),
                ),
            ],
          ),
          title: Text(
            chat.firstName?.isNotEmpty == true &&
                    chat.lastName?.isNotEmpty == true
                ? "${chat.firstName} ${chat.lastName}"
                : (chat.name ?? "Unknown"),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: _buildSubtitle(chat),
          trailing: _buildTrailing(chat),
        ),
      ),
    );
  }

  // 🟦 Subtitle UI (same as yours)
  Widget _buildSubtitle(Datu chat) {
    if (chat.contentType == "image") {
      return const Row(
        children: [
          Icon(Icons.image, size: 16, color: Colors.grey),
          SizedBox(width: 4),
          Text("Image", style: TextStyle(fontSize: 14)),
        ],
      );
    }

    if (chat.contentType == "file" ||
        (chat.mimeType?.contains("pdf") ?? false)) {
      return Row(
        children: [
          const Icon(Icons.insert_drive_file, size: 16, color: Colors.grey),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              chat.fileName?.isNotEmpty == true ? chat.fileName! : "Document",
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      );
    }

    if (chat.contentType == "audio") {
      return const Row(
        children: [
          Icon(Icons.mic, size: 16, color: Colors.grey),
          SizedBox(width: 4),
          Text("Audio", style: TextStyle(fontSize: 14)),
        ],
      );
    }

    if (chat.contentType == "video") {
      return const Row(
        children: [
          Icon(Icons.videocam, size: 16, color: Colors.grey),
          SizedBox(width: 4),
          Text("Video", style: TextStyle(fontSize: 14)),
        ],
      );
    }

    return Text(
      chat.lastMessage?.isNotEmpty == true ? chat.lastMessage! : "No message",
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(color: Colors.grey, fontSize: 14),
    );
  }

  // 🟦 Trailing UI (same as yours)
  Widget _buildTrailing(Datu chat) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          chat.lastMessageTime != null
              ? DateTimeUtils.formatMessageTime(chat.lastMessageTime!)
              : "",
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (chat.isPinned == true)
              const Icon(Icons.push_pin, color: Colors.grey, size: 16),
            if (chat.isArchived == true)
              const Icon(Icons.archive, color: Colors.grey, size: 16),
            if (chat.unreadCount != null && chat.unreadCount! > 0)
              Container(
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF25D366),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    chat.unreadCount! > 99
                        ? '99+'
                        : chat.unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
