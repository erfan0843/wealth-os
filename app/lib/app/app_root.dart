import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../presentation/router/app_router.dart';

/// ریشهٔ برنامه — تزریق ThemeMode (الان پیش‌فرض؛ بعداً از تنظیمات کاربر).
class ThemeModeProvider extends StateNotifier<ThemeMode> {
  ThemeModeProvider() : super(ThemeMode.system);
  void set(ThemeMode m) => state = m;
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeProvider, ThemeMode>((ref) {
  return ThemeModeProvider();
});

class AppRoot extends ConsumerWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'سامانهٔ ثروت',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(mode: ThemeMode.light),
      darkTheme: buildAppTheme(mode: ThemeMode.dark),
      themeMode: mode,
      routerConfig: appRouter,
      // فارسی + RTL (بند ۹۰)
      locale: const Locale('fa', 'IR'),
      supportedLocales: const [Locale('fa', 'IR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
