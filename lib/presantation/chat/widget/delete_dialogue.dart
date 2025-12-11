import 'package:flutter/material.dart';
import 'package:nde_email/utils/reusbale/common_import.dart';

class DeleteMessageDialog {
  static Future<void> show({
    required BuildContext context,
    required VoidCallback onDeleteForEveryone,
    required VoidCallback onDeleteForMe,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            "Delete message?",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                onDeleteForEveryone();
              },
              child: const Text(
                "Delete for Everyone",
                style: TextStyle(color: chatColor),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                onDeleteForMe();
              },
              child: const Text(
                "Delete for Me",
                style: TextStyle(color: chatColor),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                "Cancel",
                style: TextStyle(color: chatColor),
              ),
            ),
          ],
        );
      },
    );
  }
}
