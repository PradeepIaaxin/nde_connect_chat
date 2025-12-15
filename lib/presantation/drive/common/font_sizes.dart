import 'package:flutter/material.dart';

class FontSizes {
  static double fontSizeExtraSmall(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width >= 1300) return 14; 
    if (width >= 600) return 12;  
    return 10;                    
  }

  static double fontSizeSmall(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width >= 1300) return 16;
    if (width >= 600) return 14;
    return 12;
  }

static double fontLoginSmall(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width >= 1300) return 16;
    if (width >= 600) return 14;
    return 13;
  }

  static double fontSizeDefault(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width >= 1300) return 18;
    if (width >= 600) return 16;
    return 14;
  }

  static double fontSizeLarge(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width >= 1300) return 20;
    if (width >= 600) return 18;
    return 16;
  }
  static double fontSizeLarge2(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width >= 1300) return 19;
    if (width >= 600) return 17;
    return 15;
  }


  static double fontSizeExtraLarge(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width >= 1300) return 22;
    if (width >= 600) return 20;
    return 18;
  }

static double fontSizeExtraMedium(BuildContext context) {
  double width = MediaQuery.of(context).size.width;
  if (width >= 1300) return 24;
  if (width >= 600) return 22;
  return 20;
}

  
static double fontSizeMedium(BuildContext context) {
  double width = MediaQuery.of(context).size.width;
  if (width >= 1300) return 26;
  if (width >= 600) return 24;
  return 22;
}

static double fontSizeOverLarge(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width >= 1300) return 28;
    if (width >= 600) return 26;
    return 24;
  }
  static double fontSizeHighLarge(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width >= 1300) return 32;
    if (width >= 600) return 30;
    return 28;
  }
}
