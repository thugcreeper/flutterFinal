import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Directions API 轉換後的路線資料。
///
/// 這個類別存放的是畫地圖真正需要用到的資料，避免 widget 直接處理 JSON。
class DirectionsRoute {
  const DirectionsRoute({
    required this.polylinePoints,
    required this.distanceText,
    required this.durationText,
    required this.originAddress,
    required this.destinationAddress,
    required this.status,
    this.waypointCount = 0,
    this.rawPolyline,
  });

  /// 解碼後可直接畫在 GoogleMap 上的座標序列。
  final List<LatLng> polylinePoints;

  /// 路線總距離文字，例如 12.3 km。
  final String distanceText;

  /// 路線預估時間文字，例如 18 mins。
  final String durationText;

  /// 路線起點地址。
  final String originAddress;

  /// 路線終點地址。
  final String destinationAddress;

  /// Directions API 的回傳狀態，例如 OK。
  final String status;

  /// 中繼點數量，方便前端知道這條路線有幾個 waypoint。
  final int waypointCount;

  /// 原始的 encoded polyline 字串，必要時可用來除錯。
  final String? rawPolyline;

  bool get hasPolyline => polylinePoints.isNotEmpty;
}
