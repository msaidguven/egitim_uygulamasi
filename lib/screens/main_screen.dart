// lib/screens/main_screen.dart

import 'package:egitim_uygulamasi/models/profile_model.dart';
import 'package:egitim_uygulamasi/screens/home_screen.dart';
import 'package:egitim_uygulamasi/screens/login_screen.dart';
import 'package:egitim_uygulamasi/screens/profile_screen.dart';
import 'package:egitim_uygulamasi/screens/grades_screen.dart';
import 'package:egitim_uygulamasi/screens/statistics_screen.dart';
import 'package:egitim_uygulamasi/screens/tests_screen.dart';
import 'package:egitim_uygulamasi/utils/date_utils.dart';
import 'package:egitim_uygulamasi/viewmodels/profile_viewmodel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// NextStepsDisplayState enum'ı buradan kaldırıldı ve home_screen.dart'a taşındı.

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

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;
  late final Stream<AuthState> _authStream;

  String? _impersonatedRole;

  List<Map<String, dynamic>>? _agendaData;
  List<Map<String, dynamic>>? _nextStepsData;
  int _currentWeek = 0;
  NextStepsDisplayState _nextStepsState = NextStepsDisplayState.hidden;

  String? _getCurrentRole(Profile? profile) {
    if (profile?.role == 'admin' && _impersonatedRole != null) {
      return _impersonatedRole;
    }
    return profile?.role;
  }

  @override
  void initState() {
    super.initState();
    _authStream = Supabase.instance.client.auth.onAuthStateChange;
    _authStream.listen((data) {
      if (mounted) {
        setState(() => _impersonatedRole = null);
        ref.read(profileViewModelProvider.notifier).fetchProfile().then((_) {
          _fetchDashboardData();
        });
        setState(() {});
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _currentWeek = calculateCurrentAcademicWeek();
      if (Supabase.instance.client.auth.currentUser != null) {
        final profile = ref.read(profileViewModelProvider).profile;
        if (profile == null) {
          ref.read(profileViewModelProvider.notifier).fetchProfile().then((_) {
            _fetchDashboardData();
          });
        } else {
          _fetchDashboardData();
        }
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _toggleNextStepsSection() {
    setState(() {
      if (_nextStepsState == NextStepsDisplayState.hidden) {
        _nextStepsState = NextStepsDisplayState.collapsed;
      } else {
        _nextStepsState = NextStepsDisplayState.hidden;
      }
    });
  }

  void _expandNextSteps() {
    setState(() {
      _nextStepsState = NextStepsDisplayState.expanded;
    });
  }

  void _handleRoleChange(String? role) {
    setState(() {
      _impersonatedRole = role;
      _agendaData = null;
      _nextStepsData = null;
    });
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    final newCurrentWeek = calculateCurrentAcademicWeek();
    if (mounted) {
      setState(() {
        _currentWeek = newCurrentWeek;
      });
    }

    final user = Supabase.instance.client.auth.currentUser;
    final profile = ref.read(profileViewModelProvider).profile;
    
    final currentRole = _getCurrentRole(profile);
    if (user == null || profile == null || profile.gradeId == null || currentRole != 'student') {
      if(mounted) {
        setState(() {
          _agendaData = [];
          _nextStepsData = [];
        });
      }
      return;
    }

    try {
      debugPrint("[Network] Fetching dashboard data for role '$currentRole' and week $newCurrentWeek...");
      final agendaResponseFuture = Supabase.instance.client.rpc(
        'get_current_week_agenda',
        params: {'p_user_id': user.id, 'p_grade_id': profile.gradeId, 'p_week_no': newCurrentWeek},
      );

      final nextStepsResponseFuture = Supabase.instance.client.rpc(
        'get_all_next_steps_for_user',
        params: {'p_user_id': user.id, 'p_grade_id': profile.gradeId, 'p_exclude_week_no': newCurrentWeek, 'p_current_academic_week': newCurrentWeek},
      );

      final responses = await Future.wait([agendaResponseFuture, nextStepsResponseFuture]);

      final newAgendaData = List<Map<String, dynamic>>.from(responses[0] as List);
      final newNextStepsData = List<Map<String, dynamic>>.from(responses[1] as List);

      debugPrint("[Network] Network fetch successful. Updating UI.");

      if (mounted) {
        setState(() {
          _agendaData = newAgendaData;
          _nextStepsData = newNextStepsData;
        });
      }
    } catch (e) {
      debugPrint("[Network] Network fetch FAILED. Error: $e");
      if (mounted) {
        setState(() {
          _agendaData = [];
          _nextStepsData = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
    final profile = ref.watch(profileViewModelProvider).profile;

    final List<Widget> pages = <Widget>[
      HomeScreen(
        onNavigate: _onItemTapped,
        profile: profile,
        onRefresh: _fetchDashboardData,
        agendaData: _agendaData,
        nextStepsData: _nextStepsData,
        currentWeek: _currentWeek,
        nextStepsState: _nextStepsState,
        onToggleNextSteps: _toggleNextStepsSection,
        onExpandNextSteps: _expandNextSteps,
        impersonatedRole: _impersonatedRole,
        onRoleChanged: _handleRoleChange,
        currentRole: _getCurrentRole(profile),
      ),
      const GradesScreen(),
      //const TestsScreen(),
      isLoggedIn ? const StatisticsScreen() : const LoginPromptScreen(),
      isLoggedIn ? const ProfileScreen() : const LoginPromptScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Dersler'),
          //BottomNavigationBarItem(icon: Icon(Icons.quiz), label: 'Testler'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'İstatistikler'),
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
