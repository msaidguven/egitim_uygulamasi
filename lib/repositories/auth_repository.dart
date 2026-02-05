import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  // Sınıf listesini getirir (Kayıt ekranı için)
  Future<List<Map<String, dynamic>>> getGrades() async {
    final response = await _client
        .from('grades')
        .select('id, name')
        .order('order_no', ascending: true);
    return (response as List).map((grade) => {'id': grade['id'], 'name': grade['name']}).toList();
  }

  // Google ile Giriş Yap
  Future<AuthResponse> signInWithGoogle() async {
    // NOT: Mobil uygulamalarda Google Sign-In için:
    // 1. Android: google-services.json dosyası android/app/ altına konulmalı
    // 2. iOS: GoogleService-Info.plist dosyası ios/Runner/ altına konulmalı
    // 3. Firebase Console'da Authentication > Sign-in method > Google aktif olmalı
    
    try {
      // Google Sign-In instance'ını al
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      // Önceki oturumu temizle (önemli!)
      await googleSignIn.signOut();

      // Google Sign-In başlat
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        throw const AuthException('Giriş işlemi iptal edildi.');
      }

      // Authentication bilgilerini al
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw const AuthException('Google ID Token alınamadı.');
      }

      // Supabase ile giriş yap
      return _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } on PlatformException catch (e) {
      // Platform hataları (Android/iOS özel hataları)
      throw AuthException('Platform hatası: ${e.message}');
    } catch (e) {
      throw AuthException('Google girişi başarısız: $e');
    }
  }

  // Giriş yap
  Future<AuthResponse> signIn({required String email, required String password}) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  // Kayıt ol
  Future<AuthResponse> signUp({required String email, required String password}) async {
    return await _client.auth.signUp(email: email, password: password);
  }

  // Profil bilgilerini kaydet
  Future<void> createProfile({
    required String userId,
    required String fullName,
    required String username,
    int? gradeId,
  }) async {
    await _client.from('profiles').insert({
      'id': userId,
      'full_name': fullName,
      'username': username,
      'grade_id': gradeId,
    });
  }

  // Google kullanıcısı için profil yoksa oluşturur
  Future<void> maybeCreateProfileFromGoogle(User user) async {
    try {
      // 1. Profil var mı kontrol et
      final existingProfile = await _client
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      if (existingProfile != null) {
        // Profil zaten var, işlem yapma
        return;
      }

      // 2. Profil yoksa oluştur
      final fullName = user.userMetadata?['full_name'] ?? 'Google User';
      final email = user.email ?? '';
      String username = email.split('@').first;
      
      // Username çakışmasını önlemek için rastgele bir ek (opsiyonel basit çözüm)
      // Şimdilik sadece email prefix kullanıyoruz, UNIQUE constraint hatası olursa 
      // ileride timestamp eklenebilir.
      
      await createProfile(
        userId: user.id,
        fullName: fullName,
        username: username,
        gradeId: null, // Sınıf seçilmediği için null
      );
    } catch (e) {
      // Profil oluşturma hatası kritik bir hata mı? 
      // Kullanıcının login olmasını engellemeli miyiz? 
      // Hata fırlatarak login akışını durdurabiliriz veya loglayıp geçebiliriz.
      // Şimdilik hatayı fırlatıp kullanıcıya gösterelim.
      throw AuthException('Profil oluşturulurken hata: $e');
    }
  }

  // Şifre sıfırlama e-postası gönder
  Future<void> sendPasswordResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  // Şifre güncelle
  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  // Çıkış yap
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
