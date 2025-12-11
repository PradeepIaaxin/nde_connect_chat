import 'package:flutter/material.dart';

class UserActionDialog {
  static void show(
    BuildContext context, {
    required String name,
    required bool isAdmin,
    required VoidCallback onMessage,
    required VoidCallback onView,
    required VoidCallback onToggleAdmin,
    required VoidCallback onRemove,
    required VoidCallback onVerify,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionItem(context, "Message $name", () {
              Navigator.pop(context);
              onMessage();
            }),
            _buildActionItem(context, "View $name", () {
              Navigator.pop(context);
              onView();
            }),
            _buildActionItem(
                context, isAdmin ? "Dismiss as admin" : "Add as admin", () {
              Navigator.pop(context);
              onToggleAdmin();
            }),
            _buildActionItem(context, "Remove $name", () {
              Navigator.pop(context);
              onRemove();
            }),
            _buildActionItem(context, "Verify security code", () {
              Navigator.pop(context);
              onVerify();
            }),
          ],
        ),
      ),
    );
  }

  static Widget _buildActionItem(
      BuildContext context, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.black, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
