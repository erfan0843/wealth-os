import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_strings.dart' as s;

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(s.S.transactions)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [_filterBar(), const SizedBox(height: 8)],
      ),
    );
  }

  Widget _filterBar() {
    return Row(
      children: [
        Expanded(
          child: SearchBar(
            hintText: 'جستجو...',
            leading: const Icon(Icons.search_rounded, size: 20),
            backgroundColor: const WidgetStatePropertyAll(AppColors.surfaceAlt),
            elevation: const WidgetStatePropertyAll(0),
            onChanged: (_) {},
          ),
        ),
        const SizedBox(width: 8),
        IconButton(onPressed: () {}, icon: const Icon(Icons.tune_rounded)),
      ],
    );
  }
}
