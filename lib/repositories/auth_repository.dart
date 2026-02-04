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

  static bool _isGoogleSignInInitialized = false;

  // Google ile Giriş Yap
  Future<AuthResponse> signInWithGoogle() async {
    // DİKKAT: Buraya Google Cloud Console'dan aldığın 'Web Client ID'yi yapıştırmalısın.
    // Android Client ID değil, WEB Client ID olmalı.
    const webClientId = '910328493383-2om5bcoi1m645ukovjco5joqpjj74gh0.apps.googleusercontent.com';

    if (!_isGoogleSignInInitialized) {
      await GoogleSignIn.instance.initialize(
        serverClientId: webClientId,
      );
      _isGoogleSignInInitialized = true;
    }

    // Web'de signIn(), mobilde authenticate() kullanilir
    GoogleSignInAccount? googleUser;
    try {
      // Once signIn() dene (web uyumlulugu)
      googleUser = await GoogleSignIn.instance.signIn();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthException('Giriş işlemi iptal edildi.');
      } else {
        throw AuthException('Google girişi başarısız: (${e.code}) ${e.description ?? ""}');
      }
    } catch (e) {
      throw AuthException('Beklenmedik bir hata oluştu: $e');
    }
    
    if (googleUser == null) {
      throw const AuthException('Google kullanıcı bilgisi alınamadı.');
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw const AuthException('Google ID Token alınamadı.');
    }

    // Google Sign In v7: accessToken authentication içinde geliyor artık
    final accessToken = googleAuth.accessToken;

    if (accessToken == null) {
      throw const AuthException('Google Access Token alınamadı.');
    }

    return _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
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
