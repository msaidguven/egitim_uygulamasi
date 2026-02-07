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

import 'package:egitim_uygulamasi/screens/home/widgets/week_info_card.dart';
import 'package:egitim_uygulamasi/screens/home/widgets/week_scroll_widget.dart';
import 'package:egitim_uygulamasi/viewmodels/grade_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GradeViewModel _gradeViewModel = GradeViewModel();
  bool _isStartingSrsTest = false;

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
      final viewModel = ref.read(testViewModelProvider.notifier);

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Giriş yapmanız gerekiyor.')),
        );
        return;
      }

      // SRS test session oluştur
      final sessionId = await ref.read(testRepositoryProvider).startSrsTestSession(
        userId: userId,
        clientId: clientId,
      );

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

  @override
  Widget build(BuildContext context) {
    final bool isStudent = widget.currentRole == 'student';
    final bool isAdmin = widget.profile?.role == 'admin';
    final srsDueCountAsync = ref.watch(srsDueCountProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: RefreshIndicator(
        onRefresh: widget.onRefresh,
        color: const Color(0xFF6366F1),
        backgroundColor: Colors.white,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // 1. Header Section (Herkes)
            SliverAppBar(
              pinned: true,
              backgroundColor: const Color(0xFF6366F1),
              elevation: 0,
              expandedHeight: 110,
              flexibleSpace: FlexibleSpaceBar(
                background: HomeHeader(
                  profile: widget.profile,
                  isAdmin: isAdmin,
                  onRoleChanged: widget.onRoleChanged,
                  impersonatedRole: widget.impersonatedRole,
                ),
              ),
            ),

            // 2. Week Info Card Section (Herkes)
            SliverToBoxAdapter(
              child: WeekInfoCard(
                profile: widget.profile,
                agendaData: widget.agendaData,
                completedLessons: _calculateCompletedLessons(),
              ),
            ),

            // 3. Streak Card Widget (Sadece Üyeler/Öğrenciler)
            if (isStudent)
              const SliverToBoxAdapter(
                child: StreakCardWidget(
                  streakCount: 12,
                  dailyGoal: 20,
                  currentProgress: 15,
                ),
              ),

            // 4. SRS Alert Widget (Herkes - Veri geldiyse)
            SliverToBoxAdapter(
              child: srsDueCountAsync.when(
                data: (count) => SrsAlertWidget(
                  questionCount: count,
                  onReviewTap: _isStartingSrsTest ? () {} : () => _startSrsTest(),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
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

            // 6. Unfinished Tests Section (Sadece Üyeler/Öğrenciler)
            if (isStudent)
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
          ],
        ),
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
        ),
      ),
    );
  }

  Widget _buildTeacherContent() {
    return const SliverPadding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
      sliver: SliverToBoxAdapter(
        child: TeacherContentView(),
      ),
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
