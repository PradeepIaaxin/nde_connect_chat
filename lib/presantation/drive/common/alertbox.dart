import 'package:flutter/material.dart';

enum FileConflictOption { replace, keepBoth }

class FileConflictDialog extends StatefulWidget {
  final String title;
  final void Function(FileConflictOption) onConfirmed;

  const FileConflictDialog({
    super.key,
    required this.title,
    required this.onConfirmed,
  });

  @override
  State<FileConflictDialog> createState() => _FileConflictDialogState();
}

class _FileConflictDialogState extends State<FileConflictDialog> {
  FileConflictOption _selectedOption = FileConflictOption.replace;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioListTile<FileConflictOption>(
            title: const Text('Replace'),
            value: FileConflictOption.replace,
            groupValue: _selectedOption,
            onChanged: (value) {
              setState(() {
                _selectedOption = value!;
              });
            },
          ),
          RadioListTile<FileConflictOption>(
            title: const Text('Keep Both'),
            value: FileConflictOption.keepBoth,
            groupValue: _selectedOption,
            onChanged: (value) {
              setState(() {
                _selectedOption = value!;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onConfirmed(_selectedOption);
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}
