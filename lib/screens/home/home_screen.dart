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
import 'package:egitim_uygulamasi/screens/home/map/lesson_map.dart';
import 'package:egitim_uygulamasi/screens/home/widgets/teacher_content_view.dart';
import 'package:egitim_uygulamasi/screens/home/widgets/unfinished_tests_section.dart';
import 'package:egitim_uygulamasi/screens/home/widgets/weekly_agenda_overview_card.dart';
import 'package:egitim_uygulamasi/main.dart';

import 'package:egitim_uygulamasi/screens/outcomes/outcomes_screen_v2.dart';
import 'package:egitim_uygulamasi/ads/adsense_slots.dart';
import 'package:egitim_uygulamasi/viewmodels/grade_viewmodel.dart';
import 'package:egitim_uygulamasi/widgets/adaptive_ad_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/link.dart';

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
        builder: (_) => OutcomesScreenV2(
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
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 10, 16, 14),
                  sliver: SliverToBoxAdapter(
                    child: AdaptiveAdBanner(
                      adSlot: AdSenseSlots.homeInline,
                      margin: EdgeInsets.symmetric(horizontal: 2),
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
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 18),
                  sliver: SliverToBoxAdapter(
                    child: _LegalLinksSection(
                      currentCurriculumWeek: widget.currentCurriculumWeek,
                    ),
                  ),
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
    return SliverFillRemaining(child: LessonMapWidget(profile: widget.profile));
  }

  Widget _buildTeacherContent() {
    return const SliverPadding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
      sliver: SliverToBoxAdapter(child: TeacherContentView()),
    );
  }
}

class _SeoFooterLink {
  const _SeoFooterLink({
    required this.title,
    required this.url,
    required this.gradeOrder,
    required this.gradeName,
    required this.lessonName,
    required this.unitTitle,
  });

  final String title;
  final String url;
  final int gradeOrder;
  final String gradeName;
  final String lessonName;
  final String unitTitle;
}

class _LegalLinksSection extends StatefulWidget {
  const _LegalLinksSection({required this.currentCurriculumWeek});

  final int currentCurriculumWeek;

  @override
  State<_LegalLinksSection> createState() => _LegalLinksSectionState();
}

class _LegalLinksSectionState extends State<_LegalLinksSection> {
  late final Future<List<_SeoFooterLink>> _weeklySeoLinksFuture;

  @override
  void initState() {
    super.initState();
    _weeklySeoLinksFuture = _loadWeeklySeoLinks();
  }

  String _slugFromValue(dynamic value) {
    final raw = (value as String? ?? '').trim();
    if (raw.isNotEmpty) return raw;
    return '';
  }

  String _slugifyTr(String text) {
    const trMap = {
      'ç': 'c',
      'ğ': 'g',
      'ı': 'i',
      'ö': 'o',
      'ş': 's',
      'ü': 'u',
      'Ç': 'c',
      'Ğ': 'g',
      'İ': 'i',
      'Ö': 'o',
      'Ş': 's',
      'Ü': 'u',
    };
    var value = text.trim();
    for (final entry in trMap.entries) {
      value = value.replaceAll(entry.key, entry.value);
    }
    value = value.toLowerCase();
    value = value.replaceAll(RegExp(r'[.\s]+'), '-');
    value = value.replaceAll(RegExp(r'[^a-z0-9-]'), '');
    value = value.replaceAll(RegExp(r'-+'), '-');
    return value.replaceAll(RegExp(r'^-|-$'), '');
  }

