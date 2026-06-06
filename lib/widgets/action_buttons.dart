import 'package:flutter/material.dart';

//返回操作按鈕：復原、清除（僅清本地）、儲存路線至 Firestore、開啟已儲存路線
class ActionButtons extends StatelessWidget {
  const ActionButtons({
    super.key,
    required this.isProcessingRoute,
    required this.undoLastPoint,
    required this.clearRoute,
    required this.saveCurrentRoute,
    required this.openSavedRoutes,
  });

  final bool isProcessingRoute;
  final VoidCallback undoLastPoint;
  final VoidCallback clearRoute;
  final VoidCallback saveCurrentRoute;

  /// 開啟已儲存路線清單（selectable 模式），選取後回傳路線至 HomePage 顯示。
  final VoidCallback openSavedRoutes;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FloatingActionButton(
          heroTag: 'undo-point',
          onPressed: isProcessingRoute ? null : undoLastPoint,
          tooltip: '復原最後一個標記',
          child: const Icon(Icons.undo),
        ),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: 'clear-route',
          onPressed: isProcessingRoute ? null : clearRoute,
          tooltip: '清除路線（僅清除畫面，不影響已儲存路線）',
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          child: const Icon(Icons.delete_outline, size: 40),
        ),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: 'save-route',
          onPressed: isProcessingRoute ? null : saveCurrentRoute,
          tooltip: '儲存路線',
          backgroundColor: const Color.fromARGB(255, 131, 146, 151),
          foregroundColor: Colors.white,
          child: const Icon(Icons.save),
        ),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: 'open-saved-routes',
          onPressed: isProcessingRoute ? null : openSavedRoutes,
          tooltip: '我的路線',
          backgroundColor: const Color.fromARGB(255, 131, 146, 151),
          foregroundColor: Colors.white,
          child: const Icon(Icons.list_alt),
        ),
      ],
    );
  }
}
