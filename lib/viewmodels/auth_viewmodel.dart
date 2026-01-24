// lib/viewmodels/auth_viewmodel.dart

import 'dart:async';
import 'package:egitim_uygulamasi/viewmodels/profile_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:egitim_uygulamasi/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<List<Map<String, dynamic>>> getGrades() async {
    try {
      final response = await supabase.from('grades').select('id, name').order('order_no', ascending: true);
      return (response as List).map((grade) => {'id': grade['id'], 'name': grade['name']}).toList();
    } catch (e) {
      _errorMessage = 'Sınıflar yüklenirken bir hata oluştu.';
      notifyListeners();
      return [];
    }
  }

  Future<bool> signIn(String email, String password) async {
    return _handleAuth(() async {
      await supabase.auth.signInWithPassword(email: email, password: password);
    });
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    int? gradeId,
  }) async {
    return _handleAuth(() async {
      // 1. Adım: Supabase Auth ile kullanıcıyı oluştur.
      final AuthResponse res = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      // 2. Adım: Kullanıcı başarıyla oluşturulduysa, 'profiles' tablosuna ek bilgileri kaydet.
      if (res.user != null) {
        // Kullanıcı adı olarak e-postanın ilk bölümünü alalım (geçici çözüm)
        final username = email.split('@').first;

        await supabase.from('profiles').insert({
          'id': res.user!.id, // Auth kullanıcısının ID'si ile eşleştir
          'full_name': fullName,
          'username': username,
          'grade_id': gradeId,
        });

        // 3. Adım: Kayıt sonrası otomatik olarak oturum aç.
        await supabase.auth.signInWithPassword(email: email, password: password);

      } else {
        // Beklenmedik bir durum, kullanıcı null geldi.
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

  Future<void> signOut(WidgetRef ref) async {
    await supabase.auth.signOut();
    ref.invalidate(profileViewModelProvider);
    // Oturuma bağlı diğer provider'lar da burada invalidate edilebilir.
    // Örnek: ref.invalidate(anotherUserSpecificProvider);
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
