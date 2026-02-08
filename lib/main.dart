// lib/main.dart (güncellenmiş hali)

import 'dart:async';
import 'dart:ui';
import 'package:egitim_uygulamasi/screens/reset_password_screen.dart';
import 'package:egitim_uygulamasi/screens/login_screen.dart';
import 'package:egitim_uygulamasi/screens/signup_screen.dart';
import 'package:egitim_uygulamasi/constants.dart';
import 'package:egitim_uygulamasi/screens/auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:egitim_uygulamasi/utils/web_url.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  cleanAuthCallbackUrl();

  // Supabase'i başlat
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  // Uygulamayı ProviderScope ile sarmala
  runApp(const ProviderScope(child: EgitimUygulamasi()));
}

// Global Navigator Key
final navigatorKey = GlobalKey<NavigatorState>();

// Custom Scroll Behavior
class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}

// ============================================

class EgitimUygulamasi extends StatefulWidget {
  const EgitimUygulamasi({super.key});

  @override
  State<EgitimUygulamasi> createState() => _EgitimUygulamasiState();
}

class _EgitimUygulamasiState extends State<EgitimUygulamasi> {
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) {
        if (data.event == AuthChangeEvent.passwordRecovery) {
          navigatorKey.currentState?.pushNamed('/reset-password');
        }
      },
    );
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eğitim Uygulaması',
      navigatorKey: navigatorKey,
      scrollBehavior: MyCustomScrollBehavior(),
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: const AuthGate(),
      routes: {
        '/reset-password': (context) => const ResetPasswordScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const SignupScreen(),
      },
    );
  }
}

// Supabase'e kolay erişim
final supabase = Supabase.instance.client;
