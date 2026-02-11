import 'package:flutter/material.dart';

class TrashActions extends StatelessWidget {
  final bool show;
  final String mailboxId;

  const TrashActions({
    super.key,
    required this.show,
    required this.mailboxId,
  });

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F4F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          "Items in bin auto-delete after 30 days.",
        ),
      ),
    );
  }
}
