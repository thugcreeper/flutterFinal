import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/user_profile_api.dart';
import 'login_page.dart';
import 'edit_profile_page.dart';
import 'saved_routes_page.dart';
import '../widgets/error_snack_bar.dart';
import '../widgets/user_profile_dialog.dart';
import '../widgets/gradient_scaffold.dart';

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

  @override
  void dispose() {
    super.dispose();
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
          return GradientScaffold(
            appBar: AppBar(title: const Text('個人資料'), elevation: 0),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final backendUserId = idSnapshot.data;
        if (backendUserId == null || backendUserId.isEmpty) {
          return GradientScaffold(
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

        return GradientScaffold(
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
                      leadingColor: Color(0xFF3B82F6),
                      icon: Icons.person,
                      label: '帳號',
                      value: account,
                    ),
                    const SizedBox(height: 6),
                    _buildInfoCard(
                      leadingColor: Color(0xFFE15B74),
                      icon: Icons.email,
                      label: 'Email',
                      value: email,
                    ),
                    const SizedBox(height: 6),
                    _buildInfoCard(
                      leadingColor: Color(0xFF10B981),
                      icon: Icons.description,
                      label: '個人介紹',
                      value: description,
                      trailingIcon: const Icon(
                        Icons.arrow_forward_ios,
                        size: 20,
                      ),
                      onTap: () {
                        showDescriptionDialog(context, description);
                      },
                    ),
                    const SizedBox(height: 6),
                    _buildInfoCard(
                      leadingColor: Color(0xFFF59E0B),
                      icon: Icons.login,
                      label: '登入方式',
                      value: provider,
                    ),
                    const SizedBox(height: 6),
                    _buildInfoCard(
                      leadingColor: Color(0xFF8B5CF6),
                      icon: Icons.route,
                      label: '我的路線',
                      value: '查看和管理您儲存的自行車路線',
                      trailingIcon: const Icon(
                        Icons.arrow_forward_ios,
                        size: 20,
                      ),
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

    return GradientScaffold(
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
          } else if (user.displayName != null && user.displayName!.isNotEmpty) {
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
                  leadingColor: Color(0xFF3B82F6),
                  icon: Icons.person,
                  label: '帳號',
                  value: account,
                ),
                const SizedBox(height: 6),
                _buildInfoCard(
                  leadingColor: Color(0xFFE15B74),
                  icon: Icons.email,
                  label: 'Email',
                  value: email,
                ),
                const SizedBox(height: 6),
                _buildInfoCard(
                  leadingColor: Color(0xFF10B981),
                  icon: Icons.description,
                  label: '個人介紹',
                  value: description,
                  trailingIcon: const Icon(Icons.arrow_forward_ios, size: 20),
                  onTap: () {
                    showDescriptionDialog(context, description);
                  },
                ),
                const SizedBox(height: 6),
                _buildInfoCard(
                  leadingColor: Color(0xFFF59E0B),
                  icon: Icons.login,
                  label: '登入方式',
                  value: provider,
                ),
                const SizedBox(height: 6),
                _buildInfoCard(
                  leadingColor: Color(0xFF8B5CF6),
                  icon: Icons.route,
                  label: '我的路線',
                  value: '查看和管理自行車路線',
                  trailingIcon: const Icon(Icons.arrow_forward_ios, size: 20),
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
                    // 編輯資料按鈕
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: TextButton.icon(
                          onPressed: _isLoading ? null : _updateProfile,
                          icon: Icon(
                            Icons.edit,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : const Color(0xFF1E293B),
                            size: 18,
                          ),
                          label: const Text('編輯資料'),
                          style: TextButton.styleFrom(
                            // 根據深淺色，給予低調的灰黑或純白底色
                            backgroundColor:
                                Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF334155)
                                : const Color(0xFFF1F5F9),
                            foregroundColor:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : const Color(0xFF1E293B),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 登出按鈕
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: TextButton.icon(
                          onPressed: _isLoading ? null : _handleLogout,
                          icon: const Icon(
                            Icons.logout,
                            color: Color(0xFFEF4444),
                            size: 18,
                          ),
                          label: const Text('登出'),
                          style: TextButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF334155)
                                : const Color(0xFFF1F5F9),
                            foregroundColor: const Color(0xFFEF4444),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
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
    );
  }

  Widget _buildInfoCard({
    required Color leadingColor, // 左側區塊的背景顏色
    required IconData icon, // 顯示的 Icon
    required String label, // 主標題（如：Arts）
    required String value, // 子標題（如：114 Videos）
    Widget? trailingIcon, // 右側可選的 Icon（不傳就不顯示）
    VoidCallback? onTap, // 點擊事件
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24), // 圖片中的大圓角風格
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // ======= 左側獨立顏色區塊 =======
                  Container(
                    width: 72, // 寬度可以根據設計調整
                    color: leadingColor,
                    alignment: Alignment.center,
                    child: Icon(
                      icon,
                      size: 36, // 放大 Icon，凸顯主題
                      color: Colors.white, // 圖片中均為純白 Icon
                    ),
                  ),

                  const SizedBox(width: 18),

                  // ======= 中間文字內容 =======
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 22, // 圓潤大字體風格
                              fontWeight: FontWeight.w800, // 強調字重
                              color: Color(0xFF2D2D2D),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ======= 右側可選 Icon 區塊 =======
                  if (trailingIcon != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: trailingIcon,
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
