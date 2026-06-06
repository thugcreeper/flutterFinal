// 這個檔案負責透過經緯度反查台灣城市名稱與 TDX 縣市代碼。
// 提供附近搜尋使用的城市辨識功能。
// ex:https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=25.15089&lon=121.77531&zoom=10&addressdetails=1&accept-language=zh-TW
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/resolved_city.dart';

/// 將地圖中心點經緯度反查為台灣縣市資訊，供 TDX Tourism API 使用。
class CityLookupService {
  static const String _reverseGeocodeUrl =
      'https://nominatim.openstreetmap.org/reverse';

  static const Map<String, ResolvedCity> _cityAliases = {
    '台北市': ResolvedCity(displayName: '臺北市', tdxCityKey: 'Taipei'),
    '台北': ResolvedCity(displayName: '臺北市', tdxCityKey: 'Taipei'),
    'taipeicity': ResolvedCity(displayName: '臺北市', tdxCityKey: 'Taipei'),
    'taipei': ResolvedCity(displayName: '臺北市', tdxCityKey: 'Taipei'),
    '新北市': ResolvedCity(displayName: '新北市', tdxCityKey: 'NewTaipei'),
    '新北': ResolvedCity(displayName: '新北市', tdxCityKey: 'NewTaipei'),
    'newtaipeicity': ResolvedCity(displayName: '新北市', tdxCityKey: 'NewTaipei'),
    'newtaipei': ResolvedCity(displayName: '新北市', tdxCityKey: 'NewTaipei'),
    '桃園市': ResolvedCity(displayName: '桃園市', tdxCityKey: 'Taoyuan'),
    '桃園': ResolvedCity(displayName: '桃園市', tdxCityKey: 'Taoyuan'),
    'taoyuancity': ResolvedCity(displayName: '桃園市', tdxCityKey: 'Taoyuan'),
    'taoyuan': ResolvedCity(displayName: '桃園市', tdxCityKey: 'Taoyuan'),
    '台中市': ResolvedCity(displayName: '臺中市', tdxCityKey: 'Taichung'),
    '台中': ResolvedCity(displayName: '臺中市', tdxCityKey: 'Taichung'),
    'taichungcity': ResolvedCity(displayName: '臺中市', tdxCityKey: 'Taichung'),
    'taichung': ResolvedCity(displayName: '臺中市', tdxCityKey: 'Taichung'),
    '台南市': ResolvedCity(displayName: '臺南市', tdxCityKey: 'Tainan'),
    '台南': ResolvedCity(displayName: '臺南市', tdxCityKey: 'Tainan'),
    'tainancity': ResolvedCity(displayName: '臺南市', tdxCityKey: 'Tainan'),
    'tainan': ResolvedCity(displayName: '臺南市', tdxCityKey: 'Tainan'),
    '高雄市': ResolvedCity(displayName: '高雄市', tdxCityKey: 'Kaohsiung'),
    '高雄': ResolvedCity(displayName: '高雄市', tdxCityKey: 'Kaohsiung'),
    'kaohsiungcity': ResolvedCity(displayName: '高雄市', tdxCityKey: 'Kaohsiung'),
    'kaohsiung': ResolvedCity(displayName: '高雄市', tdxCityKey: 'Kaohsiung'),
    '基隆市': ResolvedCity(displayName: '基隆市', tdxCityKey: 'Keelung'),
    '基隆': ResolvedCity(displayName: '基隆市', tdxCityKey: 'Keelung'),
    'keelungcity': ResolvedCity(displayName: '基隆市', tdxCityKey: 'Keelung'),
    'keelung': ResolvedCity(displayName: '基隆市', tdxCityKey: 'Keelung'),
    '新竹市': ResolvedCity(displayName: '新竹市', tdxCityKey: 'Hsinchu'),
    '新竹': ResolvedCity(displayName: '新竹市', tdxCityKey: 'Hsinchu'),
    'hsinchucity': ResolvedCity(displayName: '新竹市', tdxCityKey: 'Hsinchu'),
    'hsinchu': ResolvedCity(displayName: '新竹市', tdxCityKey: 'Hsinchu'),
    '新竹縣': ResolvedCity(displayName: '新竹縣', tdxCityKey: 'HsinchuCounty'),
    'hsinchucounty': ResolvedCity(
      displayName: '新竹縣',
      tdxCityKey: 'HsinchuCounty',
    ),
    '苗栗縣': ResolvedCity(displayName: '苗栗縣', tdxCityKey: 'MiaoliCounty'),
    'miaolicounty': ResolvedCity(
      displayName: '苗栗縣',
      tdxCityKey: 'MiaoliCounty',
    ),
    '彰化縣': ResolvedCity(displayName: '彰化縣', tdxCityKey: 'ChanghuaCounty'),
    'changhuacounty': ResolvedCity(
      displayName: '彰化縣',
      tdxCityKey: 'ChanghuaCounty',
    ),
    '南投縣': ResolvedCity(displayName: '南投縣', tdxCityKey: 'NantouCounty'),
    'nantoucounty': ResolvedCity(
      displayName: '南投縣',
      tdxCityKey: 'NantouCounty',
    ),
    '雲林縣': ResolvedCity(displayName: '雲林縣', tdxCityKey: 'YunlinCounty'),
    'yunlincounty': ResolvedCity(
      displayName: '雲林縣',
      tdxCityKey: 'YunlinCounty',
    ),
    '嘉義市': ResolvedCity(displayName: '嘉義市', tdxCityKey: 'Chiayi'),
    'chiayicity': ResolvedCity(displayName: '嘉義市', tdxCityKey: 'Chiayi'),
    '嘉義縣': ResolvedCity(displayName: '嘉義縣', tdxCityKey: 'ChiayiCounty'),
    'chiayicounty': ResolvedCity(
      displayName: '嘉義縣',
      tdxCityKey: 'ChiayiCounty',
    ),
    '屏東縣': ResolvedCity(displayName: '屏東縣', tdxCityKey: 'PingtungCounty'),
    'pingtungcounty': ResolvedCity(
      displayName: '屏東縣',
      tdxCityKey: 'PingtungCounty',
    ),
    '宜蘭縣': ResolvedCity(displayName: '宜蘭縣', tdxCityKey: 'YilanCounty'),
    'yilancounty': ResolvedCity(displayName: '宜蘭縣', tdxCityKey: 'YilanCounty'),
    '花蓮縣': ResolvedCity(displayName: '花蓮縣', tdxCityKey: 'HualienCounty'),
    'hualiancounty': ResolvedCity(
      displayName: '花蓮縣',
      tdxCityKey: 'HualienCounty',
    ),
    '台東縣': ResolvedCity(displayName: '臺東縣', tdxCityKey: 'TaitungCounty'),
    '台東': ResolvedCity(displayName: '臺東縣', tdxCityKey: 'TaitungCounty'),
    'taitungcounty': ResolvedCity(
      displayName: '臺東縣',
      tdxCityKey: 'TaitungCounty',
    ),
    'taitung': ResolvedCity(displayName: '臺東縣', tdxCityKey: 'TaitungCounty'),
    '金門縣': ResolvedCity(displayName: '金門縣', tdxCityKey: 'KinmenCounty'),
    'kinmencounty': ResolvedCity(
      displayName: '金門縣',
      tdxCityKey: 'KinmenCounty',
    ),
    '澎湖縣': ResolvedCity(displayName: '澎湖縣', tdxCityKey: 'PenghuCounty'),
    'penghucounty': ResolvedCity(
      displayName: '澎湖縣',
      tdxCityKey: 'PenghuCounty',
    ),
    '連江縣': ResolvedCity(displayName: '連江縣', tdxCityKey: 'LienchiangCounty'),
    'lienchiangcounty': ResolvedCity(
      displayName: '連江縣',
      tdxCityKey: 'LienchiangCounty',
    ),
  };

