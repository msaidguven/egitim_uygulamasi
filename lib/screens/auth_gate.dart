// lib/screens/auth_gate.dart

import 'package:flutter/material.dart';
import 'package:egitim_uygulamasi/screens/main_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // Uygulama her zaman alt menü yapısını içeren MainScreen ile başlasın.
    return const MainScreen();
  }
}
