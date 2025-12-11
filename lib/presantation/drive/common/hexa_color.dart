import 'dart:developer';

import 'package:flutter/material.dart';

class ColorUtils {
  /// Converts a hex string like "#0A84FF" to a [Color] object.
  /// Returns [Colors.grey] if the input is invalid.
  static Color fromHex(String? hex) {
    try {
      if (hex == null || hex.isEmpty) return Colors.grey;

      hex = hex.replaceAll('#', '').toUpperCase();
      if (hex.length == 6) hex = 'FF$hex'; // Add alpha if missing

      if (hex.length != 8) return Colors.grey; // Ensure it's 8 characters

      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      log('Invalid hex color: $hex, error: $e');
      return Colors.grey;
    }
  }
}
