import 'package:flutter/material.dart';
import 'package:nde_email/utils/reusbale/common_import.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _buildActionItems(),
    );
  }

  List<Widget> _buildActionItems() {
    return [
      _buildActionItem(
        icon: isFavorite ? Icons.favorite : Icons.favorite_border,
        label: isFavorite ? "Remove from Favorites" : "Add to Favorites",
        onTap: onAddToFavorites,
        color: isFavorite ? Colors.redAccent : Colors.black,
      ),
      _buildActionItem(
        icon: Icons.list_alt_outlined,
        label: "Add to list",
        onTap: onAddToList,
      ),
      if (isGroupChat) ...[
        _buildActionItem(
          icon: Icons.exit_to_app,
          label: "Exit group",
          onTap: onExitGroup,
          color: Colors.redAccent,
        ),
        _buildActionItem(
          icon: Icons.thumb_down_alt_outlined,
          label: "Report group",
          onTap: onReportGroup,
          color: Colors.redAccent,
        ),
      ] else ...[
        _buildActionItem(
          icon: Icons.block,
          label: "Block $fullName",
          onTap: onReportGroup,
          color: Colors.redAccent,
        ),
        _buildActionItem(
          icon: Icons.thumb_down_alt_outlined,
          label: "Report $fullName",
          onTap: onReportGroup,
          color: Colors.redAccent,
        ),
      ],
    ];
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    Color color = Colors.black,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 25),
            const SizedBox(width: 16),
            Text(label, style: TextStyle(color: color, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
