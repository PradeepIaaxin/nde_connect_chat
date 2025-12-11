import 'package:flutter/material.dart';

typedef OnRename = void Function();
typedef OnDeleteList = void Function();
typedef OnDeleteCompleted = void Function();

void showListOptionsBottomSheet({
  required BuildContext context,
  required OnRename onRename,
  required OnDeleteList onDeleteList,
  required OnDeleteCompleted onDeleteCompleted,
  required bool hasCompletedTasks,
}) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Rename List'),
              onTap: () {
                Navigator.pop(context);
                onRename();
              },
            ),
            ListTile(
              title: const Text('Delete List'),
              onTap: () {
                Navigator.pop(context);
                onDeleteList();
              },
            ),
            ListTile(
              title: Text(
                'Delete All Completed Tasks',
                style: TextStyle(
                  color: hasCompletedTasks ? Colors.black : Colors.grey,
                ),
              ),
              onTap: hasCompletedTasks
                  ? () {
                      Navigator.pop(context);
                      onDeleteCompleted();
                    }
                  : null,
            ),
          ],
        ),
      );
    },
  );
}
