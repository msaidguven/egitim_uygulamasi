// lib/screens/forgot_password_screen.dart

import 'package:flutter/material.dart';
import 'package:egitim_uygulamasi/viewmodels/auth_viewmodel.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final AuthViewModel _viewModel = AuthViewModel();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLinkSent = false;

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
        setState(() {
          _isLinkSent = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (_formKey.currentState!.validate()) {
      await _viewModel.sendPasswordReset(_emailController.text.trim());
    }
  }

  void _goBackToLogin() {
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        title: const Text('Şifremi Unuttum'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: _goBackToLogin,
        ),
      ),
      body: _isLinkSent
          ? _buildSuccessBody(isDarkMode)
          : _buildFormBody(isDarkMode),
    );
  }

  Widget _buildFormBody(bool isDarkMode) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık bölümü
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Şifrenizi mi unuttunuz?',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 32,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Size bir sıfırlama linki göndereceğiz',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Açıklama metni
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.blue.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
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
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Kayıtlı e-posta adresinizi girin. Size bir şifre sıfırlama linki göndereceğiz.',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.blue[200] : Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

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
                        hintText: 'ornek@email.com',
                        hintStyle: TextStyle(
                          color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) =>
                      value!.isEmpty ? 'Lütfen e-posta adresinizi girin' : null,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Gönder butonu
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _viewModel.isLoading ? null : _sendResetLink,
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
                          : const Text('Sıfırlama Linki Gönder'),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // İpucu
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.grey[900]
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDarkMode
                            ? Colors.grey[800]!
                            : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'İpucu',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildTipItem(
                          'Hesabınızda kayıtlı olan e-posta adresinizi girin.',
                          Icons.mail_outline,
                          isDarkMode,
                        ),
                        _buildTipItem(
                          'Spam klasörünüzü kontrol etmeyi unutmayın.',
                          Icons.folder_special_outlined,
                          isDarkMode,
                        ),
                        _buildTipItem(
                          'Link 24 saat içinde geçerlidir.',
                          Icons.access_time_outlined,
                          isDarkMode,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Geri dön butonu
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _goBackToLogin,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                          width: 1,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      child: const Text('Giriş Ekranına Dön'),
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

  Widget _buildTipItem(String text, IconData icon, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
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
              // Başarı ikonu
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.mark_email_read_rounded,
                  color: Colors.green,
                  size: 60,
                ),
              ),

              const SizedBox(height: 32),

              // Başarı mesajı
              Text(
                'Sıfırlama Linki Gönderildi!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              Text(
                'Şifre sıfırlama linki e-posta adresinize gönderildi.\nLütfen gelen kutunuzu kontrol edin.',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Bilgi kutusu
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode
                        ? Colors.blue.withOpacity(0.3)
                        : Colors.blue.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Önemli Hatırlatmalar',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSuccessTipItem(
                      'Spam veya junk klasörünüzü kontrol edin.',
                      Icons.folder_special_outlined,
                      isDarkMode,
                    ),
                    _buildSuccessTipItem(
                      'Link 24 saat içinde geçerlidir.',
                      Icons.access_time_outlined,
                      isDarkMode,
                    ),
                    _buildSuccessTipItem(
                      'Linke tıkladıktan sonra yeni şifrenizi belirleyin.',
                      Icons.lock_reset_outlined,
                      isDarkMode,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Giriş ekranına dön butonu
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _goBackToLogin,
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
                  child: const Text('Giriş Ekranına Dön'),
                ),
              ),

              const SizedBox(height: 16),

              // Farklı e-posta ile tekrar dene
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isLinkSent = false;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.5,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  child: const Text('Farklı E-posta ile Tekrar Dene'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessTipItem(String text, IconData icon, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: isDarkMode ? Colors.blue[300] : Colors.blue[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.blue[200] : Colors.blue[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}