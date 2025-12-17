import 'package:flutter/material.dart';
import 'package:nde_email/presantation/chat/chat_list/chat_response_model.dart';
import 'package:nde_email/presantation/chat/chat_list/unread_badge.dart';
import 'package:nde_email/utils/datetime/date_time_utils.dart';

class ChatTrailing extends StatelessWidget {
  final Datu chat;

  const ChatTrailing({
    super.key,
    required this.chat,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildTime(),
        const SizedBox(height: 6),
        _buildIconsAndUnread(),
      ],
    );
  }

  Widget _buildTime() {
    return Text(
      chat.lastMessageTime != null
          ? DateTimeUtils.formatMessageTime(chat.lastMessageTime!)
          : "",
      style: TextStyle(
        fontSize: 12,
        color: chat.unreadCount != null && chat.unreadCount! > 0
            ? const Color(0xFF25D366)
            : Colors.grey,
      ),
    );
  }

  Widget _buildIconsAndUnread() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (chat.isPinned == true)
          const Icon(Icons.push_pin, color: Colors.grey, size: 16),

        if (chat.isArchived == true)
          const Icon(Icons.archive, color: Colors.grey, size: 16),

        if (chat.unreadCount != null && chat.unreadCount! > 0)
          UnreadBadge(count: chat.unreadCount!),
      ],
    );
  }
}
