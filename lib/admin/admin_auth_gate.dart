// lib/admin/admin_auth_gate.dart

import 'package:egitim_uygulamasi/admin/admin_app.dart';
import 'package:egitim_uygulamasi/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Admin paneline erişimi kontrol eden widget.
///
/// Oturum durumunu dinler ve kullanıcı giriş yapmamışsa `LoginScreen`'e,
/// giriş yapmış ve 'admin' rolüne sahipse `AdminApp`'e yönlendirir.
/// Giriş yapmış ancak 'admin' rolüne sahip değilse bir uyarı ekranı gösterir.
class AdminAuthGate extends StatefulWidget {
  const AdminAuthGate({super.key});

  @override
  State<AdminAuthGate> createState() => _AdminAuthGateState();
}

class _AdminAuthGateState extends State<AdminAuthGate> {
  Stream<AuthState>? _authStream;

  @override
  void initState() {
    super.initState();
    // Oturum durumundaki değişiklikleri dinle ve arayüzü yeniden çiz.
    _authStream = Supabase.instance.client.auth.onAuthStateChange;
    _authStream?.listen((data) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<String?> _getUserRole(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();
      return response['role'] as String?;
    } catch (e) {
      debugPrint('Kullanıcı rolü alınırken hata: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;

    // 1. Kullanıcı giriş yapmamışsa, giriş ekranını göster.
    if (currentUser == null) {
      // Admin paneli için giriş ekranını bir Scaffold içinde gösterelim.
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Girişi')),
        body: const LoginScreen(),
      );
    }

    // 2. Kullanıcı giriş yapmışsa, rolünü kontrol et.
    return FutureBuilder<String?>(
      future: _getUserRole(currentUser.id),
      builder: (context, snapshot) {
        // Rol bilgisi yüklenirken bekleme göstergesi.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Rol bilgisi alınırken hata oluşursa veya rol 'admin' değilse.
        if (snapshot.hasError || snapshot.data != 'admin') {
          return Scaffold(
            appBar: AppBar(title: const Text('Hata')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock, size: 60, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'Erişim Reddedildi',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Bu sayfayı görüntüleme yetkiniz bulunmamaktadır.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // 3. Kullanıcı 'admin' ise, admin panelini göster.
        return const AdminApp();
      },
    );
  }
}
