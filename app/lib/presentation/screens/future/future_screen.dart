import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_strings.dart' as s;

class FutureScreen extends StatelessWidget {
  const FutureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text(s.S.future)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(s.S.cashFlow,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  _row(s.S.inflow, '+۴۵٬۰۰۰٬۰۰۰', AppColors.success),
                  _row(s.S.outflow, '−۲۸٬۰۰۰٬۰۰۰', AppColors.error),
                  _row(s.S.net, '+۱۷٬۰۰۰٬۰۰۰', AppColors.success),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('تقویم تعهدات',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  SizedBox(height: 8),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _cal('۱۲ شهریور', 'قسط دیجی‌پای', '۲٬۰۰۰٬۰۰۰', dark),
                  _cal('۱۶ شهریور', 'چک دریافتی', '۳٬۰۰۰٬۰۰۰', dark),
                  _cal('۲۱ شهریور', 'اجاره (مکرر)', '۱۲٬۰۰۰٬۰۰۰', dark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _cal(String date, String name, String amount, bool dark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(Icons.calendar_today_rounded, size: 14,
                color: dark ? AppColors.textTertiaryDark : AppColors.textTertiary),
            const SizedBox(width: 8),
            Text(date, style: const TextStyle(fontSize: 13)),
          ]),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(name, textAlign: TextAlign.right, style: const TextStyle(fontSize: 13)),
            ),
          ),
          Text(amount, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
