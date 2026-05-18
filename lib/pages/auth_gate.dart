import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/material.dart';
import '../widgets/safe_asset_image.dart';
import 'home_page.dart';

//驗證閘道，負責判斷使用者是否已登入，並顯示對應的頁面
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SignInScreen(
            providers: [
              EmailAuthProvider(),
              GoogleProvider(clientId: clientId),
            ],
            headerBuilder: (context, constraints, shrinkOffset) {
              return SingleChildScrollView(
                // 加上滾動包裹
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 60,
                    left: 20,
                    right: 20,
                    bottom: 20,
                  ), // 增加 top padding 把內容往下推
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        height: 100,
                        width: 100,
                        child: SafeAssetImage(
                          assetPath: 'assets/flutterfire_300x.png',
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'RideVoyage',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }

        return const HomePage();
      },
    );
  }
}
