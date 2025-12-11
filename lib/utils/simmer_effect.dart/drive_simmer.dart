import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerListLoader extends StatelessWidget {
  final int itemCount;
  final double iconSize;
  final double titleHeight;
  final double subtitleHeight;
  final double trailingIconSize;
  final EdgeInsetsGeometry padding;
  final Color baseColor;
  final Color highlightColor;
  final double titleWidthFactor;
  final double subtitleWidth;

  const ShimmerListLoader({
    super.key,
    this.itemCount = 12,
    this.iconSize = 48,
    this.titleHeight = 16,
    this.subtitleHeight = 12,
    this.trailingIconSize = 24,
    this.padding = const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
    this.baseColor = Colors.grey,
    this.highlightColor = Colors.white,
    this.titleWidthFactor = 1.0,
    this.subtitleWidth = 120,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(), // Disable scrolling
      itemCount: itemCount > 12 ? 12 : itemCount, // Limit to max 8 items
      itemBuilder: (context, index) {
        return Padding(
          padding: padding,
          child: Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Row(
              children: [
                // Leading icon placeholder
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 16),

                // Title and subtitle placeholders
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity * titleWidthFactor,
                        height: titleHeight,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: subtitleWidth,
                        height: subtitleHeight,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Single shimmer item version (original functionality)
class ShimmerListItem extends StatelessWidget {
  final double iconSize;
  final double titleHeight;
  final double subtitleHeight;
  final double trailingIconSize;
  final EdgeInsetsGeometry padding;
  final Color baseColor;
  final Color highlightColor;
  final double titleWidthFactor;
  final double subtitleWidth;

  const ShimmerListItem({
    super.key,
    this.iconSize = 48,
    this.titleHeight = 16,
    this.subtitleHeight = 12,
    this.trailingIconSize = 24,
    this.padding = const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
    this.baseColor = Colors.grey,
    this.highlightColor = Colors.white,
    this.titleWidthFactor = 1.0,
    this.subtitleWidth = 120,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Row(
          children: [
            // Leading icon placeholder
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 16),

            // Title and subtitle placeholders
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: titleHeight,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