  Future<List<_SeoFooterLink>> _loadWeeklySeoLinks() async {
    final week = widget.currentCurriculumWeek;
    if (week <= 0) return const [];

    final gradeRows =
        (await supabase
                .from('grades')
                .select('id,name,slug,order_no,is_active')
                .eq('is_active', true)
                .inFilter('order_no', [5, 6]))
            as List;
    if (gradeRows.isEmpty) return const [];

    final grades = gradeRows
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
    final gradeById = <int, Map<String, dynamic>>{
      for (final g in grades) g['id'] as int: g,
    };
    final gradeIds = gradeById.keys.toList();
    if (gradeIds.isEmpty) return const [];

    final lessonGradeRows =
        (await supabase
                .from('lesson_grades')
                .select('grade_id,lesson_id,is_active')
                .eq('is_active', true)
                .inFilter('grade_id', gradeIds))
            as List;
    if (lessonGradeRows.isEmpty) return const [];

    final pairs = lessonGradeRows
        .map((row) => Map<String, dynamic>.from(row as Map))
        .where((row) => row['grade_id'] is int && row['lesson_id'] is int)
        .toList();
    if (pairs.isEmpty) return const [];

    final lessonIds = pairs.map((p) => p['lesson_id'] as int).toSet().toList();
    final lessonRows =
        (await supabase
                .from('lessons')
                .select('id,name,slug,is_active')
                .eq('is_active', true)
                .inFilter('id', lessonIds))
            as List;
    final lessonMaps = lessonRows
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
    final lessonById = <int, Map<String, dynamic>>{
      for (final row in lessonMaps) row['id'] as int: row,
    };

    final rpcResults = await Future.wait(
      pairs.map((pair) async {
        final gradeId = pair['grade_id'] as int;
        final lessonId = pair['lesson_id'] as int;
        final data = await supabase.rpc(
          'get_weekly_curriculum',
          params: {
            'p_user_id': null,
            'p_grade_id': gradeId,
            'p_lesson_id': lessonId,
            'p_curriculum_week': week,
            'p_is_admin': false,
          },
        );
        return {
          'grade_id': gradeId,
          'lesson_id': lessonId,
          'rows': (data as List? ?? const []),
        };
      }),
    );

    final topicIds = <int>{};
    for (final item in rpcResults) {
      final rows = item['rows'] as List;
      for (final row in rows) {
        final map = Map<String, dynamic>.from(row as Map);
        final topicId = map['topic_id'] as int?;
        if (topicId != null) topicIds.add(topicId);
      }
    }
    if (topicIds.isEmpty) return const [];

    final topicRows =
        (await supabase
                .from('topics')
                .select('id,title,slug,unit_id,is_active')
                .eq('is_active', true)
                .inFilter('id', topicIds.toList()))
            as List;
    if (topicRows.isEmpty) return const [];

    final publishedRows =
        (await supabase
                .from('topic_contents')
                .select('topic_id')
                .eq('is_published', true)
                .inFilter('topic_id', topicIds.toList()))
            as List;
    final publishedTopicIds = publishedRows
        .map((row) => (row as Map)['topic_id'] as int?)
        .whereType<int>()
        .toSet();
    if (publishedTopicIds.isEmpty) return const [];

    final topics = topicRows
        .map((row) => Map<String, dynamic>.from(row as Map))
        .where((row) => publishedTopicIds.contains(row['id'] as int?))
        .toList();
    if (topics.isEmpty) return const [];

    final unitIds = topics
        .map((t) => t['unit_id'] as int?)
        .whereType<int>()
        .toSet()
        .toList();
    final unitRows =
        (await supabase
                .from('units')
                .select('id,title,slug,grade_id,lesson_id,is_active')
                .eq('is_active', true)
                .inFilter('id', unitIds))
            as List;
    final unitMaps = unitRows
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
    final unitById = <int, Map<String, dynamic>>{
      for (final row in unitMaps) row['id'] as int: row,
    };

    final links = <_SeoFooterLink>[];
    for (final topic in topics) {
      final unitId = topic['unit_id'] as int?;
      if (unitId == null) continue;
      final unit = unitById[unitId];
      if (unit == null) continue;

      final gradeId = unit['grade_id'] as int?;
      final lessonId = unit['lesson_id'] as int?;
      if (gradeId == null || lessonId == null) continue;
      final grade = gradeById[gradeId];
      final lesson = lessonById[lessonId];
      if (grade == null || lesson == null) continue;

      final gradeName = (grade['name'] as String? ?? '').trim();
      final lessonName = (lesson['name'] as String? ?? '').trim();
      final unitTitle = (unit['title'] as String? ?? '').trim();
      final topicTitle = (topic['title'] as String? ?? '').trim();
      if (gradeName.isEmpty ||
          lessonName.isEmpty ||
          unitTitle.isEmpty ||
          topicTitle.isEmpty) {
        continue;
      }

      final gradeSlug = _slugFromValue(grade['slug']).isNotEmpty
          ? _slugFromValue(grade['slug'])
          : _slugifyTr(gradeName);
      final lessonSlug = _slugFromValue(lesson['slug']).isNotEmpty
          ? _slugFromValue(lesson['slug'])
          : _slugifyTr(lessonName);
      final unitSlug = _slugFromValue(unit['slug']).isNotEmpty
          ? _slugFromValue(unit['slug'])
          : _slugifyTr(unitTitle);
      final topicSlug = _slugFromValue(topic['slug']).isNotEmpty
          ? _slugFromValue(topic['slug'])
          : _slugifyTr(topicTitle);

      if (gradeSlug.isEmpty ||
          lessonSlug.isEmpty ||
          unitSlug.isEmpty ||
          topicSlug.isEmpty) {
        continue;
      }

      links.add(
        _SeoFooterLink(
          title: topicTitle,
          url:
              'https://derstakip.net/$gradeSlug/$lessonSlug/$unitSlug/$topicSlug/',
          gradeOrder: grade['order_no'] as int? ?? 0,
          gradeName: gradeName,
          lessonName: lessonName,
          unitTitle: unitTitle,
        ),
      );
    }

    links.sort((a, b) {
      final gradeCompare = a.gradeOrder.compareTo(b.gradeOrder);
      if (gradeCompare != 0) return gradeCompare;
      final lessonCompare = a.lessonName.compareTo(b.lessonName);
      if (lessonCompare != 0) return lessonCompare;
      final unitCompare = a.unitTitle.compareTo(b.unitTitle);
      if (unitCompare != 0) return unitCompare;
      return a.title.compareTo(b.title);
    });

    return links;
  }

  Widget _linkButton({
    required String label,
    required String url,
    required IconData icon,
  }) {
    return Link(
      uri: Uri.parse(url),
      target: LinkTarget.blank,
      builder: (context, followLink) {
        return TextButton.icon(
          onPressed: followLink,
          icon: Icon(icon, size: 15),
          label: Text(label),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF475569),
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
        );
      },
    );
  }

  Widget _weeklyTopicLinks() {
    return FutureBuilder<List<_SeoFooterLink>>(
      future: _weeklySeoLinksFuture,
      builder: (context, snapshot) {
        final links = snapshot.data ?? const <_SeoFooterLink>[];
        if (links.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.currentCurriculumWeek}. hafta konu linkleri (5-6. sınıf)',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 10,
                runSpacing: 2,
                children: links.map((item) {
                  return Link(
                    uri: Uri.parse(item.url),
                    target: LinkTarget.self,
                    builder: (context, followLink) {
                      return InkWell(
                        onTap: followLink,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '${item.gradeName} ${item.lessonName} - ${item.title}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
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
              _linkButton(
                label: 'Site Haritası',
                url: 'https://derstakip.net/sitemap.xml',
                icon: Icons.map_outlined,
              ),
            ],
          ),
          _weeklyTopicLinks(),
        ],
      ),
    );
  }
}
