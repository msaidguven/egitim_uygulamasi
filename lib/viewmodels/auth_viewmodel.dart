import 'package:egitim_uygulamasi/repositories/auth_repository.dart';
import 'package:egitim_uygulamasi/viewmodels/profile_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repository;
  
  AuthViewModel(this._repository);

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<List<Map<String, dynamic>>> getGrades() async {
    try {
      return await _repository.getGrades();
    } catch (e) {
      _errorMessage = 'Sınıflar yüklenirken bir hata oluştu.';
      notifyListeners();
      return [];
    }
  }

  Future<bool> signInWithGoogle() async {
    return _handleAuth(() async {
      final response = await _repository.signInWithGoogle();
      if (response.user != null) {
        await _repository.maybeCreateProfileFromGoogle(response.user!);
      }
    });
  }

  Future<bool> signIn(String email, String password) async {
    return _handleAuth(() async {
      await _repository.signIn(email: email, password: password);
    });
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    int? gradeId,
  }) async {
    return _handleAuth(() async {
      final AuthResponse res = await _repository.signUp(email: email, password: password);

      if (res.user != null) {
        final username = email.split('@').first;
        await _repository.createProfile(
          userId: res.user!.id,
          fullName: fullName,
          username: username,
          gradeId: gradeId,
        );
        
        // Kayıt sonrası otomatik giriş için tekrar şifre ile giriş yapmaya gerek yok,
        // Supabase signUp sonrası otomatik oturum açabilir (email confirm kapalıysa).
        // Ama emin olmak için:
        if (res.session == null) {
           await _repository.signIn(email: email, password: password);
        }
      } else {
        throw const AuthException('Kullanıcı oluşturulamadı.');
      }
    });
  }

  Future<bool> sendPasswordReset(String email) async {
    return _handleAuth(() async {
      await _repository.sendPasswordResetEmail(email);
    });
  }

  Future<bool> updatePassword(String newPassword) async {
    return _handleAuth(() async {
      await _repository.updatePassword(newPassword);
    });
  }

  Future<void> signOut(WidgetRef ref) async {
    await _repository.signOut();
    ref.invalidate(profileViewModelProvider);
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
    } catch (e) {
      _errorMessage = 'Beklenmedik bir hata: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
