// lib/main.dart

import 'package:egitim_uygulamasi/screens/reset_password_screen.dart';
import 'package:egitim_uygulamasi/constants.dart';
import 'package:egitim_uygulamasi/screens/auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  // Flutter uygulamasının başlatılmadan önce diğer bağlamaların hazır olduğundan emin ol.
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase'i başlat.
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const EgitimUygulamasi());
}

// Global Navigator Key
final navigatorKey = GlobalKey<NavigatorState>();

class EgitimUygulamasi extends StatelessWidget {
  const EgitimUygulamasi({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eğitim Uygulaması',
      navigatorKey: navigatorKey, // Navigator key'i ekliyoruz
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Uygulama başlangıcını AuthGate ile yapıyoruz.
      home: const AuthGate(),
      // İsimlendirilmiş rotaları tanımlıyoruz.
      routes: {'/reset-password': (context) => const ResetPasswordScreen()},
    );
  }
}

// Supabase'e kolay erişim için bir kısayol.
final supabase = Supabase.instance.client;
