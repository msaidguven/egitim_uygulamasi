// lib/viewmodels/profile_viewmodel.dart

import 'package:egitim_uygulamasi/main.dart';
import 'package:egitim_uygulamasi/models/profile_model.dart';
import 'package:flutter/material.dart';

class ProfileViewModel extends ChangeNotifier {
  bool _isLoading = false;
  Profile? _profile;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  Profile? get profile => _profile;
  String? get errorMessage => _errorMessage;

  Future<void> fetchProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userId = supabase.auth.currentUser!.id;
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      _profile = Profile.fromMap(data);
    } catch (e) {
      _errorMessage = "Profil bilgileri yüklenirken bir hata oluştu: $e";
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Kullanıcının 'admin' rolüne sahip olup olmadığını kontrol eder.
  /// Kullanıcı oturumu yoksa veya rol bilgisi alınamazsa `false` döner.
  Future<bool> isAdmin() async {
    try {
      if (supabase.auth.currentUser == null) return false;
      final response = await supabase
          .from('profiles')
          .select('role')
          .eq('id', supabase.auth.currentUser!.id)
          .single();
      final role = response['role'] as String?;
      return role == 'admin';
    } catch (e) {
      // Hata durumunda loglama yapılabilir.
      debugPrint('Admin kontrolünde hata: $e');
      return false; // Hata durumunda varsayılan olarak false döndür.
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userId = supabase.auth.currentUser!.id;
      await supabase.from('profiles').update(data).eq('id', userId);

      // Güncelleme sonrası en son veriyi çekmek için profili yeniden yükle.
      await fetchProfile();
      return true;
    } catch (e) {
      _errorMessage = "Profil güncellenirken bir hata oluştu: $e";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await supabase.auth.signOut();
    } catch (e) {
      _errorMessage = "Çıkış yapılırken bir hata oluştu: $e";
    }

    _isLoading = false;
    // Çıkış yapıldıktan sonra dinleyicileri haberdar etmeye gerek yok,
    // çünkü ekran kapatılacak.
  }
}
