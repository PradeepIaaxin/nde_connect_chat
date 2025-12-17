import 'dart:async';
import 'package:flutter/material.dart';

enum NetworkStatus {
  connected,
  disconnected,
  reconnecting,
}

class WhatsAppOfflineBanner extends StatefulWidget {
  final NetworkStatus status;
  final VoidCallback onRetry;

  const WhatsAppOfflineBanner({
    super.key,
    required this.status,
    required this.onRetry,
  });

  @override
  State<WhatsAppOfflineBanner> createState() =>
      _WhatsAppOfflineBannerState();
}

class _WhatsAppOfflineBannerState extends State<WhatsAppOfflineBanner> {
  Timer? _waitTimer;
  bool _isWaiting = false;

  void _handleRetry() {
    if (_isWaiting) return;

    widget.onRetry(); // trigger reconnect

    setState(() => _isWaiting = true);

    _waitTimer?.cancel();
    _waitTimer = Timer(const Duration(seconds: 5), () {
      if (widget.status != NetworkStatus.connected) {
        setState(() => _isWaiting = false);
      }
    });
  }

  @override
  void didUpdateWidget(covariant WhatsAppOfflineBanner oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If connected before 5 sec → stop waiting
    if (widget.status == NetworkStatus.connected && _isWaiting) {
      _waitTimer?.cancel();
      setState(() => _isWaiting = false);
    }
  }

  @override
  void dispose() {
    _waitTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isReconnecting =
        widget.status == NetworkStatus.reconnecting || _isWaiting;

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
                if (!_isWaiting)
                  GestureDetector(
                    onTap: _handleRetry,
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
