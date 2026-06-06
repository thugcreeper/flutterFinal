import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/convenience_store.dart';

class ConvenienceStoreApi {
  final FirebaseFirestore _db;

  ConvenienceStoreApi({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  String _normalizeCity(String city) {
    return city.replaceAll('臺', '台');
  }

  // ── 查詢附近 7-11 ──────────────────────────────────────────

  /// 查詢指定縣市＋行政區的 7-11 門市
  /// [city] 縣市名稱，例如「台北市」
  /// [area] 行政區名稱，例如「中正區」
  /// [keyword] 可選，有傳入時在前端過濾店名
  Future<List<ConvenienceStore>> getNearby711Stores({
    required String city,
    required String area,
    String? keyword,
  }) async {
    try {
      final normalizedCity = _normalizeCity(city);

      final snapshot = await _db
          .collection('7-11Store')
          .doc(normalizedCity)
          .collection(area)
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint('ConvenienceStoreApi: $normalizedCity $area 查無 7-11 門市');
        return [];
      }

      final stores = snapshot.docs
          .map((doc) {
            final data = doc.data();
            return ConvenienceStore(
              id: data['id']?.toString() ?? doc.id,
              name: data['name']?.toString() ?? '',
              address: data['address']?.toString() ?? '',
              city: data['city']?.toString() ?? normalizedCity,
              area: data['area']?.toString() ?? area,
              latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
              longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
              telephone: data['telephone']?.toString() ?? '',
              openTime: data['open_time']?.toString(),
              brand: '7-11',
            );
          })
          .where((s) => s.latitude != 0.0 && s.longitude != 0.0)
          .toList();

      // 關鍵字過濾在前端做（Firestore 不支援 contains 查詢）
      if (keyword != null && keyword.isNotEmpty) {
        return stores.where((s) => s.name.contains(keyword)).toList();
      }

      return stores;
    } catch (e) {
      debugPrint('ConvenienceStoreApi: 查詢 7-11 失敗：$e');
      return [];
    }
  }
}
