import 'package:flutter/material.dart';

/// Design tokens extracted directly from Figma Design System (Frame 00)
class AppColors {
  // Canvas & Backgrounds
  static const Color oledCanvas = Color(0xFF080A12);
  static const Color slateCard = Color(0xFF121726);
  static const Color slateCardSubtle = Color(0x0AFFFFFF);
  static const Color darkBezel = Color(0xFF0A1F40);

  // Brand Accents
  static const Color electricCyan = Color(0xFF00D9FF);
  static const Color cyanGlow = Color(0x4000D9FF);
  static const Color cyanBorder = Color(0x3300D9FF);

  // Status & Highlights
  static const Color amberGold = Color(0xFFFAB22E);
  static const Color amberBadge = Color(0x26FAB22E);
  static const Color emeraldGreen = Color(0xFF21D487);
  static const Color emeraldBadge = Color(0x2621D487);
  static const Color rubyRed = Color(0xFFFF4D4F);

  // Typography Colors
  static const Color textPureWhite = Color(0xFFFAFAFF);
  static const Color textMuted = Color(0xFF9EADC7);
  static const Color textSubtle = Color(0xFF66738C);
  static const Color textDark = Color(0xFF080D14);
}

class AppStyles {
  static const TextStyle displayLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPureWhite,
    letterSpacing: -0.5,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPureWhite,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSubtle,
  );

  static const TextStyle priceHighlight = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.amberGold,
  );
}
