import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nde_email/presantation/widgets/mail_widgets/constants/font_colors.dart';


class TextStyles {
  static TextStyle get fromName => GoogleFonts.roboto(
        fontSize: 15,
        fontWeight: FontWeight.w900,
        color: AppColors.headingText,
      );

  
  static TextStyle get subject => GoogleFonts.roboto(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.headingText,
      );

  
  static TextStyle get intro => GoogleFonts.roboto(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color:AppColors.secondaryText,
      );
}




