import 'map_point.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

//超商資料類別
class ConvenienceStore implements MapPoint {
  const ConvenienceStore({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.area,
    required this.latitude,
    required this.longitude,
    required this.telephone,
    this.openTime, // 全家沒有，nullable
    required this.brand, // '7-11' | '全家'，fromJson 時傳入
  });

  final String id;
  final String name;
  final String address;
  final String city;
  final String area;
  final double latitude;
  final double longitude;
  final String telephone;
  final String? openTime;
  final String brand;
  @override
  String? get webUrl => null;

  // ── MapPoint 實作 ─────────────────────────────────────────

  @override
  String get description => [
    if (openTime != null) '營業時間：$openTime',
    if (telephone.isNotEmpty) '電話：$telephone',
    if (address.isNotEmpty) address,
  ].join('\n');

  @override
  String get pictureUrl => brand == '7-11'
      ? 'assets/icons/711_marker.png'
      : 'assets/icons/fm_marker.png';

  @override
  String get typeLabel => brand;

  @override
  double get markerHue =>
      brand == '7-11' ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueGreen;
}
