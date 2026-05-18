import 'package:flutter/material.dart';
import '../pages/settingPage.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('RideVoyage'),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: '搜尋',
          onPressed: () {
            // TODO: 搜尋功能
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: '設定',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.person_outline),
          tooltip: '個人資料',
          onPressed: () {
            Navigator.pushNamed(context, '/profile');
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
