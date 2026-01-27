// lib/screens/reset_password_screen.dart

import 'package:egitim_uygulamasi/providers.dart'; // Provider'lar buradan gelecek
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSuccess = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (_formKey.currentState!.validate()) {
      // ViewModel'e erişim
      final viewModel = ref.read(authViewModelProvider);
      
      final success = await viewModel.updatePassword(_passwordController.text.trim());
      if (success && mounted) {
        setState(() {
          _isSuccess = true;
        });
      } else if (mounted) {
        final errorMessage = viewModel.errorMessage ?? 'Bir hata oluştu.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final authViewModel = ref.watch(authViewModelProvider);

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        title: const Text('Yeni Şifre Belirle'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
      ),
      body: _isSuccess
          ? _buildSuccessBody(isDarkMode)
          : _buildFormBody(isDarkMode, authViewModel.isLoading),
    );
  }

  Widget _buildFormBody(bool isDarkMode, bool isLoading) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yeni Şifre Belirleyin',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 32,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Güvenli bir şifre oluşturun',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextFormField(
                      controller: _passwordController,
                      style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Yeni Şifre',
                        labelStyle: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600], fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        prefixIcon: Icon(Icons.lock_outline, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.info_outline_rounded, color: isDarkMode ? Colors.grey[500] : Colors.grey[500], size: 20),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Şifreniz en az 6 karakter olmalıdır', style: TextStyle(fontWeight: FontWeight.w500)),
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ),
                      obscureText: true,
                      validator: (value) => value!.length < 6 ? 'Şifre en az 6 karakter olmalı' : null,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextFormField(
                      controller: _confirmPasswordController,
                      style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Yeni Şifre (Tekrar)',
                        labelStyle: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600], fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        prefixIcon: Icon(Icons.lock_reset_outlined, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Şifreler eşleşmiyor';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 32),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Güvenli Şifre İpuçları',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white : Colors.black),
                        ),
                        const SizedBox(height: 8),
                        _buildSecurityTip('En az 6 karakter', Icons.check_circle_outline, isDarkMode),
                        _buildSecurityTip('Büyük ve küçük harf', Icons.check_circle_outline, isDarkMode),
                        _buildSecurityTip('Rakam ve sembol kullanın', Icons.check_circle_outline, isDarkMode),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _updatePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      child: isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Şifreyi Güncelle'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityTip(String text, IconData icon, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isDarkMode ? Colors.green[400] : Colors.green[600]),
          const SizedBox(width: 10),
          Text(text, style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.grey[400] : Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildSuccessBody(bool isDarkMode) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green.withOpacity(0.3), width: 2),
                ),
                child: const Icon(Icons.check_rounded, color: Colors.green, size: 50),
              ),
              const SizedBox(height: 32),
              Text(
                'Şifreniz Başarıyla Güncellendi!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 24, color: isDarkMode ? Colors.white : Colors.black),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Artık yeni şifrenizle giriş yapabilirsiniz.',
                style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    await ref.read(authViewModelProvider).signOut(ref);
                    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Giriş Ekranına Dön'),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () async {
                    await ref.read(authViewModelProvider).signOut(ref);
                    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Hemen Giriş Yap'),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.blue.withOpacity(0.1) : Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDarkMode ? Colors.blue.withOpacity(0.3) : Colors.blue.withOpacity(0.2), width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Güvenliğiniz için lütfen şifrenizi kimseyle paylaşmayın.',
                        style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.blue[200] : Colors.blue[700], fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
