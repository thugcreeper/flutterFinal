// 這個檔案負責顯示使用者已儲存的路線清單，支援即時更新、刪除，以及選取後回傳。

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import '../providers/route_provider.dart';
import '../api/saved_route_api.dart';
import '../models/saved_route.dart';
import '../widgets/error_snack_bar.dart';

/// 已儲存路線瀏覽頁面。
///
/// Parameters:
/// - selectable: 若為 true，點擊路線後會以 Navigator.pop 回傳 [SavedRoute]；
///               若為 false（預設），只供瀏覽與刪除。
class SavedRoutesPage extends StatefulWidget {
  const SavedRoutesPage({super.key, this.selectable = false});

  final bool selectable;

  @override
  State<SavedRoutesPage> createState() => _SavedRoutesPageState();
}

class _SavedRoutesPageState extends State<SavedRoutesPage> {
  final _storage = const FlutterSecureStorage();
  String? _userId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _resolveUserId();
  }

  /// 優先使用 Firebase Auth UID，若無則讀取 backendUserId（本地登入）。
  Future<void> _resolveUserId() async {
    final firebaseUid = FirebaseAuth.instance.currentUser?.uid;
    if (firebaseUid != null && firebaseUid.isNotEmpty) {
      setState(() {
        _userId = firebaseUid;
        _loading = false;
      });
      return;
    }

    final backendId = await _storage.read(key: 'backendUserId');
    setState(() {
      _userId = (backendId?.isNotEmpty == true) ? backendId : null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的路線'), elevation: 0),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_userId == null) return const Center(child: Text('尚未登入'));

    return StreamBuilder<List<SavedRoute>>(
      stream: SavedRouteApiService().getUserRoutesStream(_userId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('讀取失敗：${snapshot.error}'));
        }

        final routes = snapshot.data ?? [];
        if (routes.isEmpty) return const Center(child: Text('尚未儲存任何路線'));

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: routes.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final route = routes[index];
            return _RouteListTile(
              route: route,
              selectable: widget.selectable,
              //
              onSelect: () {
                context.read<RouteProvider>().selectRoute(route);
                Navigator.of(
                  context,
                ).popUntil((route) => route.settings.name == '/');
              },
            );
          },
        );
      },
    );
  }
}

/// 單一路線的 ListTile，包含基本資訊、刪除按鈕，以及可選取模式。
class _RouteListTile extends StatelessWidget {
  const _RouteListTile({
    required this.route,
    required this.selectable,
    required this.onSelect,
  });

  final SavedRoute route;
  final bool selectable;
  final VoidCallback onSelect;

  /// 刪除路線，並顯示對應的 SnackBar。
  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('刪除路線'),
        content: Text('確定要刪除「${route.routeName}」嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('刪除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await SavedRouteApiService().deleteRoute(route.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(ErrorSnackBar(message: '刪除失敗：$e'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final date =
        '${route.createdAt.year}/${route.createdAt.month.toString().padLeft(2, '0')}/${route.createdAt.day.toString().padLeft(2, '0')}';

    return ListTile(
      leading: const Icon(Icons.route),
      title: Text(route.routeName),
      subtitle: Text(
        '$date  ·  ${route.distance}  ·  ${route.duration}\n'
        '爬升 ${route.totalAscent.toStringAsFixed(0)} m  ·  下降 ${route.totalDescent.toStringAsFixed(0)} m',
      ),
      isThreeLine: true,
      onTap: selectable ? onSelect : null,
      trailing: selectable
          ? const Icon(Icons.arrow_forward_ios, size: 16)
          : IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: '刪除路線',
              onPressed: () => _delete(context),
            ),
    );
  }
}
