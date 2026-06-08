import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../models/map_point.dart';
import 'result_card.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// 顯示首頁上的附近搜尋結果清單。
class NearbySearchResultsPanel extends StatefulWidget {
  final bool isLoading;
  final String? cityLabel;
  final String? areaLabel;
  final String category;
  final String? keyword;
  final String? errorMessage;
  final List<MapPoint> results;
  final Future<void> Function() onRefresh;
  final VoidCallback onClose;
  final ValueChanged<MapPoint> onTapPoint;
  final Future<void> Function(MapPoint point) onAddToRoute;
  final DraggableScrollableController? sheetController;

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

  @override
  State<NearbySearchResultsPanel> createState() =>
      NearbySearchResultsPanelState();
}

class NearbySearchResultsPanelState extends State<NearbySearchResultsPanel> {
  // 每個 card 對應一個 GlobalKey，用於 ensureVisible
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  bool scrollToIndex(int index) {
    if (index < 0 || index >= widget.results.length) return false;
    if (!_itemScrollController.isAttached) return false;

    _itemScrollController.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      alignment: 0.1,
    );
    return true;
  }

  void _adjustSheetSize(BuildContext context, double deltaY) {
    final controller = widget.sheetController;
    if (controller == null || !controller.isAttached) return;
    final height = MediaQuery.sizeOf(context).height;
    if (height <= 0) return;
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
                    widget.cityLabel == null
                        ? '正在判斷目前城市'
                        : '目前城市：${widget.cityLabel} ${widget.areaLabel}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '找到 ${widget.results.length} 筆結果',
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
                        label: '目前模式：${widget.category}',
                        color: widget.category == '餐廳'
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF3B82F6),
                      ),
                      if (widget.keyword != null &&
                          widget.keyword!.trim().isNotEmpty)
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
              onPressed: widget.isLoading ? null : widget.onRefresh,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              tooltip: '關閉搜尋結果',
              onPressed: widget.onClose,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheet(ScrollController scrollController) {
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
            if (widget.isLoading)
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
                    if (widget.isLoading && widget.results.isEmpty) {
                      return ListView(
                        controller: scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 120),
                          Center(child: CircularProgressIndicator()),
                        ],
                      );
                    }

                    if (widget.errorMessage != null) {
                      return ListView(
                        controller: scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 80),
                          Center(child: Text(widget.errorMessage!)),
                        ],
                      );
                    }

                    if (widget.results.isEmpty) {
                      return ListView(
                        controller: scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 80),
                          Center(child: Text('目前沒有找到符合的附近結果')),
                        ],
                      );
                    }

                    return ScrollablePositionedList.separated(
                      itemScrollController: _itemScrollController,
                      itemPositionsListener: _itemPositionsListener,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: widget.results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 2),
                      itemBuilder: (context, index) {
                        return ResultCard(
                          point: widget.results[index],
                          onTap: () => widget.onTapPoint(widget.results[index]),
                          onAddToRoute: widget.onAddToRoute,
                        );
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

  @override
  Widget build(BuildContext context) {
    final controller = widget.sheetController;

    if (controller == null) {
      return DraggableScrollableSheet(
        initialChildSize: 0.38,
        minChildSize: 0.24,
        maxChildSize: 0.88,
        builder: (_, scrollController) => _buildSheet(scrollController),
      );
    }

    return DraggableScrollableSheet(
      controller: controller,
      initialChildSize: 0.38,
      minChildSize: 0.24,
      maxChildSize: 0.88,
      builder: (_, scrollController) => _buildSheet(scrollController),
    );
  }
}

class _DesktopDragScrollBehavior extends MaterialScrollBehavior {
  const _DesktopDragScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices =>
      NearbySearchResultsPanel._dragDevices;
}

class _TypeChip extends StatelessWidget {
  final String label;
  final Color color;

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
