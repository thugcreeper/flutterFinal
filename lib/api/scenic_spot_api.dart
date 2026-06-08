import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/scenic_spot.dart';

class ScenicSpotService {
  static const String _tokenUrl =
      'https://tdx.transportdata.tw/auth/realms/TDXConnect/protocol/openid-connect/token';
  static const String _baseUrl =
      'https://tdx.transportdata.tw/api/basic/v2/Tourism';

  String get _clientId => dotenv.env['TDX_CLIENT_ID'] ?? '';
  String get _clientSecret => dotenv.env['TDX_CLIENT_SECRET'] ?? '';

  final http.Client _client;

  String? _accessToken;
  DateTime? _tokenExpiry;

  ScenicSpotService({http.Client? client}) : _client = client ?? http.Client();

  String _escapeODataString(String input) => input.replaceAll("'", "''");

  // ── Token 管理 ────────────────────────────────────────────

  /// 取得 access token，若未過期則直接回傳快取的 token
  Future<String?> _getToken() async {
    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _accessToken;
    }

    try {
      final response = await _client
          .post(
            Uri.parse(_tokenUrl),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {
              'grant_type': 'client_credentials',
              'client_id': _clientId,
              'client_secret': _clientSecret,
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _accessToken = data['access_token'] as String?;

      if (_accessToken == null || _accessToken!.isEmpty) {
        return null;
      }

      // token 有效期通常是 1 小時，提前 5 分鐘更新
      final expiresIn = (data['expires_in'] as num?)?.toInt() ?? 3600;
      _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 300));

      return _accessToken;
    } on TimeoutException {
      return null;
    } on SocketException {
      return null;
    } on http.ClientException {
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── 景點搜尋 ──────────────────────────────────────────────

  /// 依關鍵字搜尋景點
  /// [keyword] 搜尋關鍵字
  /// [top] 最多回傳幾筆，預設 20
  Future<List<ScenicSpot>> searchScenicSpots({
    required String keyword,
    int top = 20,
  }) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      return <ScenicSpot>[];
    }
    final escapedKeyword = _escapeODataString(keyword);

    final uri = Uri.parse('$_baseUrl/ScenicSpot').replace(
      queryParameters: {
        '\$filter': "contains(ScenicSpotName,'$escapedKeyword')",
        '\$top': top.toString(),
        '\$format': 'JSON',
      },
    );

    try {
      final response = await _client
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return <ScenicSpot>[];
      }

      final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;

      return jsonList
          .map((e) => ScenicSpot.fromJson(e as Map<String, dynamic>))
          .where((spot) => spot.latitude != 0.0 && spot.longitude != 0.0)
          .toList();
    } on TimeoutException {
      return <ScenicSpot>[];
    } on SocketException {
      return <ScenicSpot>[];
    } on http.ClientException {
      return <ScenicSpot>[];
    } catch (_) {
      return <ScenicSpot>[];
    }
  }

  /// 依城市取得景點
  /// [city] 城市名稱，例如 'Taipei'
  /// [top] 最多回傳幾筆
  Future<List<ScenicSpot>> getScenicSpotsByCity({
    required String city,
    int top = 300,
  }) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      return <ScenicSpot>[];
    }

    final uri = Uri.parse(
      '$_baseUrl/ScenicSpot/$city',
    ).replace(queryParameters: {'\$top': top.toString(), '\$format': 'JSON'});

    try {
      final response = await _client
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return <ScenicSpot>[];
      }

      final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;

      return jsonList
          .map((e) => ScenicSpot.fromJson(e as Map<String, dynamic>))
          .where((spot) => spot.latitude != 0.0 && spot.longitude != 0.0)
          .toList();
    } on TimeoutException {
      return <ScenicSpot>[];
    } on SocketException {
      return <ScenicSpot>[];
    } on http.ClientException {
      return <ScenicSpot>[];
    } catch (_) {
      return <ScenicSpot>[];
    }
  }
}
