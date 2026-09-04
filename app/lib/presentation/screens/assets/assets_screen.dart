import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_strings.dart' as s;

class AssetsScreen extends StatelessWidget {
  const AssetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text(s.S.assets)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
        children: [
          // Empty state — بند ۸۵
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Text('🏺', style: TextStyle(fontSize: 44)),
                  const SizedBox(height: 8),
                  Text(s.S.noAsset,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(
                    'اولین دارایی‌ات رو اضافه کن تا وضعیت ثروتت رو ببینی.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13,
                        color: dark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add_rounded),
                    label: Text(s.S.addFirstAsset),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
