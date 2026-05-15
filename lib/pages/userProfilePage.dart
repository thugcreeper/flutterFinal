import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

//使用者資料頁面，用firebase_auth取得使用者資料
class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late User? _currentUser; //用firebase auth的User物件來存當前user資料
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  Future<void> _handleLogout() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('登出失敗：$e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    // TODO: 實作編輯頁面
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('編輯功能尚未開放')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('個人資料'), elevation: 0),
      body: _currentUser == null
          ? const Center(child: Text('未登入'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 頭像區域
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: _currentUser!.photoURL != null
                              ? NetworkImage(_currentUser!.photoURL!)
                              : null,
                          child: _currentUser!.photoURL == null
                              ? const Icon(Icons.person, size: 60)
                              : null,
                        ),
                        const SizedBox(height: 16),
                        // 用户名稱
                        Text(
                          _currentUser!.displayName ?? '無名稱',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 資料卡片
                  _buildInfoCard(
                    icon: Icons.email,
                    label: '郵箱',
                    value: _currentUser!.email ?? '無郵箱',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.fingerprint,
                    label: 'UID',
                    value: _currentUser!.uid,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.phone,
                    label: '電話',
                    value: _currentUser!.phoneNumber ?? '無電話號碼',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.verified,
                    label: '郵箱驗證',
                    value: _currentUser!.emailVerified ? '已驗證' : '未驗證',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.calendar_today,
                    label: '帳戶建立時間',
                    value:
                        _currentUser!.metadata.creationTime?.toString() ??
                        '無資訊',
                  ),
                  const SizedBox(height: 32),

                  // 按鈕區域
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _updateProfile,
                          icon: const Icon(Icons.edit),
                          label: const Text('編輯資料'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _handleLogout,
                          icon: const Icon(Icons.logout),
                          label: const Text('登出'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(value, maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
