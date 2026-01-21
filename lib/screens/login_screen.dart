// lib/screens/login_screen.dart

import 'package:egitim_uygulamasi/screens/forgot_password_screen.dart';
import 'package:egitim_uygulamasi/screens/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:egitim_uygulamasi/viewmodels/auth_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  /// Giriş başarılı olduğunda sayfanın otomatik olarak kapanıp kapanmayacağını belirler.
  /// Varsayılan değer [true]'dur. AdminAuthGate gibi sayfa içinde gömülü kullanımlarda [false] yapılmalıdır.
  final bool shouldPopOnSuccess;

  const LoginScreen({super.key, this.shouldPopOnSuccess = true});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthViewModel _viewModel = AuthViewModel();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _rememberMe = false;
  bool _isLoadingCredentials = true;

  // SharedPreferences anahtarları
  static const String _rememberMeKey = 'remember_me';
  static const String _emailKey = 'saved_email';
  static const String _passwordKey = 'saved_password';

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _viewModel.addListener(() {
      if (mounted) {
        setState(() {});
      }
      if (_viewModel.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_viewModel.errorMessage!),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    });
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(_rememberMeKey) ?? false;

      if (mounted) {
        setState(() {
          _rememberMe = rememberMe;
        });
      }

      if (rememberMe) {
        final savedEmail = prefs.getString(_emailKey);
        final savedPassword = prefs.getString(_passwordKey);

        if (mounted) {
          setState(() {
            if (savedEmail != null) _emailController.text = savedEmail;
            if (savedPassword != null) _passwordController.text = savedPassword;
            _isLoadingCredentials = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingCredentials = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCredentials = false;
        });
      }
    }
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setBool(_rememberMeKey, true);
      await prefs.setString(_emailKey, _emailController.text.trim());
      await prefs.setString(_passwordKey, _passwordController.text.trim());
    } else {
      await prefs.setBool(_rememberMeKey, false);
      await prefs.remove(_emailKey);
      await prefs.remove(_passwordKey);
    }
  }

  Future<void> _clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, false);
    await prefs.remove(_emailKey);
    await prefs.remove(_passwordKey);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      final success = await _viewModel.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (success) {
        // Başarılı girişte kimlik bilgilerini kaydet
        await _saveCredentials();

        if (mounted && widget.shouldPopOnSuccess) {
          Navigator.of(context).pop();
        }
      } else {
        // Giriş başarısızsa kimlik bilgilerini temizle
        await _clearCredentials();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_isLoadingCredentials) {
      return Scaffold(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık bölümü
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hoş Geldiniz',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 32,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hesabınıza giriş yapın',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 48),

              // Form bölümü
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // E-posta alanı
                    Container(
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.grey[900]
                            : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextFormField(
                        controller: _emailController,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          labelText: 'E-posta',
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
                            Icons.email_outlined,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) =>
                        value!.isEmpty ? 'Lütfen e-posta adresinizi girin' : null,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Şifre alanı
                    Container(
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.grey[900]
                            : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextFormField(
                        controller: _passwordController,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Şifre',
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
                            Icons.lock_outline,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        obscureText: true,
                        validator: (value) =>
                        value!.isEmpty ? 'Lütfen şifrenizi girin' : null,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Beni Hatırla seçeneği
                    Row(
                      children: [
                        Transform.scale(
                          scale: 0.9,
                          child: Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              if (mounted) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              }
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            activeColor: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            if (mounted) {
                              setState(() {
                                _rememberMe = !_rememberMe;
                              });
                            }
                          },
                          child: Text(
                            'Beni hatırla',
                            style: TextStyle(
                              fontSize: 15,
                              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Şifremi unuttum buraya da koyalım
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.primary,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                          ),
                          child: Text(
                            'Şifremi unuttum',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Giriş butonu
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _viewModel.isLoading ? null : _signIn,
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
                            : const Text('Giriş Yap'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Kayıt ol
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Hesabınız yok mu?',
                    style: TextStyle(
                      fontSize: 15,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignUpScreen(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Text(
                      'Kayıt Olun',
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

              // Google ile devam et butonu (yakında)
              Column(
                children: [
                  // Buton
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Yakında mesajı göster
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Google ile giriş özelliği yakında eklenecek!',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.g_mobiledata,
                        color: isDarkMode ? Colors.white : Colors.black,
                        size: 24,
                      ),
                      label: Text(
                        'Google ile devam et',
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

                  // Bilgilendirme metni
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDarkMode
                            ? Colors.blue.withOpacity(0.3)
                            : Colors.blue.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Google ile giriş özelliği yakında eklenecektir',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDarkMode
                                  ? Colors.blue[200]
                                  : Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}