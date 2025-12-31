// lib/admin/admin_auth_gate.dart

import 'dart:async';
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
  // Oturum durumunu dinlemek için StreamSubscription
  late final StreamSubscription<AuthState> _authSubscription;
  // Kullanıcı rolünü ve yüklenme durumunu tutmak için Future
  Future<String?>? _userRoleFuture;

  @override
  void initState() {
    super.initState();
    debugPrint('AdminAuthGate: initState called');

    // Oturum durumundaki değişiklikleri dinle
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      // Oturum değiştiğinde (giriş/çıkış), rolü yeniden kontrol etmek için Future'ı sıfırla ve UI'ı güncelle
      if (mounted) {
        // Future'ı yeniden oluşturarak FutureBuilder'ın tekrar çalışmasını sağlıyoruz.
        final user = data.session?.user;
        _userRoleFuture = user != null
            ? _getUserRole(user.id)
            : Future.value(null);
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  Future<String?> _getUserRole(String userId) async {
    debugPrint('AdminAuthGate: _getUserRole called for userId: $userId');
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();
      debugPrint('AdminAuthGate: User role fetched: ${response['role']}');
      return response['role'] as String?;
    } catch (e) {
      // Hata durumunda null döndürerek FutureBuilder'ın hata yoluna düşmesini sağlarız.
      debugPrint('Kullanıcı rolü alınırken hata: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _userRoleFuture,
      builder: (context, snapshot) {
        // Rol bilgisi yüklenirken bekleme göstergesi.
        if (snapshot.connectionState == ConnectionState.waiting) {
          debugPrint('AdminAuthGate: FutureBuilder waiting for role');
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Kullanıcı giriş yapmamışsa (rol null ise) veya rol 'admin' değilse.
        if (snapshot.data == null) {
          // Kullanıcı giriş yapmamış, giriş ekranını göster.
          debugPrint('AdminAuthGate: Role is null, showing LoginScreen');
          return Scaffold(
            appBar: AppBar(title: const Text('Admin Girişi')),
            body: const LoginScreen(shouldPopOnSuccess: false),
          );
        } else if (snapshot.hasError || snapshot.data != 'admin') {
          // Hata varsa veya rol admin değilse, erişim reddedildi ekranı.
          debugPrint(
            'AdminAuthGate: FutureBuilder has error or role is not admin. Error: ${snapshot.error}, Role: ${snapshot.data}',
          );
          return Scaffold(
            appBar: AppBar(title: const Text('Hata')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock, size: 60, color: Colors.red),
                    const SizedBox(height: 16), // Added const
                    const Text(
                      'Erişim Reddedildi',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      // Changed to Text to allow dynamic content if needed, but keeping it const for now.
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
        debugPrint('AdminAuthGate: User role is admin, showing AdminApp');
        return const AdminApp();
      },
    );
  }
}
