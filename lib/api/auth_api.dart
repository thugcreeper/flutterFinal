import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  final _storage = const FlutterSecureStorage();

  String get _baseUrl {
    final baseUrl = dotenv.env['API_BASE_URL'];
    if (baseUrl == null || baseUrl.trim().isEmpty) {
      throw Exception('環境變數 API_BASE_URL 未設定');
    }
    return baseUrl.trim().replaceAll(RegExp(r'\/$'), '');
  }

  //用Map<String,dynamic>是因為回傳的json key總是字串，而value可以是int bool...
  //註冊API
  Future<Map<String, dynamic>> register(
    String account,
    String password,
    String name,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'account': account,
        'password': password,
        'name': name,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _storage.write(key: 'accessToken', value: data['accessToken']);
      return data;
    } else {
      throw Exception('註冊失敗: ${response.body}');
    }
  }

  //登入API
  Future<Map<String, dynamic>> login(String account, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'account': account,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _storage.write(key: 'accessToken', value: data['accessToken']);
      return data;
    } else {
      throw Exception('登入失敗: ${response.body}');
    }
  }

  //google 登入API
  Future<Map<String, dynamic>> googleLogin(String idToken) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/googlelogin'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{'idToken': idToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _storage.write(key: 'accessToken', value: data['accessToken']);
      return data;
    } else {
      throw Exception('Google 登入失敗: ${response.body}');
    }
  }
}
