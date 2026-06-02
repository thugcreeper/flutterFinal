import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../models/elevation_summary.dart';

class ElevationApiService {
  ElevationApiService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  /// 以座標點清單向 Elevation API 查詢海拔摘要（採樣以避免過長的 URL）。
  ///
  /// - `points`: 原始路線座標（Directions 解碼後的 polyline points）。
  /// - `maxSamples`: 向 Elevation API 發出查詢的最大採樣點數，預設 100。
  /// - `thresholdMeters`: 差異低於此閾值會被視為雜訊並忽略（單位：公尺）。
  Future<ElevationSummary> fetchElevationSummaryFromPoints(
    List<LatLng> points, {
    int maxSamples = 100,
    double thresholdMeters = 2.0,
  }) async {
    if (points.length < 2) {
      return ElevationSummary(
        startElevation: 0.0,
        endElevation: 0.0,
        totalAscent: 0.0,
        totalDescent: 0.0,
        sampleCount: 0,
        samples: const [],
      );
    }

    final apiKey = dotenv.env['MAPS_PLATFORM_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw StateError('MAPS_PLATFORM_API_KEY 尚未設定');
    }

    final sampled = _samplePoints(points, maxSamples);
    //將採樣後的座標點轉換成 Elevation API 所需的 locations 參數格式，例如 "lat,lng|lat,lng|..."
    final locations = sampled
        .map((p) => '${p.latitude},${p.longitude}')
        .join('|');

    final uri = Uri.https('maps.googleapis.com', '/maps/api/elevation/json', {
      'locations': locations,
      'key': apiKey,
    });

    final resp = await _client
        .get(uri)
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () {
            throw TimeoutException('Elevation API 請求逾時');
          },
        );
    if (resp.statusCode != 200) {
      throw StateError('Elevation API 呼叫失敗：${resp.statusCode}');
    }

    final Map<String, dynamic> data =
        jsonDecode(resp.body) as Map<String, dynamic>;
    final String status = data['status'] as String? ?? 'UNKNOWN';
    if (status != 'OK') {
      final errorMessage = data['error_message'] as String?;
      throw StateError(
        'Elevation API 回傳失敗：$status${errorMessage == null ? '' : ' - $errorMessage'}',
      );
    }

    final List<dynamic> results = data['results'] as List<dynamic>? ?? const [];
    final elevations = results.map<double>((r) {
      final Map<String, dynamic> m = r as Map<String, dynamic>;
      final dynamic elev = m['elevation'];
      if (elev is num) return elev.toDouble();
      return 0.0;
    }).toList();

    if (elevations.isEmpty) {
      return ElevationSummary(
        startElevation: 0.0,
        endElevation: 0.0,
        totalAscent: 0.0,
        totalDescent: 0.0,
        sampleCount: 0,
        samples: elevations,
      );
    }

    double ascent = 0.0;
    double descent = 0.0;
    //計算總爬升與總下降，並使用閾值過濾掉小的變化
    for (int i = 1; i < elevations.length; i++) {
      final diff = elevations[i] - elevations[i - 1];
      if (diff > thresholdMeters) {
        ascent += diff;
      } else if (diff < -thresholdMeters) {
        descent += -diff;
      }
    }

    return ElevationSummary(
      startElevation: elevations.first,
      endElevation: elevations.last,
      totalAscent: ascent,
      totalDescent: descent,
      sampleCount: elevations.length,
      samples: elevations,
    );
  }

  List<LatLng> _samplePoints(List<LatLng> points, int maxSamples) {
    // 如果點數已經在限制內，直接回傳原始清單。
    if (points.length <= maxSamples) return List<LatLng>.from(points);

    final List<LatLng> out = [];
    //factor 計算原始點與採樣點之間的比例，確保均勻分布在整條路線上。
    final double factor = (points.length - 1) / (maxSamples - 1);
    for (int i = 0; i < maxSamples; i++) {
      final int idx = (i * factor).round();
      final int clamped = idx.clamp(0, points.length - 1);
      out.add(points[clamped]);
    }
    return out;
  }
}
