import 'package:flutter/material.dart';

class GmailAvatar extends StatelessWidget {
  final String name;
  final double radius;

  /// Optional override colors
  final List<Color>? colors;

  /// Optional custom child (icon / image)
  final Widget? child;

  const GmailAvatar({
    super.key,
    required this.name,
    this.radius = 20,
    this.colors,
    this.child,
  });

  /// Gmail color palette
  static const List<Color> avatarColors = [
    Color(0xFF4285F4),
    Color(0xFFEA4335),
    Color(0xFFFBBC05),
    Color(0xFF34A853),
    Color(0xFF8E24AA),
    Color(0xFF5E35B1),
    Color(0xFF3949AB),
    Color(0xFF1E88E5),
    Color(0xFF039BE5),
    Color(0xFF00ACC1),
    Color(0xFF00897B),
    Color(0xFF43A047),
    Color(0xFF7CB342),
    Color(0xFFFDD835),
    Color(0xFFFFB300),
    Color(0xFFFB8C00),
    Color(0xFFF4511E),
    Color(0xFF6D4C41),
    Color(0xFF757575),
    Color(0xFFD81B60),
    Color(0xFF5C6BC0),
    Color(0xFF26A69A),
    Color(0xFF66BB6A),
    Color(0xFF9CCC65),
    Color(0xFFFFCA28),
    Color(0xFFFF7043),
    Color(0xFF90CAF9),
    Color(0xFFA5D6A7),
    Color(0xFFFFE082),
    Color(0xFFCE93D8),
    Color(0xFFFFAB91),
  ];

  /// Pick color
  Color _getAvatarColor(String name) {
    if (colors != null && colors!.isNotEmpty) {
      return colors!.first;
    }

    int hash =
        name.codeUnits.fold(0, (p, e) => p + e);

    return avatarColors[
        hash % avatarColors.length];
  }

  /// Initial letter
  String _getInitial(String name) {
    if (name.trim().isEmpty) return "?";
    return name.trim()[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _getAvatarColor(name);
    final initial = _getInitial(name);

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,

      /// If custom child exists → use it
      child: child ??
          Text(
            initial,
            style: TextStyle(
              color: Colors.white,
              fontSize: radius * 0.9,
              fontWeight: FontWeight.w600,
            ),
          ),
    );
  }
}
