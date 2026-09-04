import 'package:flutter/material.dart';

/// رنگ‌های معنایی (Semantic tokens) — بند ۸۸، ۸۹.
/// هم لایت هم دارک؛ بر پایهٔ `app_colors` (خام) تعریف می‌شوند.
class AppColors {
  AppColors._();

  // Light
  static const bg = Color(0xFFF6F7F9);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF1F2F5);
  static const textPrimary = Color(0xFF1A1C1E);
  static const textSecondary = Color(0xFF6B7178);
  static const textTertiary = Color(0xFF9AA0A6);
  static const primary = Color(0xFF135F56);
  static const primarySoft = Color(0xFFE2F0ED);
  static const onPrimary = Color(0xFFFFFFFF);
  static const success = Color(0xFF1F9D61);
  static const warning = Color(0xFFE0A03C);
  static const error = Color(0xFFD14D4D);
  static const successSoft = Color(0xFFE3F5EB);
  static const warningSoft = Color(0xFFFBEFD8);
  static const errorSoft = Color(0xFFFBE6E6);
  static const border = Color(0xFFE8EAED);
  static const grid = Color(0xFFECEEF1);

  // Dark
  static const bgDark = Color(0xFF0E1213);
  static const surfaceDark = Color(0xFF15191B);
  static const surfaceAltDark = Color(0xFF1D2225);
  static const textPrimaryDark = Color(0xFFF0F2F3);
  static const textSecondaryDark = Color(0xFFA6ADB3);
  static const textTertiaryDark = Color(0xFF6C737A);
  static const primaryDark = Color(0xFF5BC2AE);
  static const primarySoftDark = Color(0xFF16302B);
  static const onPrimaryDark = Color(0xFF0E1614);
  static const successDark = Color(0xFF43C98D);
  static const warningDark = Color(0xFFE8B458);
  static const errorDark = Color(0xFFE67474);
  static const borderDark = Color(0xFF262B2E);
  static const gridDark = Color(0xFF22282B);

  /// آکستن قابل‌شخصی‌سازی (بند ۸).
  static const accents = <Color>[
    Color(0xFF135F56), // زمردی
    Color(0xFF1F7A8C), // فیروزه‌ای دریایی
    Color(0xFF6A5FA5), // بنفش یشمی
    Color(0xFFD98A2B), // نارنجی لطیف
    Color(0xFF3A6EA5), // آبی محو
  ];
}

class AppSpacing {
  AppSpacing._();
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const screenPad = 20.0;
}

class AppRadius {
  AppRadius._();
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const full = 999.0;
}
