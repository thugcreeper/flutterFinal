//負責儲存目前所選的路線資訊，提供給首頁與路線規劃頁面存取
import 'package:flutter/material.dart';
import '../models/saved_route.dart';

class RouteProvider extends ChangeNotifier {
  SavedRoute? _selectedRoute;

  SavedRoute? get selectedRoute => _selectedRoute;

  void selectRoute(SavedRoute route) {
    _selectedRoute = route;
    notifyListeners();
  }

  void consumeRoute() {
    _selectedRoute = null;
    notifyListeners();
  }

  void clear() {
    _selectedRoute = null;
    notifyListeners();
  }
}
