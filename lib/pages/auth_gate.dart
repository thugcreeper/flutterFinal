import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:flutter/material.dart';
import '../api/user_profile_api.dart';
import 'login_page.dart';
import 'home_page.dart';

//驗證閘道，負責判斷使用者是否已登入，並顯示對應的頁面
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<bool> _hasBackendSession() async {
    final api = UserProfileApiService();
    return api.hasValidSession();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return const HomePage();
        }

        return FutureBuilder<bool>(
          future: _hasBackendSession(),
          builder: (context, backendSnapshot) {
            if (backendSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (backendSnapshot.data == true) {
              return const HomePage();
            }

            return const LoginPage();
          },
        );
      },
    );
  }
}
