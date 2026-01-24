// lib/viewmodels/profile_viewmodel.dart

import 'package:egitim_uygulamasi/main.dart';
import 'package:egitim_uygulamasi/models/profile_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Riverpod import'u

final profileViewModelProvider = ChangeNotifierProvider((ref) => ProfileViewModel());

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
    // UI'ın hemen tepki vermesi için notifyListeners'ı başa alıyoruz.
    notifyListeners();

    try {
      final user = supabase.auth.currentUser;

      // 1. ADIM: Kullanıcı oturumu yoksa, profili temizle ve işlemi bitir.
      // Bu, çıkış yapıldığında eski verilerin kalmasını engeller.
      if (user == null) {
        _profile = null;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Kullanıcı oturumu var, veriyi çek.
      const query = '''
        *,
        grades ( id, name ),
        cities ( id, name ),
        districts ( id, name )
      ''';

      final data = await supabase
          .from('profiles')
          .select(query)
          .eq('id', user.id)
          .single();
          
      _profile = Profile.fromMap(data);
      _errorMessage = null; // Başarılı olunca eski hataları temizle.

    } catch (e) {
      _errorMessage = "Profil bilgileri yüklenirken bir hata oluştu: $e";
      // 2. ADIM: Veri çekme sırasında bir hata olursa, profili temizle.
      // Bu, tutarsız veya eksik veri gösterimini engeller.
      _profile = null; 
      debugPrint('Profil Hatası: $_errorMessage');
    }

    // 3. ADIM: Her durumda işlemin bittiğini ve UI'ın son durumu yansıtması gerektiğini bildir.
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> isAdmin() async {
    try {
      if (supabase.auth.currentUser == null) return false;
      if (_profile == null) await fetchProfile();
      return _profile?.role == 'admin';
    } catch (e) {
      debugPrint('Admin kontrolünde hata: $e');
      return false;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userId = supabase.auth.currentUser!.id;
      await supabase.from('profiles').update(data).eq('id', userId);
      // Güncelleme sonrası veriyi tazelemek için fetchProfile'i tekrar çağır.
      await fetchProfile();
      return true;
    } catch (e) {
      _errorMessage = "Profil güncellenirken bir hata oluştu: $e";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
