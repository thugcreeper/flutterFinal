import 'package:flutter/material.dart';
import 'social_login_button.dart';

class SocialLoginSection extends StatelessWidget {
  const SocialLoginSection({super.key});

  // ── Facebook ─────────────────────────────────────────────
  Future<void> _loginWithFacebook(BuildContext context) async {
    // TODO: 待 Meta 開發者後台設定完成後實作
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Facebook 登入尚未開放')));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SocialLoginButton(
          label: '以 Facebook 帳號登入',
          icon: const Icon(Icons.facebook, size: 24, color: Color(0xFF1877F2)),
          onPressed: () => _loginWithFacebook(context),
        ),
      ],
    );
  }
}
