import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_config.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get clientTheme => _buildTheme(
        primary: AppConfig.primaryColor,
        primaryDark: AppConfig.primaryDarkColor,
        primaryLight: AppConfig.primaryLightColor,
      );

  static ThemeData get contractorTheme => _buildTheme(
        primary: AppConfig.secondaryColor,
        primaryDark: AppConfig.secondaryDarkColor,
        primaryLight: AppConfig.secondaryLightColor,
      );

  static ThemeData _buildTheme({
    required Color primary,
    required Color primaryDark,
    required Color primaryLight,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: AppConfig.secondaryColor,
        error: AppConfig.errorColor,
        surface: AppConfig.surfaceColor,
      ),
      scaffoldBackgroundColor: AppConfig.backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: AppConfig.backgroundColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppConfig.backgroundColor,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: AppConfig.backgroundColor,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppConfig.textHintColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppConfig.textHintColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppConfig.errorColor),
        ),
        hintStyle: const TextStyle(color: AppConfig.textHintColor),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      textTheme: GoogleFonts.sarabunTextTheme(const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppConfig.textPrimaryColor,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppConfig.textPrimaryColor,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppConfig.textPrimaryColor,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppConfig.textPrimaryColor,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: AppConfig.textPrimaryColor,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: AppConfig.textPrimaryColor,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: AppConfig.textSecondaryColor,
        ),
      )),
      cardTheme: CardThemeData(
        color: AppConfig.backgroundColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primaryLight,
        labelStyle: TextStyle(color: primaryDark),
        side: BorderSide.none,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppConfig.backgroundColor,
        selectedItemColor: primary,
        unselectedItemColor: AppConfig.textSecondaryColor,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: AppConfig.backgroundColor,
      ),
    );
  }
}
