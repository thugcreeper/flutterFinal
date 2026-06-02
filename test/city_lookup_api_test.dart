import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:RideVoyage/api/city_lookup_api.dart';

void main() {
  test('只要回傳 city 就能正確解析縣市', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'address': {'city': '基隆市'},
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final service = CityLookupService();
    final result = await service.resolveCityFromCoordinates(
      latitude: 25.1,
      longitude: 121.7,
      client: client,
    );

    expect(result?.displayName, '基隆市');
    expect(result?.tdxCityKey, 'Keelung');
  });

  test('只有 state=Taiwan 時不應解析成全台', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'address': {'state': 'Taiwan'},
          'display_name': 'Taiwan',
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final service = CityLookupService();
    final result = await service.resolveCityFromCoordinates(
      latitude: 25.1,
      longitude: 121.7,
      client: client,
    );

    expect(result, isNull);
  });

  test('city 不存在但 display_name 含臺北市時仍能解析', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'address': {'suburb': '大安區'},
          'display_name': '大安區, 臺北市, 台灣',
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final service = CityLookupService();
    final result = await service.resolveCityFromCoordinates(
      latitude: 25.033,
      longitude: 121.565,
      client: client,
    );

    expect(result?.displayName, '臺北市');
    expect(result?.tdxCityKey, 'Taipei');
  });

  test('Nominatim 回傳官方用字臺北市時仍能解析', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'address': {'city': '臺北市'},
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final service = CityLookupService();
    final result = await service.resolveCityFromCoordinates(
      latitude: 25.033,
      longitude: 121.565,
      client: client,
    );

    expect(result?.displayName, '臺北市');
    expect(result?.tdxCityKey, 'Taipei');
  });
}
