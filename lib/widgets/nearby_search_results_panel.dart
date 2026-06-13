import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../models/map_point.dart';
import 'result_card.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

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
  final ValueChanged<double>? onHeightChanged;

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
    required this.onHeightChanged,
  });

  @override
  State<NearbySearchResultsPanel> createState() =>
      NearbySearchResultsPanelState();
}

class NearbySearchResultsPanelState extends State<NearbySearchResultsPanel>
    with SingleTickerProviderStateMixin {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  // 面板高度比例：0.0 ~ 1.0，對應螢幕高度的 24% ~ 88%
  double _heightFraction = 0.42;
  static const double _minFraction = 0.24;
  static const double _maxFraction = 0.88;

  late final AnimationController _snapController;
  late Animation<double> _snapAnimation;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _onHandleDragUpdate(DragUpdateDetails details) {
    final screenHeight = MediaQuery.of(context).size.height;
    setState(() {
      _heightFraction = (_heightFraction - details.delta.dy / screenHeight)
          .clamp(_minFraction, _maxFraction);
    });
  }

  void _onHandleDragEnd(DragEndDetails details) {
    // 放手時 snap 到最近的一個固定高度
    const snapPoints = [0.24, 0.42, 0.88];
    final nearest = snapPoints.reduce(
      (a, b) =>
          (_heightFraction - a).abs() < (_heightFraction - b).abs() ? a : b,
    );

    _snapAnimation =
        Tween<double>(begin: _heightFraction, end: nearest).animate(
          CurvedAnimation(parent: _snapController, curve: Curves.easeOut),
        )..addListener(() {
          setState(() => _heightFraction = _snapAnimation.value);
        });

    _snapController.forward(from: 0);
  }

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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final panelHeight = screenHeight * _heightFraction;
    // 通知父 widget 面板高度變化（用於調整地圖 padding）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onHeightChanged?.call(panelHeight);
    });
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: panelHeight,
      child: Container(
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
              // ── Handle bar（唯一可拖曳區域）─────────────────
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: _onHandleDragUpdate,
                onVerticalDragEnd: _onHandleDragEnd,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── 摘要列 ────────────────────────────────────
              Padding(
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
                                : '${widget.cityLabel} ${widget.areaLabel}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            children: [
                              Text(
                                '${widget.results.length} 筆結果',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              _TypeChip(
                                label: widget.category,
                                color: widget.category == '餐廳'
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF3B82F6),
                              ),
                              if (widget.keyword != null &&
                                  widget.keyword!.trim().isNotEmpty)
                                const _TypeChip(
                                  label: '關鍵字',
                                  color: Color(0xFF64748B),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (widget.isLoading)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    IconButton(
                      tooltip: '重新整理',
                      onPressed: widget.isLoading ? null : widget.onRefresh,
                      icon: const Icon(Icons.refresh, size: 20),
                    ),
                    IconButton(
                      tooltip: '關閉',
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
              ),

              const Divider(height: 12),

              // ── 結果列表 ──────────────────────────────────
              Expanded(child: _buildList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    if (widget.isLoading && widget.results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.errorMessage != null) {
      return Center(child: Text(widget.errorMessage!));
    }

    if (widget.results.isEmpty) {
      return const Center(child: Text('目前沒有找到符合的附近結果'));
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
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final Color color;

  const _TypeChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
