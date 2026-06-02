import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../models/directions_route.dart';

class DirectionsApiService {
  DirectionsApiService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  /// Calls Google Directions API and converts the encoded polyline into
  /// a list of coordinates that GoogleMap can draw directly.
  Future<DirectionsRoute> fetchRoute(List<LatLng> points) async {
    if (points.length < 2) {
      throw StateError('至少需要兩個點才能查詢路線');
    }

    final apiKey = dotenv.env['MAPS_PLATFORM_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw StateError('MAPS_PLATFORM_API_KEY 尚未設定');
    }

    final uri = _buildDirectionsUri(points, apiKey);
    final response = await _client
        .get(uri)
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () {
            throw TimeoutException('Directions API 請求逾時');
          },
        );

    if (response.statusCode != 200) {
      throw StateError('Directions API 呼叫失敗：${response.statusCode}');
    }

    final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;
    final String status = data['status'] as String? ?? 'UNKNOWN';
    if (status != 'OK') {
      final errorMessage = data['error_message'] as String?;
      throw StateError(
        'Directions API 回傳失敗：$status${errorMessage == null ? '' : ' - $errorMessage'}',
      );
    }

    final List<dynamic> routes = data['routes'] as List<dynamic>;
    if (routes.isEmpty) {
      throw StateError('Directions API 沒有回傳任何路線');
    }

    final Map<String, dynamic> route = routes.first as Map<String, dynamic>;

    // overview_polyline 是 Directions API 提供的整段路線折線字串。
    final String overviewPolyline =
        route['overview_polyline']?['points'] as String? ?? '';
    final List<LatLng> decodedPoints = _decodePolyline(overviewPolyline);

    // legs 代表一段一段的路程區間，通常是起點到終點之間的單段路線。
    final List<dynamic> routeLegs = route['legs'] as List<dynamic>? ?? const [];
    final Map<String, dynamic>? firstLeg = routeLegs.isNotEmpty
        ? routeLegs.first as Map<String, dynamic>
        : null;
    final Map<String, dynamic>? lastLeg = routeLegs.isNotEmpty
        ? routeLegs.last as Map<String, dynamic>
        : null;

    // 多個 waypoint 會產生多段 leg，因此要把所有 leg 的距離與時間加總。
    final int totalDistanceMeters = routeLegs.fold<int>(0, (sum, leg) {
      final Map<String, dynamic> legMap = leg as Map<String, dynamic>;
      return sum + _extractNumericValue(legMap['distance'], 'value');
    });
    final int totalDurationSeconds = routeLegs.fold<int>(0, (sum, leg) {
      final Map<String, dynamic> legMap = leg as Map<String, dynamic>;
      return sum + _extractNumericValue(legMap['duration'], 'value');
    });

    final String distanceText = _formatDistance(totalDistanceMeters);
    final String durationText = _formatDuration(totalDurationSeconds);

    // 起點與終點地址，保留給畫面顯示或後續除錯使用。
    final String originAddress = firstLeg?['start_address'] as String? ?? 'N/A';
    final String destinationAddress =
        lastLeg?['end_address'] as String? ?? 'N/A';

    return DirectionsRoute(
      polylinePoints: decodedPoints,
      distanceText: distanceText,
      durationText: durationText,
      originAddress: originAddress,
      destinationAddress: destinationAddress,
      status: status,
      waypointCount: points.length > 2 ? points.length - 2 : 0,
      rawPolyline: overviewPolyline,
    );
  }

  Uri _buildDirectionsUri(List<LatLng> points, String apiKey) {
    final origin = '${points.first.latitude},${points.first.longitude}';
    final destination = '${points.last.latitude},${points.last.longitude}';
    final waypointPoints = points.sublist(1, points.length - 1);
    final waypoints = waypointPoints.isEmpty
        ? null
        : waypointPoints
              .map((point) => '${point.latitude},${point.longitude}')
              .join('|');

    return Uri.https('maps.googleapis.com', '/maps/api/directions/json', {
      'origin': origin,
      'destination': destination,
      if (waypoints != null && waypoints.isNotEmpty) 'waypoints': waypoints,
      'mode': 'bicycling', // 單車模式
      'key': apiKey,
    });
  }

  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0;
    int latitude = 0;
    int longitude = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;

      while (true) {
        final int byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
        if (byte < 0x20) break;
      }

      final int deltaLatitude = (result & 1) != 0
          ? ~(result >> 1)
          : (result >> 1);
      latitude += deltaLatitude;

      shift = 0;
      result = 0;

      while (true) {
        final int byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
        if (byte < 0x20) break;
      }

      final int deltaLongitude = (result & 1) != 0
          ? ~(result >> 1)
          : (result >> 1);
      longitude += deltaLongitude;

      points.add(LatLng(latitude / 1E5, longitude / 1E5));
    }

    return points;
  }

  /// 從巢狀 JSON 區塊中取出數值欄位，避免 widget 直接碰 API 結構。
  int _extractNumericValue(Map<String, dynamic>? section, String key) {
    if (section == null) {
      return 0;
    }

    final dynamic rawValue = section[key];
    if (rawValue is int) {
      return rawValue;
    }
    if (rawValue is double) {
      return rawValue.round();
    }
    return 0;
  }

  /// 將公尺格式化成較適合畫面顯示的文字。
  String _formatDistance(int meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '$meters m';
  }

  /// 將秒數格式化成較適合畫面顯示的文字。
  String _formatDuration(int seconds) {
    if (seconds >= 3600) {
      final int hours = seconds ~/ 3600;
      final int minutes = (seconds % 3600) ~/ 60;
      return minutes > 0 ? '$hours 小時 $minutes 分' : '$hours 小時';
    }
    final int minutes = (seconds / 60).round();
    return '$minutes 分';
  }
}
