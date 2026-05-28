import 'package:flutter/material.dart';
import 'account_management_page.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _darkMode = false;
  String _selectedLanguage = '繁體中文';

  final List<String> _languages = ['繁體中文', 'English', '日本語'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          // ── 一般 ──────────────────────────────────────────
          _SectionHeader(title: '一般'),

          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: const Text('語言'),
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedLanguage,
                items: _languages
                    .map(
                      (lang) =>
                          DropdownMenuItem(value: lang, child: Text(lang)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedLanguage = value);
                    // TODO: 實作語言切換邏輯
                  }
                },
              ),
            ),
          ),

          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('深色模式'),
            value: _darkMode,
            onChanged: (value) {
              setState(() => _darkMode = value);
              //有時候只是要操作該實例提供的方法而已，就可以使用Provider.of
              Provider.of<ThemeProvider>(
                context,
                listen: false,
              ).setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
            },
          ),

          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('推播通知'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() => _notificationsEnabled = value);
              // TODO: 實作通知權限控制
            },
          ),

          const Divider(),

          // ── 帳號 ──────────────────────────────────────────
          _SectionHeader(title: '帳號'),

          ListTile(
            leading: const Icon(Icons.manage_accounts_outlined),
            title: const Text('帳號管理'),
            subtitle: const Text('變更密碼、刪除帳號'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AccountManagementPage(),
                ),
              );
            },
          ),

          const Divider(),

          // ── 其他 ──────────────────────────────────────────
          _SectionHeader(title: '其他'),

          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('關於'),
            trailing: const Text(
              'v1.0.0',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            onTap: () {},
          ),

          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('隱私權政策'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 開啟隱私權政策
            },
          ),

          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('服務條款'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 開啟服務條款
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade500,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
