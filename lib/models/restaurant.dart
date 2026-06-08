// 餐廳資料模型，對應 TDX 觀光餐廳 API 回傳的 JSON 欄位
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'map_point.dart';

class Restaurant implements MapPoint {
  final String id;
  final String name;
  final String description;
  final String address;
  final String pictureUrl;
  final double latitude;
  final double longitude;
  final String city;
  final String? webUrl;

  @override
  double get markerHue => BitmapDescriptor.hueRed;

  @override
  String get typeLabel => '餐廳';

  const Restaurant({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.pictureUrl,
    required this.latitude,
    required this.longitude,
    required this.city,
    this.webUrl,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    final position = json['Position'] as Map<String, dynamic>? ?? {};
    final picture = json['Picture'] as Map<String, dynamic>? ?? {};

    return Restaurant(
      id: json['RestaurantID']?.toString() ?? '',
      name: json['RestaurantName']?.toString() ?? '',
      description: json['Description']?.toString() ?? '',
      address: json['Address']?.toString() ?? '',
      pictureUrl: picture['PictureUrl1']?.toString() ?? '',
      latitude: (position['PositionLat'] as num?)?.toDouble() ?? 0.0,
      longitude: (position['PositionLon'] as num?)?.toDouble() ?? 0.0,
      city: json['City']?.toString() ?? '',
      webUrl: json['WebsiteUrl']?.toString(),
    );
  }
}
