import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/userProfilePage.dart';
import 'pages/auth_gate.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
      ),
      //home要設定為AuthGate，讓它負責判斷要顯示登入頁還是首頁
      home: AuthGate(clientId: clientId),
      //main統一管理路由
      routes: {'/profile': (context) => const UserProfilePage()},
    );
  }
}
