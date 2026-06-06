import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../pages/setting_page.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final LatLng? initialSearchCenter;
  final Future<void> Function(String keyword, String category)?
  onSearchSubmitted;
  final Future<void> Function()? onPullRefresh;

  const CustomAppBar({
    super.key,
    this.initialSearchCenter,
    this.onSearchSubmitted,
    this.onPullRefresh,
  });

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends State<CustomAppBar>
    with SingleTickerProviderStateMixin {
  static const String _scenicLabel = '景點';
  static const String _restaurantLabel = '餐廳';
  static const String _storeLabel = '便利商店';
  static const double _triggerDistance = 48.0;

  bool _isSearching = false;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  OverlayEntry? _categoryOverlayEntry;
  String _selectedSearchCategory = _scenicLabel;

  // pull to refresh 狀態
  double _pullDistance = 0.0;
  bool _isPullRefreshing = false;
  bool _pullTriggered = false; // 是否已達觸發距離

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  // pull 指示器的 overlay
  OverlayEntry? _pullIndicatorEntry;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _removeCategoryOverlay();
    _removePullIndicator();
    _animController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ── Pull Indicator Overlay ────────────────────────────────

  void _showPullIndicator() {
    _removePullIndicator();
    final overlay = Overlay.of(context);
    _pullIndicatorEntry = OverlayEntry(
      builder: (_) => _PullIndicatorWidget(
        pullDistance: _pullDistance,
        triggerDistance: _triggerDistance,
        isTriggered: _pullTriggered,
        isRefreshing: _isPullRefreshing,
        topOffset: MediaQuery.of(context).padding.top + kToolbarHeight,
      ),
    );
    overlay.insert(_pullIndicatorEntry!);
  }

  void _updatePullIndicator() {
    _pullIndicatorEntry?.markNeedsBuild();
  }

  void _removePullIndicator() {
    _pullIndicatorEntry?.remove();
    _pullIndicatorEntry = null;
  }

  // ── Category Overlay ──────────────────────────────────────

  void _insertCategoryOverlay() {
    _removeCategoryOverlay();
    final overlay = Overlay.of(context);
    _categoryOverlayEntry = OverlayEntry(
      builder: (context) {
        final topOffset = MediaQuery.of(context).padding.top + kToolbarHeight;
        return Positioned(
          left: 0,
          right: 0,
          top: topOffset,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSearchCategoryButton(
                          label: _scenicLabel,
                          icon: Icons.terrain_outlined,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildSearchCategoryButton(
                          label: _restaurantLabel,
                          icon: Icons.restaurant_outlined,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildSearchCategoryButton(
                          label: _storeLabel,
                          icon: Icons.store_outlined,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_categoryOverlayEntry!);
  }

  void _removeCategoryOverlay() {
    _categoryOverlayEntry?.remove();
    _categoryOverlayEntry = null;
  }

  Widget _buildSearchCategoryButton({
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedSearchCategory == label;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        setState(() => _selectedSearchCategory = label);
        _categoryOverlayEntry?.markNeedsBuild();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF111827) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : const Color(0xFF111827),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF111827),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Search ────────────────────────────────────────────────

  void _openSearch() {
    setState(() => _isSearching = true);
    _selectedSearchCategory = _scenicLabel;
    _insertCategoryOverlay();
    _animController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  void _closeSearch() {
    _removeCategoryOverlay();
    _animController.reverse().then((_) {
      setState(() {
        _isSearching = false;
        _searchController.clear();
        _selectedSearchCategory = _scenicLabel;
      });
    });
    _searchFocusNode.unfocus();
  }

  // ── Pull to Refresh ───────────────────────────────────────

  void _handlePullRefreshStart(DragStartDetails details) {
    if (_isSearching || widget.onPullRefresh == null) return;
    _pullDistance = 0.0;
    _pullTriggered = false;
  }

  void _handlePullRefreshUpdate(DragUpdateDetails details) {
    if (_isSearching || widget.onPullRefresh == null || _isPullRefreshing) {
      return;
    }
    if (details.delta.dy > 0) {
      setState(() {
        _pullDistance = (_pullDistance + details.delta.dy).clamp(
          0.0,
          _triggerDistance * 1.5,
        );
        _pullTriggered = _pullDistance >= _triggerDistance;
      });
      if (_pullIndicatorEntry == null) {
        _showPullIndicator();
      } else {
        _updatePullIndicator();
      }
    }
  }

  Future<void> _handlePullRefreshEnd(DragEndDetails details) async {
    if (_isSearching || widget.onPullRefresh == null) {
      _pullDistance = 0.0;
      _removePullIndicator();
      return;
    }

    if (_pullDistance < _triggerDistance || _isPullRefreshing) {
      setState(() {
        _pullDistance = 0.0;
        _pullTriggered = false;
      });
      _removePullIndicator();
      return;
    }

    // 達到觸發距離，執行刷新
    setState(() => _isPullRefreshing = true);
    _updatePullIndicator();

    try {
      await widget.onPullRefresh?.call();
    } finally {
      if (mounted) {
        setState(() {
          _isPullRefreshing = false;
          _pullDistance = 0.0;
          _pullTriggered = false;
        });
        _removePullIndicator();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragStart: _handlePullRefreshStart,
      onVerticalDragUpdate: _handlePullRefreshUpdate,
      onVerticalDragEnd: _handlePullRefreshEnd,
      child: AppBar(
        title: _isSearching
            ? FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: const InputDecoration(
                      hintText: '輸入關鍵字後按 Enter',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                    style: const TextStyle(fontSize: 16),
                    onSubmitted: (value) async {
                      final keyword = value.trim();
                      if (keyword.isEmpty) return;
                      final selectedCategory = _selectedSearchCategory;
                      _closeSearch();
                      await widget.onSearchSubmitted?.call(
                        keyword,
                        selectedCategory,
                      );
                    },
                  ),
                ),
              )
            : const Text('RideVoyage'),
        leading: _isSearching
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _closeSearch,
              )
            : null,
        actions: [
          if (!_isSearching) ...[
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: '搜尋',
              onPressed: _openSearch,
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: '設定',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.person_outline),
              tooltip: '個人資料',
              onPressed: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
            const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}

// pull to refresh 指示器的 widget
class _PullIndicatorWidget extends StatelessWidget {
  final double pullDistance;
  final double triggerDistance;
  final bool isTriggered;
  final bool isRefreshing;
  final double topOffset;

  const _PullIndicatorWidget({
    required this.pullDistance,
    required this.triggerDistance,
    required this.isTriggered,
    required this.isRefreshing,
    required this.topOffset,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (pullDistance / triggerDistance).clamp(0.0, 1.0);

    return Positioned(
      top: topOffset + 8,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isTriggered
                ? const Color.fromARGB(115, 17, 24, 39)
                : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: isRefreshing
                    ? CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isTriggered
                            ? Colors.white
                            : const Color.fromARGB(115, 17, 24, 39),
                      )
                    : TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress),
                        duration: Duration.zero,
                        builder: (_, value, __) => CircularProgressIndicator(
                          value: value,
                          strokeWidth: 2,
                          color: isTriggered
                              ? Colors.white
                              : const Color.fromARGB(115, 17, 24, 39),
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              Text(
                isRefreshing
                    ? '重新整理中'
                    : isTriggered
                    ? '放開以重新整理'
                    : '下拉重新整理',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isTriggered
                      ? Colors.white
                      : const Color.fromARGB(115, 17, 24, 39),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
