import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:egitim_uygulamasi/constants.dart';
import 'package:egitim_uygulamasi/admin/admin_auth_gate.dart';

Future<void> main() async {
  // Flutter binding'lerinin başlatıldığından emin ol.
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase'i başlat.
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  // Uygulamayı AdminAuthGate ile başlatarak kimlik kontrolü sağla.
  runApp(const AdminGirisUygulamasi());
}

class AdminGirisUygulamasi extends StatelessWidget {
  const AdminGirisUygulamasi({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Paneli',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AdminAuthGate(),
    );
  }
}
