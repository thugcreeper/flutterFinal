import 'package:flutter/material.dart';
import 'package:sign_in_button/sign_in_button.dart';

// 社群登入區塊，包含 Google、Facebook 等第三方登入選項，目前僅實作 Google 登入的按鈕與提示，Facebook 登入待 Meta 開發者後台設定完成後再實作。
class SocialLoginSection extends StatelessWidget {
  const SocialLoginSection({
    super.key,
    this.onGooglePressed,
    this.buttonWidth = double.infinity,
    this.buttonHeight = 50,
  });

  final VoidCallback? onGooglePressed;
  final double buttonWidth;
  final double buttonHeight;

  // ── Google ───────────────────────────────────────────────
  void _loginWithGoogle(BuildContext context) {
    //  如果外部有提供 Google 登入的實作，就呼叫它；否則顯示提示訊息
    if (onGooglePressed != null) {
      onGooglePressed!();
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Google 登入尚未接上')));
  }

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
        SizedBox(
          width: buttonWidth,
          height: buttonHeight,
          child: SignInButton(
            Buttons.google,
            onPressed: () => _loginWithGoogle(context),
            loadingIndicatorColor: const Color.fromARGB(255, 54, 232, 66),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: buttonWidth,
          height: buttonHeight,
          child: SignInButton(
            Buttons.facebook,
            onPressed: () => _loginWithFacebook(context),
            loadingIndicatorColor: const Color.fromARGB(255, 57, 89, 179),
          ),
        ),
      ],
    );
  }
}
