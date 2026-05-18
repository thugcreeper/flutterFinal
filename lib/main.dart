import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/user_profile_page.dart';
import 'pages/settingPage.dart';
import 'pages/auth_gate.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'map_Initializer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 初始化環境變數
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('Error loading .env file: $e');
  }
  // 初始化Firebase，將驗證等流程交給firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  //初始化google map
  final GoogleMapsFlutterPlatform mapsImplementation =
      GoogleMapsFlutterPlatform.instance;
  if (mapsImplementation is GoogleMapsFlutterAndroid) {
    await initializeMapRenderer();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    String? clientId = dotenv.env['GOOGLE_CLIENT_ID'];
    if (clientId == null) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Google Client ID 未設定，請檢查 .env 檔案')),
        ),
      );
    }
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        fontFamily: 'english',
      ),
      //home要設定為AuthGate，讓它負責判斷要顯示登入頁還是首頁
      home: AuthGate(clientId: clientId),
      //main統一管理路由
      routes: {
        '/profile': (context) => const UserProfilePage(),
        '/settings': (context) => const SettingsPage(),
      },
    );
  }
}
