// 定義地圖上的點位資料結構，包含景點、餐廳、住宿等資訊
abstract class MapPoint {
  String get id;
  String get name;
  String get description;
  String get pictureUrl;
  double get latitude;
  double get longitude;
  String get city;
  String get typeLabel;
  double get markerHue;
  String? get webUrl;
}
