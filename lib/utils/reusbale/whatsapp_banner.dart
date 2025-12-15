import 'package:flutter/material.dart';

class WhatsAppAdBanner extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onGetStarted;

  const WhatsAppAdBanner({
    super.key,
    required this.onClose,
    required this.onGetStarted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100, 
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 📣 ICON
            const Icon(
              Icons.campaign,
              color: Color(0xFF25D366),
              size: 22,
            ),

            const SizedBox(width: 10),

            /// 📝 TEXT
            Expanded(
              child: RichText(
                text: TextSpan(
                  text: 'Create ads from ₹91.03/day\n',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  children: [
                    const TextSpan(
                      text:
                          'Reach potential new customers with an ad that lets people start WhatsApp chats with you. ',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.normal,
                        color: Colors.black87,
                      ),
                    ),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.top,
                      child: GestureDetector(
                        onTap: onGetStarted,
                        child: const Text(
                          'Get started',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF25D366),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            /// ❌ CLOSE BUTTON
            GestureDetector(
              onTap: onClose,
              child: const Icon(
                Icons.close,
                size: 18,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
