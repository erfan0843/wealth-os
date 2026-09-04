import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_strings.dart' as s;
import '../../../core/utils/format.dart';
import '../../widgets/wealth_metric_card.dart';
import '../../widgets/wealth_networth_card.dart';

/// داشبورد — بند ۵۲، ۵۳، ۱۰۴ (داده‌ها در فازهای بعد متصل می‌شوند).
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text('سلام، کاربر 👋'),
        actions: const [
          IconButton(onPressed: null, icon: Icon(Icons.search_rounded)),
          IconButton(onPressed: null, icon: Icon(Icons.notifications_none_rounded)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
        children: [
          const WealthNetWorthCard(
            netWorth: 920000000,
            totalAssets: 1250000000,
            totalLiabilities: 48000000,
            growthPercent: 2.1,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: WealthMetricCard(
                  label: s.S.income,
                  value: 25000000,
                  delta: 25,
                  icon: Icons.trending_up_rounded,
                  color: AppColors.success,
                  dark: dark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: WealthMetricCard(
                  label: s.S.expense,
                  value: 18500000,
                  delta: 18,
                  icon: Icons.trending_down_rounded,
                  color: AppColors.error,
                  dark: dark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ThisMonthCard(dark: dark),
          const SizedBox(height: 16),
          _UpcomingCard(dark: dark),
        ],
      ),
    );
  }
}

class _ThisMonthCard extends StatelessWidget {
  final bool dark;
  const _ThisMonthCard({required this.dark});

  @override
  Widget build(BuildContext context) {
    return _sectionCard(
      dark: dark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.S.whereDidMoneyGo,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _bar('خوراک', 7, 40),
          _bar('حمل‌ونقل', 3, 18),
          _bar('خرید', 5, 26),
          const SizedBox(height: 6),
          Text('معادل ۴۲ گرم نقره (قیمت همان زمان)',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _bar(String name, int valueMillions, double w) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 70, child: Text(name, style: const TextStyle(fontSize: 13))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: w / 100,
                minHeight: 8,
                backgroundColor: dark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 64,
            child: Text(faCompact(valueMillions * 1000000), style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  final bool dark;
  const _UpcomingCard({required this.dark});

  @override
  Widget build(BuildContext context) {
    return _sectionCard(
      dark: dark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(s.S.upcomingCommitments,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const Text(s.S.seeAll, style: TextStyle(fontSize: 12, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 8),
          _row('قسط دیجی‌پای', '۲٬۰۰۰٬۰۰۰', '۵ روز مانده'),
          _row('چک دریافتی', '۳٬۰۰۰٬۰۰۰', '۹ روز مانده'),
        ],
      ),
    );
  }

  Widget _row(String name, String amount, String sub) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(name, style: const TextStyle(fontSize: 14))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              Text(sub, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _sectionCard({required bool dark, required Widget child}) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: child,
    ),
  );
}
