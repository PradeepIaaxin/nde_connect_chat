// lib/utils/color_utils.dart
import 'package:flutter/material.dart';

class ColorUtil {
  static final List<Color> _alphabetColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
    const Color.fromARGB(255, 112, 198, 88),
    const Color.fromARGB(255, 79, 99, 101),
    Colors.greenAccent,
    Colors.orangeAccent,
    Colors.pinkAccent,
    Colors.redAccent,
    const Color.fromARGB(255, 21, 193, 153),
  ];

  static Color getColorFromAlphabet(String letter) {
    if (letter.isEmpty) return _alphabetColors[0];

    int index = letter.toUpperCase().codeUnitAt(0) - 'A'.codeUnitAt(0);
    if (index < 0 || index >= _alphabetColors.length) {
      index = 0;
    }
    return _alphabetColors[index];
  }
}
