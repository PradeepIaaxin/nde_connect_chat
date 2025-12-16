import 'package:flutter/material.dart';

enum NetworkStatus {
  connected,
  disconnected,
  reconnecting,
}

class WhatsAppOfflineBanner extends StatelessWidget {
  final NetworkStatus status;
  final VoidCallback onRetry;

  const WhatsAppOfflineBanner({
    super.key,
    required this.status,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final bool isReconnecting = status == NetworkStatus.reconnecting;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            isReconnecting ? Icons.sync : Icons.wifi_off,
            color: Colors.black54,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isReconnecting
                      ? "Reconnecting to NDE Connect"
                      : "Connecting to NDE Connect",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                if (!isReconnecting)
                  GestureDetector(
                    onTap: onRetry,
                    child: const Text(
                      "Retry now ›",
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else
                  const Text(
                    "Please wait…",
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
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
