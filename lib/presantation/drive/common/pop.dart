import 'package:flutter/material.dart';

class SortPopupMenu extends StatelessWidget {
  final List<String> sortOptions;
  final String selectedOption;
  final void Function(String) onSelected;
  final String headerText;

  const SortPopupMenu({
    super.key,
    required this.sortOptions,
    required this.selectedOption,
    required this.onSelected,
    this.headerText = 'Sort By',
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: CircleAvatar(
          maxRadius: 15,
          backgroundColor: Colors.grey,
          child: Icon(
            Icons.arrow_upward_outlined,
            color: Colors.white,
            size: 20,
          )),
      onSelected: onSelected,
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem<String>(
            enabled: false,
            child: Text(
              headerText,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const PopupMenuDivider(),
          ...sortOptions.map((String option) {
            return PopupMenuItem<String>(
              value: option,
              child: Row(
                children: [
                  if (selectedOption == option)
                    Icon(Icons.check, color: Colors.blue, size: 18),
                  if (selectedOption != option) SizedBox(width: 18),
                  SizedBox(width: 8),
                  Text(option),
                ],
              ),
            );
          }),
        ];
      },
    );
  }
}
