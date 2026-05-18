import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:RideVoyage/widgets/app_bar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

//google map
class loadGoogleMap extends StatefulWidget {
  const loadGoogleMap({super.key});

  @override
  State<loadGoogleMap> createState() => _loadGoogleMapState();
}

class _loadGoogleMapState extends State<loadGoogleMap> {
  late GoogleMapController _mapController;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(25.0330, 121.5654), // 台北
    zoom: 14,
  );

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: _initialPosition,
      onMapCreated: (controller) => _mapController = controller,
    );
  }
}

//整個app的主頁面，目前作為測試登入功能而已
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    // AuthGate 會自動偵測並切回登入頁，不需要手動導頁
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(appBar: const CustomAppBar(), body: loadGoogleMap());
  }
}
