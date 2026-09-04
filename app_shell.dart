import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/app_strings.dart' as s;
import '../../core/theme/app_colors.dart';

/// Shell ناوبری اصلی — ۵ تب با دکمهٔ مرکزی «+» (بند ۱۲).
class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static const _items = [
    (nav: '/home', label: s.S.home, icon: Icons.home_rounded),
    (nav: '/transactions', label: s.S.transactions, icon: Icons.receipt_long_rounded),
    (nav: '/assets', label: s.S.assets, icon: Icons.diamond_outlined),
    (nav: '/future', label: s.S.future, icon: Icons.calendar_month_rounded),
    (nav: '/profile', label: 'پروفایل', icon: Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context);
    final index = _items.indexWhere((i) => i.nav == loc.matchedLocation);
    return Scaffold(
      body: child,
      floatingActionButton: FloatingActionButton(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ثبت سریع (به‌زودی ساخته می‌شود)')),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        color: Theme.of(context).colorScheme.surface,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (final item in _items.sublist(0, 2)) _tab(context, index, item),
            const SizedBox(width: 56),
            for (final item in _items.sublist(2)) _tab(context, index, item),
          ],
        ),
      ),
    );
  }

  Widget _tab(BuildContext context, int index, ({String nav, String label, IconData icon}) item) {
    final selected = index == _items.indexOf(item);
    final color = selected ? Theme.of(context).colorScheme.primary : AppColors.textTertiary;
    return InkWell(
      onTap: () => context.go(item.nav),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, color: color, size: 22),
            Text(item.label, style: TextStyle(fontSize: 10, color: color)),
          ],
        ),
      ),
    );
  }
}
