// lib/screens/reset_password_screen.dart

import 'package:flutter/material.dart';
import 'package:egitim_uygulamasi/viewmodels/auth_viewmodel.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final AuthViewModel _viewModel = AuthViewModel();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(() {
      if (!mounted) return;
      setState(() {});

      final errorMessage = _viewModel.errorMessage;
      if (errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      } else if (!_viewModel.isLoading && !_isSuccess) {
        _isSuccess = true;
      }
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (_formKey.currentState!.validate()) {
      await _viewModel.updatePassword(_passwordController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Şifre Belirle')),
      body: _isSuccess ? _buildSuccessBody() : _buildFormBody(),
    );
  }

  Widget _buildFormBody() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Yeni Şifre'),
              obscureText: true,
              validator: (value) =>
                  value!.length < 6 ? 'Şifre en az 6 karakter olmalı' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Yeni Şifre (Tekrar)',
              ),
              obscureText: true,
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'Şifreler eşleşmiyor';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            _viewModel.isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _updatePassword,
                    child: const Text('Şifreyi Güncelle'),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessBody() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 80,
            ),
            const SizedBox(height: 20),
            const Text(
              'Şifreniz başarıyla güncellendi!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // Önce çıkış yap, sonra AuthGate'in yönlendirmesini bekle.
                await _viewModel.signOut();
                // AuthGate yönlendirme yapmazsa diye bir güvenlik önlemi.
                if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
              },
              child: const Text('Giriş Ekranına Dön'),
            ),
          ],
        ),
      ),
    );
  }
}
