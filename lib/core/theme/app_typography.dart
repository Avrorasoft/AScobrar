import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();
  static TextStyle get displayLarge => GoogleFonts.plusJakartaSans(
        fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textDark);
  static TextStyle get displayMedium => GoogleFonts.plusJakartaSans(
        fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textDark);
  static TextStyle get titleLarge => GoogleFonts.poppins(
        fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark);
  static TextStyle get titleMedium => GoogleFonts.poppins(
        fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark);
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textDark);
  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textDark);
  static TextStyle get label => GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w500,
        color: AppColors.textDark.withOpacity(0.7));
  static TextStyle get number => GoogleFonts.poppins(
        fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textDark);
}
