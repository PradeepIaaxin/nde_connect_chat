import 'package:flutter/material.dart';

class UnreadBadge extends StatelessWidget {
  final int count;

  const UnreadBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(
        minWidth: 20,
        minHeight: 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF25D366),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          count > 99 ? '99+' : count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
