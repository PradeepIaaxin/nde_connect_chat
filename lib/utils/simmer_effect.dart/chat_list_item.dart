import 'package:flutter/material.dart';
import 'package:nde_email/presantation/chat/chat_list/chat_screen.dart';
import 'package:nde_email/presantation/chat/widget/profile_dialog.dart';
import 'package:nde_email/utils/reusbale/colour_utlis.dart';
import 'package:nde_email/utils/reusbale/common_import.dart';
import 'package:shimmer/shimmer.dart';

class ChatListItem extends StatelessWidget {
  final ChatItemData chat;
  final bool isOnline;
  final bool isSelected;
  final bool longPressed;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Color chatColor;
  final List<String> onlineUsers;

  const ChatListItem({
    super.key,
    required this.chat,
    required this.isOnline,
    required this.isSelected,
    required this.longPressed,
    required this.onTap,
    required this.onLongPress,
    required this.chatColor,
    required this.onlineUsers,
  });

  @override
  Widget build(BuildContext context) {
    final profileAvatarUrl =
        chat.profilePic?.isNotEmpty == true ? chat.profilePic! : '';
    final profileAvatar = profileAvatarUrl.isNotEmpty
        ? profileAvatarUrl
        : (chat.name?.isNotEmpty == true ? chat.name![0].toUpperCase() : 'U');

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        color: isSelected ? chatColor.withOpacity(0.3) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => ProfileDialog(
                          tag: 'bkjn_cahtlist${chat.id}',
                          imageUrl: profileAvatarUrl,
                          fallbackText: profileAvatar,
                          actions: [
                            ProfileAction(
                                icon: Icons.chat, label: 'Chat', onTap: () {}),
                            ProfileAction(
                                icon: Icons.call, label: 'Call', onTap: () {}),
                            ProfileAction(
                                icon: Icons.videocam,
                                label: 'Video',
                                onTap: () {}),
                            ProfileAction(
                                icon: Icons.info, label: 'Info', onTap: () {}),
                          ],
                          userName: chat.firstName ?? "",
                          groupName: chat.name ?? "",
                        ),
                      );
                    },
                    child: Hero(
                      transitionOnUserGestures: true,
                      tag: '9iprofile_hero_chatList_${chat.id}',
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: profileAvatarUrl.isEmpty
                            ? ColorUtil.getColorFromAlphabet(profileAvatar)
                            : Colors.transparent,
                        child: _buildAvatarContent(
                          profileAvatarUrl: profileAvatarUrl,
                          profileAvatar: profileAvatar,
                        ),
                      ),
                    ),
                  ),
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
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      (chat.firstName?.isNotEmpty == true &&
                              chat.lastName?.isNotEmpty == true)
                          ? "${chat.firstName} ${chat.lastName}"
                          : (chat.name?.isNotEmpty == true
                              ? chat.name!
                              : "Unknown"),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  children: [
                    if (chat.contentType == "image") ...[
                      const Icon(Icons.image, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      const Text("Image", style: TextStyle(fontSize: 14)),
                    ] else if (chat.contentType == "file" ||
                        (chat.mimeType?.contains("pdf") ?? false)) ...[
                      const Icon(Icons.insert_drive_file,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          chat.fileName?.isNotEmpty == true
                              ? chat.fileName!
                              : "Document",
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ] else if (chat.contentType == "audio") ...[
                      const Icon(Icons.mic, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      const Text("Audio", style: TextStyle(fontSize: 14)),
                    ] else if (chat.contentType == "video") ...[
                      const Icon(Icons.videocam, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      const Text("Video", style: TextStyle(fontSize: 14)),
                    ] else ...[
                      Expanded(
                        child: Text(
                          chat.lastMessage?.isNotEmpty == true
                              ? chat.lastMessage!
                              : "No message",
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (chat.isPinned == true)
                        const Icon(Icons.push_pin,
                            color: Colors.grey, size: 16),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarContent({
    required String profileAvatarUrl,
    required String profileAvatar,
  }) {
    if (profileAvatarUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          profileAvatarUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Text(
              profileAvatar,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
      );
    } else {
      return Text(
        profileAvatar,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      );
    }
  }
}

class ChatListItemShimmer extends StatelessWidget {
  const ChatListItemShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Circle avatar
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            // Text shimmer
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: 120,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: double.infinity,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  height: 10,
                  width: 30,
                  color: Colors.white,
                ),
                const SizedBox(height: 10),
                Container(
                  height: 16,
                  width: 16,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class ChatItemData {
  final String? profilePic;
  final String? name;
  final String? datumId;
  final String? id;
  final bool? isGroupChat;
  final String? firstName;
  final String? lastName;
  final String? lastMessageTime;
  final String? contentType;
  final String? mimeType;
  final String? fileName;
  final String? lastMessage;
  final bool? isPinned;
  final bool? isArchived;
  final int? unreadCount;
  final bool? isFavorites;

  ChatItemData({
    this.profilePic,
    this.name,
    this.datumId,
    this.id,
    this.isGroupChat,
    this.firstName,
    this.lastName,
    this.lastMessageTime,
    this.contentType,
    this.mimeType,
    this.fileName,
    this.lastMessage,
    this.isPinned,
    this.isArchived,
    this.unreadCount,
    this.isFavorites,
  });
}
