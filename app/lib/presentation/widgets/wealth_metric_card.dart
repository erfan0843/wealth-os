import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';

/// کارت سنجهٔ کوچک (درآمد/هزینه/...).
class WealthMetricCard extends StatelessWidget {
  final String label;
  final int value;
  final int? delta; // درصد (اختیاری)
  final IconData icon;
  final Color color;
  final bool dark;

  const WealthMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.dark,
    this.delta,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 12,
                          color: dark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(faCompact(value),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            if (delta != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('▲ ${faPercent(delta)}٪',
                    style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w700)),
              ),
          ],
        ),
      ),
    );
  }

}
