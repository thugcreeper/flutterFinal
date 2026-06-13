import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/social_login_section.dart';
import 'register_page.dart';
import 'login_success_page.dart';
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

    //先讀取 Firestore 現有資料（避免蓋掉使用者後來改過的名字或頭像）
    final existing = await docRef.get();
    final bool hasExisting = existing.exists;
    final existingImageUrl = hasExisting
        ? (existing.data()?['imageUrl'] ?? '')
        : '';
    final existingName = hasExisting ? (existing.data()?['name'] ?? '') : '';

    // 確保 Email 與 Account 絕對有值
    String emailTarget = user.email ?? '';
    if (emailTarget.isEmpty && user.providerData.isNotEmpty) {
      emailTarget = user.providerData.first.email ?? '';
    }

    final String providerId = user.providerData.isNotEmpty
        ? user.providerData.first.providerId
        : 'unknown';

    String imageUrl = user.photoURL ?? '';

    String accountTarget = emailTarget;
    if (accountTarget.isEmpty) {
      accountTarget = '$providerId:${user.uid}';
    }

    // 準備基礎 Payload
    final payload = {
      'uid': user.uid,
      'account': accountTarget,
      'email': emailTarget,
      'name': existingName.isNotEmpty
          ? existingName
          : (user.displayName ?? '未知使用者'),
      'imageUrl': existingImageUrl.isNotEmpty ? existingImageUrl : imageUrl,
      'provider': providerId,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // 只有當資料庫沒有舊資料時，才寫入絕對的創帳時間
    if (!hasExisting) {
      payload['createdAt'] = FieldValue.serverTimestamp();
    }

    // 寫入或更新到 Firestore
    await docRef.set(payload, SetOptions(merge: true));
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
          MaterialPageRoute(builder: (context) => const LoginSuccessPage()),
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
      await googleSignIn.signOut(); // 確保每次都會彈出帳號選擇器
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
          MaterialPageRoute(builder: (_) => const LoginSuccessPage()),
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

  Future<void> _handleFacebookLogin() async {
    setState(() => _isLoading = true);

    try {
      // 1. 透過 flutter_facebook_auth 觸發原生 Facebook 登入
      final LoginResult loginResult = await FacebookAuth.instance.login(
        permissions: ['public_profile', 'email'],
      );

      if (loginResult.status != LoginStatus.success) {
        setState(() => _isLoading = false);
        if (loginResult.status == LoginStatus.cancelled) return;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            ErrorSnackBar(
              message: 'Facebook 授權失敗：${loginResult.message}',
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final AccessToken? fbToken = loginResult.accessToken;
      if (fbToken == null) {
        setState(() => _isLoading = false);
        return;
      }

      // 2. 使用 Facebook 的 AccessToken 登入 Firebase
      final OAuthCredential credential = FacebookAuthProvider.credential(
        fbToken.tokenString,
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
            message: 'Facebook 登入成功！(Firebase)',
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginSuccessPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        final message = switch (e.code) {
          'account-exists-with-different-credential' =>
            '此 Email 已被其他登入方式註冊，請使用原方式登入。',
          'invalid-credential' => 'Facebook 登入憑證無效或已過期。',
          'user-disabled' => '此帳號已被停用。',
          'operation-not-allowed' => 'Facebook 登入尚未在 Firebase 啟用。',
          _ => 'Firebase 錯誤 (${e.code}): ${e.message}',
        };

        ScaffoldMessenger.of(context).showSnackBar(
          ErrorSnackBar(message: message, duration: const Duration(seconds: 3)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          ErrorSnackBar(
            message: '發生未知錯誤：$e',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.fromARGB(255, 163, 205, 238), Color(0xFFF8FFFE)],
          ),
        ),
        child: SafeArea(
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
                      onFacebookPressed: _handleFacebookLogin,
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
