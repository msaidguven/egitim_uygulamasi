// lib/screens/home_screen.dart

import 'package:egitim_uygulamasi/viewmodels/profile_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProfileViewModel _profileViewModel = ProfileViewModel();
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _profileViewModel.addListener(() {
      if (mounted) setState(() {});
    });

    // Eğer kullanıcı giriş yapmışsa profil bilgilerini çek
    if (_supabase.auth.currentUser != null) {
      _profileViewModel.fetchProfile();
    }
  }

  @override
  void dispose() {
    _profileViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Bildirim sayısını temsil eden örnek bir değişken
    const int notificationCount = 3;
    final bool isLoggedIn = _supabase.auth.currentUser != null;

    return Scaffold(
      appBar: AppBar(
        // AppBar'ın yüksekliğini ayarlayabiliriz
        toolbarHeight: 65,
        // Başlığı sola yaslamak için
        title: const Text('Ana Sayfa'),
        // Arka planı gradient yapmak için flexibleSpace kullanılır
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.lightBlueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 28),
            onPressed: () {
              // Arama butonu işlevi
            },
          ),
          // Bildirimler için Badge (rozet) kullanımı
          badges.Badge(
            position: badges.BadgePosition.topEnd(top: 4, end: 4),
            badgeContent: Text(
              notificationCount.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined, size: 28),
              onPressed: () {
                // Bildirimler butonu işlevi
              },
            ),
          ),
          const SizedBox(width: 8), // Sağdan biraz boşluk
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeMessage(isLoggedIn),
            const SizedBox(height: 24),
            const Text(
              'Günün Önerileri',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            // Buraya ileride önerilen dersler, videolar vb. eklenebilir.
            const Expanded(
              child: Center(
                child: Text('Yakında burada içerik önerileri olacak.'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeMessage(bool isLoggedIn) {
    if (isLoggedIn && _profileViewModel.profile != null) {
      return Text(
        'Hoş geldin, ${_profileViewModel.profile!.fullName}!',
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      );
    }
    return const Text(
      'Hoş geldin!',
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    );
  }
}
