// 這個檔案負責顯示使用者已儲存的路線清單，支援即時更新、刪除，以及選取後回傳。

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import '../providers/route_provider.dart';
import '../api/saved_route_api.dart';
import '../models/saved_route.dart';
import '../widgets/error_snack_bar.dart';
import '../widgets/safe_asset_image.dart';
import '../widgets/gradient_scaffold.dart';

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
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('我的路線'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
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
        if (routes.isEmpty) {
          return const Center(
            child: Text(
              '尚未儲存任何路線!!!',
              style: TextStyle(fontSize: 28, color: Colors.black),
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 8, bottom: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                //用richtext讓數字部分突出顯示
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 18,
                      //避免寫死顏色，讓他依據深淺色模式自動變換
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    children: [
                      TextSpan(
                        text: '${routes.length}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      const TextSpan(text: ' 條已儲存路線'),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
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
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 單一路線的 ListTile，包含基本資訊、刪除按鈕
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

    return Dismissible(
      // key 必須是唯一的，這裡用 route.id
      key: Key(route.id),
      // 設定只允許從右往左拉（出現右側的垃圾桶）
      direction: DismissDirection.endToStart,
      // 觸發滑動時彈出確認對話框，回傳 true 才會真正觸發滑動消失動畫
      confirmDismiss: (direction) async {
        await _delete(context);
        // 因為 _delete 內部已經處理了 API 刪除，不論成功或失敗，
        // 這裡都回傳 false，讓 StreamBuilder 重新整理資料來控制 UI 的消失，避免與滑動動畫衝突
        return false;
      },
      // 滑動時顯現的背景（垃圾桶圖案）
      background: Container(
        color: Colors.redAccent,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SafeAssetImage(
              assetPath: 'assets/icons/route.png',
              width: 40,
              height: 40,
            ),
          ),
          title: Text(
            route.routeName,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),

              Row(
                children: [
                  Expanded(child: _buildBadge(route.distance)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildBadge(route.duration)),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      '↑ ${route.totalAscent.toStringAsFixed(0)}m',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      '↓ ${route.totalDescent.toStringAsFixed(0)}m',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "建立日期: ${date}",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),

          onTap: selectable ? onSelect : null,
          // 如果是 selectable 模式就顯示箭頭，否則顯示提示使用者可以滑動刪除的圖標（或保留清除）
          trailing: selectable
              ? const Icon(Icons.arrow_forward_ios, size: 20)
              : const Icon(
                  Icons.drag_handle,
                  color: Colors.grey,
                  size: 20,
                ), // 提示可拖曳/滑動
        ),
      ),
    );
  }
}

// 用於顯示路線類型或其他標籤
Widget _buildBadge(String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  );
}
