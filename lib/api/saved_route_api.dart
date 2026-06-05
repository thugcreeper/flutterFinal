//這個code提供對 Firestore 中已儲存路線 (Saved Routes) 進行新增、讀取與刪除的服務層。

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/saved_route.dart';

/// 路線管理服務層，提供 Firestore 的 CRUD 操作。
class SavedRouteApiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 儲存一條新路線至 Firestore。
  ///
  /// Parameters:
  /// - userId: 使用者 UID
  /// - routeName: 路線自訂名稱
  /// - distance: 總距離 (例如: "12.8 km")
  /// - duration: 預估時間 (例如: "50 分鐘")
  /// - points: 經緯度座標清單（可以是 LatLng 或 Map）
  /// - totalAscent: 總爬升高度 (公尺)
  /// - totalDescent: 總下降高度 (公尺)
  ///
  /// Returns:
  /// - 儲存成功後的 Document ID
  Future<String> saveRoute({
    required String userId,
    required String routeName,
    required String distance,
    required String duration,
    required List<dynamic> points,
    required double totalAscent,
    required double totalDescent,
  }) async {
    final Map<String, dynamic> data = {
      'userId': userId,
      'routeName': routeName,
      'createdAt': FieldValue.serverTimestamp(),
      'distance': distance,
      'duration': duration,
      'points': points.map((p) {
        if (p is Map) {
          return {'lat': p['lat'], 'lng': p['lng']};
        } else {
          // 假設是 LatLng 物件
          return {'lat': p.latitude, 'lng': p.longitude};
        }
      }).toList(),
      'totalAscent': totalAscent,
      'totalDescent': totalDescent,
    };

    final docRef = await _firestore.collection('routes').add(data);
    return docRef.id;
  }

  /// 刪除指定的儲存路線。
  ///
  /// Parameters:
  /// - routeId: 欲刪除之路線 Document ID
  Future<void> deleteRoute(String routeId) async {
    await _firestore.collection('routes').doc(routeId).delete();
  }

  /// 取得特定使用者的所有儲存路線（以即時串流 Stream 回傳，方便 UI 即時更新）。
  ///
  /// Parameters:
  /// - userId: 使用者 UID
  ///
  /// Returns:
  /// - 已儲存路線清單的 Stream
  Stream<List<SavedRoute>> getUserRoutesStream(String userId) {
    return _firestore
        .collection('routes')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => SavedRoute.fromFirestore(doc))
              .toList();
        });
  }
}
