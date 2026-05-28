import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:RideVoyage/api/directions_api.dart';
import 'package:RideVoyage/api/elevation_api.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/directions_route.dart';

class RouteMapView extends StatefulWidget {
  const RouteMapView({super.key});

  @override
  State<RouteMapView> createState() => _RouteMapViewState();
}

class _RouteMapViewState extends State<RouteMapView> {
  static const String _savedRoutePointsKey = 'saved_route_points';

  GoogleMapController? _mapController;
  final DirectionsApiService _directionsApiService = DirectionsApiService();
  final ElevationApiService _elevationApiService = ElevationApiService();
  final List<LatLng> _routePoints = []; // 用來存放使用者點選的路線點位
  final Set<Marker> _markers = {}; // 用來存放地圖上的標記，與 _routePoints 對應
  Set<Polyline> _polylines = {}; // 用來存放從 Directions API 取得的路線 polyline，理論上只會有一條
  bool _isProcessingRoute = false;
  bool _showRouteInfo = false;
  String? _routeDistanceText;
  String? _routeDurationText;
  String? _routeErrorText;
  // 海拔摘要
  double? _startElevation;
  double? _endElevation;
  double? _totalAscent;
  double? _totalDescent;
  String? _elevationErrorText;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreSavedRoutePoints();
    });
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

  //將目前的路線點位清單儲存到 SharedPreferences
  Future<void> _saveRoutePoints() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      _routePoints
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
  Future<void> _refreshRouteData() async {
    // 少於兩個點時沒有路線可查，所以直接清掉 polyline 與距離資訊。
    if (_routePoints.length < 2) {
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
      return;
    }

    final DirectionsRoute route = await _directionsApiService.fetchRoute(
      _routePoints,
    );

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

    // 取得 Elevation 資訊（採樣以降低請求數量與 URL 長度）
    try {
      final summary = await _elevationApiService
          .fetchElevationSummaryFromPoints(
            route.polylinePoints,
            maxSamples: 120,
            thresholdMeters: 2.0,
          );
      setState(() {
        _startElevation = summary.startElevation;
        _endElevation = summary.endElevation;
        _totalAscent = summary.totalAscent;
        _totalDescent = summary.totalDescent;
        _elevationErrorText = null;
        _showRouteInfo = true;
      });
    } catch (e) {
      setState(() {
        _startElevation = null;
        _endElevation = null;
        _totalAscent = null;
        _totalDescent = null;
        _elevationErrorText = '海拔查詢失敗：$e';
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('海拔查詢失敗：$e'), duration: Duration(seconds: 2)),
      );
    }
  }

  Future<void> _handleMapTap(LatLng position) async {
    if (_isProcessingRoute) return;
    // 先把點加入清單，Directions API 會依照點的順序計算路線。
    final nextIndex = _routePoints.length + 1;
    final markerHue = _getMarkerHue(_routePoints.length);

    setState(() {
      _isProcessingRoute = true;
      _routeErrorText = null;
      _routePoints.add(position);
      //放marker
      _markers.add(
        Marker(
          markerId: MarkerId('point_$nextIndex'),
          position: position,
          infoWindow: InfoWindow(title: '標記 $nextIndex'),
          icon: BitmapDescriptor.defaultMarkerWithHue(markerHue),
        ),
      );
    });

    await _saveRoutePoints();

    try {
      // 呼叫 Directions API 取得真實道路路線，而不是手動畫直線。
      await _refreshRouteData();

      await _mapController?.animateCamera(CameraUpdate.newLatLng(position));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已加入第 $nextIndex 個標記'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      setState(() {
        _routeErrorText = '路線查詢失敗：$e';
        _polylines = {};
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('路線查詢失敗：$e'), duration: Duration(seconds: 2)),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessingRoute = false);
      }
    }
  }

  Future<void> _undoLastPoint() async {
    if (_routePoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('目前沒有可復原的標記'),
          duration: Duration(seconds: 2),
        ),
      );
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
      _routeErrorText = null;
    });

    await _saveRoutePoints();

    setState(() => _isProcessingRoute = true);

    try {
      await _refreshRouteData();
    } catch (e) {
      setState(() {
        _routeErrorText = '路線查詢失敗：$e';
        _polylines = {};
        _routeDistanceText = null;
        _routeDurationText = null;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('路線查詢失敗：$e'), duration: Duration(seconds: 2)),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessingRoute = false);
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已移除最後一個標記'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _clearRoute() async {
    if (_routePoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('目前沒有標記與路線可清除'),
          duration: Duration(seconds: 2),
        ),
      );
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
        _routeErrorText = null;
        _startElevation = null;
        _endElevation = null;
        _totalAscent = null;
        _totalDescent = null;
        _showRouteInfo = false;
      });

      await _saveRoutePoints();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已清除所有標記與路線'),
          duration: Duration(seconds: 1),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessingRoute = false);
      }
    }
  }

  //顯示路線資訊卡
  Widget _buildStatusCard() {
    return IgnorePointer(
      ignoring: true,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_routeDistanceText != null || _routeDurationText != null) ...[
              const SizedBox(height: 8),
              Text(
                '距離：${_routeDistanceText ?? 'N/A'}  |  預估時間：${_routeDurationText ?? 'N/A'}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
            if (_startElevation != null || _elevationErrorText != null) ...[
              const SizedBox(height: 8),
              Text(
                _elevationErrorText != null
                    ? _elevationErrorText!
                    : '起點高度：${_startElevation!.toStringAsFixed(1)} m  |  終點高度：${_endElevation!.toStringAsFixed(1)} m',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
            if (_totalAscent != null && _totalDescent != null) ...[
              const SizedBox(height: 4),
              Text(
                '總爬升：${_totalAscent!.toStringAsFixed(1)} m  |  總下降：${_totalDescent!.toStringAsFixed(1)} m',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  //返回 刪除路線icon
  Widget _buildActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FloatingActionButton(
          heroTag: 'undo-point',
          onPressed: _isProcessingRoute ? null : _undoLastPoint,
          tooltip: '復原最後一個標記',
          child: const Icon(Icons.undo),
        ),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: 'clear-route',
          onPressed: _isProcessingRoute ? null : _clearRoute,
          tooltip: '清除路線',
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          child: const Icon(Icons.delete_outline, size: 40),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(25.15089, 121.77531), //ntou
            zoom: 14,
          ),
          onMapCreated: (controller) => _mapController = controller,
          onTap: _handleMapTap,
          markers: _markers,
          polylines: _polylines,
          myLocationButtonEnabled: false,
        ),
        if (_showRouteInfo && _routePoints.length >= 2)
          Positioned(
            left: 0,
            right: 0,
            top: 16,
            child: SafeArea(child: _buildStatusCard()),
          ),
        if (_routePoints.isNotEmpty)
          Positioned(
            left: 16,
            bottom: 4,
            child: SafeArea(child: _buildActionButtons()),
          ),
        if (_isProcessingRoute)
          Positioned.fill(
            child: AbsorbPointer(
              absorbing: true,
              child: Container(
                color: Colors.black.withValues(alpha: 0.18),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
      ],
    );
  }
}
