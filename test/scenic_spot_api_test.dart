import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ridevoyage/api/scenic_spot_api.dart';

void main() {
  test('關鍵字「碼頭」可以命中大稻埕碼頭', () async {
    dotenv.testLoad(fileInput: 'TDX_CLIENT_ID=test\nTDX_CLIENT_SECRET=test');

    final client = MockClient((request) async {
      if (request.url.toString().contains('openid-connect/token')) {
        return http.Response(
          jsonEncode({'access_token': 'fake-token', 'expires_in': 3600}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      if (request.url.path.contains('/ScenicSpot') &&
          request.url.queryParameters[r'$filter']?.contains(
                "contains(ScenicSpotName,'碼頭')",
              ) ==
              true) {
        return http.Response(
          jsonEncode([
            {
              'ScenicSpotID': 'C1_379000000A_000001',
              'ScenicSpotName': '大稻埕碼頭_大稻埕碼頭貨櫃市集',
              'DescriptionDetail': '測試用景點',
              'Phone': '02-12345678',
              'Picture': {'PictureUrl1': 'https://example.com/spot.jpg'},
              'Position': {
                'PositionLon': 121.50760650634766,
                'PositionLat': 25.056400299072266,
              },
              'City': '臺北市',
            },
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      return http.Response(
        '[]',
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final service = ScenicSpotService(client: client);
    final results = await service.searchScenicSpots(keyword: '碼頭');

    expect(results, hasLength(1));
    expect(results.first.name, contains('大稻埕碼頭'));
    expect(results.first.city, '臺北市');
  });
}
