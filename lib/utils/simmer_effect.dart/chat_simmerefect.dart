import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:math' show Random;

class ShimmerMessageBubble extends StatelessWidget {
  final bool isSentByMe;
  late final Random random;
  final Color baseColor;
  final Color highlightColor;
  final double maxWidthFactor;

  ShimmerMessageBubble({
    super.key,
    required this.isSentByMe,
    Random? random,
    this.baseColor = Colors.grey,
    this.highlightColor = Colors.white,
    this.maxWidthFactor = 0.75,
  }) {
    this.random = random ?? Random();
  }
  @override
  Widget build(BuildContext context) {
    final hasImage = random.nextDouble() > 0.7;
    final hasFile = random.nextDouble() > 0.8;
    final hasUsername = !isSentByMe && random.nextDouble() > 0.5;
    final textLines = random.nextInt(3) + 1;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Align(
        alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Shimmer.fromColors(
          baseColor: baseColor.withOpacity(0.5),
          highlightColor: highlightColor,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar for received messages
              if (!isSentByMe)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: highlightColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

              // Message content
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * maxWidthFactor,
                ),
                child: Column(
                  crossAxisAlignment: isSentByMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    // Username for received messages
                    if (hasUsername)
                      Container(
                        width: random.nextDouble() * 80 + 60,
                        height: 14,
                        color: highlightColor,
                        margin: const EdgeInsets.only(bottom: 4),
                      ),

                    // Message bubble container
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: highlightColor,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: isSentByMe
                              ? const Radius.circular(16)
                              : const Radius.circular(4),
                          bottomRight: isSentByMe
                              ? const Radius.circular(4)
                              : const Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image placeholder
                          if (hasImage)
                            Container(
                              width: double.infinity,
                              height: 150,
                              color: highlightColor,
                              margin: const EdgeInsets.only(bottom: 8),
                            ),

                          // File attachment placeholder
                          if (hasFile)
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: baseColor.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    color: highlightColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: random.nextDouble() * 100 + 50,
                                    height: 14,
                                    color: highlightColor,
                                  ),
                                ],
                              ),
                            ),

                          // Text content placeholders
                          ...List.generate(textLines, (index) {
                            final isLastLine = index == textLines - 1;
                            return Container(
                              width: random.nextDouble() * 150 +
                                  (isLastLine ? 50 : 100),
                              height: 12,
                              color: highlightColor,
                              margin: EdgeInsets.only(
                                bottom: isLastLine ? 0 : 4,
                                top: index == 0 ? 0 : 4,
                              ),
                            );
                          }),

                          // Timestamp placeholder
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Container(
                              width: 40,
                              height: 10,
                              color: highlightColor,
                              margin: const EdgeInsets.only(top: 6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Status indicator for sent messages
              if (isSentByMe)
                Padding(
                  padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: highlightColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
