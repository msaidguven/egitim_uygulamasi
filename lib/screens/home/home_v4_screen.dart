import 'dart:math' as math;
import 'package:egitim_uygulamasi/main.dart';
import 'package:egitim_uygulamasi/models/profile_model.dart';
import 'package:egitim_uygulamasi/screens/home/unit_map_v2_screen.dart';
import 'package:egitim_uygulamasi/screens/home/widgets_v2/incomplete_tests_variants.dart';
import 'package:egitim_uygulamasi/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────────────────────────────────────
// WORLD DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────

class _LessonWorld {
  final IconData icon;
  final String worldName;
  final List<Color> skyColors;
  final Color groundColor;
  final Color accentColor;

  const _LessonWorld({
    required this.icon,
    required this.worldName,
    required this.skyColors,
    required this.groundColor,
    required this.accentColor,
  });
}

_LessonWorld _getWorld(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('mat'))
    return const _LessonWorld(
      icon: Icons.calculate_rounded, worldName: 'Sayı Krallığı',
      skyColors: [Color(0xFF1a1aff), Color(0xFF6C63FF)],
      groundColor: Color(0xFF4040CC), accentColor: Color(0xFFFFD700),
    );
  if (lower.contains('fen'))
    return const _LessonWorld(
      icon: Icons.science_rounded, worldName: 'Bilim Adası',
      skyColors: [Color(0xFF006400), Color(0xFF00C9A7)],
      groundColor: Color(0xFF005500), accentColor: Color(0xFF7FFF00),
    );
  if (lower.contains('türk'))
    return const _LessonWorld(
      icon: Icons.menu_book_rounded, worldName: 'Kelime Ormanı',
      skyColors: [Color(0xFFCC0000), Color(0xFFFF6B6B)],
      groundColor: Color(0xFF990000), accentColor: Color(0xFFFFD700),
    );
  if (lower.contains('sos'))
    return const _LessonWorld(
      icon: Icons.public_rounded, worldName: 'Tarih Kalesi',
      skyColors: [Color(0xFFCC7700), Color(0xFFFFB347)],
      groundColor: Color(0xFF994400), accentColor: Color(0xFFFFF176),
    );
  if (lower.contains('ing'))
    return const _LessonWorld(
      icon: Icons.translate_rounded, worldName: 'Dil Köyü',
      skyColors: [Color(0xFF008080), Color(0xFF4ECDC4)],
      groundColor: Color(0xFF006060), accentColor: Color(0xFFFFFF99),
    );
  if (lower.contains('din'))
    return const _LessonWorld(
      icon: Icons.auto_stories_rounded, worldName: 'Huzur Bahçesi',
      skyColors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
      groundColor: Color(0xFF1B5E20), accentColor: Color(0xFFFFE082),
    );
  return const _LessonWorld(
    icon: Icons.school_rounded, worldName: 'Gizemli Diyar',
    skyColors: [Color(0xFF4A148C), Color(0xFF9C27B0)],
    groundColor: Color(0xFF311B92), accentColor: Color(0xFFE040FB),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class HomeV4Screen extends ConsumerStatefulWidget {
  final Profile? profile;
  const HomeV4Screen({super.key, this.profile});

  @override
  ConsumerState<HomeV4Screen> createState() => _HomeV4ScreenState();
}

class _HomeV4ScreenState extends ConsumerState<HomeV4Screen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _agendaData = [];
  bool _isLoading = false;

  late AnimationController _floatController;
  late AnimationController _starsController;
  late AnimationController _coinController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _starsController = AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat();
    _coinController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _fetchDashboardData();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _starsController.dispose();
    _coinController.dispose();
    super.dispose();
  }

  Future<void> _fetchDashboardData() async {
    if (widget.profile == null || widget.profile!.gradeId == null) return;
    setState(() => _isLoading = true);
    try {
      final currentWeek = calculateCurrentAcademicWeek();
      final response = await supabase.rpc('get_weekly_dashboard_agenda', params: {
        'p_user_id': widget.profile!.id,
        'p_grade_id': widget.profile!.gradeId,
        'p_curriculum_week': currentWeek,
      });
      if (!mounted) return;
      setState(() {
        _agendaData = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('HomeV4 hata: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A0533), Color(0xFF2D1460)],
            ),
            border: Border.all(color: const Color(0xFFFFD700), width: 3),
            boxShadow: [BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.3), blurRadius: 30)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔐', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 10),
              const Text('Giriş Gerekli!',
                  style: TextStyle(color: Color(0xFFFFD700), fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Text('Maceraya devam etmek için\ngiriş yapmalısın!',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 22),
              Row(children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Kapat', style: TextStyle(color: Colors.white54)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: const Center(child: Text('Giriş Yap',
                          style: TextStyle(color: Color(0xFF1A0533), fontSize: 14, fontWeight: FontWeight.w900))),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLessonTap(String lessonName, {int? lessonId}) {
    if (widget.profile == null) { _showLoginDialog(); return; }
    final lessonData = _agendaData.firstWhere((item) {
      if (lessonId != null && item['lesson_id'] == lessonId) return true;
      final dbName = item['lesson_name'].toString().toLowerCase();
      final searchName = lessonName.toLowerCase();
      return dbName == searchName || dbName.contains(searchName) || searchName.contains(dbName);
    }, orElse: () => {});
    final foundLessonId = lessonData['lesson_id'] ?? lessonId;
    if (foundLessonId != null && widget.profile!.gradeId != null) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => UnitMapV2Screen(
        lessonId: foundLessonId, lessonName: lessonName, gradeId: widget.profile!.gradeId!,
      )));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$lessonName bulunamadı 😢'),
        backgroundColor: const Color(0xFF1A0533),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ));
    }
  }

  int _totalSolved() => _agendaData.fold<int>(0, (s, i) => s + ((i['solved_questions'] as num? ?? 0).toInt()));
  int _totalQuestions() => _agendaData.fold<int>(0, (s, i) => s + _safeMax(1, ((i['total_questions'] as num? ?? 0).toInt())));
  double _overallProgress() { final tq = _totalQuestions(); return tq > 0 ? (_totalSolved() / tq).clamp(0.0, 1.0) : 0.0; }
  int _completedCount() => _agendaData.where((i) {
    final s = (i['solved_questions'] as num? ?? 0).toInt();
    final t = _safeMax(1, (i['total_questions'] as num? ?? 0).toInt());
    return s >= t;
  }).length;
  Map<String, dynamic>? _nextLesson() {
    if (_agendaData.isEmpty) return null;
    final incomplete = _agendaData.where((i) {
      final s = (i['solved_questions'] as num? ?? 0).toInt();
      final t = _safeMax(1, (i['total_questions'] as num? ?? 0).toInt());
      return s < t;
    }).toList();
    return incomplete.isNotEmpty ? incomplete.first : _agendaData.first;
  }

  List<IncompleteTest> _buildIncompleteTests() {
    final tests = <IncompleteTest>[];
    for (var i = 0; i < _agendaData.length; i++) {
      final item = _agendaData[i];
      final solved = (item['solved_questions'] as num? ?? 0).toInt();
      final total = _safeMax(1, (item['total_questions'] as num? ?? 0).toInt());
      if (solved >= total) continue;

      final lessonName = item['lesson_name'] as String? ?? 'Ders';
      final lessonId = (item['lesson_id'] as num?)?.toInt();
      final answered = solved.clamp(0, total);

      tests.add(
        IncompleteTest(
          testId: lessonId ?? -(i + 1),
          testName: '$lessonName Görevi',
          lessonName: lessonName,
          answeredQuestions: answered,
          totalQuestions: total,
          earnedPoints: (item['earned_points'] as num?)?.toInt() ?? (answered * 10),
        ),
      );
    }
    return tests;
  }

  String _rankTitle(double p) {
    if (p >= 1.0) return '👑 EFSANE';
    if (p >= 0.75) return '🏆 KAHRAMAN';
    if (p >= 0.5) return '⚔️ SAVAŞÇI';
    if (p >= 0.25) return '🛡️ MACERACI';
    return '🌱 YENİ BAŞLAYAN';
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = widget.profile != null;
    final firstName = (widget.profile?.fullName ?? 'Kahraman').trim().split(' ').first;
    final progress = _overallProgress();
    final next = _nextLesson();
    final incompleteTests = _buildIncompleteTests();

    return Scaffold(
      backgroundColor: const Color(0xFF0D001A),
      body: Stack(
        children: [
          // Animated starfield
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _starsController,
              builder: (_, __) => CustomPaint(painter: _StarfieldPainter(_starsController.value)),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenW = constraints.maxWidth;
                // Web/tablet: center content with max width
                final isWide = screenW > 700;
                final contentMaxW = isWide ? 860.0 : double.infinity;

                Widget content = Column(
                  children: [
                    _RpgHeader(
                      name: firstName,
                      isLoggedIn: isLoggedIn,
                      totalSolved: _totalSolved(),
                      progress: progress,
                      completed: _completedCount(),
                      total: _agendaData.length,
                      rankTitle: _rankTitle(progress),
                      floatController: _floatController,
                      canGoBack: Navigator.of(context).canPop(),
                      onBack: () => Navigator.of(context).maybePop(),
                    ),
                    Expanded(
                      child: _isLoading
                          ? _buildLoading()
                          : _agendaData.isEmpty
                              ? _buildEmpty()
                              : _buildWorldGrid(screenW),
                    ),
                    if (!_isLoading && incompleteTests.isNotEmpty)
                      IncompleteTestsHorizontalStrip(
                        tests: incompleteTests,
                        onTap: (test) => _handleLessonTap(
                          test.lessonName,
                          lessonId: test.testId > 0 ? test.testId : null,
                        ),
                      ),
                    if (!_isLoading && next != null)
                      _QuestBar(
                        isLoggedIn: isLoggedIn,
                        nextLesson: next,
                        coinController: _coinController,
                        onTap: () => _handleLessonTap(
                          next['lesson_name'] as String? ?? 'Ders',
                          lessonId: next['lesson_id'] as int?,
                        ),
                      ),
                  ],
                );

                if (isWide) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: contentMaxW),
                      child: content,
                    ),
                  );
                }
                return content;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('⏳', style: TextStyle(fontSize: 52))
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 600.ms),
        const SizedBox(height: 16),
        const Text('Dünyalar yükleniyor...',
            style: TextStyle(color: Color(0xFFFFD700), fontSize: 16, fontWeight: FontWeight.w800)),
      ]),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('🗺️', style: TextStyle(fontSize: 64))
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .slideY(begin: 0, end: -0.05, duration: 1200.ms),
        const SizedBox(height: 16),
        const Text('Harita henüz boş!',
            style: TextStyle(color: Color(0xFFFFD700), fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text('Öğretmenin derslerini ekleyince\nburada görünür.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
      ]),
    );
  }

  Widget _buildWorldGrid([double screenWidth = 400]) {
    // Responsive: sütun sayısı ve kart oranı ekran genişliğine göre
    final int columns;
    final double aspectRatio;
    final double hPadding;

    if (screenWidth >= 1200) {
      columns = 5; aspectRatio = 0.88; hPadding = 20;
    } else if (screenWidth >= 900) {
      columns = 4; aspectRatio = 0.86; hPadding = 18;
    } else if (screenWidth >= 600) {
      columns = 3; aspectRatio = 0.84; hPadding = 16;
    } else {
      columns = 2; aspectRatio = 0.82; hPadding = 14;
    }

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(hPadding, 6, hPadding, 6),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: aspectRatio,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _agendaData.length,
      itemBuilder: (context, index) {
        final item = _agendaData[index];
        final name = item['lesson_name'] as String;
        final solved = (item['solved_questions'] as num? ?? 0).toInt();
        final total = _safeMax(1, (item['total_questions'] as num? ?? 0).toInt());
        final progress = (solved / total).clamp(0.0, 1.0);
        return _WorldCard(
          lessonName: name,
          world: _getWorld(name),
          progress: progress,
          solvedQuestions: solved,
          totalQuestions: total,
          index: index,
          floatController: _floatController,
          onTap: () => _handleLessonTap(name, lessonId: item['lesson_id'] as int?),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RPG HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _RpgHeader extends StatelessWidget {
  final String name;
  final bool isLoggedIn;
  final int totalSolved;
  final double progress;
  final int completed;
  final int total;
  final String rankTitle;
  final AnimationController floatController;
  final bool canGoBack;
  final VoidCallback onBack;

  const _RpgHeader({
    required this.name, required this.isLoggedIn, required this.totalSolved,
    required this.progress, required this.completed, required this.total,
    required this.rankTitle, required this.floatController,
    required this.canGoBack, required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF1A0533), Color(0xFF2D1460)],
        ),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.6), width: 2),
        boxShadow: [BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (canGoBack) ...[
                GestureDetector(
                  onTap: onBack,
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white.withOpacity(0.1),
                      border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4)),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 16),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              // Floating hero avatar
              AnimatedBuilder(
                animation: floatController,
                builder: (_, child) => Transform.translate(
                  offset: Offset(0, floatController.value * -5),
                  child: child,
                ),
                child: Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF8C00)]),
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.5), blurRadius: 16)],
                  ),
                  child: Center(child: Text(isLoggedIn ? '🧙' : '🎮', style: const TextStyle(fontSize: 26))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLoggedIn ? '$name\'in Macerası 🗡️' : 'Büyük Macera!',
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: -0.2),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5)),
                      ),
                      child: Text(rankTitle,
                          style: const TextStyle(color: Color(0xFFFFD700), fontSize: 11, fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
              ),
              // Star counter
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('⭐', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text('$totalSolved',
                            style: const TextStyle(color: Color(0xFFFFD700), fontSize: 15, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('$completed/$total Dünya',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          // XP bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Deneyim Puanı (XP)',
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.w700)),
                  Text('%${(progress * 100).toInt()}',
                      style: const TextStyle(color: Color(0xFFFFD700), fontSize: 11, fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 6),
              Stack(
                children: [
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.2)),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF8C00)]),
                        boxShadow: [BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.6), blurRadius: 8)],
                      ),
                    ),
                  ),
                  // Segment dividers on bar
                  ...List.generate(3, (i) => FractionallySizedBox(
                    widthFactor: (i + 1) / 4,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(width: 2, height: 12, color: Colors.black.withOpacity(0.35)),
                    ),
                  )),
                ],
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WORLD CARD
// ─────────────────────────────────────────────────────────────────────────────

