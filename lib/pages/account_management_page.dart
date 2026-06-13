import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/user_profile_api.dart';
import '../widgets/error_snack_bar.dart';
import '../widgets/success_snack_bar.dart';
import '../widgets/gradient_scaffold.dart';
import 'login_page.dart';

class AccountManagementPage extends StatefulWidget {
  const AccountManagementPage({super.key});

  @override
  State<AccountManagementPage> createState() => _AccountManagementPageState();
}

class _AccountManagementPageState extends State<AccountManagementPage> {
  static const String _savedRoutePointsKey = 'saved_route_points';
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ── 變更密碼 ───────────────────────────────────────────
  Future<void> _handleChangePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        ErrorSnackBar(
          message: '新密碼與確認密碼不一致',
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        ErrorSnackBar(
          message: '新密碼至少需要 6 個字元',
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );

      // 重新驗證後才能改密碼
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(_newPasswordController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SuccessSnackBar(
            message: '密碼已成功更新',
            duration: const Duration(seconds: 2),
          ),
        );
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
    } on FirebaseAuthException catch (e) {
      final message = switch (e.code) {
        'wrong-password' => '目前密碼錯誤',
        'weak-password' => '新密碼強度不足',
        'requires-recent-login' => '請重新登入後再試',
        _ => '更新失敗：${e.message}',
      };
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          ErrorSnackBar(message: message, duration: const Duration(seconds: 2)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── 刪除帳號 ───────────────────────────────────────────
  Future<void> _handleDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認刪除帳號'),
        content: const Text('此操作無法復原，你的帳號與所有資料將被永久刪除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('確認刪除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // ── Firebase 登入（Google / Facebook）────────────────
        final String uid = user.uid;
        // 先刪 Firestore 資料
        await FirebaseFirestore.instance.collection('users').doc(uid).delete();
        // 再刪 Firebase Auth 帳號
        await user.delete();
        await FirebaseAuth.instance.signOut();
      } else {
        // ── 本地登入 ──────────────────────────────────────────
        final backendUserId = await _storage.read(key: 'backendUserId');
        if (backendUserId != null && backendUserId.isNotEmpty) {
          // 刪 Firestore 的使用者資料
          await FirebaseFirestore.instance
              .collection('users')
              .doc(backendUserId)
              .delete();
        }
        // 呼叫後端 API 刪帳號
        await UserProfileApiService().deleteAccount();
      }

      // 清除本地所有資料
      await _storage.delete(key: 'backendUserId');
      await _storage.delete(key: 'accessToken');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_savedRoutePointsKey);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SuccessSnackBar(
            message: '帳號已成功刪除',
            duration: const Duration(seconds: 2),
          ),
        );
        // 導回登入頁，清除所有 route
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        final message = e.code == 'requires-recent-login'
            ? '請重新登入後再試'
            : '刪除失敗：${e.message}';
        ScaffoldMessenger.of(context).showSnackBar(
          ErrorSnackBar(message: message, duration: const Duration(seconds: 3)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          ErrorSnackBar(
            message: '刪除失敗：$e',
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
    final user = FirebaseAuth.instance.currentUser;
    final isEmailUser =
        user?.providerData.any((p) => p.providerId == 'password') ?? false;

    return GradientScaffold(
      appBar: AppBar(
        title: const Text('帳號管理'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _glassCard(
            child: ListTile(
              leading: const Icon(
                Icons.account_circle_outlined,
                color: Color.fromARGB(255, 90, 90, 90),
              ),
              title: const Text(
                '登入帳號',
                style: TextStyle(
                  color: Color.fromARGB(255, 90, 90, 90),
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                user?.email ?? '社群帳號登入',
                style: const TextStyle(color: Color.fromARGB(255, 90, 90, 90)),
              ),
            ),
          ),

          const SizedBox(height: 24),

          if (isEmailUser) ...[
            _sectionTitle('變更密碼'),

            const SizedBox(height: 12),
            _glassInput(
              _PasswordField(
                controller: _currentPasswordController,
                label: '目前密碼',
              ),
            ),
            const SizedBox(height: 12),
            _glassInput(
              _PasswordField(controller: _newPasswordController, label: '新密碼'),
            ),
            const SizedBox(height: 12),
            _glassInput(
              _PasswordField(
                controller: _confirmPasswordController,
                label: '確認新密碼',
              ),
            ),

            const SizedBox(height: 16),
            _glassButton(
              text: _isLoading ? '更新中...' : '更新密碼',
              onTap: _isLoading ? null : _handleChangePassword,
            ),

            const SizedBox(height: 24),
          ],

          _sectionTitle('危險區域', color: Colors.red),

          const SizedBox(height: 8),
          _glassCard(
            child: const ListTile(
              leading: Icon(Icons.warning_amber, color: Colors.red),
              title: Text('刪除帳號', style: TextStyle(color: Colors.red)),
              subtitle: Text(
                '刪除後資料無法復原',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ),

          const SizedBox(height: 12),

          _glassButton(
            text: '刪除帳號',

            onTap: _isLoading ? null : _handleDeleteAccount,
          ),
        ],
      ),
    );
  }
}

class _PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;

  const _PasswordField({required this.controller, required this.label});

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(
            _obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}

Widget _glassCard({required Widget child, Color? color}) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 6),
    decoration: BoxDecoration(
      color: (color ?? Colors.white).withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
      border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
    ),
    child: child,
  );
}

Widget _glassInput(Widget child) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
    ),
    child: child,
  );
}

Widget _glassButton({required String text, required VoidCallback? onTap}) {
  return SizedBox(
    width: double.infinity,
    height: 48,

    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.red,
        ),
      ),
    ),
  );
}

Widget _sectionTitle(String text, {Color? color}) {
  return Text(
    text,
    style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: color ?? Colors.black87,
    ),
  );
}
