import 'package:flutter/material.dart';

class ColorAssignUtils {
  static Color parse(String? input, {Color fallback = Colors.black}) {
    try {
      if (input == null || input.isEmpty) return fallback;

      input = input.trim();

      // Handle rgb or rgba format
      if (input.startsWith('rgb')) {
        final regExp = RegExp(r'rgba?\(([^)]+)\)');
        final match = regExp.firstMatch(input);
        if (match != null) {
          final parts =
              match.group(1)!.split(',').map((e) => e.trim()).toList();
          final r = int.parse(parts[0]);
          final g = int.parse(parts[1]);
          final b = int.parse(parts[2]);
          final a =
              parts.length == 4 ? (double.parse(parts[3]) * 255).round() : 255;
          return Color.fromARGB(a, r, g, b);
        }
      }

      // Handle hex format
      input = input.toUpperCase().replaceAll("#", "");
      if (input.length == 6) input = "FF$input";
      if (input.length == 8) {
        return Color(int.parse(input, radix: 16));
      }
    } catch (_) {
      // Log if needed
    }

    return fallback;
  }
}
