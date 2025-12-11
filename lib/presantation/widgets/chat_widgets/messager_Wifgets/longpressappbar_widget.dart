import 'package:flutter/material.dart';
import 'package:nde_email/utils/spacer/spacer.dart';

class LongPressAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final VoidCallback? onReplayPressed;
  final VoidCallback? onStarPressed;
  final VoidCallback? onDeletePressed;
  final VoidCallback? onForwardPressed;
  final List<PopupMenuEntry<String>>? additionalMenuItems;

  const LongPressAppBar({
    super.key,
    required this.title,
    this.onBackPressed,
    this.onReplayPressed,
    this.onStarPressed,
    this.onDeletePressed,
    this.onForwardPressed,
    this.additionalMenuItems,
  });

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBackPressed,
      ),
      title: Text(title),
      actions: [
        if (onReplayPressed != null)
          IconButton(
            icon: Icon(Icons.reply),
            onPressed: onReplayPressed,
          ),
        hSpace8,
        if (onStarPressed != null)
          IconButton(
            icon: const Icon(Icons.star_border),
            onPressed: onStarPressed,
          ),
        hSpace8,
        if (onDeletePressed != null)
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: onDeletePressed,
          ),
        hSpace8,
        if (onForwardPressed != null)
          GestureDetector(
            onTap: onForwardPressed,
            child: Image.asset(
              "assets/images/forward.png",
              height: 20,
              width: 20,
            ),
          ),
        hSpace8,
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (String value) {
            switch (value) {
              case 'Copy':
                break;
              case 'Pin':
                break;
              case 'Report':
                break;
            }
          },
          itemBuilder: (BuildContext context) {
            return [
              const PopupMenuItem(
                value: 'Copy',
                child: Text('Copy'),
              ),
              const PopupMenuItem(
                value: 'Pin',
                child: Text('Pin'),
              ),
              const PopupMenuItem(
                value: 'Report',
                child: Text('Report'),
              ),
              if (additionalMenuItems != null) ...additionalMenuItems!,
            ];
          },
        ),
      ],
    );
  }
}
