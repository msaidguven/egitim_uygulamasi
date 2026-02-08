import 'package:egitim_uygulamasi/constants.dart';
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
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId: '910328493383-2om5bcoi1m645ukovjco5joqpjj74gh0.apps.googleusercontent.com',
      );

      await googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        throw const AuthException('Giriş işlemi iptal edildi.');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw const AuthException('Google ID Token alınamadı.');
      }

      return _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
    } on PlatformException catch (e) {
      throw AuthException('Google Sign-In hatası: ${e.message}');
    } catch (e) {
      throw AuthException('Google girişi başarısız: $e');
    }
  }

  Future<AuthResponse> signIn({required String email, required String password}) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp({required String email, required String password}) async {
    return await _client.auth.signUp(email: email, password: password);
  }

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

  Future<void> maybeCreateProfileFromGoogle(User user) async {
    return maybeCreateProfileFromGoogleWithGrade(user, null);
  }

  Future<void> maybeCreateProfileFromGoogleWithGrade(
    User user,
    int? gradeId,
  ) async {
    try {
      final existingProfile = await _client
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      if (existingProfile != null) return;

      final fullName = user.userMetadata?['full_name'] ?? 'Google User';
      final email = user.email ?? '';
      String username = email.split('@').first;
      
      await createProfile(
        userId: user.id,
        fullName: fullName,
        username: username,
        gradeId: gradeId,
      );
    } catch (e) {
      throw AuthException('Profil oluşturulurken hata: $e');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: authRedirectUrl,
    );
  }

  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
