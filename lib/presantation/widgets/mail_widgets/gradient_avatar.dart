import 'package:flutter/material.dart';

class GradientAvatar extends StatelessWidget {
  final String name;
  final double radius;

  const GradientAvatar({
    Key? key,
    required this.name,
    this.radius = 28,
  }) : super(key: key);

  List<Color> _generateAvatarColors(String name) {
    List<List<Color>> gradientColors = [
      [Colors.red, Colors.orange, Colors.yellow],
      [Colors.blue, Colors.indigo, Colors.cyan],
      [Colors.green, Colors.teal, Colors.lightGreen],
      [Colors.purple, Colors.pink, Colors.deepPurple],
      [Colors.amber, Colors.deepOrange, Colors.orangeAccent],
      [Colors.cyan, Colors.lime, Colors.blueAccent],
    ];

    int hash = name.codeUnits.fold(0, (prev, element) => prev + element);
    return gradientColors[hash % gradientColors.length];
  }

  @override
  Widget build(BuildContext context) {
    final colors = _generateAvatarColors(name);
    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : "U";

    return ClipOval(
      child: Container(
        width: radius * 2.2,
        height: radius * 2.2,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.last.withOpacity(0.6),
              blurRadius: 15,
              spreadRadius: 3,
              offset: Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: radius * 0.8,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 2,
                offset: Offset(0, 1),
              )
            ],
          ),
        ),
      ),
    );
  }
}
