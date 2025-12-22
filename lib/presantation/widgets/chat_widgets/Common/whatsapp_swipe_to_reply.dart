import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SwipeToReply extends StatefulWidget {
  final Widget child;
  final VoidCallback onReply;
  final IconData icon;
  final Color iconColor;
  final double threshold;

  const SwipeToReply({
    super.key,
    required this.child,
    required this.onReply,
    this.icon = Icons.reply,
    this.iconColor = Colors.grey,
    this.threshold = 60.0,
  });

  @override
  State<SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<SwipeToReply>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _dragOffset = 0.0;
  bool _isThresholdReached = false;
  bool _hapticFeedbackTriggered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = Tween<double>(begin: 0.0, end: 0.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      // Apply a friction effect as the user swipes further
      double delta = details.delta.dx;
      if (_dragOffset > widget.threshold) {
        delta /= 2.0; // Slow down after threshold
      }

      _dragOffset += delta;

      if (_dragOffset < 0) _dragOffset = 0; // Only swipe right

      // Limit maximum drag
      if (_dragOffset > widget.threshold * 1.8) {
        _dragOffset = widget.threshold * 1.8;
      }

      if (_dragOffset >= widget.threshold) {
        if (!_isThresholdReached) {
          _isThresholdReached = true;
          if (!_hapticFeedbackTriggered) {
            HapticFeedback.lightImpact();
            _hapticFeedbackTriggered = true;
          }
        }
      } else {
        _isThresholdReached = false;
        _hapticFeedbackTriggered = false;
      }
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_isThresholdReached) {
      widget.onReply();
    }

    _animation = Tween<double>(begin: _dragOffset, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    )..addListener(() {
        setState(() {
          _dragOffset = _animation.value;
        });
      });

    _controller.reset();
    _controller.forward();
    _isThresholdReached = false;
    _hapticFeedbackTriggered = false;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        // The background icon that appears during swipe
        Positioned(
          left: 16.0,
          child: Opacity(
            opacity: (_dragOffset / widget.threshold).clamp(0.0, 1.0),
            child: Transform.scale(
              scale: (_dragOffset / widget.threshold).clamp(0.5, 1.0),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isThresholdReached
                      ? widget.iconColor.withOpacity(0.1)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  color: _isThresholdReached
                      ? widget.iconColor
                      : widget.iconColor.withOpacity(0.6),
                  size: 24,
                ),
              ),
            ),
          ),
        ),
        // The swipable content
        Transform.translate(
          offset: Offset(_dragOffset, 0),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragUpdate: _onHorizontalDragUpdate,
            onHorizontalDragEnd: _onHorizontalDragEnd,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
