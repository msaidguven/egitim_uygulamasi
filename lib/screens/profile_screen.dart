// lib/screens/profile_screen.dart

import 'package:egitim_uygulamasi/main.dart';
import 'package:egitim_uygulamasi/viewmodels/profile_viewmodel.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileViewModel _viewModel = ProfileViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(() {
      if (mounted) setState(() {});
    });
    _viewModel.fetchProfile();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    await _viewModel.signOut();
    if (mounted) {
      // Profil ekranını kapat ve ana ekrana dön.
      // Ana ekran, auth state değişikliğini dinleyerek kendini güncelleyecek.
      Navigator.of(context).pop();
    }
  }

  // Alanları düzenlemek için bir diyalog gösteren yardımcı metot
  Future<void> _editProfileField({
    required String title,
    required String dbField, // Veritabanı sütun adı (örn: 'full_name')
    required String currentValue,
  }) async {
    final controller = TextEditingController(text: currentValue);

    final newValue = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$title Alanını Düzenle'),
        content: TextFormField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: title),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(controller.text.trim());
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    // Eğer yeni bir değer girildiyse ve bu değer eskisinden farklıysa güncelleme yap
    if (newValue != null && newValue.isNotEmpty && newValue != currentValue) {
      final success = await _viewModel.updateProfile({dbField: newValue});
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil başarıyla güncellendi!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profilim')),
      body: _viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _viewModel.errorMessage != null
          ? Center(child: Text(_viewModel.errorMessage!))
          : _viewModel.profile == null || user == null
          ? const Center(child: Text('Profil bilgileri bulunamadı.'))
          : _buildProfileView(user.email!),
    );
  }

  Widget _buildProfileView(String email) {
    final profile = _viewModel.profile!;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(
              profile.fullName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: const Text('İsim Soyisim'),
            trailing: const Icon(Icons.edit, size: 20),
            onTap: () => _editProfileField(
              title: 'İsim Soyisim',
              dbField: 'full_name',
              currentValue: profile.fullName,
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.alternate_email),
            title: Text(
              profile.username,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: const Text('Kullanıcı Adı'),
            trailing: const Icon(Icons.edit, size: 20),
            onTap: () => _editProfileField(
              title: 'Kullanıcı Adı',
              dbField: 'username',
              currentValue: profile.username,
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.email),
            title: Text(email),
            subtitle: const Text('E-posta'),
          ),
          const Spacer(), // Boşlukları doldurur
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout),
              label: const Text('Çıkış Yap'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
