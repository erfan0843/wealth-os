import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('پروفایل')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _tile(Icons.person_rounded, 'نام و پروفایل'),
          _tile(Icons.palette_rounded, 'شخصی‌سازی: رنگ، تم، واحد'),
          _tile(Icons.category_rounded, 'دسته‌بندی‌ها'),
          _tile(Icons.security_rounded, 'امنیت و قفل برنامه'),
          _tile(Icons.cloud_rounded, 'پشتیبان‌گیری و همگام‌سازی'),
          _tile(Icons.shield_rounded, 'حریم خصوصی (AI خاموش است)'),
        ],
      ),
    );
  }
}

class _tile extends StatelessWidget {
  final IconData icon;
  final String label;
  const _tile(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label, style: const TextStyle(fontSize: 14)),
        trailing: const Icon(Icons.chevron_left_rounded, size: 20),
        onTap: () {},
      ),
    );
  }
}
