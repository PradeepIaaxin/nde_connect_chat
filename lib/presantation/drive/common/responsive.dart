import 'package:flutter/material.dart';

class Responsive {
  static double w(BuildContext context) => MediaQuery.of(context).size.width;
  static double h(BuildContext context) => MediaQuery.of(context).size.height;

  /// Breakpoints
  static bool isMobile(BuildContext context) => w(context) < 600;
  static bool isTablet(BuildContext context) =>
      w(context) >= 600 && w(context) < 1024;
  static bool isDesktop(BuildContext context) => w(context) >= 1024;

  /// Scale factor based on breakpoint
  static double scale(BuildContext context) {
    if (isMobile(context)) return 1.0;
    if (isTablet(context)) return 1.3;
    if (isDesktop(context)) return 1.7;
    return 1.0;
  }

  static double size(BuildContext context, double base) {
    double scaled = base * scale(context);
    double min = base * 0.8;
    double max = base * 1.5;

    return scaled.clamp(min, max);
  }

  /// Font & size helpers using base size * scale
  static double avatar(BuildContext context) {
    final base = 48.0;
    return (base * scale(context)).clamp(36.0, 80.0);
  }

  static double icon(BuildContext context) {
    final base = 20.0;
    return (base * scale(context)).clamp(16.0, 32.0);
  }

  static double callBtn(BuildContext context) {
    final base = 40.0;
    return (base * scale(context)).clamp(32.0, 64.0);
  }

  static double nameFont(BuildContext context) {
    final base = 16.0;
    return (base * scale(context)).clamp(14.0, 26.0);
  }

 static double loginemail(BuildContext context) {
    final base = 18.0;
    return (base * scale(context)).clamp(16.0, 32.0);
  }
  static double infoFont(BuildContext context) {
    final base = 14.0;
    return (base * scale(context)).clamp(12.0, 22.0);
  }

  static double recordFont(BuildContext context) {
    final base = 13.0;
    return (base * scale(context)).clamp(11.0, 20.0);
  }

  static double navIcon(BuildContext context) {
    final base = 24.0;
    return (base * scale(context)).clamp(20.0, 34.0);
  }

  static double navFont(BuildContext context) {
    final base = 12.0;
    return (base * scale(context)).clamp(10.0, 18.0);
  }

  static double fabRadius(BuildContext context) {
    final base = 12.0;
    return (base * scale(context)).clamp(10.0, 24.0);
  }

  static double fabIcon(BuildContext context) {
    final base = 24.0;
    return (base * scale(context)).clamp(20.0, 36.0);
  }
}
