// lib/screens/signup_screen.dart

import 'package:egitim_uygulamasi/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:egitim_uygulamasi/constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:egitim_uygulamasi/providers.dart';
import 'package:egitim_uygulamasi/widgets/ad_banner_widget.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int? _selectedGradeId;
  List<Map<String, dynamic>> _grades = [];

  @override
  void initState() {
    super.initState();
    // Load grades after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGrades();
    });
  }

  Future<void> _loadGrades() async {
    final grades = await ref.read(authViewModelProvider).getGrades();
    if (mounted) {
      setState(() {
        _grades = grades;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(authViewModelProvider).signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _fullNameController.text.trim(),
        gradeId: _selectedGradeId,
      );
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kayıt başarılı. Ana sayfaya yönlendiriliyorsunuz.')),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );
      } else {
        final error = ref.read(authViewModelProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Kayıt başarısız oldu.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık Bölümü (Geri butonu ve Başlık)
              Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: isDarkMode ? Colors.white : Colors.black,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  Text(
                    'Hesap Oluşturun',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Form bölümü
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // İsim Soyisim
                    _buildTextField(
                      label: 'İsim Soyisim',
                      controller: _fullNameController,
                      icon: Icons.person_outline,
                      validator: (value) => value!.isEmpty
                          ? 'Lütfen isminizi ve soyisminizi girin'
                          : null,
                    ),

                    const SizedBox(height: 20),

                    // E-posta
                    _buildTextField(
                      label: 'E-posta',
                      controller: _emailController,
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) =>
                      value!.isEmpty ? 'Lütfen e-posta girin' : null,
                    ),

                    const SizedBox(height: 20),

                    // Sınıf
                    Container(
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.grey[900]
                            : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: DropdownButtonFormField<int>(
                        initialValue: _selectedGradeId,
                        decoration: InputDecoration(
                          labelText: 'Sınıf',
                          labelStyle: TextStyle(
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                          prefixIcon: Icon(
                            Icons.school_outlined,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        hint: Text(
                          'Sınıfınızı Seçin',
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                          ),
                        ),
                        dropdownColor: isDarkMode ? Colors.grey[900] : Colors.white,
                        items: _grades.map<DropdownMenuItem<int>>((grade) {
                          return DropdownMenuItem<int>(
                            value: grade['id'] as int,
                            child: Text(grade['name'] as String),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedGradeId = value;
                          });
                        },
                        validator: (value) =>
                        value == null ? 'Lütfen sınıfınızı seçin' : null,
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Şifre
                    _buildTextField(
                      label: 'Şifre',
                      controller: _passwordController,
                      icon: Icons.lock_outline,
                      obscureText: true,
                      validator: (value) => value!.length < 6
                          ? 'Şifre en az 6 karakter olmalı'
                          : null,
                    ),

                    const SizedBox(height: 20),

                    // Şifre Onayla
                    _buildTextField(
                      label: 'Şifreyi Onayla',
                      controller: _confirmPasswordController,
                      icon: Icons.lock_reset_outlined,
                      obscureText: true,
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Şifreler eşleşmiyor';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    // Kayıt Ol butonu
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: ref.watch(authViewModelProvider).isLoading ? null : _signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: ref.watch(authViewModelProvider).isLoading
                            ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Text('Kayıt Ol'),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Zaten hesabınız var mı?
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Zaten bir hesabınız var mı?',
                          style: TextStyle(
                            fontSize: 15,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 4),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: Text(
                            'Giriş Yap',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    const AdBannerWidget(
                      margin: EdgeInsets.only(bottom: 24),
                    ),

                    // Bölücü çizgi
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'veya',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                      // Sosyal medya butonları
                      Column(
                        children: [
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton(
                              onPressed: ref.watch(authViewModelProvider).isLoading ? null : _signUpWithGoogle,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isDarkMode ? Colors.white : Colors.black87,
                                backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
                                side: BorderSide(
                                  color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Google Logosu (Network Image yerine güvenli olması için renkli G harfi veya asset varsa o kullanılır.
                                  // Asset olmadığı için şık bir 'G' harfi tasarımı yapıyoruz.)
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Image.network(
                                      'https://lh3.googleusercontent.com/COxitq8kCuVtIeQf2d4_2QwFfJ-420-9_i8D5l8vC3t2-T6_1_c8', // Google 'G' logosu URL'i
                                      height: 24,
                                      width: 24,
                                      errorBuilder: (context, error, stackTrace) => const Icon(
                                        Icons.g_mobiledata,
                                        color: Colors.blue,
                                        size: 32,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Google ile devam et',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isDarkMode ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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

  Future<void> _signUpWithGoogle() async {
    final gradeId = _selectedGradeId ?? defaultGoogleGradeId;
    final success = await ref
        .read(authViewModelProvider)
        .signInWithGoogle(gradeId: gradeId);
    if (success && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
      );
    } else if (mounted) {
      final error = ref.read(authViewModelProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Google ile kayıt başarısız oldu.')),
      );
    }
  }

  // Yardımcı metod: TextField widget'ı oluşturur
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        style: TextStyle(
          fontSize: 16,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
          prefixIcon: Icon(
            icon,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
      ),
    );
  }
}
