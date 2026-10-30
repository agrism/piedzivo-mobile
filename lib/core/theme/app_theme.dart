import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_dimensions.dart';

class AppTheme {
  static bool isTestMode = false;

  static TextStyle _font({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    if (isTestMode) {
      return TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
    }
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  static ThemeData get lightTheme {
    final baseTextTheme = isTestMode
        ? Typography.material2021().black
        : GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryViolet,
        secondary: AppColors.accentBlue,
        surface: AppColors.cardWhite,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSurface: AppColors.primaryNavy,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.cardBorderRadius,
          side: const BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryViolet,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.buttonBorderRadius,
          ),
          textStyle: _font(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textTheme: baseTextTheme.copyWith(
        headlineMedium: _font(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryNavy,
        ),
        titleLarge: _font(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryNavy,
        ),
        titleMedium: _font(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryNavy,
        ),
        bodyLarge: _font(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.primaryNavy,
        ),
        bodyMedium: _font(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        labelSmall: _font(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
