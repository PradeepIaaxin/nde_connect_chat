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

  static Color getColorFromAlphabet(String input) {
    if (input.trim().isEmpty) return _alphabetColors[0];

    // Safely get the first grapheme cluster (letter/emoji)
    final String firstGrapheme = input.trim().characters.first.toUpperCase();

    // Check if it's a standard A-Z letter
    int index = -1;
    if (firstGrapheme.length == 1) {
      final int code = firstGrapheme.codeUnitAt(0);
      if (code >= 65 && code <= 90) {
        // A-Z
        index = code - 65;
      }
    }

    // If standard letter, use its index.
    // If NOT standard (Emoji, Number, Symbol, or Multi-code-unit char),
    // hash the ENTIRE input string to ensure uniqueness.
    // e.g. "Group 1" vs "Group 2" should potentially differ if we passed full string,
    // but typically we pass initials.
    // However, for Emojis: "😀" vs "😁" should definitely differ.
    // Using simple codeUnit sum of just the first grapheme is safer for consistency.
    if (index < 0 || index >= _alphabetColors.length) {
      index = firstGrapheme.codeUnits.fold(0, (p, c) => p + c) %
          _alphabetColors.length;
    }

    return _alphabetColors[index];
  }
}
