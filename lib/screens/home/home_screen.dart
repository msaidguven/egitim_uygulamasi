// lib/screens/home_screen.dart

import 'package:egitim_uygulamasi/features/test/data/models/test_question.dart';
import 'package:egitim_uygulamasi/features/test/data/models/test_session.dart';
import 'package:egitim_uygulamasi/features/test/presentation/views/questions_screen.dart';
import 'package:egitim_uygulamasi/models/profile_model.dart';
import 'package:egitim_uygulamasi/providers.dart';
import 'package:egitim_uygulamasi/screens/home/models/home_models.dart';
import 'package:egitim_uygulamasi/screens/home/widgets/common_widgets.dart';
import 'package:egitim_uygulamasi/screens/home/widgets/guest_content_view.dart';
import 'package:egitim_uygulamasi/screens/home/widgets/home_header.dart';
import 'package:egitim_uygulamasi/screens/home/widgets/srs_alert_widget.dart';
import 'package:egitim_uygulamasi/screens/home/widgets/streak_card_widget.dart';
import 'package:egitim_uygulamasi/screens/home/widgets/student_content_view.dart';
import 'package:egitim_uygulamasi/screens/home/widgets/teacher_content_view.dart';
import 'package:egitim_uygulamasi/screens/home/widgets/unfinished_tests_section.dart';
import 'package:egitim_uygulamasi/screens/home/widgets/weekly_agenda_overview_card.dart';

