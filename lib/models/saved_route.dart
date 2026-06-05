// 這個code定義已儲存路線的資料結構模型，支援與 Firestore 的序列化與反序列化。

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// 已儲存路線的資料結構模型。
class SavedRoute {
  /// 建立一個 [SavedRoute] 實例。
  const SavedRoute({
    required this.id,
    required this.userId,
    required this.routeName,
    required this.createdAt,
    required this.distance,
    required this.duration,
    required this.points,
    required this.totalAscent,
    required this.totalDescent,
  });

  /// 路線唯一識別碼 (Document ID)
  final String id;

  /// 建立路線的使用者 ID
  final String userId;

  /// 使用者自訂的路線名稱
  final String routeName;

  /// 建立時間
  final DateTime createdAt;

  /// 路線距離文字 (例如: "12.8 km")
  final String distance;

  /// 路線預估時間 (例如: "50 分鐘")
  final String duration;

  /// 經緯度座標清單
  final List<LatLng> points;

  /// 總爬升高度 (公尺)
  final double totalAscent;

  /// 總下降高度 (公尺)
  final double totalDescent;

  /// 從 Firestore 的 Document 快照建立 [SavedRoute]。
  factory SavedRoute.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final pointsList = data['points'] as List<dynamic>? ?? [];
    final parsedPoints = pointsList.map((p) {
      final map = p as Map<String, dynamic>;
      return LatLng(
        (map['lat'] as num).toDouble(),
        (map['lng'] as num).toDouble(),
      );
    }).toList();

    DateTime parsedDate;
    final createdVal = data['createdAt'];
    if (createdVal is Timestamp) {
      parsedDate = createdVal.toDate();
    } else if (createdVal is String) {
      parsedDate = DateTime.tryParse(createdVal) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return SavedRoute(
      id: doc.id,
      userId: (data['userId'] ?? '').toString(),
      routeName: (data['routeName'] ?? '').toString(),
      createdAt: parsedDate,
      distance: (data['distance'] ?? '').toString(),
      duration: (data['duration'] ?? '').toString(),
      points: parsedPoints,
      totalAscent: (data['totalAscent'] as num? ?? 0.0).toDouble(),
      totalDescent: (data['totalDescent'] as num? ?? 0.0).toDouble(),
    );
  }

  /// 將 [SavedRoute] 物件轉換為寫入 Firestore 的 Map 格式。
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'routeName': routeName,
      'createdAt': FieldValue.serverTimestamp(),
      'distance': distance,
      'duration': duration,
      'points': points
          .map((p) => {'lat': p.latitude, 'lng': p.longitude})
          .toList(),
      'totalAscent': totalAscent,
      'totalDescent': totalDescent,
    };
  }
}
