import 'package:flutter/material.dart';

import 'app_colors.dart';

/// ساخت ThemeData برای هر دو حالت (روشن/تیره) بر پایهٔ نظام طراحی فاز ۴.
ThemeData buildAppTheme({required ThemeMode mode, Color accent = AppColors.primary}) {
  final isDark = mode == ThemeMode.dark;
  final scheme = _schemeFor(isDark, accent);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Vazirmatn',
    scaffoldBackgroundColor: isDark ? AppColors.bgDark : AppColors.bg,
    splashFactory: InkSparkle.splashFactory,
    textTheme: _textTheme(isDark),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bg,
      foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Vazirmatn',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
      ),
    ),
    cardTheme: CardTheme(
      elevation: 0,
      color: isDark ? AppColors.surfaceDark : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: accent, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        textStyle: const TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    ),
    chipTheme: ChipThemeData(
      side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
      shape: const StadiumBorder(),
    ),
  );
}

ColorScheme _schemeFor(bool dark, Color accent) {
  if (dark) {
    return const ColorScheme.dark(
      primary: AppColors.primaryDark,
      onPrimary: AppColors.onPrimaryDark,
      secondary: AppColors.primaryDark,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimaryDark,
      error: AppColors.errorDark,
    ).copyWith(primary: accent, surfaceContainerHighest: AppColors.surfaceAltDark);
  }
  return const ColorScheme.light(
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    secondary: AppColors.primarySoft,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    error: AppColors.error,
  ).copyWith(primary: accent, surfaceContainerHighest: AppColors.surfaceAlt);
}

TextTheme _textTheme(bool dark) {
  final base = TextStyle(
    fontFamily: 'Vazirmatn',
    color: dark ? AppColors.textPrimaryDark : AppColors.textPrimary,
    fontFeatures: const [FontFeature('tnum')],
  );
  return TextTheme(
    displayLarge: base.copyWith(fontSize: 34, fontWeight: FontWeight.w800, height: 1.3),
    headlineMedium: base.copyWith(fontSize: 26, fontWeight: FontWeight.w700),
    titleLarge: base.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
    titleMedium: base.copyWith(fontSize: 17, fontWeight: FontWeight.w600),
    bodyLarge: base.copyWith(fontSize: 15, height: 1.7),
    bodyMedium: base.copyWith(fontSize: 14, height: 1.7),
    bodySmall: base.copyWith(fontSize: 13, color: dark ? AppColors.textSecondaryDark : AppColors.textSecondary),
    labelLarge: base.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
    labelMedium: base.copyWith(fontSize: 12, color: dark ? AppColors.textSecondaryDark : AppColors.textSecondary),
    labelSmall: base.copyWith(fontSize: 11, color: dark ? AppColors.textTertiaryDark : AppColors.textTertiary),
  );
}