class _WorldCard extends StatefulWidget {
  final String lessonName;
  final _LessonWorld world;
  final double progress;
  final int solvedQuestions;
  final int totalQuestions;
  final int index;
  final AnimationController floatController;
  final VoidCallback onTap;

  const _WorldCard({
    required this.lessonName, required this.world, required this.progress,
    required this.solvedQuestions, required this.totalQuestions,
    required this.index, required this.floatController, required this.onTap,
  });

  @override
  State<_WorldCard> createState() => _WorldCardState();
}

class _WorldCardState extends State<_WorldCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.progress >= 1.0;
    final isLocked = widget.progress <= 0;
    final isInProgress = !isCompleted && !isLocked;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [widget.world.skyColors[0], widget.world.skyColors[1], widget.world.groundColor],
              stops: const [0.0, 0.65, 1.0],
            ),
            border: Border.all(
              color: isCompleted
                  ? const Color(0xFFFFD700)
                  : isLocked
                      ? Colors.white.withOpacity(0.1)
                      : widget.world.accentColor.withOpacity(0.6),
              width: isCompleted ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isCompleted ? const Color(0xFFFFD700) : widget.world.accentColor)
                    .withOpacity(isLocked ? 0.05 : 0.28),
                blurRadius: 16, offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Clouds
              Positioned(top: 12, left: 8,
                  child: Opacity(opacity: isLocked ? 0.2 : 0.55, child: const Text('☁️', style: TextStyle(fontSize: 16)))),
              Positioned(top: 22, right: 12,
                  child: Opacity(opacity: isLocked ? 0.15 : 0.35, child: const Text('☁️', style: TextStyle(fontSize: 10)))),
              // Completed sparkles
              if (isCompleted) ...[
                const Positioned(top: 8, right: 8, child: Text('✨', style: TextStyle(fontSize: 14))),
                const Positioned(top: 20, right: 20, child: Text('⭐', style: TextStyle(fontSize: 10))),
              ],
              // Lock overlay
              if (isLocked)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      color: Colors.black.withOpacity(0.45),
                    ),
                  ),
                ),
              // Main content
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      const SizedBox(height: 16),
                      // Floating island emoji
                      Expanded(
                        child: Center(
                          child: AnimatedBuilder(
                            animation: widget.floatController,
                            builder: (_, child) => Transform.translate(
                              offset: Offset(0, math.sin((widget.floatController.value + widget.index * 0.3) * math.pi) * 5),
                              child: child,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 64, height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: widget.world.accentColor.withOpacity(isLocked ? 0.05 : 0.2),
                                  ),
                                ),
                                if (isLocked)
                                  const Icon(Icons.lock_rounded, color: Colors.white54, size: 30)
                                else
                                  Icon(widget.world.icon, color: Colors.white, size: 36),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // World name
                      Text(
                        isLocked ? '???' : widget.world.worldName,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isLocked ? Colors.white.withOpacity(0.3) : widget.world.accentColor,
                          fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.lessonName,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isLocked ? Colors.white.withOpacity(0.4) : Colors.white,
                          fontSize: 13, fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // HP bar
                      Row(
                        children: [
                          const Text('❤️', style: TextStyle(fontSize: 11)),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Stack(
                              children: [
                                Container(height: 6, decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(99))),
                                FractionallySizedBox(
                                  widthFactor: widget.progress,
                                  child: Container(
                                    height: 6,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(99),
                                      color: isCompleted ? const Color(0xFFFFD700) : const Color(0xFFFF4D4D),
                                      boxShadow: isLocked ? null : [BoxShadow(
                                        color: (isCompleted ? const Color(0xFFFFD700) : const Color(0xFFFF4D4D)).withOpacity(0.6),
                                        blurRadius: 6,
                                      )],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Action badge
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: isLocked
                              ? Colors.white.withOpacity(0.06)
                              : isCompleted
                                  ? const Color(0xFFFFD700).withOpacity(0.2)
                                  : Colors.white.withOpacity(0.18),
                          border: Border.all(
                            color: isLocked
                                ? Colors.white.withOpacity(0.1)
                                : isCompleted
                                    ? const Color(0xFFFFD700).withOpacity(0.6)
                                    : Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          isLocked ? '🔒 Kilitli' : isCompleted ? '👑 Tamamlandı!' : isInProgress ? '▶ Devam Et' : '🚀 Başla!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isLocked ? Colors.white.withOpacity(0.3) : isCompleted ? const Color(0xFFFFD700) : Colors.white,
                            fontSize: 12, fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        )
            .animate(delay: Duration(milliseconds: 70 * widget.index))
            .fadeIn(duration: 400.ms)
            .scale(begin: const Offset(0.85, 0.85), end: const Offset(1, 1), duration: 350.ms, curve: Curves.easeOutBack),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUEST BAR
// ─────────────────────────────────────────────────────────────────────────────

class _QuestBar extends StatelessWidget {
  final bool isLoggedIn;
  final Map<String, dynamic> nextLesson;
  final AnimationController coinController;
  final VoidCallback onTap;

  const _QuestBar({required this.isLoggedIn, required this.nextLesson, required this.coinController, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = nextLesson['lesson_name'] as String? ?? 'Ders';
    final world = _getWorld(name);
    final solved = (nextLesson['solved_questions'] as num? ?? 0).toInt();
    final total = _safeMax(1, (nextLesson['total_questions'] as num? ?? 0).toInt());

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(colors: [world.skyColors[0].withOpacity(0.9), world.skyColors[1].withOpacity(0.9)]),
        border: Border.all(color: world.accentColor.withOpacity(0.7), width: 2),
        boxShadow: [BoxShadow(color: world.accentColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: coinController,
                  builder: (_, child) => Transform.scale(scale: 1.0 + coinController.value * 0.12, child: child),
                  child: Icon(world.icon, color: Colors.white, size: 36),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: world.accentColor.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: world.accentColor.withOpacity(0.5)),
                            ),
                            child: Text('⚔️ GÖREV',
                                style: TextStyle(color: world.accentColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                          ),
                          const SizedBox(width: 8),
                          Text('$solved/$total soru',
                              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isLoggedIn ? name : 'Maceraya başla!',
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: world.accentColor,
                    boxShadow: [BoxShadow(color: world.accentColor.withOpacity(0.5), blurRadius: 14)],
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().slideY(begin: 0.2, end: 0).fadeIn(duration: 450.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STARFIELD PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _StarfieldPainter extends CustomPainter {
  final double t;
  _StarfieldPainter(this.t);

  static final _rng = math.Random(42);
  static final _stars = List.generate(80, (_) => Offset(_rng.nextDouble(), _rng.nextDouble()));
  static final _sizes = List.generate(80, (_) => _rng.nextDouble() * 2.5 + 0.5);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < _stars.length; i++) {
      final twinkle = (math.sin(t * math.pi * 2 + i * 0.7) + 1) / 2;
      final paint = Paint()
        ..color = Colors.white.withOpacity(0.1 + twinkle * 0.5)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(_stars[i].dx * size.width, _stars[i].dy * size.height), _sizes[i], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter old) => old.t != t;
}

int _safeMax(int a, int b) => a > b ? a : b;
