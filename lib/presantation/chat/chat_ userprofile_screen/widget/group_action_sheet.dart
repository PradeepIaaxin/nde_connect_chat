import 'package:flutter/material.dart';
import 'package:nde_email/utils/reusbale/common_import.dart';

import 'package:nde_email/presantation/widgets/chat_widgets/messager_Wifgets/ChateHomeMoreOptionsButton.dart';

class GroupActionSheet extends StatelessWidget {
  final VoidCallback? onAddToFavorites;
  final VoidCallback? onAddToList;
  final VoidCallback? onExitGroup;
  final VoidCallback? onReportGroup;
  final bool isGroupChat;
  final String? fullName;
  final bool isFavorite;

  const GroupActionSheet({
    super.key,
    this.onAddToFavorites,
    this.onAddToList,
    this.onExitGroup,
    this.onReportGroup,
    required this.isGroupChat,
    this.fullName,
    required this.isFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isTablet = width > 600;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _buildActionItems(context, isTablet),
        );
      },
    );
  }

  List<Widget> _buildActionItems(BuildContext context, bool isTablet) {
    return [
      _buildActionItem(
        context,
        icon: isFavorite ? Icons.favorite : Icons.favorite_border,
        label: isFavorite ? "Remove from Favorites" : "Add to Favorites",
        onTap: onAddToFavorites,
        color: isFavorite ? Colors.redAccent : Colors.black,
        isTablet: isTablet,
      ),
      // _buildActionItem(
      //   context,
      //   icon: Icons.list_alt_outlined,
      //   label: "Add to list",
      //   onTap: onAddToList,
      //   isTablet: isTablet,
      // ),
      if (isGroupChat) ...[
        _buildActionItem(
          context,
          icon: Icons.exit_to_app,
          label: "Exit group",
          onTap: () {
            MoreOptionsButton.showExitGroupDialog(
              context,
              fullName ?? "Group",
              onExit: onExitGroup,
            );
          },
          color: Colors.redAccent,
          isTablet: isTablet,
        ),
        _buildActionItem(
          context,
          icon: Icons.thumb_down_alt_outlined,
          label: "Report group",
          onTap: () {
            MoreOptionsButton.showReportDialog(context,
                name: fullName ?? "Group", isGroup: true);
          },
          color: Colors.redAccent,
          isTablet: isTablet,
        ),
      ] else ...[
        _buildActionItem(
          context,
          icon: Icons.block,
          label: "Block $fullName",
          onTap: onReportGroup,
          color: Colors.redAccent,
          isTablet: isTablet,
        ),
        _buildActionItem(
          context,
          icon: Icons.thumb_down_alt_outlined,
          label: "Report $fullName",
          onTap: () {
            MoreOptionsButton.showReportDialog(context,
                name: fullName ?? "Contact", isGroup: false);
          },
          color: Colors.redAccent,
          isTablet: isTablet,
        ),
      ],
      const SizedBox(height: 20),
    ];
  }

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    Color color = Colors.black,
    required bool isTablet,
  }) {
    final textSize = isTablet ? 18.0 : 15.0;
    final iconSize = isTablet ? 28.0 : 24.0;
    final paddingV = isTablet ? 18.0 : 14.0;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: paddingV),
        child: Row(
          children: [
            Icon(icon, color: color, size: iconSize),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: color, fontSize: textSize),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
