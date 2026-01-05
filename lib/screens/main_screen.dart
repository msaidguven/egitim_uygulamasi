// lib/screens/main_screen.dart

import 'package:egitim_uygulamasi/screens/home_screen.dart';
import 'package:egitim_uygulamasi/screens/login_screen.dart';
import 'package:egitim_uygulamasi/screens/profile_screen.dart';
import 'package:egitim_uygulamasi/screens/grades_screen.dart';
import 'package:egitim_uygulamasi/screens/tests_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Misafir kullanıcılar için Profil sekmesinde gösterilecek ekran.
class LoginPromptScreen extends StatelessWidget {
  const LoginPromptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Profilinizi görüntülemek ve kişisel ayarlarınızı yönetmek için lütfen giriş yapın.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text('Giriş Yap / Kayıt Ol'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final Stream<AuthState> _authStream;

  @override
  void initState() {
    super.initState();
    _authStream = Supabase.instance.client.auth.onAuthStateChange;
    _authStream.listen((data) {
      if (mounted) setState(() {});
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = Supabase.instance.client.auth.currentUser != null;

    // Her sekme için gösterilecek sayfaların listesi
    // DİKKAT: HomeScreen'e _onItemTapped fonksiyonunu geçiyoruz.
    final List<Widget> _pages = <Widget>[
      HomeScreen(onNavigate: _onItemTapped), // Ana Sayfa
      const GradesScreen(), // Dersler
      const TestsScreen(), // Testler
      isLoggedIn ? const ProfileScreen() : const LoginPromptScreen(), // Profil
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Dersler'),
          BottomNavigationBarItem(icon: Icon(Icons.quiz), label: 'Testler'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
