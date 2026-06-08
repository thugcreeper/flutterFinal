import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/restaurant.dart';

class RestaurantService {
  static const String _tokenUrl =
      'https://tdx.transportdata.tw/auth/realms/TDXConnect/protocol/openid-connect/token';
  static const String _baseUrl =
      'https://tdx.transportdata.tw/api/basic/v2/Tourism';

  String get _clientId => dotenv.env['TDX_CLIENT_ID'] ?? '';
  String get _clientSecret => dotenv.env['TDX_CLIENT_SECRET'] ?? '';

  String? _accessToken;
  DateTime? _tokenExpiry;

  String _escapeODataString(String input) => input.replaceAll("'", "''");

  // ── Token 管理 ────────────────────────────────────────────

  Future<String?> _getToken() async {
    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _accessToken;
    }

    try {
      final response = await http
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

  // ── 餐廳搜尋 ──────────────────────────────────────────────

  /// 依關鍵字搜尋餐廳
  Future<List<Restaurant>> searchRestaurants({
    required String keyword,
    int top = 20,
  }) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      return <Restaurant>[];
    }
    final escapedKeyword = _escapeODataString(keyword);

    final uri = Uri.parse('$_baseUrl/Restaurant').replace(
      queryParameters: {
        '\$filter': "contains(RestaurantName,'$escapedKeyword')",
        '\$top': top.toString(),
        '\$format': 'JSON',
      },
    );

    try {
      final response = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return <Restaurant>[];
      }

      final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;

      return jsonList
          .map((e) => Restaurant.fromJson(e as Map<String, dynamic>))
          .where((r) => r.latitude != 0.0 && r.longitude != 0.0)
          .toList();
    } on TimeoutException {
      return <Restaurant>[];
    } on SocketException {
      return <Restaurant>[];
    } on http.ClientException {
      return <Restaurant>[];
    } catch (_) {
      return <Restaurant>[];
    }
  }

  /// 依城市取得餐廳
  Future<List<Restaurant>> getRestaurantsByCity({
    required String city,
    int top = 300,
  }) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      return <Restaurant>[];
    }

    final uri = Uri.parse(
      '$_baseUrl/Restaurant/$city',
    ).replace(queryParameters: {'\$top': top.toString(), '\$format': 'JSON'});

    try {
      final response = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return <Restaurant>[];
      }

      final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;

      return jsonList
          .map((e) => Restaurant.fromJson(e as Map<String, dynamic>))
          .where((r) => r.latitude != 0.0 && r.longitude != 0.0)
          .toList();
    } on TimeoutException {
      return <Restaurant>[];
    } on SocketException {
      return <Restaurant>[];
    } on http.ClientException {
      return <Restaurant>[];
    } catch (_) {
      return <Restaurant>[];
    }
  }
}
