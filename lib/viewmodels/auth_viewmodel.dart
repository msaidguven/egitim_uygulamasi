// lib/viewmodels/auth_viewmodel.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:egitim_uygulamasi/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> signIn(String email, String password) async {
    return _handleAuth(() async {
      await supabase.auth.signInWithPassword(email: email, password: password);
    });
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String username,
    required String gender,
    DateTime? birthDate,
  }) async {
    return _handleAuth(() async {
      // 1. Adım: Supabase Auth ile kullanıcıyı oluştur.
      final AuthResponse res = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      // 2. Adım: Kullanıcı başarıyla oluşturulduysa, 'profiles' tablosuna ek bilgileri kaydet.
      if (res.user != null) {
        // Supabase'de tarih formatı 'YYYY-MM-DD' olmalıdır.
        final String? birthDateString = birthDate
            ?.toIso8601String()
            .split('T')
            .first;

        await supabase.from('profiles').insert({
          'id': res.user!.id, // Auth kullanıcısının ID'si ile eşleştir
          'full_name': fullName,
          'username': username,
          'gender': gender,
          'birth_date': birthDateString,
        });
      } else {
        // Beklenmedik bir durum, kullanıcı null geldi.
        // _handleAuth bunu yakalayacaktır, ancak yine de bir istisna fırlatmak iyi bir pratiktir.
        throw const AuthException(
          'Kullanıcı oluşturulamadı. Lütfen tekrar deneyin.',
        );
      }
    });
  }

  Future<bool> sendPasswordReset(String email) async {
    return _handleAuth(() async {
      await supabase.auth.resetPasswordForEmail(email);
    });
  }

  Future<bool> updatePassword(String newPassword) async {
    return _handleAuth(() async {
      await supabase.auth.updateUser(UserAttributes(password: newPassword));
    });
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  Future<bool> _handleAuth(Future<void> Function() authFunction) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await authFunction();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } on PostgrestException catch (e) {
      _errorMessage = 'Veritabanı hatası: ${e.message}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
