import 'package:flutter/material.dart';

class CustomAppBarWidget extends StatelessWidget
    implements PreferredSizeWidget {
  final String lastSendTime;

  const CustomAppBarWidget({
    Key? key,
    required this.lastSendTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      leading: const Padding(
        padding: EdgeInsets.only(left: 16.0),
        child: Center(
          child: Text(
            'SendIt',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ),
      leadingWidth: 100,
      title: Text(
        'Last sent: $lastSendTime',
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 14,
        ),
      ),
      centerTitle: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.star_border_outlined, color: Colors.black),
          onPressed: () {
            // Handle start action
          },
        ),
        IconButton(
          icon: const Icon(Icons.forward_5_outlined, color: Colors.black),
          onPressed: () {
            // Handle forward action
          },
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.black),
          onPressed: () {
            // Handle more options
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
