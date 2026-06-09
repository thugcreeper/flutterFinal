import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  final _storage = const FlutterSecureStorage();
  static const Duration _requestTimeout = Duration(seconds: 10);

  Map<String, dynamic> _failed(
    String message, {
    int? statusCode,
    String? body,
  }) {
    return <String, dynamic>{
      'ok': false,
      'message': message,
      if (statusCode != null) 'statusCode': statusCode,
      if (body != null) 'body': body,
    };
  }

  String? get _baseUrlOrNull {
    final baseUrl = dotenv.env['API_BASE_URL'];
    if (baseUrl == null || baseUrl.trim().isEmpty) {
      return null;
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
    final baseUrl = _baseUrlOrNull;
    if (baseUrl == null) {
      return _failed('環境變數 API_BASE_URL 未設定');
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/register'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode(<String, String>{
              'account': account,
              'password': password,
              'name': name,
            }),
          )
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _storage.write(
          key: 'accessToken',
          value: data['accessToken']?.toString() ?? '',
        );
        return <String, dynamic>{'ok': true, ...data};
      }

      return _failed(
        '註冊失敗 (${response.statusCode})',
        statusCode: response.statusCode,
        body: response.body,
      );
    } on TimeoutException {
      return _failed('註冊請求逾時，請稍後再試');
    } catch (_) {
      return _failed('註冊失敗，請稍後再試');
    }
  }

  //登入API
  Future<Map<String, dynamic>> login(String account, String password) async {
    final baseUrl = _baseUrlOrNull;
    if (baseUrl == null) {
      return _failed('環境變數 API_BASE_URL 未設定');
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode(<String, String>{
              'account': account,
              'password': password,
            }),
          )
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _storage.write(
          key: 'accessToken',
          value: data['accessToken']?.toString() ?? '',
        );
        return <String, dynamic>{'ok': true, ...data};
      }

      if (response.statusCode == 404) {
        return _failed('登入失敗：找不到該帳號', statusCode: response.statusCode);
      }

      if (response.statusCode == 401) {
        return _failed('登入失敗：帳號或密碼錯誤', statusCode: response.statusCode);
      }

      return _failed(
        '登入失敗 (${response.statusCode})',
        statusCode: response.statusCode,
        body: response.body,
      );
    } on TimeoutException {
      return _failed('登入請求逾時，請確認後端是否已啟動');
    } catch (_) {
      return _failed('登入失敗，請稍後再試');
    }
  }

  //google 登入API
  Future<Map<String, dynamic>> googleLogin(String idToken) async {
    final baseUrl = _baseUrlOrNull;
    if (baseUrl == null) {
      return _failed('環境變數 API_BASE_URL 未設定');
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/googlelogin'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode(<String, String>{'idToken': idToken}),
          )
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _storage.write(
          key: 'accessToken',
          value: data['accessToken']?.toString() ?? '',
        );
        return <String, dynamic>{'ok': true, ...data};
      }

      return _failed(
        'Google 登入失敗 (${response.statusCode})',
        statusCode: response.statusCode,
        body: response.body,
      );
    } on TimeoutException {
      return _failed('Google 登入請求逾時，請稍後再試');
    } catch (_) {
      return _failed('Google 登入失敗，請稍後再試');
    }
  }

  // Facebook 登入API
  Future<Map<String, dynamic>> facebookLogin(String fbAccessToken) async {
    final baseUrl = _baseUrlOrNull;
    if (baseUrl == null) {
      return _failed('環境變數 API_BASE_URL 未設定');
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/facebooklogin'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode(<String, String>{'idToken': fbAccessToken}),
          )
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        await _storage.write(
          key: 'accessToken',
          value: data['accessToken']?.toString() ?? '',
        );
        return <String, dynamic>{'ok': true, ...data};
      }

      return _failed(
        'Facebook 登入失敗 (${response.statusCode})',
        statusCode: response.statusCode,
        body: response.body,
      );
    } on TimeoutException {
      return _failed('Facebook 登入請求逾時，請稍後再試');
    } catch (_) {
      return _failed('Facebook 登入失敗，請稍後再試');
    }
  }
}