import 'package:egitim_uygulamasi/screens/home/widgets/week_info_card.dart';
import 'package:egitim_uygulamasi/screens/outcomes/outcomes_screen.dart';
import 'package:egitim_uygulamasi/viewmodels/grade_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final Function(int) onNavigate;
  final Profile? profile;
  final Future<void> Function() onRefresh;
  final List<Map<String, dynamic>>? agendaData;
  final List<Map<String, dynamic>>? nextStepsData;
  final int currentCurriculumWeek;
  final NextStepsDisplayState nextStepsState;
  final VoidCallback onToggleNextSteps;
  final VoidCallback onExpandNextSteps;
  final String? impersonatedRole;
  final ValueChanged<String?> onRoleChanged;
  final String? currentRole;
  final List<TestSession>? unfinishedSessions;
  final bool isUnfinishedSessionsLoading;
  final Map<String, dynamic>? streakStats;

  const HomeScreen({
    super.key,
    required this.onNavigate,
    required this.profile,
    required this.onRefresh,
    this.agendaData,
    this.nextStepsData,
    this.currentCurriculumWeek = 0,
    required this.nextStepsState,
    required this.onToggleNextSteps,
    required this.onExpandNextSteps,
    this.impersonatedRole,
    required this.onRoleChanged,
    this.currentRole,
    this.unfinishedSessions,
    this.isUnfinishedSessionsLoading = false,
    this.streakStats,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GradeViewModel _gradeViewModel = GradeViewModel();
  bool _isStartingSrsTest = false;
  bool _hasTrackedHomeOpen = false;
  String? _dailyMissionCompletedTrackedDay;

  @override
  void initState() {
    super.initState();
    if (widget.profile == null) {
      _gradeViewModel.addListener(() {
        if (mounted) setState(() {});
      });
      _gradeViewModel.fetchGrades();
    }
  }

  @override
  void dispose() {
    _gradeViewModel.dispose();
    super.dispose();
  }

  Future<void> _startSrsTest() async {
    if (_isStartingSrsTest) return;

    setState(() {
      _isStartingSrsTest = true;
    });

    try {
      final userId = ref.read(userIdProvider);
      final clientId = await ref.read(clientIdProvider.future);
      if (!mounted) return;
      final viewModel = ref.read(testViewModelProvider.notifier);

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Giriş yapmanız gerekiyor.')),
        );
        return;
      }

      // SRS test session oluştur
      final sessionId = await ref
          .read(testRepositoryProvider)
          .startSrsTestSession(userId: userId, clientId: clientId);

      // ViewModel'de SRS testi başlat
      await viewModel.startSrsTest(
        sessionId: sessionId,
        userId: userId,
        clientId: clientId,
      );

      if (mounted) {
        // Test ekranına git
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuestionsScreen(
              unitId: 0, // SRS testinde unitId yok
              sessionId: sessionId,
              testMode: TestMode.srs,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tekrar testi başlatılırken hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isStartingSrsTest = false;
        });
      }
    }
  }

  void _trackEvent(String event, Map<String, dynamic> params) {
    ref.read(analyticsServiceProvider).track(event, {
      'screen': 'home',
      'role': widget.currentRole,
      ...params,
    });
  }

  int _questionsSolvedToday() {
    return widget.streakStats?['today_solved'] as int? ?? 0;
  }

  bool _topicOpenedToday() {
    final agenda = widget.agendaData;
    if (agenda == null || agenda.isEmpty) return false;
    return agenda.any(
      (item) => ((item['progress_percentage'] ?? 0) as num) > 0,
    );
  }

  bool _miniQuizCompletedToday() {
    final agenda = widget.agendaData;
    if (agenda == null || agenda.isEmpty) return false;
    return agenda.any((item) {
      final solved =
          ((item['correct_count'] ?? 0) as num).toInt() +
          ((item['wrong_count'] ?? 0) as num).toInt();
      return solved >= 5;
    });
  }

  int _completedMissionCount() {
    var done = 0;
    if (_questionsSolvedToday() >= 10) done++;
    if (_topicOpenedToday()) done++;
    if (_miniQuizCompletedToday()) done++;
    return done;
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  Map<String, dynamic>? _primaryAgendaItem() {
    final agenda = widget.agendaData;
    if (agenda == null || agenda.isEmpty) return null;

    final sorted =
        agenda.map((item) => Map<String, dynamic>.from(item)).toList()..sort((
          a,
          b,
        ) {
          final aProgress = (a['progress_percentage'] as num? ?? 0).toDouble();
          final bProgress = (b['progress_percentage'] as num? ?? 0).toDouble();
          final aUnsolved = (a['unsolved_count'] as num? ?? 0).toInt();
          final bUnsolved = (b['unsolved_count'] as num? ?? 0).toInt();
          final byUnsolved = bUnsolved.compareTo(aUnsolved);
          if (byUnsolved != 0) return byUnsolved;
          return aProgress.compareTo(bProgress);
        });

    final firstIncomplete = sorted.firstWhere(
      (item) => (item['progress_percentage'] as num? ?? 0).toDouble() < 100,
      orElse: () => sorted.first,
    );
    return firstIncomplete;
  }

  Future<void> _openOutcomesForItem(Map<String, dynamic> item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OutcomesScreen(
          lessonId: item['lesson_id'] as int? ?? 0,
          gradeId: item['grade_id'] as int? ?? 0,
          gradeName: item['grade_name'] as String? ?? '',
          lessonName: item['lesson_name'] as String? ?? 'Ders',
          initialCurriculumWeek:
              item['curriculum_week'] as int? ?? widget.currentCurriculumWeek,
        ),
      ),
    );
    widget.onRefresh();
  }

  Future<void> _handlePrimaryCtaTap() async {
    _trackEvent('primary_cta_clicked', {
      'current_week': widget.currentCurriculumWeek,
    });
    _trackEvent('daily_mission_started', {
      'completed_missions': _completedMissionCount(),
    });

    final target = _primaryAgendaItem();
    if (target == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu hafta için uygun görev bulunamadı.')),
      );
      return;
    }
    await _openOutcomesForItem(target);
  }

  @override
  Widget build(BuildContext context) {
    final bool isStudent = widget.currentRole == 'student';
    final bool isAdmin = widget.profile?.role == 'admin';
    final bool isLoggedIn = widget.profile != null;
    final srsDueCountAsync = ref.watch(srsDueCountProvider);
    final completedMissionCount = _completedMissionCount();

    if (!_hasTrackedHomeOpen) {
      _hasTrackedHomeOpen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _trackEvent('home_opened', {
          'is_logged_in': widget.profile != null,
          'current_week': widget.currentCurriculumWeek,
        });
      });
    }

    if (isStudent && completedMissionCount >= 3) {
      final today = _todayKey();
      if (_dailyMissionCompletedTrackedDay != today) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final currentToday = _todayKey();
          if (_dailyMissionCompletedTrackedDay == currentToday) return;
          _trackEvent('daily_mission_completed', {
            'completed_missions': completedMissionCount,
            'questions_solved_today': _questionsSolvedToday(),
            'topic_opened_today': _topicOpenedToday(),
            'mini_quiz_completed_today': _miniQuizCompletedToday(),
            'current_week': widget.currentCurriculumWeek,
          });
          _dailyMissionCompletedTrackedDay = currentToday;
        });
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F8FF),
      body: Stack(
        children: [
          IgnorePointer(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF7FBFF),
                    Color(0xFFEEF7FF),
                    Color(0xFFF9FCFF),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -70,
                    right: -24,
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF9ED1FF).withValues(alpha: 0.32),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 200,
                    left: -70,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFD7A8).withValues(alpha: 0.28),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -70,
                    right: -24,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFBFEFD3).withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 140,
                    right: 34,
                    child: Transform.rotate(
                      angle: 0.35,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFC864).withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 320,
                    left: 24,
                    child: Transform.rotate(
                      angle: -0.45,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6ED4FF).withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 180,
                    right: 40,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF7BD88F).withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          RefreshIndicator(
            onRefresh: widget.onRefresh,
            color: const Color(0xFF6366F1),
            backgroundColor: Colors.white,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                // 1. Header Section (Herkes)
                SliverToBoxAdapter(
                  child: HomeHeader(
                    profile: widget.profile,
                    isAdmin: isAdmin,
                    onRoleChanged: widget.onRoleChanged,
                    impersonatedRole: widget.impersonatedRole,
                  ),
                ),

                // 2. Student Mission Hero (Öğrenci)
                if (isStudent)
                  SliverToBoxAdapter(
                    child: WeeklyAgendaOverviewCard(
                      agendaData: widget.agendaData ?? const [],
                      currentWeek: widget.currentCurriculumWeek,
                      onContinueTap: _handlePrimaryCtaTap,
                    ),
                  ),

                // 3. Streak Card Widget (Sadece Üyeler/Öğrenciler)
                if (isStudent && widget.streakStats != null)
                  SliverToBoxAdapter(
                    child: StreakCardWidget(
                      streakCount:
                          widget.streakStats!['current_streak'] as int? ?? 0,
                      dailyGoal:
                          widget.streakStats!['daily_goal'] as int? ?? 40,
                      currentProgress:
                          widget.streakStats!['today_solved'] as int? ?? 0,
                    ),
                  ),

                // 4. SRS Alert Widget (Sadece giriş yapan öğrenci)
                if (isLoggedIn && isStudent)
                  SliverToBoxAdapter(
                    child: srsDueCountAsync.when(
                      data: (count) => SrsAlertWidget(
                        questionCount: count,
                        onReviewTap: _isStartingSrsTest
                            ? () {}
                            : () => _startSrsTest(),
                        showActionButton: true,
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (error, stackTrace) => const SizedBox.shrink(),
                    ),
                  ),

                // 5. Week Info Card Section (Sadece giriş yapan kullanıcılar)
                if (isLoggedIn)
                  SliverToBoxAdapter(
                    child: WeekInfoCard(
                      profile: widget.profile,
                      agendaData: widget.agendaData,
                      completedLessons: _calculateCompletedLessons(),
                    ),
                  ),

                // 5. Week Scroll Widget (Herkes) - GECICI OLARAK KAPATILDI
                // SliverToBoxAdapter(
                //   child: WeekScrollWidget(
                //     currentWeek: widget.currentCurriculumWeek,
                //     onWeekSelected: (week) {
                //       debugPrint('Selected week: $week');
                //     },
                //   ),
                // ),

                // 6. Unfinished Tests Section (Giriş yapan herkes)
                if (widget.profile != null)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverToBoxAdapter(
                      child: UnfinishedTestsSection(
                        unfinishedSessions: widget.unfinishedSessions,
                        isLoading: widget.isUnfinishedSessionsLoading,
                        onRefresh: widget.onRefresh,
                      ),
                    ),
                  ),

                // Remaining Content Section
                if (widget.profile == null)
                  _buildGuestContent()
                else if (isStudent)
                  _buildStudentContent()
                else
                  _buildTeacherContent(),
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 18),
                  sliver: SliverToBoxAdapter(child: _LegalLinksSection()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestContent() {
    if (_gradeViewModel.isLoading) {
      return const SliverPadding(
        padding: EdgeInsets.all(24.0),
        sliver: SliverToBoxAdapter(child: LoadingShimmer()),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      sliver: SliverToBoxAdapter(
        child: GuestContentView(grades: _gradeViewModel.grades),
      ),
    );
  }

  Widget _buildStudentContent() {
    if (widget.agendaData == null) {
      return const SliverPadding(
        padding: EdgeInsets.all(24.0),
        sliver: SliverToBoxAdapter(child: LoadingShimmer()),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      sliver: SliverToBoxAdapter(
        child: StudentContentView(
          agendaData: widget.agendaData,
          nextStepsData: widget.nextStepsData,
          currentCurriculumWeek: widget.currentCurriculumWeek,
          nextStepsState: widget.nextStepsState,
          onToggleNextSteps: widget.onToggleNextSteps,
          onExpandNextSteps: widget.onExpandNextSteps,
          onRefresh: widget.onRefresh,
          onLessonCardTap: (item) {
            _trackEvent('lesson_card_clicked', {
              'lesson_id': item['lesson_id'],
              'grade_id': item['grade_id'],
              'curriculum_week':
                  item['curriculum_week'] ?? widget.currentCurriculumWeek,
            });
          },
        ),
      ),
    );
  }

  Widget _buildTeacherContent() {
    return const SliverPadding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
      sliver: SliverToBoxAdapter(child: TeacherContentView()),
    );
  }

  int _calculateCompletedLessons() {
    if (widget.agendaData == null) return 0;

    return widget.agendaData!
        .where(
          (item) => (item['progress_percentage'] ?? 0.0).toDouble() >= 100.0,
        )
        .length;
  }
}

class _LegalLinksSection extends StatelessWidget {
  const _LegalLinksSection();

  Future<void> _openUrl(String value) async {
    final uri = Uri.parse(value);
    await launchUrl(uri, webOnlyWindowName: '_blank');
  }

  Widget _linkButton({
    required String label,
    required String url,
    required IconData icon,
  }) {
    return TextButton.icon(
      onPressed: () => _openUrl(url),
      icon: Icon(icon, size: 15),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF475569),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE6F5)),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 4,
        runSpacing: 2,
        children: [
          _linkButton(
            label: 'Ana Sayfa',
            url: 'https://derstakip.net/',
            icon: Icons.home_outlined,
          ),
          _linkButton(
            label: 'Gizlilik Politikası',
            url: 'https://derstakip.net/privacy-policy.html',
            icon: Icons.privacy_tip_outlined,
          ),
          _linkButton(
            label: 'Hakkımızda',
            url: 'https://derstakip.net/about.html',
            icon: Icons.info_outline_rounded,
          ),
          _linkButton(
            label: 'İletişim',
            url: 'https://derstakip.net/contact.html',
            icon: Icons.mail_outline_rounded,
          ),
        ],
      ),
    );
  }
}
