import 'package:flutter/material.dart';

class MessageStatusIcon extends StatelessWidget {
  final String status;
  final bool? isStatus;

  const MessageStatusIcon({
    super.key,
    required this.status,
    this.isStatus = false,
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
      case 'pending':
      case 'sending':
        return Icon(Icons.access_time, size: 14); // clock

      case 'sent':
        return Icon(
          Icons.check,
          size: 14,
          color: Colors.grey.shade600,
        ); // single tick (grey)
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
          color: isStatus! ? Colors.white : Colors.blue,
        );
      case 'failed':
      case 'pending_offline':
        return Container(
          key: const ValueKey('error'),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.priority_high,
            size: 12,
            color: Colors.white,
          ),
        );
      default:
        return const SizedBox(key: ValueKey('default'));
    }
  }
}