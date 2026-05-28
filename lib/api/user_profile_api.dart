import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class UserProfileApiService {
  UserProfileApiService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  String get _baseUrl {
    final baseUrl = dotenv.env['API_BASE_URL'];
    if (baseUrl == null || baseUrl.trim().isEmpty) {
      throw Exception('環境變數 API_BASE_URL 未設定');
    }
    return baseUrl.trim().replaceAll(RegExp(r'\/$'), '');
  }

  Future<Map<String, dynamic>> getMe() async {
    final token = await _storage.read(key: 'accessToken');
    if (token == null || token.isEmpty) {
      throw Exception('未找到 accessToken');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/users/me'),
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception('取得使用者資訊失敗: ${response.body}');
  }

  Future<void> logout() async {
    await _storage.delete(key: 'accessToken');
  }

  Future<void> deleteAccount() async {
    final token = await _storage.read(key: 'accessToken');
    if (token == null || token.isEmpty) {
      throw Exception('未找到 accessToken');
    }
    final response = await http.delete(
      Uri.parse('$_baseUrl/users/me'),
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 204) {
      throw Exception('刪除帳號失敗: ${response.body}');
    }
  }
}
