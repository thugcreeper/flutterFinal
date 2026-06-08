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

  //查詢附近 7-11
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

      return _mapStores(snapshot.docs, normalizedCity, area, '7-11', keyword);
    } catch (e) {
      debugPrint('ConvenienceStoreApi: 查詢 7-11 失敗：$e');
      return [];
    }
  }

  //查詢附近全家
  Future<List<ConvenienceStore>> getNearbyFamilyMartStores({
    required String city,
    required String area,
    String? keyword,
  }) async {
    try {
      final normalizedCity = _normalizeCity(city);
      final snapshot = await _db
          .collection('familyMartStore')
          .doc(normalizedCity)
          .collection(area)
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint('ConvenienceStoreApi: $normalizedCity $area 查無全家門市');
        return [];
      }

      return _mapStores(snapshot.docs, normalizedCity, area, '全家', keyword);
    } catch (e) {
      debugPrint('ConvenienceStoreApi: 查詢全家失敗：$e');
      return [];
    }
  }

  //同時查詢兩家，合併結果
  Future<List<ConvenienceStore>> getNearbyAllStores({
    required String city,
    required String area,
    String? keyword,
  }) async {
    final results = await Future.wait([
      getNearby711Stores(city: city, area: area, keyword: keyword),
      getNearbyFamilyMartStores(city: city, area: area, keyword: keyword),
    ]);
    return [...results[0], ...results[1]];
  }

  // 根據brand（7-11或全家）將Firestore查詢結果轉換為ConvenienceStore物件列表，
  // 並過濾掉缺乏座標的資料。若提供keyword，則進一步過濾名稱不包含keyword的門市。
  List<ConvenienceStore> _mapStores(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String city,
    String area,
    String brand,
    String? keyword,
  ) {
    final stores = docs
        .map((doc) {
          final data = doc.data();
          return ConvenienceStore(
            id: data['id']?.toString() ?? doc.id,
            name: data['name']?.toString() ?? '',
            address: data['address']?.toString() ?? '',
            city: data['city']?.toString() ?? city,
            area: data['area']?.toString() ?? area,
            latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
            longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
            telephone: data['telephone']?.toString() ?? '',
            openTime: data['open_time']?.toString(),
            brand: brand,
          );
        })
        .where((s) => s.latitude != 0.0 && s.longitude != 0.0)
        .toList();

    if (keyword != null && keyword.isNotEmpty) {
      return stores.where((s) => s.name.contains(keyword)).toList();
    }

    return stores;
  }
}
