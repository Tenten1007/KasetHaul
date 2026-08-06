import 'package:flutter/material.dart';

class AppConfig {
  AppConfig._();

  static const String appName = 'KasetHaul';
  static const String appVersion = '1.0.0';

  // Primary colors — Client side (Green) — CSS: --primary #2E7D32
  static const Color primaryColor = Color(0xFF2E7D32);
  static const Color primaryDarkColor = Color(0xFF1B5E20);
  static const Color primaryLightColor = Color(0xFF4CAF50);

  // Secondary colors — Contractor side (Orange) — CSS: --secondary #FF9800
  static const Color secondaryColor = Color(0xFFFF9800);
  static const Color secondaryDarkColor = Color(0xFFF57C00);
  static const Color secondaryLightColor = Color(0xFFFFB74D); // CSS: --secondary-light

  // Accent color — CSS: --info #2196F3
  static const Color accentColor = Color(0xFF2196F3);

  // Neutral colors
  static const Color backgroundColor = Color(0xFFFFFFFF);
  static const Color surfaceColor = Color(0xFFF5F5F5);       // CSS: --gray-100 (scaffold bg)
  static const Color contentBackgroundColor = Color(0xFFFAFAFA); // CSS: --gray-50 (scroll area)
  static const Color errorColor = Color(0xFFF44336);          // CSS: --danger

  // Text colors — CSS gray scale
  static const Color textPrimaryColor = Color(0xFF212121);    // --gray-900
  static const Color textSecondaryColor = Color(0xFF757575);  // --gray-600
  static const Color textHintColor = Color(0xFFBDBDBD);       // --gray-400

  // Status colors
  static const Color statusActiveColor = Color(0xFF4CAF50);
  static const Color statusWarningColor = Color(0xFFFF9800);
  static const Color statusErrorColor = Color(0xFFF44336);    // CSS: --danger

  // Shadow values — CSS: --shadow / --shadow-lg
  static const BoxShadow cardShadow = BoxShadow(
    color: Color(0x1A000000), // rgba(0,0,0,0.10)
    blurRadius: 8,
    offset: Offset(0, 2),
  );
  static const BoxShadow cardShadowLg = BoxShadow(
    color: Color(0x26000000), // rgba(0,0,0,0.15)
    blurRadius: 16,
    offset: Offset(0, 4),
  );

  // Platform fee
  static const double platformFeePercent = 0.03; // 3%
  static const double platformFeePerSide = 0.015; // 1.5% each

  // Deposit limits
  static const double depositMinAmount = 100.0;
  static const double depositMaxAmount = 100000.0;

  // Withdraw fee
  static const double withdrawFee = 30.0;
}
