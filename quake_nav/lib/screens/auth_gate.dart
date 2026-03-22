import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';
import 'register_screen.dart';

class AuthGate extends StatefulWidget {
  final Widget child;
  final AuthService authService;

  const AuthGate({
    super.key,
    required this.child,
    required this.authService,
  });

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _showLogin = true;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: widget.authService.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        if (user != null) {
          return StreamBuilder<bool>(
            stream: widget.authService.userTourSeenStream(user.uid),
            builder: (context, buildingSnapshot) {
              if (buildingSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final tourSeen = buildingSnapshot.data ?? false;
              if (!tourSeen) {
                return OnboardingScreen(
                  onFinish: () => widget.authService.markCurrentUserTourSeen(),
                );
              }

              return widget.child;
            },
          );
        }
        return _showLogin
            ? LoginScreen(
                authService: widget.authService,
                onSwitch: () => setState(() => _showLogin = false),
              )
            : RegisterScreen(
                authService: widget.authService,
                onSwitch: () => setState(() => _showLogin = true),
              );
      },
    );
  }
}