  /// 依經緯度反查城市資訊。
  ///
  /// Parameters:
  /// - latitude: 地圖中心點緯度
  /// - longitude: 地圖中心點經度
  ///
  /// Returns:
  /// - 成功時回傳城市資訊，失敗則回傳 null。
  Future<ResolvedCity?> resolveCityFromCoordinates({
    required double latitude,
    required double longitude,
    http.Client? client,
  }) async {
    try {
      final uri = Uri.parse(_reverseGeocodeUrl).replace(
        queryParameters: {
          'format': 'jsonv2',
          'lat': latitude.toString(),
          'lon': longitude.toString(),
          'zoom': '10',
          'addressdetails': '1',
          'accept-language': 'zh-TW',
        },
      );

      final response = client == null
          ? await http.get(
              uri,
              headers: const {
                'User-Agent': 'RideVoyage/1.0 (Flutter)',
                'Accept-Language': 'zh-TW',
              },
            )
          : await client.get(
              uri,
              headers: const {
                'User-Agent': 'RideVoyage/1.0 (Flutter)',
                'Accept-Language': 'zh-TW',
              },
            );

      if (response.statusCode != 200) {
        debugPrint('CityLookupService: 反查城市失敗，status=${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final address = data['address'] as Map<String, dynamic>? ?? {};
      final displayName = data['display_name']?.toString();
      final area =
          address['suburb']?.toString() ??
          address['town']?.toString() ??
          address['city_district']?.toString() ??
          address['quarter']?.toString();

      final candidates = <String?>[
        address['city']?.toString(),
        address['town']?.toString(),
        address['county']?.toString(),
        address['city_district']?.toString(),
        address['district']?.toString(),
        address['suburb']?.toString(),
        ..._addressValueCandidates(address),
        ..._displayNameCandidates(displayName),
      ];

      for (final candidate in candidates) {
        final resolvedCity = _resolveByRawName(candidate);
        if (resolvedCity != null) {
          debugPrint(
            'CityLookupService: 座標=($latitude, $longitude) -> ${resolvedCity.displayName} / ${resolvedCity.tdxCityKey}',
          );
          return ResolvedCity(
            displayName: resolvedCity.displayName,
            tdxCityKey: resolvedCity.tdxCityKey,
            area: area,
          );
        }
      }

      debugPrint(
        'CityLookupService: 無法從反查結果判斷縣市，座標=($latitude, $longitude)，address=$address',
      );
      return null;
    } catch (error) {
      debugPrint('CityLookupService: 反查城市失敗：$error');
      return null;
    }
  }

  List<String> _addressValueCandidates(Map<String, dynamic> address) {
    return address.values
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
  }

  List<String> _displayNameCandidates(String? displayName) {
    if (displayName == null || displayName.trim().isEmpty) {
      return const [];
    }
    return displayName
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
  }

  ResolvedCity? _resolveByRawName(String? rawName) {
    if (rawName == null || rawName.trim().isEmpty) {
      return null;
    }

    final trimmed = rawName.trim();
    final taiwaneseVariant = trimmed.replaceAll('臺', '台');
    final normalized = _normalize(trimmed);
    return _cityAliases[trimmed] ??
        _cityAliases[taiwaneseVariant] ??
        _cityAliases[normalized];
  }

  String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('臺', '台')
        .replaceAll(' ', '')
        .replaceAll('－', '')
        .replaceAll('–', '')
        .replaceAll('-', '')
        .replaceAll('市', 'city')
        .replaceAll('縣', 'county')
        .replaceAll('區', '')
        .replaceAll('鄉', '')
        .replaceAll('鎮', '');
  }
}
