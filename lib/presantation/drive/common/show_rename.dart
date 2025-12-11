import 'package:flutter/material.dart';

Future<void> showRenameDialog({
  required BuildContext context,
  required String initialName,
  required void Function(String newName) onRename,
  String title = 'Rename File',
  String hintText = 'Enter new file name',
}) async {
  final TextEditingController _nameController =
      TextEditingController(text: initialName);

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: hintText,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newName = _nameController.text.trim();
              if (newName.isNotEmpty) {
                onRename(newName);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}
