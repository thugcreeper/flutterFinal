// 景點資料模型，對應 TDX 觀光景點 API 回傳的 JSON 欄位
//URL:https://tdx.transportdata.tw/api-service/swagger#/Tourism
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'map_point.dart';

class ScenicSpot implements MapPoint {
  final String id;
  final String name;
  final String description;
  final String phone;
  final String pictureUrl;
  final double latitude;
  final double longitude;
  final String city;
  final String? webUrl;

  @override
  double get markerHue => BitmapDescriptor.hueAzure;

  @override
  String get typeLabel => '景點';

  const ScenicSpot({
    required this.id,
    required this.name,
    required this.description,
    required this.phone,
    required this.pictureUrl,
    required this.latitude,
    required this.longitude,
    required this.city,
    this.webUrl,
  });

  factory ScenicSpot.fromJson(Map<String, dynamic> json) {
    final position = json['Position'] as Map<String, dynamic>? ?? {};
    final picture = json['Picture'] as Map<String, dynamic>? ?? {};

    return ScenicSpot(
      id: json['ScenicSpotID']?.toString() ?? '',
      name: json['ScenicSpotName']?.toString() ?? '',
      description: json['DescriptionDetail']?.toString() ?? '',
      phone: json['Phone']?.toString() ?? '',
      pictureUrl: picture['PictureUrl1']?.toString() ?? '',
      latitude: (position['PositionLat'] as num?)?.toDouble() ?? 0.0,
      longitude: (position['PositionLon'] as num?)?.toDouble() ?? 0.0,
      city: json['City']?.toString() ?? '',
      webUrl: json['WebsiteUrl']?.toString(),
    );
  }
}
