//超商資料類別
class ConvenienceStore {
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
}
