import 'package:flutter/material.dart';
import 'package:wealth_core/wealth_core.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_strings.dart' as s;
import '../../core/utils/format.dart';

/// کارت قهرمان دارایی خالص — بند ۵۲، ۱۰۴ (قابل Drill-Down در فازهای بعد).
class WealthNetWorthCard extends StatelessWidget {
  final int netWorth;
  final int totalAssets;
  final int totalLiabilities;
  final double growthPercent;

  const WealthNetWorthCard({
    super.key,
    required this.netWorth,
    required this.totalAssets,
    required this.totalLiabilities,
    required this.growthPercent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF1F7A8C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.S.netWorth,
              style: const TextStyle(color: Colors.white, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            _money(netWorth),
            style: const TextStyle(
                color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text('▲ ${faPercentDec(growthPercent)}٪ این ماه',
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _mini(s.S.totalAssets, _moneyCompact(totalAssets)),
              const SizedBox(width: 12),
              _mini(s.S.totalLiabilities, _moneyCompact(totalLiabilities)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mini(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.14),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(color: Colors.white,
                    fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  String _money(int v) => faMoney(v, Currency.irt);

  String _moneyCompact(int v) => faCompact(v);
}
