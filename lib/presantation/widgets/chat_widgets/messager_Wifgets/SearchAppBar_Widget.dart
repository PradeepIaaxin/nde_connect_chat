import 'package:flutter/material.dart';

class SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onBack;

  const SearchAppBar({
    Key? key,
    required this.onBack,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            print("Back pressed");
            onBack();
          }
          // onBack,
          ),
      title: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: TextFormField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search...',
            hintStyle: const TextStyle(color: Colors.grey),
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            filled: true,
            fillColor: Colors.grey[200],
            contentPadding:
                const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.arrow_upward_outlined, color: Colors.black),
          onPressed: () {
            // Upward action
          },
        ),
        IconButton(
          icon: const Icon(Icons.arrow_downward_outlined, color: Colors.black),
          onPressed: () {
            // Downward action
          },
        ),
      ],
    );
  }
}
