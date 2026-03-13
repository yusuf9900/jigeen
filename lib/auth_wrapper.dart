import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:jigeen/home_screen.dart';
import 'package:jigeen/main.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If the connection is still loading, show a progress indicator
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF1E1B2E),
            body: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        // If user is logged in, show the home screen
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        // If user is not logged in, show the onboarding screen
        return const OnboardingScreen();
      },
    );
  }
}
