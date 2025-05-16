import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../screens/login.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService.isLoggedIn(), // ✅ Call the async function properly
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator()); // ✅ Show loading while checking auth
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == false) {
          return LoginScreen(); // ✅ No `const` here
        }

        return child; // ✅ If logged in, show the child widget
      },
    );
  }
}
