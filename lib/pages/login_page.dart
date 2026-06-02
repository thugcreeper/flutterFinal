import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/social_login_section.dart';
import 'register_page.dart';
import 'home_page.dart';
import '../api/auth_api.dart';
import '../widgets/error_snack_bar.dart';
import '../widgets/success_snack_bar.dart';

//登入頁面，目前提供可用的google功能，fb line 自訂登入開發中，之後有時間可以提供免登入體驗模式
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _accountController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  bool _isLoading = false;

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _syncFirebaseUserProfile(User user) async {
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final payload = {
      'uid': user.uid,
      'account': user.email ?? '',
      'name': user.displayName ?? '',
      'email': user.email ?? '',
      'imageUrl': user.photoURL ?? '',
      'provider': user.providerData.isNotEmpty
          ? user.providerData.first.providerId
          : 'google.com',
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await docRef.set({
      ...payload,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _syncBackendUserProfile(Map<String, dynamic> user) async {
    final userId = (user['id'] ?? '').toString();
    if (userId.isEmpty) return;

    final docRef = FirebaseFirestore.instance.collection('users').doc(userId);
    await docRef.set({
      'uid': userId,
      'account': (user['account'] ?? '').toString(),
      'name': (user['name'] ?? '').toString(),
      'email': '',
      'imageUrl': (user['imageUrl'] ?? '').toString(),
      'provider': (user['provider'] ?? 'local').toString(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _storage.write(key: 'backendUserId', value: userId);
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final api = ApiService();
      final result = await api.login(
        _accountController.text.trim(),
        _passwordController.text.trim(),
      );

      final isOk = result['ok'] == true;
      if (!isOk) {
        final message = (result['message'] ?? '登入失敗，請稍後再試').toString();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            ErrorSnackBar(
              message: message,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final user = Map<String, dynamic>.from(result['user'] as Map);
      await _syncBackendUserProfile(user);
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SuccessSnackBar(
            message: '登入成功',
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          ErrorSnackBar(
            message: '登入失敗：$e',
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);

    try {
      // 先叫出 Google 帳號選擇器，再把結果換成 Firebase 可用的憑證。
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      // 使用從 Google 取得的 access token 和 id token 來建立 Firebase 的 OAuth 憑證。
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final user = userCredential.user;
      if (user != null) {
        await _syncFirebaseUserProfile(user);
        await _storage.delete(key: 'backendUserId');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SuccessSnackBar(
            message: 'Google 登入成功',
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      final message = switch (e.code) {
        'account-exists-with-different-credential' => '此帳號已用其他方式註冊',
        'invalid-credential' => 'Google 驗證失敗',
        'operation-not-allowed' => 'Google 登入尚未啟用',
        'user-disabled' => '此帳號已被停用',
        _ => 'Google 登入失敗：${e.message}',
      };

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          ErrorSnackBar(message: message, duration: const Duration(seconds: 3)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          ErrorSnackBar(
            message: 'Google 登入失敗：$e',
            duration: const Duration(seconds: 3),
          ),
        );
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
                  label: '帳號',
                  prefixIcon: Icons.mail_outline_rounded,
                  controller: _accountController,
                  validator: (value) {
                    if (value == null || value.isEmpty) return '請輸入帳號';

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

                Center(
                  child: SocialLoginSection(
                    onGooglePressed: _handleGoogleLogin,
                  ),
                ),

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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterPage(),
                            ),
                          );
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
