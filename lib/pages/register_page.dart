import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'register_success_page.dart';
import '../api/auth_api.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _accountController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  String _confirmError = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_confirmError.isNotEmpty) return;

    setState(() => _isLoading = true);

    try {
      final account = _accountController.text.trim();
      final name = _nameController.text.trim();

      final api = ApiService();
      final result = await api.register(
        account,
        _passwordController.text.trim(),
        name,
      );
      final user = Map<String, dynamic>.from(result['user'] as Map);
      final userId = (user['id'] ?? '').toString();
      if (userId.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'uid': userId,
          'account': (user['account'] ?? account).toString(),
          'name': (user['name'] ?? name).toString(),
          'email': '',
          'imageUrl': (user['imageUrl'] ?? '').toString(),
          'provider': (user['provider'] ?? 'local').toString(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        await _storage.write(key: 'backendUserId', value: userId);
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RegistrationSuccessPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('註冊失敗：$e'),
            backgroundColor: Colors.red,
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
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1A1A2E),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // 標題
                const Text(
                  '建立帳號',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                    height: 1.1,
                  ),
                ),

                const SizedBox(height: 36),

                _buildField(
                  controller: _nameController,
                  label: '顯示名稱',
                  icon: Icons.badge_outlined,
                  hint: '你希望別人怎麼稱呼你',
                  validator: (v) => (v == null || v.isEmpty) ? '請輸入名稱' : null,
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _accountController,
                  label: '帳號',
                  icon: Icons.person_outline_rounded,
                  hint: 'yourusername',
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _passwordController,
                  label: '密碼',
                  icon: Icons.lock_outline_rounded,
                  hint: '至少 6 個字元',
                  isPassword: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return '請輸入密碼';
                    if (v.length < 6) return '密碼至少需要 6 個字元';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _confirmPasswordController,
                  label: '確認密碼',
                  icon: Icons.lock_outline_rounded,
                  hint: '再次輸入密碼',
                  isPassword: true,
                  errorText: _confirmError.isEmpty ? null : _confirmError,
                  onChanged: (v) {
                    setState(() {
                      _confirmError = v != _passwordController.text
                          ? '密碼不一致'
                          : '';
                    });
                  },
                  validator: (v) {
                    if (v == null || v.isEmpty) return '請再次輸入密碼';
                    if (v != _passwordController.text) return '密碼不一致';
                    return null;
                  },
                ),

                const SizedBox(height: 36),

                // 註冊按鈕
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF93C5FD),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            '建立帳號',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // 返回登入
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '已有帳號？',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8A8FA8),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF3B82F6),
                          padding: const EdgeInsets.only(left: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          '返回登入',
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    bool isPassword = false,
    String? errorText,
    TextInputType? keyboardType,
    void Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return _PasswordAwareField(
      controller: controller,
      label: label,
      icon: icon,
      hint: hint,
      isPassword: isPassword,
      externalErrorText: errorText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
    );
  }
}

// 支援密碼顯示切換的欄位
class _PasswordAwareField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String hint;
  final bool isPassword;
  final String? externalErrorText;
  final TextInputType? keyboardType;
  final void Function(String)? onChanged;
  final String? Function(String?)? validator;

  const _PasswordAwareField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.hint,
    this.isPassword = false,
    this.externalErrorText,
    this.keyboardType,
    this.onChanged,
    this.validator,
  });

  @override
  State<_PasswordAwareField> createState() => _PasswordAwareFieldState();
}

class _PasswordAwareFieldState extends State<_PasswordAwareField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF8A8FA8),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          obscureText: widget.isPassword && _obscure,
          keyboardType: widget.keyboardType,
          onChanged: widget.onChanged,
          validator: widget.validator,
          style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E)),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(color: Color(0xFFCBD5E0), fontSize: 14),
            errorText: widget.externalErrorText,
            prefixIcon: Icon(
              widget.icon,
              color: const Color(0xFFCBD5E0),
              size: 20,
            ),
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFFCBD5E0),
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE8ECF0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE8ECF0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF3B82F6),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
