import 'package:flutter/material.dart';
import 'package:nde_email/presantation/drive/common/font_sizes.dart';
import 'package:nde_email/presantation/drive/common/responsive.dart' show Responsive;


TextStyle robotoRegular(BuildContext context) {
  final infoFont = Responsive.infoFont(context);
  final theme = Theme.of(context);
  final textTheme = theme.textTheme.bodyLarge?.color;
  return TextStyle(
    color: textTheme,
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w400,
    fontSize: infoFont,
    height: 1.25,
    letterSpacing: -0.07,
  );
}

TextStyle robotoMedium(BuildContext context) {
  final nameFont = Responsive.nameFont(context);
  final theme = Theme.of(context);
   final textTheme = theme.textTheme.bodyLarge?.color;
  return TextStyle(
    color: textTheme,
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w400,
    fontSize: nameFont,
    height: 1.25,
    letterSpacing: -0.07,
  );
}

TextStyle robotoBold(BuildContext context) {
  final nameFont = Responsive.nameFont(context);
  final theme = Theme.of(context);
  final textTheme = theme.textTheme.bodyLarge?.color;
  return TextStyle(
    color: textTheme,
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w500,
    fontSize: nameFont,
    height: 1.25,
    letterSpacing: -0.07,
  );
}

TextStyle robotoBlack(BuildContext context) {
  final nameFont = Responsive.nameFont(context);
  final theme = Theme.of(context);
  final textTheme = theme.textTheme.bodyLarge?.color;
  return TextStyle(
    color:textTheme,
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w500,
    fontSize: nameFont,
    height: 1.25,
    letterSpacing: -0.07,
  );
}

// Log in to NDE
TextStyle loginemail(BuildContext context) {
  final fontSizeExtraLarge = FontSizes.fontSizeExtraLarge(context);
  final theme = Theme.of(context);
  final colorScheme = theme.cardColor;
  final textTheme = theme.textTheme.bodyLarge?.color;
  final isDark = theme.brightness == Brightness.dark;
  return TextStyle(
    color: isDark?textTheme:Colors.black,
    fontSize: fontSizeExtraLarge,
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w500,
    height: 1.11,
    letterSpacing: -0.09,
  );
}

//Email
TextStyle email(BuildContext context) {
  final fontSizeDefault = FontSizes.fontSizeDefault(context);
  final theme = Theme.of(context);
  final colorScheme = theme.cardColor;
  final textTheme = theme.textTheme.bodyLarge?.color;
  final isDark = theme.brightness == Brightness.dark;
  return TextStyle(
    fontSize: fontSizeDefault,
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w400,
    height: 1.25,
    letterSpacing: -0.07,
    color: isDark?textTheme:Color(0xFF6C6C89),
  );
}

// Forgotten Mail_id

TextStyle forgettenmailid(BuildContext context) {
  final fontSizeSmall = FontSizes.fontLoginSmall(context);

  return TextStyle(
    fontSize: fontSizeSmall,
    color: Color(0xFF4752EB),
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w600,
    height: 1.33,
  );
}

// Next
TextStyle next(BuildContext context) {
  final fontSizeLarge = FontSizes.fontSizeLarge(context);
  final fontSizeDefault = FontSizes.fontSizeDefault(context);
  final theme = Theme.of(context);
  final colorScheme = theme.cardColor;
  final textTheme = theme.textTheme.bodyLarge?.color;
  final isDark = theme.brightness == Brightness.dark;
  return TextStyle(
    fontSize: fontSizeLarge,
    fontWeight: FontWeight.w600,
    color: isDark?textTheme:Colors.white,
  );
}

// change
TextStyle change(BuildContext context) {
  final fontSizeExtraLarge = FontSizes.fontSizeExtraLarge(context);
  return TextStyle(
    color: const Color(0xFF2F80ED),
    fontSize: fontSizeExtraLarge,
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w400,
    height: 1.11,
    letterSpacing: -0.09,
    decoration: TextDecoration.underline,
    decorationColor: const Color(0xFF2F80ED),
  );
}

TextStyle widgetemail(BuildContext context) {
  final fontSizeExtraLarge = FontSizes.fontSizeExtraLarge(context);
  final fontSizeLarge = FontSizes.fontSizeLarge(context);
  final fontSizeDefault = FontSizes.fontSizeDefault(context);
  final theme = Theme.of(context);
  final colorScheme = theme.cardColor;
  final textTheme = theme.textTheme.bodyLarge?.color;
  final isDark = theme.brightness == Brightness.dark;
  return TextStyle(
    color: isDark?textTheme:Colors.black,
    fontSize: fontSizeExtraLarge,
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w400,
    height: 1.11,
    letterSpacing: -0.09,
  );
}

TextStyle nodataavailable(BuildContext context) {
  final theme = Theme.of(context);
  final colorScheme = theme.cardColor;
  final textTheme = theme.textTheme.bodyLarge?.color;
  final isDark = theme.brightness == Brightness.dark;
  return TextStyle(color: isDark?colorScheme:Colors.black, fontSize: 14);
}
