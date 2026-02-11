import 'package:flutter/material.dart';

class CollapsibleQuotedContent extends StatefulWidget {
  final Widget child;
  const CollapsibleQuotedContent({super.key, required this.child});

  @override
  State<CollapsibleQuotedContent> createState() =>
      _CollapsibleQuotedContentState();
}

class _CollapsibleQuotedContentState extends State<CollapsibleQuotedContent> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (_isExpanded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildThreeDots(onTap: () => setState(() => _isExpanded = false)),
          const SizedBox(height: 8),
          widget.child,
        ],
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
        child: _buildThreeDots(onTap: () => setState(() => _isExpanded = true)),
      );
    }
  }

  Widget _buildThreeDots({required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 32,
        height: 18,
        decoration: BoxDecoration(
          //color: const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Icon(
            Icons.more_horiz,
            size: _isExpanded ? 10 : 24,
            color: Color(0xFF616161),
          ),
        ),
      ),
    );
  }
}
