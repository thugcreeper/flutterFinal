import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/social_login_section.dart';

//登入頁面，目前提供可用的google功能，fb line 自訂登入開發中，之後有時間可以提供免登入體驗模式
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('登入成功')));
        // TODO: 導向主頁面
      }
    } on FirebaseAuthException catch (e) {
      final message = switch (e.code) {
        'user-not-found' => '找不到此帳號',
        'wrong-password' => '密碼錯誤',
        'invalid-email' => '電子郵件格式不正確',
        'user-disabled' => '此帳號已被停用',
        'too-many-requests' => '嘗試次數過多，請稍後再試',
        _ => '登入失敗：${e.message}',
      };

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const _LoginHeader(),
                const SizedBox(height: 48),

                CustomTextField(
                  label: 'EMAIL',
                  prefixIcon: Icons.mail_outline_rounded,
                  controller: _emailController,
                  validator: (value) {
                    if (value == null || value.isEmpty) return '請輸入電子郵件';
                    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                    if (!emailRegex.hasMatch(value)) return '請輸入有效的電子郵件格式';
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                CustomTextField(
                  label: '密碼',
                  prefixIcon: Icons.lock_outline_rounded,
                  controller: _passwordController,
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) return '請輸入密碼';
                    if (value.length < 6) return '密碼至少需要 6 個字元';
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO: 前往忘記密碼頁面
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF3B82F6),
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      '忘記密碼？',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                PrimaryButton(
                  label: '登入',
                  onPressed: _handleLogin,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 28),
                const _OrDivider(),
                const SizedBox(height: 24),

                const SocialLoginSection(),

                const SizedBox(height: 32),

                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '還沒有帳號？',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: 前往註冊頁面
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF3B82F6),
                          padding: const EdgeInsets.only(left: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          '立即註冊',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 24),
        const Text(
          '歡迎回來',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '請登入你的帳號以繼續',
          style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '或使用以下方式登入',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
      ],
    );
  }
}
