import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/user_profile_page.dart';
import 'pages/setting_page.dart';
import 'pages/auth_gate.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart'; //狀態管理套件
import '../providers/theme_provider.dart';
import '../providers/route_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 初始化環境變數
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Error loading .env file: $e');
  }
  // 初始化Firebase，將驗證等流程交給firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    //MaterialApp外要包一層ChangeNotifierProvider，提供ThemeProvider給整個app使用，
    //讓它能控制主題切換
    return MultiProvider(
      //建立這個 Provider 的實例。這行的意思是：在 widget tree 這個位置放一個 ThemeProvider，
      //所有在它底下的 widget 都能取得它。
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => RouteProvider()),
      ],
      //Consumer 是我要監聽這個 Provider，它一變我就重建
      child: Consumer<ThemeProvider>(
        builder: (_, themeProvider, _) => MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            fontFamily: 'english',
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromARGB(255, 63, 59, 71),
              brightness: Brightness.dark,
            ),
            fontFamily: 'english',
          ),
          themeMode: themeProvider.themeMode,
          //home要設定為AuthGate，讓它負責判斷要顯示登入頁還是首頁
          home: const AuthGate(),
          routes: {
            '/profile': (context) => const UserProfilePage(),
            '/settings': (context) => const SettingsPage(),
          },
        ),
      ),
    );
  }
}
