import 'package:flutter/material.dart';

class MessageStatusIcon extends StatelessWidget {
  final String status;

  const MessageStatusIcon({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _getStatusIcon(status),
    );
  }

  Widget _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending_offline':
      case 'pending':
      case 'sending':
        return Icon(Icons.access_time, size: 14); // clock

      case 'sent':
        return Icon(Icons.check, size: 14);       // single tick (grey)
      case 'delivered':
        return Icon(
          Icons.done_all,
          key: const ValueKey('delivered'),
          size: 16,
          color: Colors.grey.shade600,
        );
      case 'read':
        return Icon(
          Icons.done_all,
          key: const ValueKey('read'),
          size: 16,
          color: Colors.blue,
        );
      case 'failed':
        return Icon(Icons.error, size: 14, color: Colors.red);
      default:
        return const SizedBox(key: ValueKey('default'));
    }
  }
}
