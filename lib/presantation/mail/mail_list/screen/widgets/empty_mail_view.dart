import 'package:flutter/material.dart';

class EmptyMailView extends StatelessWidget {
  final String mailboxId;
  final String? mailboxName;
  final Future<void> Function() onRefresh;

  const EmptyMailView({
    super.key,
    required this.mailboxId,
    required this.mailboxName,
    required this.onRefresh,
  });

  String get title {
    final name = mailboxName?.toLowerCase() ?? '';
    if (name == 'inbox') return 'No inbox mails';
    if (name == 'sent') return 'No sent mails';
    if (name == 'trash') return 'No trash mails';
    return 'No mails available';
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/empty_mailbox.png',
                  width: 300,
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
