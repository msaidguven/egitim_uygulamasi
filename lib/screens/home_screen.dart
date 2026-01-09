// lib/screens/home_screen.dart

import 'package:egitim_uygulamasi/screens/statistics_screen.dart';
import 'package:egitim_uygulamasi/viewmodels/profile_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  final Function(int) onNavigate; // Sekme değiştirme fonksiyonu için parametre

  const HomeScreen({super.key, required this.onNavigate});

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
    final bool isLoggedIn = _supabase.auth.currentUser != null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 180.0,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildWelcomeHeader(isLoggedIn),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hızlı Erişim',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureGrid(context),
                  const SizedBox(height: 24),
                  const Text(
                    'Son Aktiviteler',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text('Yakında burada son aktiviteleriniz görünecek.'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(bool isLoggedIn) {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).primaryColor, Colors.blue.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            isLoggedIn && _profileViewModel.profile != null
                ? 'Hoş geldin,'
                : 'Eğitime Hoş Geldin!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w300,
            ),
          ),
          if (isLoggedIn && _profileViewModel.profile != null)
            Text(
              _profileViewModel.profile!.fullName ?? 'Kullanıcı',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _FeatureCard(
          title: 'Derslere Göz At',
          icon: Icons.school_outlined,
          color: Colors.orange,
          onTap: () => widget.onNavigate(1), // Dersler sekmesi (index 1)
        ),
        _FeatureCard(
          title: 'Testleri Çöz',
          icon: Icons.quiz_outlined,
          color: Colors.green,
          onTap: () => widget.onNavigate(2), // Testler sekmesi (index 2)
        ),
        _FeatureCard(
          title: 'Profilim',
          icon: Icons.person_outline,
          color: Colors.blue,
          onTap: () => widget.onNavigate(3), // Profil sekmesi (index 3)
        ),
        _FeatureCard(
          title: 'İstatistiklerim',
          icon: Icons.bar_chart_outlined,
          color: Colors.red,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const StatisticsScreen()),
            );
          },
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
