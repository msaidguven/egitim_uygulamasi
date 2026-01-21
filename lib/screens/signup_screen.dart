// lib/screens/signup_screen.dart

import 'package:flutter/material.dart';
import 'package:egitim_uygulamasi/viewmodels/auth_viewmodel.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final AuthViewModel _viewModel = AuthViewModel();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _selectedGender;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(() {
      if (!mounted) return;

      setState(() {});

      final errorMessage = _viewModel.errorMessage;
      if (errorMessage != null) {
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
      } else if (!_viewModel.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Kayıt başarılı! Giriş ekranına yönlendiriliyorsunuz...',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _usernameController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      final username = _usernameController.text.trim();

      final isTaken = await _viewModel.isUsernameTaken(username);

      if (!mounted) return;

      if (isTaken) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Bu kullanıcı adı zaten alınmış. Lütfen farklı bir kullanıcı adı seçin.',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else {
        await _viewModel.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          fullName: _fullNameController.text.trim(),
          username: username,
          gender: _selectedGender!,
          birthDate: _selectedDate,
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
              // Geri butonu
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: isDarkMode ? Colors.white : Colors.black,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),

              const SizedBox(height: 20),

              // Başlık bölümü
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hesap Oluşturun',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 32,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Eğitim yolculuğunuza başlayın',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 16,
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

                    // Kullanıcı Adı
                    _buildTextField(
                      label: 'Kullanıcı Adı',
                      controller: _usernameController,
                      icon: Icons.alternate_email_rounded,
                      validator: (value) =>
                      value!.isEmpty ? 'Lütfen bir kullanıcı adı girin' : null,
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

                    // Cinsiyet
                    Container(
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.grey[900]
                            : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: InputDecoration(
                          labelText: 'Cinsiyet',
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
                            Icons.transgender,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        hint: Text(
                          'Seçiniz',
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                          ),
                        ),
                        dropdownColor: isDarkMode ? Colors.grey[900] : Colors.white,
                        items: const [
                          DropdownMenuItem(
                            value: 'female',
                            child: Text('Kadın'),
                          ),
                          DropdownMenuItem(
                            value: 'male',
                            child: Text('Erkek'),
                          ),

                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value;
                          });
                        },
                        validator: (value) =>
                        value == null ? 'Lütfen cinsiyet seçin' : null,
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Doğum Tarihi
                    Container(
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.grey[900]
                            : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextFormField(
                        readOnly: true,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Doğum Tarihi (İsteğe Bağlı)',
                          labelStyle: TextStyle(
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 14,
                          ),
                          hintText: _selectedDate == null
                              ? 'Tarih seçmek için dokunun'
                              : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                          hintStyle: TextStyle(
                            color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                          prefixIcon: Icon(
                            Icons.calendar_today_outlined,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                          suffixIcon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate ?? DateTime.now(),
                            firstDate: DateTime(1920),
                            lastDate: DateTime.now(),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: Theme.of(context).colorScheme.primary,
                                    onPrimary: Colors.white,
                                    surface: isDarkMode ? Colors.grey[900]! : Colors.white,
                                    onSurface: isDarkMode ? Colors.white : Colors.black,
                                  ),
                                  dialogBackgroundColor:
                                  isDarkMode ? Colors.grey[900] : Colors.white,
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null && picked != _selectedDate) {
                            setState(() {
                              _selectedDate = picked;
                            });
                          }
                        },
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
                        onPressed: _viewModel.isLoading ? null : _signUp,
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
                        child: _viewModel.isLoading
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
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.g_mobiledata,
                              size: 24,
                            ),
                            label: Text(
                              'Google ile kaydolun',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(
                                color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                                width: 1,
                              ),
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