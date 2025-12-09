// lib/screens/auth_gate.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:egitim_uygulamasi/screens/home_screen.dart';
import 'package:egitim_uygulamasi/screens/login_screen.dart';
import 'package:egitim_uygulamasi/screens/reset_password_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    // Sadece şifre sıfırlama olayını dinleyip yönlendirme yap.
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        // Bu ekran zaten açıksa tekrar açma.
        if (ModalRoute.of(context)?.settings.name != '/reset-password') {
          Navigator.of(context).pushNamed('/reset-password');
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Oturum durumunu sürekli dinleyerek doğru ekranı göster.
    return StreamBuilder<User?>(
      stream: Supabase.instance.client.auth.onAuthStateChange.map(
        (data) => data.session?.user,
      ),
      builder: (context, snapshot) =>
          snapshot.data == null ? const LoginScreen() : const HomeScreen(),
    );
  }
}
