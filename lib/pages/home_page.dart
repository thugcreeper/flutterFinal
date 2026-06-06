// 這個檔案是主頁面，包含地圖顯示、路線規劃、以及路線儲存功能。
import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ridevoyage/api/directions_api.dart';
import 'package:ridevoyage/api/elevation_api.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/saved_route_api.dart';
import '../api/tourism_search_api.dart';
import '../api/convenience_store_api.dart';
import '../models/directions_route.dart';
import '../models/map_point.dart';
import '../models/saved_route.dart';
import '../widgets/app_bar.dart';
import '../widgets/nearby_search_results_panel.dart';
import '../widgets/error_snack_bar.dart';
import '../widgets/success_snack_bar.dart';
import '../widgets/route_info_card.dart';
import '../widgets/action_buttons.dart';
import 'saved_routes_page.dart';
import '../providers/route_provider.dart';
import 'package:provider/provider.dart';
import '../controller/nearby_search_controller.dart';

// 主頁面，包含地圖顯示與路線規劃功能，登入後要來到這裡
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String _savedRoutePointsKey = 'saved_route_points';
  static const String _scenicLabel = '景點';
  static const String _restaurantLabel = '餐廳';
  static const String _storeLabel = '超商';
  LatLng _currentMapCenter = LatLng(25.15089, 121.77531);
  GoogleMapController? _mapController;
  final DraggableScrollableController _nearbySearchSheetController =
      DraggableScrollableController();
  final DirectionsApiService _directionsApiService = DirectionsApiService();
  final ElevationApiService _elevationApiService = ElevationApiService();
  final TourismSearchService _tourismSearchService = TourismSearchService();
  final ConvenienceStoreApi _convenienceStoreApi = ConvenienceStoreApi();
  late final NearbySearchController _searchController =
      NearbySearchController();
  final List<LatLng> _routePoints = []; // 用來存放使用者點選的路線點位
  final Set<Marker> _markers = {}; // 用來存放地圖上的標記，與 _routePoints 對應
  Set<Polyline> _polylines = {}; // 用來存放從 Directions API 取得的路線 polyline，理論上只會有一條
  bool _isProcessingRoute = false;
  bool _showRouteInfo = false;
  String? _routeDistanceText;
  String? _routeDurationText;
  // 海拔摘要
  double? _startElevation;
  double? _endElevation;
  double? _totalAscent;
  double? _totalDescent;
  String? _elevationErrorText;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchStateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RouteProvider>().addListener(_onRouteSelected);
    });
  }

  void _onSearchStateChanged() {
    if (!mounted) return;
    setState(() {});

    // 有新結果時移動地圖
    final center = _searchController.lastResultCenter;
    if (center != null) {
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(center, 16));
    }
  }

  void _onRouteSelected() {
    final route = context.read<RouteProvider>().selectedRoute;
    if (route == null) return;

    _loadSavedRoute(route);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SuccessSnackBar(message: '已載入路線「${route.routeName}」'));
    context.read<RouteProvider>().clear();
  }

  @override
  void dispose() {
    _nearbySearchSheetController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  static const PolylineId _routePolylineId = PolylineId('route-line');

  static const List<double> _markerHueCycle = [
    BitmapDescriptor.hueAzure,
    BitmapDescriptor.hueBlue,
    BitmapDescriptor.hueCyan,
    BitmapDescriptor.hueMagenta,
    BitmapDescriptor.hueOrange,
    BitmapDescriptor.hueRed,
    BitmapDescriptor.hueRose,
    BitmapDescriptor.hueViolet,
    BitmapDescriptor.hueYellow,
  ];

  /// 第一個標記固定綠色，後面的標記依照清單循環。
  double _getMarkerHue(int existingPointCount) {
    if (existingPointCount == 0) {
      return BitmapDescriptor.hueGreen;
    }

    final int index = (existingPointCount - 1) % _markerHueCycle.length;
    return _markerHueCycle[index];
  }

  // 根據目前的搜尋結果清單建立對應的 Marker Set，並在 markerId 中包含類型與 id 以利識別。
  Set<Marker> _buildNearbySearchMarkers() {
    return _searchController.results.map((point) {
      return Marker(
        markerId: MarkerId('search_${point.typeLabel}_${point.id}'),
        position: LatLng(point.latitude, point.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          point.markerHue,
        ), // ← 用 point 自己的顏色
        infoWindow: InfoWindow(title: point.name, snippet: point.typeLabel),
        onTap: () => _focusNearbyResult(point),
      );
    }).toSet();
  }

  Future<int?> _appendRoutePoint(LatLng position) async {
    if (_isProcessingRoute) {
      return null;
    }

    final nextIndex = _routePoints.length + 1;
    final markerHue = _getMarkerHue(_routePoints.length);
    final previousRoutePoints = List<LatLng>.from(_routePoints);
    final previousMarkers = Set<Marker>.from(_markers);
    final previousPolylines = Set<Polyline>.from(_polylines);
    final previousRouteDistanceText = _routeDistanceText;
    final previousRouteDurationText = _routeDurationText;
    final previousStartElevation = _startElevation;
    final previousEndElevation = _endElevation;
    final previousTotalAscent = _totalAscent;
    final previousTotalDescent = _totalDescent;
    final previousElevationErrorText = _elevationErrorText;
    final previousShowRouteInfo = _showRouteInfo;

    setState(() {
      _isProcessingRoute = true;
      _routePoints.add(position);
      _markers.add(
        Marker(
          markerId: MarkerId('point_$nextIndex'),
          position: position,
          infoWindow: InfoWindow(title: '標記 $nextIndex'),
          icon: BitmapDescriptor.defaultMarkerWithHue(markerHue),
        ),
      );
    });

    try {
      final isRouteDataUpdated = await _refreshRouteData();
      if (!isRouteDataUpdated) {
        throw StateError(_elevationErrorText ?? '路線查詢失敗');
      }
      if (!mounted) {
        return null;
      }
      await _saveRoutePoints();
      await _mapController?.animateCamera(CameraUpdate.newLatLng(position));
      return nextIndex;
    } catch (e) {
      if (!mounted) {
        return null;
      }
      setState(() {
        _routePoints
          ..clear()
          ..addAll(previousRoutePoints);
        _markers
          ..clear()
          ..addAll(previousMarkers);
        _polylines = {};
        _polylines = previousPolylines;
        _routeDistanceText = previousRouteDistanceText;
        _routeDurationText = previousRouteDurationText;
        _startElevation = previousStartElevation;
        _endElevation = previousEndElevation;
        _totalAscent = previousTotalAscent;
        _totalDescent = previousTotalDescent;
        _elevationErrorText = previousElevationErrorText;
        _showRouteInfo = previousShowRouteInfo;
      });
      await _saveRoutePoints(previousRoutePoints);
      if (!mounted) {
        return null;
      }
      final errorText = e is StateError ? e.message : e.toString();
      final message = errorText.startsWith('路線查詢失敗')
          ? errorText
          : '路線查詢失敗：$errorText';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(ErrorSnackBar(message: message));
      return null;
    } finally {
      if (mounted) {
        setState(() => _isProcessingRoute = false);
      }
    }
  }

  // 根據目前的搜尋結果清單建立對應的 Marker Set，並在 markerId 中包含類型與 id 以利識別。
  Future<void> _handleNearbyResultRouteAction(MapPoint point) async {
    try {
      if (_routePoints.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(ErrorSnackBar(message: '請在地圖上選擇起點'));
        return;
      }

      // 驗證座標是否為有效數值
      if (!point.latitude.isFinite || !point.longitude.isFinite) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(ErrorSnackBar(message: '目標座標無效，無法接到路線'));
        return;
      }

      final addedIndex = await _appendRoutePoint(
        LatLng(point.latitude, point.longitude),
      );
      if (!mounted || addedIndex == null) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SuccessSnackBar(message: '已將路線接到 ${point.name}'));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(ErrorSnackBar(message: '接到路線失敗：$e'));
    }
  }

  Future<void> _focusNearbyResult(MapPoint point) async {
    final controller = _mapController;
    if (controller == null) {
      return;
    }

    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(point.latitude, point.longitude), 16),
    );
  }

  void _closeNearbySearchPanel() {
    _searchController.closePanel();
  }

  //將目前的路線點位清單儲存到 SharedPreferences
  Future<void> _saveRoutePoints([List<LatLng>? points]) async {
    final routePoints = points ?? _routePoints;
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      routePoints
          .map((point) => {'lat': point.latitude, 'lng': point.longitude})
          .toList(),
    );
    //setString將編碼後的路線點位字串儲存到 SharedPreferences
    await prefs.setString(_savedRoutePointsKey, encoded);
  }

  //從 SharedPreferences 還原路線點位，並更新地圖上的標記與路線資訊。
  Future<void> _restoreSavedRoutePoints() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_savedRoutePointsKey);
    if (raw == null || raw.isEmpty || !mounted) {
      return;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return;
    }

    final restoredPoints = <LatLng>[];
    for (final item in decoded) {
      if (item is Map) {
        final lat = item['lat'];
        final lng = item['lng'];
        if (lat is num && lng is num) {
          restoredPoints.add(LatLng(lat.toDouble(), lng.toDouble()));
        }
      }
    }

    if (restoredPoints.isEmpty || !mounted) {
      return;
    }

    setState(() {
      _routePoints
        ..clear()
        ..addAll(restoredPoints);
      _markers.clear();
      //還原點位後根據順序放置標記
      for (var i = 0; i < _routePoints.length; i++) {
        final markerNumber = i + 1;
        _markers.add(
          Marker(
            markerId: MarkerId('point_$markerNumber'),
            position: _routePoints[i],
            infoWindow: InfoWindow(title: '標記 $markerNumber'),
            icon: BitmapDescriptor.defaultMarkerWithHue(_getMarkerHue(i)),
          ),
        );
      }
    });
    // 還原點位後自動呼叫 Directions API 取得路線資訊，並更新地圖顯示。
    try {
      await _refreshRouteData();
    } catch (_) {
      // 重啟時若查詢失敗，保留已還原的點位即可。
    }
  }

  // 刷新路線資料，包含呼叫 Directions API 與更新 polyline 與距離時間資訊。
  Future<bool> _refreshRouteData() async {
    // 少於兩個點時沒有路線可查，所以直接清掉 polyline 與距離資訊。
    if (_routePoints.length < 2) {
      if (!mounted) {
        return true;
      }
      setState(() {
        _polylines = {};
        _routeDistanceText = null;
        _routeDurationText = null;
        _startElevation = null;
        _endElevation = null;
        _totalAscent = null;
        _totalDescent = null;
        _elevationErrorText = null;
        _showRouteInfo = false;
      });
      return true;
    }

    late final DirectionsRoute route;
    try {
      route = await _directionsApiService.fetchRoute(_routePoints);
    } catch (e) {
      if (!mounted) {
        return false;
      }

      setState(() {
        _polylines = {};
        _routeDistanceText = null;
        _routeDurationText = null;
        _startElevation = null;
        _endElevation = null;
        _totalAscent = null;
        _totalDescent = null;
        _elevationErrorText = '路線查詢失敗：$e';
        _showRouteInfo = false;
      });
      return false;
    }

    if (!mounted) {
      return true;
    }

    // 成功取得路線後，更新 polyline 與距離時間資訊。
    setState(() {
      _polylines = {
        Polyline(
          polylineId: _routePolylineId,
          points: route.polylinePoints,
          color: Colors.blueAccent,
          width: 5,
          geodesic: false,
        ),
      };
      _routeDistanceText = route.distanceText;
      _routeDurationText = route.durationText;
      _elevationErrorText = null;
      _showRouteInfo = true;
    });

    // 海拔查詢不阻塞接路線流程，避免 Elevation API 慢時讓畫面被 loading 鎖住。
    unawaited(_refreshElevationData(route.polylinePoints));
    return true;
  }

  Future<void> _refreshElevationData(List<LatLng> routePolylinePoints) async {
    try {
      final summary = await _elevationApiService
          .fetchElevationSummaryFromPoints(
            routePolylinePoints,
            maxSamples: 120,
            thresholdMeters: 2.0,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _startElevation = summary.startElevation;
        _endElevation = summary.endElevation;
        _totalAscent = summary.totalAscent;
        _totalDescent = summary.totalDescent;
        _elevationErrorText = null;
        _showRouteInfo = true;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _startElevation = null;
        _endElevation = null;
        _totalAscent = null;
        _totalDescent = null;
        _elevationErrorText = '海拔查詢失敗：$e';
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(ErrorSnackBar(message: '海拔查詢失敗：$e'));
      }
    }
  }

  Future<void> _handleMapTap(LatLng position) async {
    final messenger = ScaffoldMessenger.of(context);
    final nextIndex = await _appendRoutePoint(position);
    if (!mounted || nextIndex == null) {
      return;
    }

    messenger.showSnackBar(
      SuccessSnackBar(
        message: '已加入第 $nextIndex 個標記',
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _undoLastPoint() async {
    if (_routePoints.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(ErrorSnackBar(message: '目前沒有可復原的標記'));
      return;
    }

    setState(() {
      final removedIndex = _routePoints.length;
      final removedPoint = _routePoints.removeLast();
      _markers.removeWhere(
        (marker) =>
            marker.position == removedPoint ||
            marker.markerId.value == 'point_$removedIndex',
      );
    });

    await _saveRoutePoints();

    setState(() => _isProcessingRoute = true);

    try {
      final isRouteDataUpdated = await _refreshRouteData();
      if (!isRouteDataUpdated && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(ErrorSnackBar(message: _elevationErrorText ?? '路線查詢失敗'));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingRoute = false);
      }
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SuccessSnackBar(
        message: '已移除最後一個標記',
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _clearRoute() async {
    if (_routePoints.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(ErrorSnackBar(message: '目前沒有標記與路線可清除'));
      return;
    }

    setState(() => _isProcessingRoute = true);

    try {
      setState(() {
        _routePoints.clear();
        _markers.clear();
        _polylines = {};
        _routeDistanceText = null;
        _routeDurationText = null;
        _startElevation = null;
        _endElevation = null;
        _totalAscent = null;
        _totalDescent = null;
        _showRouteInfo = false;
      });

      await _saveRoutePoints();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SuccessSnackBar(
          message: '已清除所有標記與路線',
          duration: const Duration(seconds: 1),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessingRoute = false);
      }
    }

    if (!mounted) return;
  }

  /// 將已儲存路線的點位載入地圖，並重新查詢路線資訊。
  ///
  /// Parameters:
  /// - route: 欲載入的 [SavedRoute]
  Future<void> _loadSavedRoute(SavedRoute route) async {
    if (route.points.isEmpty) return;

    setState(() {
      _isProcessingRoute = true;
      _routePoints
        ..clear()
        ..addAll(route.points);
      _markers.clear();
      for (var i = 0; i < _routePoints.length; i++) {
        final markerNumber = i + 1;
        _markers.add(
          Marker(
            markerId: MarkerId('point_$markerNumber'),
            position: _routePoints[i],
            infoWindow: InfoWindow(title: '標記 $markerNumber'),
            icon: BitmapDescriptor.defaultMarkerWithHue(_getMarkerHue(i)),
          ),
        );
      }
    });

    try {
      await _saveRoutePoints();
      await _refreshRouteData();
      if (mounted && _mapController != null && _routePoints.isNotEmpty) {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLng(_routePoints.first),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingRoute = false);
    }
  }

  /// 開啟已儲存路線清單（selectable 模式），使用者選取後載入地圖。
  Future<void> _openSavedRoutes() async {
    final selected = await Navigator.push<SavedRoute>(
      context,
      MaterialPageRoute(
        builder: (_) => const SavedRoutesPage(selectable: true),
      ),
    );
    if (!mounted || selected == null) return;
    await _loadSavedRoute(selected);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SuccessSnackBar(message: '已載入路線「${selected.routeName}」'));
  }

  /// 提示使用者輸入路線名稱，並將目前路線儲存至 Firestore。
  Future<void> _saveCurrentRoute() async {
    if (_routePoints.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(ErrorSnackBar(message: '目前沒有路線可以儲存'));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(ErrorSnackBar(message: '尚未登入，無法儲存路線'));
      return;
    }

    final routeName = await _promptForRouteName();
    if (routeName == null || routeName.isEmpty) return;

    try {
      await SavedRouteApiService().saveRoute(
        userId: user.uid,
        routeName: routeName,
        distance: _routeDistanceText ?? '',
        duration: _routeDurationText ?? '',
        points: _routePoints,
        totalAscent: _totalAscent ?? 0.0,
        totalDescent: _totalDescent ?? 0.0,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SuccessSnackBar(message: '路線「$routeName」已儲存'));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(ErrorSnackBar(message: '儲存失敗：$e'));
    }
  }

  /// 顯示對話框讓使用者輸入路線名稱，回傳輸入值或 null（取消）。
  Future<String?> _promptForRouteName() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('儲存路線'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '請輸入路線名稱'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final combinedMarkers = <Marker>{
      ..._markers,
      ..._buildNearbySearchMarkers(),
    };

    return Scaffold(
      appBar: CustomAppBar(
        initialSearchCenter: _currentMapCenter,
        onSearchSubmitted: (keyword, category) =>
            _searchController.handleNearbySearch(
              keyword,
              category,
              searchScenicSpots: _tourismSearchService.searchScenicSpotsNearby,
              searchRestaurants: _tourismSearchService.searchRestaurantsNearby,
              searchStores: _convenienceStoreApi.getNearby711Stores,
            ),
        // pull to refresh 在附近搜尋面板開啟時才啟用
        onPullRefresh: _searchController.showPanel
            ? () => _searchController.handleNearbySearch(
                _searchController.currentKeyword ?? '',
                _searchController.currentCategory,
                searchScenicSpots:
                    _tourismSearchService.searchScenicSpotsNearby,
                searchRestaurants:
                    _tourismSearchService.searchRestaurantsNearby,
                searchStores: _convenienceStoreApi.getNearby711Stores,
              )
            : null,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(25.15089, 121.77531), //ntou
              zoom: 14,
            ),
            onMapCreated: (controller) {
              setState(() {
                _mapController = controller;
                _currentMapCenter = const LatLng(25.15089, 121.77531);
                _searchController.updateMapCenter(_currentMapCenter);
              });
            },
            //當地圖移動時更新目前的中心座標，這樣搜尋功能就能以目前地圖中心為基準。
            onCameraMove: (position) {
              setState(() {
                _currentMapCenter = position.target;
                _searchController.updateMapCenter(
                  position.target,
                ); //controller也要更新，這樣搜尋功能才會以目前地圖中心為基準
              });
            },
            onTap: _handleMapTap,
            markers: combinedMarkers,
            polylines: _polylines,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            padding: EdgeInsets.only(
              bottom: _searchController.showPanel ? 320 : 24,
              right: 16,
            ),
          ),
          if (_showRouteInfo && _routePoints.length >= 2)
            Positioned(
              key: const ValueKey('route-info-card'),
              left: 0,
              right: 0,
              top: 16,
              child: SafeArea(
                child: RouteInfoCard(
                  routeDistanceText: _routeDistanceText,
                  routeDurationText: _routeDurationText,
                  startElevation: _startElevation,
                  endElevation: _endElevation,
                  totalAscent: _totalAscent,
                  totalDescent: _totalDescent,
                  elevationErrorText: _elevationErrorText,
                ),
              ),
            ),
          if (_searchController.showPanel)
            Positioned.fill(
              key: const ValueKey('nearby-search-panel'),
              child: NearbySearchResultsPanel(
                isLoading: _searchController.isLoading,
                cityLabel: _searchController.cityLabel,
                areaLabel: _searchController.areaLabel,
                category: _searchController.currentCategory,
                keyword: _searchController.currentKeyword,
                errorMessage: _searchController.errorMessage,
                results: _searchController.results,
                onRefresh: () => _searchController.handleNearbySearch(
                  _searchController.currentKeyword ?? '',
                  _searchController.currentCategory,
                  searchScenicSpots:
                      _tourismSearchService.searchScenicSpotsNearby,
                  searchRestaurants:
                      _tourismSearchService.searchRestaurantsNearby,
                  searchStores: _convenienceStoreApi.getNearby711Stores,
                ),
                onClose: _closeNearbySearchPanel,
                onTapPoint: _focusNearbyResult,
                onAddToRoute: _handleNearbyResultRouteAction,
                sheetController: _nearbySearchSheetController,
              ),
            ),
          if (_routePoints.isNotEmpty && !_searchController.showPanel)
            Positioned(
              key: const ValueKey('route-action-buttons'),
              left: 16,
              bottom: 4,
              child: SafeArea(
                child: ActionButtons(
                  isProcessingRoute: _isProcessingRoute,
                  undoLastPoint: _undoLastPoint,
                  clearRoute: _clearRoute,
                  saveCurrentRoute: _saveCurrentRoute,
                  openSavedRoutes: _openSavedRoutes,
                ),
              ),
            ),
          if (_isProcessingRoute)
            Positioned.fill(
              key: const ValueKey('route-processing-overlay'),
              child: AbsorbPointer(
                absorbing: true,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.18),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
