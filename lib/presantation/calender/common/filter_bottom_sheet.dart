import 'package:flutter/material.dart';

enum FilterOption { myOrder, byDate, starredRecent }

typedef Myorder = void Function();
typedef OnDate = void Function();
typedef OnStarredRecent = void Function();

void showListFilterOption({
  required BuildContext context,
  required Myorder onMyOrder,
  required OnDate onByDate,
  required OnStarredRecent onStarredRecent,
  required FilterOption selectedOption,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Sort by",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            ListTile(
              title: const Text('My Order'),
              leading: selectedOption == FilterOption.myOrder
                  ? const Icon(Icons.check, color: Colors.blue)
                  : SizedBox(
                      width: 25,
                    ),
              onTap: () {
                Navigator.pop(context);
                onMyOrder();
              },
            ),
            ListTile(
              title: const Text('By Date'),
              leading: selectedOption == FilterOption.byDate
                  ? const Icon(Icons.check, color: Colors.blue)
                  : SizedBox(
                      width: 25,
                    ),
              onTap: () {
                Navigator.pop(context);
                onByDate();
              },
            ),
            ListTile(
                title: Text(
                  'Starred Recently',
                  style: TextStyle(
                    color: Colors.black,
                  ),
                ),
                leading: selectedOption == FilterOption.starredRecent
                    ? const Icon(Icons.check, color: Colors.blue)
                    : SizedBox(
                        width: 25,
                      ),
                onTap: () {
                  Navigator.pop(context);
                  onStarredRecent();
                }),
          ],
        ),
      );
    },
  );
}
