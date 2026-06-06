import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'error_snack_bar.dart';

import '../models/map_point.dart';
import '../models/restaurant.dart';

/// 顯示首頁上的附近搜尋結果清單。
class NearbySearchResultsPanel extends StatelessWidget {
  /// 是否正在載入搜尋結果。
  final bool isLoading;

  /// 目前判斷出的城市名稱。
  final String? cityLabel;

  /// 目前判斷出的區域名稱。
  final String? areaLabel;

  /// 目前搜尋分類。
  final String category;

  /// 使用者輸入的關鍵字。
  final String? keyword;

  /// 錯誤訊息。
  final String? errorMessage;

  /// 搜尋結果清單。
  final List<MapPoint> results;

  /// 重新整理搜尋結果。
  final Future<void> Function() onRefresh;

  /// 關閉結果面板。
  final VoidCallback onClose;

  /// 點擊卡片時要聚焦地圖上的點位。
  final ValueChanged<MapPoint> onTapPoint;

  /// 將點位接到目前路線。
  final Future<void> Function(MapPoint point) onAddToRoute;

  /// 控制底部面板高度。
  final DraggableScrollableController? sheetController;

  /// 建立附近搜尋結果面板。
  const NearbySearchResultsPanel({
    super.key,
    required this.isLoading,
    required this.cityLabel,
    required this.areaLabel,
    required this.category,
    required this.keyword,
    required this.errorMessage,
    required this.results,
    required this.onRefresh,
    required this.onClose,
    required this.onTapPoint,
    required this.onAddToRoute,
    this.sheetController,
  });

  static const Set<PointerDeviceKind> _dragDevices = {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
    PointerDeviceKind.trackpad,
  };

  void _adjustSheetSize(BuildContext context, double deltaY) {
    final controller = sheetController;
    if (controller == null || !controller.isAttached) {
      return;
    }

    final height = MediaQuery.sizeOf(context).height;
    if (height <= 0) {
      return;
    }

    final nextSize = (controller.size - (deltaY / height)).clamp(0.24, 0.88);
    controller.jumpTo(nextSize);
  }

  Widget _buildDraggableSummary(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: (details) =>
          _adjustSheetSize(context, details.delta.dy),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    cityLabel == null
                        ? '正在判斷目前城市'
                        : '目前城市：$cityLabel $areaLabel',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '找到 ${results.length} 筆結果',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _TypeChip(
                        label: '目前模式：$category',
                        color: category == '餐廳'
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF3B82F6),
                      ),
                      if (keyword != null && keyword!.trim().isNotEmpty)
                        const _TypeChip(
                          label: '關鍵字搜尋',
                          color: Color(0xFF64748B),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: '重新整理搜尋結果',
              onPressed: isLoading ? null : onRefresh,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              tooltip: '關閉搜尋結果',
              onPressed: onClose,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, MapPoint point) {
    final subtitle = point is Restaurant
        ? point.address.isNotEmpty
              ? point.address
              : point.description
        : point.description;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onTapPoint(point),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: point.pictureUrl.isNotEmpty
                        ? Image.network(
                            point.pictureUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildLeadingAvatar(point),
                          )
                        : _buildLeadingAvatar(point),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          point.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle.isNotEmpty ? subtitle : point.city,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _TypeChip(
                              label: point.typeLabel,
                              color: point.typeLabel == '餐廳'
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF3B82F6),
                            ),
                            if (point.city.isNotEmpty)
                              const _TypeChip(
                                label: '城市',
                                color: Color(0xFF64748B),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await onAddToRoute(point);
                    } catch (e) {
                      messenger.showSnackBar(
                        ErrorSnackBar(message: '接到路線發生錯誤：$e'),
                      );
                    }
                  },
                  icon: const Icon(Icons.route_outlined),
                  label: const Text('接到路線'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingAvatar(MapPoint point) {
    return Container(
      width: 60,
      height: 60,
      color: Colors.grey.shade200,
      child: Icon(
        point.typeLabel == '餐廳' ? Icons.restaurant : Icons.location_on,
        color: Colors.grey.shade600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = sheetController;

    Widget buildSheet(ScrollController scrollController) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),
              _buildDraggableSummary(context),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: ScrollConfiguration(
                  behavior: const _DesktopDragScrollBehavior(),
                  child: Builder(
                    builder: (context) {
                      if (isLoading && results.isEmpty) {
                        return ListView(
                          controller: scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 120),
                            Center(child: CircularProgressIndicator()),
                          ],
                        );
                      }

                      if (errorMessage != null) {
                        return ListView(
                          controller: scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 80),
                            Center(child: Text(errorMessage!)),
                          ],
                        );
                      }

                      if (results.isEmpty) {
                        return ListView(
                          controller: scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 80),
                            Center(child: Text('目前沒有找到符合的附近結果')),
                          ],
                        );
                      }

                      return ListView.separated(
                        controller: scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: results.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 2),
                        itemBuilder: (context, index) {
                          return _buildResultCard(context, results[index]);
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (controller == null) {
      return DraggableScrollableSheet(
        initialChildSize: 0.38,
        minChildSize: 0.24,
        maxChildSize: 0.88,
        builder: (context, scrollController) => buildSheet(scrollController),
      );
    }

    return DraggableScrollableSheet(
      controller: controller,
      initialChildSize: 0.38,
      minChildSize: 0.24,
      maxChildSize: 0.88,
      builder: (context, scrollController) => buildSheet(scrollController),
    );
  }
}

class _DesktopDragScrollBehavior extends MaterialScrollBehavior {
  const _DesktopDragScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices =>
      NearbySearchResultsPanel._dragDevices;
}

/// 搜尋結果分類卡片的小標籤。
class _TypeChip extends StatelessWidget {
  /// 標籤文字。
  final String label;

  /// 標籤顏色。
  final Color color;

  /// 建立分類標籤。
  const _TypeChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
