import 'package:flutter/material.dart';
import 'package:RideVoyage/widgets/app_bar.dart';
import 'package:RideVoyage/widgets/route_map_view.dart';

//整個app的主頁面，目前作為測試登入功能而已
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: const CustomAppBar(), body: const RouteMapView());
  }
}
