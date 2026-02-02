import 'package:flutter/material.dart';

class SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onBack;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onUpPressed;
  final VoidCallback? onDownPressed;
  final int matchCount;
  final int currentIndex;

  const SearchAppBar({
    Key? key,
    required this.onBack,
    this.controller,
    this.onChanged,
    this.onUpPressed,
    this.onDownPressed,
    this.matchCount = 0,
    this.currentIndex = 1,
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
        onPressed: onBack,
      ),
      title: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: controller,
              onChanged: onChanged,
              autofocus: true,
              style: const TextStyle(color: Colors.black, fontSize: 16),
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

        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.arrow_upward_outlined, color: Colors.black),
          onPressed: matchCount > 0 ? onUpPressed : null,
        ),
        IconButton(
          icon: const Icon(Icons.arrow_downward_outlined, color: Colors.black),
          onPressed: matchCount > 0 ? onDownPressed : null,
        ),
      ],
    );
  }
}
