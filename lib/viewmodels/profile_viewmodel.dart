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
      // İlişkili tablolardan veri çekmek için sorguyu genişletiyoruz.
      // Supabase, foreign key'leri otomatik olarak tanır.
      const query = '''
        *,
        grades ( id, name ),
        cities ( id, name ),
        districts ( id, name )
      ''';

      final data = await supabase
          .from('profiles')
          .select(query)
          .eq('id', userId)
          .single();
          
      _profile = Profile.fromMap(data);

    } catch (e) {
      _errorMessage = "Profil bilgileri yüklenirken bir hata oluştu: $e";
      debugPrint('Profil Hatası: $_errorMessage');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Kullanıcının 'admin' rolüne sahip olup olmadığını kontrol eder.
  /// Kullanıcı oturumu yoksa veya rol bilgisi alınamazsa `false` döner.
  Future<bool> isAdmin() async {
    try {
      if (supabase.auth.currentUser == null) return false;
      // fetchProfile zaten rol bilgisini çektiği için _profile'ı kullanabiliriz.
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
      _profile = null; // Çıkış yapıldığında profili temizle
    } catch (e) {
      _errorMessage = "Çıkış yapılırken bir hata oluştu: $e";
    }

    _isLoading = false;
    notifyListeners();
  }
}
