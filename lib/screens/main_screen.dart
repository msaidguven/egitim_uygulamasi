// lib/screens/main_screen.dart

import 'package:egitim_uygulamasi/models/profile_model.dart';
import 'package:egitim_uygulamasi/screens/home/home_screen.dart';
import 'package:egitim_uygulamasi/screens/home/models/home_models.dart';
import 'package:egitim_uygulamasi/screens/login_screen.dart';
import 'package:egitim_uygulamasi/screens/profile_screen.dart';
import 'package:egitim_uygulamasi/screens/grades_screen.dart';
import 'package:egitim_uygulamasi/screens/statistics_screen.dart';
import 'package:egitim_uygulamasi/utils/date_utils.dart';
import 'package:egitim_uygulamasi/providers.dart';
import 'package:egitim_uygulamasi/features/test/data/models/test_session.dart';
import 'package:egitim_uygulamasi/viewmodels/profile_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  late final Stream<AuthState> _authStream;

  String? _impersonatedRole;

  List<Map<String, dynamic>>? _agendaData;
  List<Map<String, dynamic>>? _nextStepsData;
  int _currentCurriculumWeek = 0;
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
        _initializeProfileAndData();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _currentCurriculumWeek = calculateCurrentAcademicWeek();
      if (Supabase.instance.client.auth.currentUser != null) {
        _initializeProfileAndData();
      }
    });
  }

  Future<void> _initializeProfileAndData() async {
    if (!mounted) return;

    // Profil verisini getir.
    await ref.read(profileViewModelProvider.notifier).fetchProfile();

    if (mounted) {
      final profile = ref.read(profileViewModelProvider).profile;
      // Eğer kullanıcı admin ise ve taklit edilen bir rol yoksa, varsayılan olarak 'student' rolünü taklit et.
      if (profile?.role == 'admin' && _impersonatedRole == null) {
        setState(() {
          _impersonatedRole = 'student';
        });
      }
      // Dashboard verilerini getir.
      _fetchDashboardData();
    }
  }

  void _onItemTapped(int index) {
    ref.read(mainScreenIndexProvider.notifier).state = index;
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
    if (!mounted) return;

    final user = Supabase.instance.client.auth.currentUser;
    final profile = ref.read(profileViewModelProvider).profile;
    if (user == null || profile?.gradeId == null) {
      setState(() {
        _agendaData = [];
        _nextStepsData = [];
      });
      return;
    }

    final newCurrentCurriculumWeek = calculateCurrentAcademicWeek();
    setState(() {
      _currentCurriculumWeek = newCurrentCurriculumWeek;
    });

    try {
      final response =
          await Supabase.instance.client.rpc(
                'get_weekly_dashboard_agenda',
                params: {
                  'p_user_id': user.id,
                  'p_grade_id': profile!.gradeId,
                  'p_curriculum_week': _currentCurriculumWeek,
                },
              )
              as List<dynamic>;

      final processedData = response.map((item) {
        final total = item['total_questions'] as int? ?? 0;
        final solved = item['solved_questions'] as int? ?? 0;
        final correct = item['correct_answers'] as int? ?? 0;
        final wrong = item['wrong_answers'] as int? ?? 0; // RPC'den geliyorsa
        // Eğer RPC wrong_answers döndürmüyorsa, solved - correct olarak hesaplayabiliriz (basit mantık)
        // Ancak RPC yapısını tam bilmediğimiz için solved - correct güvenli bir tahmin olabilir.
        final calculatedWrong = solved - correct; 
        final unsolved = total - solved;

        final progress = total > 0 ? (solved / total) * 100 : 0.0;
        final success = solved > 0 ? (correct / solved) * 100 : 0.0;

        return {
          'lesson_id': item['lesson_id'],
          'lesson_name': item['lesson_name'],
          'lesson_icon': item['lesson_icon'],
          'progress_percentage': progress,
          'success_rate': success,
          'grade_id': item['grade_id'],
          'grade_name': item['grade_name'],
          'topic_title': item['current_topic_title'],
          'curriculum_week': item['current_curriculum_week'],
          // Yeni eklenen istatistik alanları
          'total_questions': total,
          'correct_count': correct,
          'wrong_count': calculatedWrong < 0 ? 0 : calculatedWrong,
          'unsolved_count': unsolved < 0 ? 0 : unsolved,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _agendaData = processedData;
          _nextStepsData = []; // Bu bölüm şimdilik boş
        });
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Error fetching dashboard data: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veriler yüklenirken bir hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _agendaData = [];
          _nextStepsData = [];
        });
      }
    }
  }

  Future<void> _refreshHome() async {
    await _fetchDashboardData();
    // HomeScreen'deki "Yarım Kalan Testler" listesini de yenile
    ref.invalidate(unfinishedSessionsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(mainScreenIndexProvider);
    final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
    final profile = ref.watch(profileViewModelProvider).profile;
    final unfinishedAsync = ref.watch(unfinishedSessionsProvider);

    final List<Widget> pages = <Widget>[
      HomeScreen(
        onNavigate: _onItemTapped,
        profile: profile,
        onRefresh: _refreshHome,
        agendaData: _agendaData,
        nextStepsData: _nextStepsData,
        currentCurriculumWeek: _currentCurriculumWeek,
        nextStepsState: _nextStepsState,
        onToggleNextSteps: _toggleNextStepsSection,
        onExpandNextSteps: _expandNextSteps,
        impersonatedRole: _impersonatedRole,
        onRoleChanged: _handleRoleChange,
        currentRole: _getCurrentRole(profile),
        unfinishedSessions: unfinishedAsync.value ?? const <TestSession>[],
        isUnfinishedSessionsLoading: unfinishedAsync.isLoading,
      ),
      const GradesScreen(),
      const StatisticsScreen(),
      isLoggedIn ? const ProfileScreen() : const LoginPromptScreen(),
    ];

    return WillPopScope(
      onWillPop: () async {
        if (selectedIndex != 0) {
          ref.read(mainScreenIndexProvider.notifier).state = 0;
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: IndexedStack(index: selectedIndex, children: pages),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
            BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Dersler'),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'İstatistikler',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          ],
          currentIndex: selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey,
        ),
      ),
    );
  }
}
