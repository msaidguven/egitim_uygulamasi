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

  Future<bool> signUp(String email, String password) async {
    return _handleAuth(() async {
      await supabase.auth.signUp(email: email, password: password);
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
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
