
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BottomBarWidget extends StatelessWidget {
  final Function() onReplyPressed;
  final Function() onEmojiPressed;

  const BottomBarWidget({
    Key? key,
    required this.onReplyPressed,
    required this.onEmojiPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side - Emoji button
          IconButton(
            icon: const Icon(Icons.emoji_emotions_outlined),
            onPressed: onEmojiPressed,
            tooltip: 'Open emoji picker',
          ),

          // Right side - Reply button with text
          TextButton.icon(
            onPressed: onReplyPressed,
            icon: const Icon(Icons.reply),
            label: const Text('Reply'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            ),
          ),
        ],
      ),
    );
  }
}