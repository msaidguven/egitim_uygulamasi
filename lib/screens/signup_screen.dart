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
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      } else if (!_viewModel.isLoading) {
        // Kayıt başarılıysa, kullanıcıya bilgi verip giriş ekranına yönlendir.
        // Supabase, e-posta onayı gerektiriyorsa, kullanıcı ana ekrana hemen yönlendirilmez.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Kayıt başarılı! Giriş ekranına yönlendiriliyorsunuz...',
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Kısa bir beklemenin ardından giriş ekranına geri dön.
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

      // Kullanıcı adının alınıp alınmadığını kontrol et
      final isTaken = await _viewModel.isUsernameTaken(username);

      if (!mounted) return;

      if (isTaken) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Bu kullanıcı adı zaten alınmış. Lütfen farklı bir kullanıcı adı seçin.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        // Kullanıcı adı müsaitse kayıt işlemine devam et
        await _viewModel.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          fullName: _fullNameController.text.trim(),
          username: username,
          gender: _selectedGender!, // Validator null olmamasını garantiliyor
          birthDate: _selectedDate,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kayıt Ol')),
      body: SingleChildScrollView(
        // Alanlar ekrana sığmazsa kaydırma özelliği ekler
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(labelText: 'İsim Soyisim'),
                  validator: (value) => value!.isEmpty
                      ? 'Lütfen isminizi ve soyisminizi girin'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Kullanıcı Adı'),
                  validator: (value) =>
                      value!.isEmpty ? 'Lütfen bir kullanıcı adı girin' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'E-posta'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) =>
                      value!.isEmpty ? 'Lütfen e-posta girin' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: const InputDecoration(labelText: 'Cinsiyet'),
                  hint: const Text('Seçiniz'),
                  // Veritabanı şemasındaki CHECK kısıtlamasına ('Kadın', 'Erkek', 'Diğer') uyumlu hale getirildi.
                  // DB şeması güncellendi: CHECK ('male', 'female', 'other')
                  // Hatalı .map() çağrısı kaldırılarak liste doğrudan kullanıldı.
                  items: const [
                    DropdownMenuItem(
                      value: 'female', // DB'ye 'female' gidecek
                      child: Text('Kadın'),
                    ),
                    DropdownMenuItem(
                      value: 'male',
                      child: Text('Erkek'),
                    ), // DB'ye 'male' gidecek
                    DropdownMenuItem(
                      value: 'other', // DB'ye 'other' gidecek
                      child: Text('Belirtmek İstemiyorum'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Lütfen cinsiyet seçin' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Doğum Tarihi (İsteğe Bağlı)',
                    hintText: _selectedDate == null
                        ? 'Tarih seçmek için dokunun'
                        : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime(1920),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null && picked != _selectedDate) {
                      setState(() {
                        _selectedDate = picked;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Şifre'),
                  obscureText: true,
                  validator: (value) => value!.length < 6
                      ? 'Şifre en az 6 karakter olmalı'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Şifreyi Onayla',
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
                        onPressed: _signUp,
                        child: const Text('Kayıt Ol'),
                      ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Zaten bir hesabın var mı?'),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Giriş Yap'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
