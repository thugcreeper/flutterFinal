// 這個檔案負責觀光資料的搜尋服務。
// 提供關鍵字搜尋與依城市的附近搜尋功能。

import 'dart:math' as math;

import '../models/map_point.dart';
import '../models/restaurant.dart';
import '../models/scenic_spot.dart';
import 'restaurant_api.dart';
import 'scenic_spot_api.dart';

/// 觀光資料搜尋服務，提供關鍵字搜尋與依城市的附近搜尋。
class TourismSearchService {
  final ScenicSpotService _scenicSpotService;
  final RestaurantService _restaurantService;

  TourismSearchService({
    ScenicSpotService? scenicSpotService,
    RestaurantService? restaurantService,
  }) : _scenicSpotService = scenicSpotService ?? ScenicSpotService(),
       _restaurantService = restaurantService ?? RestaurantService();

  /// 依關鍵字同時搜尋景點與餐廳。
  ///
  /// Parameters:
  /// - keyword: 搜尋關鍵字
  /// - top: 各 API 最多回傳幾筆資料
  ///
  /// Returns:
  /// - 已合併的景點與餐廳清單
  Future<List<MapPoint>> searchAll({
    required String keyword,
    int top = 20,
  }) async {
    List<ScenicSpot> scenicSpots = [];
    List<Restaurant> restaurants = [];

    try {
      scenicSpots = await _scenicSpotService.searchScenicSpots(
        keyword: keyword,
        top: top,
      );
    } catch (_) {}

    try {
      restaurants = await _restaurantService.searchRestaurants(
        keyword: keyword,
        top: top,
      );
    } catch (_) {}

    return <MapPoint>[...scenicSpots, ...restaurants];
  }

  /// 依城市搜尋附近景點，並以目前中心點距離排序。
  /// 若提供關鍵字，則會再以名稱、描述與城市資訊過濾。
  ///
  /// Parameters:
  /// - city: TDX 縣市代碼
  /// - latitude: 地圖中心點緯度
  /// - longitude: 地圖中心點經度
  /// - keyword: 可選關鍵字
  /// - top: 最多回傳幾筆資料
  ///
  /// Returns:
  /// - 排序後的景點清單
  Future<List<MapPoint>> searchScenicSpotsNearby({
    required String city,
    required double latitude,
    required double longitude,
    String? keyword,
    int top = 50,
  }) async {
    final scenicSpots = await _scenicSpotService.getScenicSpotsByCity(
      city: city,
      top: top,
    );

    return _sortByDistance(
      _filterByKeyword(scenicSpots, keyword),
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// 依城市搜尋附近餐廳，並以目前中心點距離排序。
  /// 若提供關鍵字，則會再以名稱、描述、地址與城市資訊過濾。
  ///
  /// Parameters:
  /// - city: TDX 縣市代碼
  /// - latitude: 地圖中心點緯度
  /// - longitude: 地圖中心點經度
  /// - keyword: 可選關鍵字
  /// - top: 最多回傳幾筆資料
  ///
  /// Returns:
  /// - 排序後的餐廳清單
  Future<List<MapPoint>> searchRestaurantsNearby({
    required String city,
    required double latitude,
    required double longitude,
    String? keyword,
    int top = 50,
  }) async {
    final restaurants = await _restaurantService.getRestaurantsByCity(
      city: city,
      top: top,
    );

    return _sortByDistance(
      _filterByKeyword(restaurants, keyword),
      latitude: latitude,
      longitude: longitude,
    );
  }

  List<T> _filterByKeyword<T extends MapPoint>(
    List<T> points,
    String? keyword,
  ) {
    final normalizedKeyword = keyword?.trim().toLowerCase() ?? '';
    if (normalizedKeyword.isEmpty) {
      return points;
    }

    return points.where((point) {
      final searchableText = <String>[
        point.name,
        point.description,
        point.city,
        if (point is Restaurant) point.address,
      ].join(' ').toLowerCase();

      return searchableText.contains(normalizedKeyword);
    }).toList();
  }

  List<T> _sortByDistance<T extends MapPoint>(
    List<T> points, {
    required double latitude,
    required double longitude,
  }) {
    final sortedPoints = [...points];
    sortedPoints.sort((a, b) {
      final distanceA = _distanceMeters(
        latitude,
        longitude,
        a.latitude,
        a.longitude,
      );
      final distanceB = _distanceMeters(
        latitude,
        longitude,
        b.latitude,
        b.longitude,
      );

      return distanceA.compareTo(distanceB);
    });
    return sortedPoints;
  }

  double _distanceMeters(
    double latitudeA,
    double longitudeA,
    double latitudeB,
    double longitudeB,
  ) {
    const earthRadiusMeters = 6371000.0;
    final lat1 = latitudeA * math.pi / 180;
    final lat2 = latitudeB * math.pi / 180;
    final deltaLat = (latitudeB - latitudeA) * math.pi / 180;
    final deltaLng = (longitudeB - longitudeA) * math.pi / 180;

    final a =
        math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLng / 2) *
            math.sin(deltaLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }
}
