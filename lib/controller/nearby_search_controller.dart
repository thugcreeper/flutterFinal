import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../api/city_lookup_api.dart';
import '../models/map_point.dart';
import '../models/convenience_store.dart';

class NearbySearchController extends ChangeNotifier {
  static const String scenicLabel = '景點';
  static const String restaurantLabel = '餐廳';
  static const String storeLabel = '超商';

  // ── 狀態 ──────────────────────────────────────────────────
  bool isLoading = false;
  bool showPanel = false;
  String? cityLabel;
  String? areaLabel;
  String? errorMessage;
  String? currentKeyword;
  String currentCategory = scenicLabel;
  List<MapPoint> results = [];
  LatLng? lastResultCenter;

  // ── 內部依賴 ──────────────────────────────────────────────
  final CityLookupService _cityLookupService = CityLookupService();
  LatLng? _currentMapCenter;

  void updateMapCenter(LatLng center) {
    _currentMapCenter = center;
  }

  LatLng _defaultSearchCenter() {
    return _currentMapCenter ?? const LatLng(25.15089, 121.77531);
  }

  // ── 主要搜尋方法 ──────────────────────────────────────────
  Future<void> handleNearbySearch(
    String keyword,
    String category, {
    LatLngBounds? bounds, //取得地圖邊界以優化搜尋
    required Future<List<MapPoint>> Function({
      required String city,
      required double latitude,
      required double longitude,
      String? keyword,
      int top,
    })
    searchScenicSpots,
    required Future<List<MapPoint>> Function({
      required String city,
      required double latitude,
      required double longitude,
      String? keyword,
      int top,
    })
    searchRestaurants,
    required Future<List<ConvenienceStore>> Function({
      required String city,
      required String area,
      String? keyword,
    })
    searchStores,
  }) async {
    final normalizedKeyword = keyword.trim();
    final center = _defaultSearchCenter();

    isLoading = true;
    showPanel = true;
    results = [];
    errorMessage = null;
    currentKeyword = normalizedKeyword;
    currentCategory = category;
    lastResultCenter = null;
    notifyListeners();

    try {
      final resolvedCity = await _cityLookupService.resolveCityFromCoordinates(
        latitude: center.latitude,
        longitude: center.longitude,
      );

      if (resolvedCity == null) {
        cityLabel = '未知';
        areaLabel = '未知';
        errorMessage =
            '無法判斷目前地圖中心所在城市，'
            '有可能是因為地圖中心點在海上，請稍微移動地圖後再試一次';
        notifyListeners();
        return;
      }

      cityLabel = resolvedCity.displayName;
      areaLabel = resolvedCity.area ?? '未知';

      List<MapPoint> fetchedResults = [];

      if (category == storeLabel) {
        // 超商：查 Firestore，area 可能為 null 就回傳空
        final area = resolvedCity.area;
        if (area == null) {
          errorMessage = '無法判斷目前行政區，請稍微移動地圖後再試一次';
          notifyListeners();
          return;
        }

        final stores = await searchStores(
          city: resolvedCity.displayName,
          area: area,
          keyword: normalizedKeyword.isEmpty ? null : normalizedKeyword,
        );

        // ConvenienceStore 實作 MapPoint，直接 cast
        fetchedResults = stores;
      } else if (category == scenicLabel) {
        fetchedResults = await searchScenicSpots(
          city: resolvedCity.tdxCityKey,
          latitude: center.latitude,
          longitude: center.longitude,
          keyword: normalizedKeyword.isEmpty ? null : normalizedKeyword,
          top: 50,
        );
      } else {
        fetchedResults = await searchRestaurants(
          city: resolvedCity.tdxCityKey,
          latitude: center.latitude,
          longitude: center.longitude,
          keyword: normalizedKeyword.isEmpty ? null : normalizedKeyword,
          top: 50,
        );
      }
      if (bounds != null) {
        final latDiff = bounds.northeast.latitude - bounds.southwest.latitude;
        final lngDiff = bounds.northeast.longitude - bounds.southwest.longitude;

        fetchedResults = fetchedResults.where((point) {
          return point.latitude >= bounds.southwest.latitude - latDiff / 2 &&
              point.latitude <= bounds.northeast.latitude + latDiff / 2 &&
              point.longitude >= bounds.southwest.longitude - lngDiff / 2 &&
              point.longitude <= bounds.northeast.longitude + lngDiff / 2;
        }).toList();
      }
      results = fetchedResults;
      errorMessage = fetchedResults.isEmpty ? '目前區域內沒有符合的$category結果' : null;

      if (fetchedResults.isNotEmpty) {
        lastResultCenter = LatLng(
          fetchedResults.first.latitude,
          fetchedResults.first.longitude,
        );
      }

      notifyListeners();
    } catch (e) {
      cityLabel = '未知';
      areaLabel = '未知';
      errorMessage = '搜尋失敗：$e';
      results = [];
      debugPrint('NearbySearchController: 搜尋失敗：$e');
      notifyListeners();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── 面板控制 ──────────────────────────────────────────────
  void closePanel() {
    showPanel = false;
    results = [];
    errorMessage = null;
    cityLabel = null;
    areaLabel = null;
    lastResultCenter = null;
    notifyListeners();
  }
}
