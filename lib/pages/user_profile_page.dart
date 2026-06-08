import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/user_profile_api.dart';
import 'login_page.dart';
import 'edit_profile_page.dart';
import 'saved_routes_page.dart';
import '../widgets/error_snack_bar.dart';

//使用者資料頁面，用firebase_auth取得使用者資料
class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late User? _currentUser; // 當前登入使用者
  final _storage = const FlutterSecureStorage();
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
      await UserProfileApiService().logout();
      await _storage.delete(key: 'backendUserId');
      if (mounted) {
        //用pushAndRemove來將先前route全部銷毀
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          ErrorSnackBar(
            message: '登出失敗：$e',
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    // 根據目前使用者類型開啟編輯頁
    try {
      if (_currentUser != null) {
        final result = await Navigator.push<bool?>(
          context,
          MaterialPageRoute(
            builder: (_) => EditProfilePage(firebaseUser: _currentUser),
          ),
        );
        if (result == true && mounted) setState(() {});
        return;
      }

      final backendUserId = await _storage.read(key: 'backendUserId');
      if (backendUserId == null || backendUserId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            ErrorSnackBar(
              message: '找不到後端使用者 ID，請重新登入',
              duration: const Duration(seconds: 3),
            ),
          );
        }

        return;
      }

      final result = await Navigator.push<bool?>(
        context,
        MaterialPageRoute(
          builder: (_) => EditProfilePage(backendUserId: backendUserId),
        ),
      );
      if (result == true && mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          ErrorSnackBar(
            message: '開啟編輯失敗：$e',
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;

    if (user != null) {
      return _buildFirebaseProfile(user);
    }

    return FutureBuilder<String?>(
      future: _storage.read(key: 'backendUserId'),
      builder: (context, idSnapshot) {
        if (idSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('個人資料'), elevation: 0),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final backendUserId = idSnapshot.data;
        if (backendUserId == null || backendUserId.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('個人資料'), elevation: 0),
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                ),
                child: const Text('跳轉至登入頁'),
              ),
            ),
          );
        }

        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromARGB(255, 161, 195, 221),
                Color.fromARGB(255, 255, 255, 255),
              ],
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: const Text('個人資料'),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(backendUserId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data?.data();
                if (data == null) {
                  return const Center(child: Text('找不到使用者資料'));
                }

                final name = (data['name'] ?? '').toString();
                final account = (data['account'] ?? '').toString();
                final email = (data['email'] ?? '').toString();
                final description = (data['description'] ?? '').toString();
                final imageUrl = (data['imageUrl'] ?? '').toString();
                final provider = (data['provider'] ?? 'local').toString();

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundImage: imageUrl.isNotEmpty
                                  ? NetworkImage(imageUrl)
                                  : null,
                              child: imageUrl.isEmpty
                                  ? const Icon(Icons.person, size: 60)
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              name.isEmpty ? '無名稱' : name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildInfoCard(
                        icon: Icons.person,
                        label: '帳號',
                        value: account,
                      ),
                      const SizedBox(height: 6),
                      _buildInfoCard(
                        icon: Icons.email,
                        label: '電子信箱',
                        value: email.isEmpty ? '尚未提供電子信箱!' : email,
                      ),
                      const SizedBox(height: 6),
                      _buildInfoCard(
                        icon: Icons.description,
                        label: '簡介',
                        value: description.isEmpty ? '尚未提供簡介!' : description,
                      ),
                      const SizedBox(height: 6),
                      _buildInfoCard(
                        icon: Icons.login,
                        label: '登入方式',
                        value: provider,
                      ),
                      const SizedBox(height: 6),
                      _buildInfoCard(
                        icon: Icons.route,
                        label: '我的路線',
                        value: '查看和管理您儲存的自行車路線',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const SavedRoutesPage(selectable: true),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
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
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildFirebaseProfile(User user) {
    String? userPhoto;
    for (final profile in user.providerData) {
      if (profile.providerId == 'facebook.com') {
        userPhoto = profile.photoURL;
        break;
      }
    }
    userPhoto ??= user.photoURL;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromARGB(255, 161, 195, 221),
            Color.fromARGB(255, 255, 255, 255),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('個人資料'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data?.data();
            String displayName = '無名稱';

            if (data?['name'] != null &&
                (data!['name'] as String).trim().isNotEmpty) {
              // 優先使用 Firestore 資料庫裡的名字
              displayName = data['name'] as String;
            } else if (user.displayName != null &&
                user.displayName!.isNotEmpty) {
              // 次之使用第三方登入（Google/FB）帶過來的名字
              displayName = user.displayName!;
            }
            final account = (data?['account'] as String?) ?? (user.email ?? '');
            final email = (data?['email'] as String?) ?? (user.email ?? '無郵箱');
            final description = (data?['description'] as String?) ?? '尚未提供簡介';
            String imageUrl = '';
            if (data?['imageUrl'] != null &&
                (data!['imageUrl'] as String).trim().isNotEmpty) {
              imageUrl = data['imageUrl'] as String;
            } else if (userPhoto != null && userPhoto.isNotEmpty) {
              // 沒有才用第三方登入的頭像
              imageUrl = userPhoto;
            }
            if (imageUrl.contains("graph.facebook.com") &&
                !imageUrl.contains("?")) {
              imageUrl = "$imageUrl?type=large";
            }
            final provider =
                (data?['provider'] as String?) ??
                (user.providerData.isNotEmpty
                    ? user.providerData.first.providerId
                    : 'unknown');

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: imageUrl.isNotEmpty
                              ? NetworkImage(imageUrl)
                              : null,
                          child: imageUrl.isEmpty
                              ? const Icon(Icons.person, size: 60)
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildInfoCard(
                    icon: Icons.person,
                    label: '帳號',
                    value: account,
                  ),
                  const SizedBox(height: 6),
                  _buildInfoCard(
                    icon: Icons.email,
                    label: 'Email',
                    value: email,
                  ),
                  const SizedBox(height: 6),
                  _buildInfoCard(
                    icon: Icons.description,
                    label: '個人介紹',
                    value: description ?? '暫無介紹',
                  ),
                  const SizedBox(height: 6),
                  _buildInfoCard(
                    icon: Icons.login,
                    label: '登入方式',
                    value: provider,
                  ),
                  const SizedBox(height: 6),
                  _buildInfoCard(
                    icon: Icons.route,
                    label: '我的路線',
                    value: '查看和管理您儲存的自行車路線',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SavedRoutesPage(selectable: true),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color.fromARGB(255, 227, 226, 226), Color(0xFFFFFFFF)],
          stops: [0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: const Color.fromARGB(255, 247, 216, 16),
          width: 0.7,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap, // 點擊事件
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 30, color: const Color(0xFF2563EB)),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),

                if (onTap != null)
                  const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
