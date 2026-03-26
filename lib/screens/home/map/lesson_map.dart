import 'package:egitim_uygulamasi/main.dart';
import 'package:egitim_uygulamasi/models/profile_model.dart';
import 'package:egitim_uygulamasi/screens/home/unit_map_v3_screen.dart';
import 'package:egitim_uygulamasi/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeV3Screen extends StatelessWidget {
  final Profile? profile;

  const HomeV3Screen({super.key, this.profile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LessonMapWidget(profile: profile),
    );
  }
}

class LessonMapWidget extends ConsumerStatefulWidget {
  final Profile? profile;

  const LessonMapWidget({super.key, this.profile});

  @override
  ConsumerState<LessonMapWidget> createState() => _LessonMapWidgetState();
}

class _LessonMapWidgetState extends ConsumerState<LessonMapWidget> {
  List<Map<String, dynamic>> _agendaData = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchDashboardData() async {
    if (widget.profile == null || widget.profile!.gradeId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentWeek = calculateCurrentAcademicWeek();
      final response = await supabase.rpc(
        'get_weekly_dashboard_agenda',
        params: {
          'p_user_id': widget.profile!.id,
          'p_grade_id': widget.profile!.gradeId,
          'p_curriculum_week': currentWeek,
        },
      );

      if (!mounted) return;

      setState(() {
        _agendaData = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('LessonMap verisi çekilirken hata: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Giriş Gerekli'),
        content: const Text(
          'Ders içeriklerine erişmek ve ilerlemeni kaydetmek için lütfen giriş yap.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Giriş Yap'),
          ),
        ],
      ),
    );
  }

  void _handleLessonTap(String lessonName, {int? lessonId}) {
    if (widget.profile == null) {
      _showLoginDialog();
      return;
    }

    final lessonData = _agendaData.firstWhere((item) {
      if (lessonId != null && item['lesson_id'] == lessonId) return true;

      final dbName = item['lesson_name'].toString().toLowerCase();
      final searchName = lessonName.toLowerCase();
      return dbName == searchName ||
          dbName.contains(searchName) ||
          searchName.contains(dbName);
    }, orElse: () => {});

    final foundLessonId = lessonData['lesson_id'] ?? lessonId;

    if (foundLessonId != null && widget.profile!.gradeId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UnitMapV3Screen(
            lessonId: foundLessonId,
            lessonName: lessonName,
            gradeId: widget.profile!.gradeId!,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$lessonName dersine ait bilgi bulunamadı.')),
      );
    }
  }

  Color _getLessonColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('mat')) return const Color(0xFF2563EB);
    if (lower.contains('fen')) return const Color(0xFF059669);
    if (lower.contains('türk')) return const Color(0xFFDC2626);
    if (lower.contains('sos')) return const Color(0xFFD97706);
    if (lower.contains('ing')) return const Color(0xFF7C3AED);
    return const Color(0xFF0EA5E9);
  }

  IconData _getIconForLesson(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('mat')) return Icons.calculate_rounded;
    if (lower.contains('türk')) return Icons.menu_book_rounded;
    if (lower.contains('fen')) return Icons.biotech_rounded;
    if (lower.contains('sos')) return Icons.history_edu_rounded;
    if (lower.contains('din')) return Icons.mosque_rounded;
    if (lower.contains('ing')) return Icons.translate_rounded;
    return Icons.school_rounded;
  }

  Map<String, dynamic>? _nextContinueLesson() {
    if (_agendaData.isEmpty) return null;
    final sorted =
        _agendaData.map((item) => Map<String, dynamic>.from(item)).toList()
          ..sort((a, b) {
            final aProgress = (a['solved_questions'] as num? ?? 0).toInt();
            final bProgress = (b['solved_questions'] as num? ?? 0).toInt();
            return bProgress.compareTo(aProgress);
          });
    return sorted.first;
  }

  int _totalSolved() {
    return _agendaData.fold<int>(
      0,
      (sum, item) => sum + ((item['solved_questions'] as num? ?? 0).toInt()),
    );
  }

  int _totalQuestions() {
    return _agendaData.fold<int>(
      0,
      (sum, item) =>
          sum + _safeMax(1, ((item['total_questions'] as num? ?? 0).toInt())),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = widget.profile != null;
    final fullName = widget.profile?.fullName ?? 'Öğrenci';
    final firstName = fullName.trim().split(' ').first;
    final nextLesson = _nextContinueLesson();
    final totalSolved = _totalSolved();
    final totalQuestions = _totalQuestions();
    final overallProgress = totalQuestions > 0
        ? (totalSolved / totalQuestions)
        : 0.0;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF5FAFF), Color(0xFFEFF6FF), Color(0xFFF8FAFC)],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -60,
              right: -30,
              child: _bgBubble(const Color(0xFF93C5FD), 160),
            ),
            Positioned(
              top: 80,
              left: -45,
              child: _bgBubble(const Color(0xFFBFDBFE), 120),
            ),
            Column(
              children: [
                _HomeV3TopBar(
                  name: firstName,
                  isLoggedIn: isLoggedIn,
                  totalSolved: totalSolved,
                  overallProgress: overallProgress,
                  canGoBack: Navigator.of(context).canPop(),
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildHorizontalMap(),
                ),
              ],
            ),
            Positioned(
              right: 16,
              top: 138,
              child: _CompactStatsCard(
                lessonCount: _agendaData.length,
                overallProgress: overallProgress,
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _BottomContinueCard(
                isLoggedIn: isLoggedIn,
                nextLesson: nextLesson,
                onTap: () {
                  if (nextLesson != null) {
                    _handleLessonTap(
                      nextLesson['lesson_name'] as String? ?? 'Ders',
                      lessonId: nextLesson['lesson_id'] as int?,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalMap() {
    if (_agendaData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Sınıfınıza atanmış ders bulunamadı.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth < 420 ? 168.0 : 192.0;
        final amplitude = constraints.maxWidth < 420 ? 58.0 : 72.0;
        final mapHeight = constraints.maxWidth < 420 ? 270.0 : 320.0;

        return Center(
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: constraints.maxWidth * 0.24,
              vertical: 12,
            ),
            child: SizedBox(
              height: mapHeight,
              child: CustomPaint(
                painter: _LessonPathPainterV3(
                  lessonsCount: _agendaData.length,
                  nodeWidth: itemWidth,
                  amplitude: amplitude,
                ),
                child: Row(
                  children: List.generate(_agendaData.length, (index) {
                    final item = _agendaData[index];
                    final lessonId = item['lesson_id'] as int;
                    final name = item['lesson_name'] as String;
                    final solvedQ = ((item['solved_questions'] ?? 0) as num)
                        .toInt();
                    final totalQ = _safeMax(
                      1,
                      ((item['total_questions'] ?? 10) as num).toInt(),
                    );
                    final progress = (solvedQ / totalQ).clamp(0.0, 1.0);
                    final yOffset = index.isEven ? -amplitude : amplitude;

                    return SizedBox(
                      width: itemWidth,
                      child: Transform.translate(
                        offset: Offset(0, yOffset),
                        child: _LessonNodeV3(
                          label: name,
                          icon: _getIconForLesson(name),
                          color: _getLessonColor(name),
                          progress: progress,
                          onTap: () =>
                              _handleLessonTap(name, lessonId: lessonId),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _bgBubble(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.18),
      ),
    );
  }
}

class _HomeV3TopBar extends StatelessWidget {
  final String name;
  final bool isLoggedIn;
  final int totalSolved;
  final double overallProgress;
  final bool canGoBack;
  final VoidCallback onBack;

  const _HomeV3TopBar({
    required this.name,
    required this.isLoggedIn,
    required this.totalSolved,
    required this.overallProgress,
    required this.canGoBack,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            if (canGoBack) ...[
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                  foregroundColor: const Color(0xFF0F172A),
                  minimumSize: const Size(36, 36),
                  padding: const EdgeInsets.all(8),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF0EA5E9)],
                ),
              ),
              child: const Icon(Icons.explore_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLoggedIn ? 'Merhaba $name' : 'Öğrenme Haritası',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Toplam $totalSolved soru • %${(overallProgress * 100).toInt()} ilerleme',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B)),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 320.ms).slideY(begin: -0.1, end: 0);
  }
}

class _LessonPathPainterV3 extends CustomPainter {
  final int lessonsCount;
  final double nodeWidth;
  final double amplitude;

  const _LessonPathPainterV3({
    required this.lessonsCount,
    required this.nodeWidth,
    required this.amplitude,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (lessonsCount < 2) return;

    final linePaint = Paint()
      ..color = const Color(0xFFBFDBFE)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < lessonsCount - 1; i++) {
      final isUp1 = i.isEven;
      final isUp2 = (i + 1).isEven;

      final dx1 = (i * nodeWidth) + (nodeWidth / 2);
      final dy1 = (size.height / 2) + (isUp1 ? -amplitude : amplitude);

      final dx2 = ((i + 1) * nodeWidth) + (nodeWidth / 2);
      final dy2 = (size.height / 2) + (isUp2 ? -amplitude : amplitude);

      final path = Path()..moveTo(dx1, dy1);
      path.cubicTo(
        dx1 + (nodeWidth / 3),
        dy1,
        dx2 - (nodeWidth / 3),
        dy2,
        dx2,
        dy2,
      );
      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LessonPathPainterV3 oldDelegate) {
    return oldDelegate.lessonsCount != lessonsCount ||
        oldDelegate.nodeWidth != nodeWidth ||
        oldDelegate.amplitude != amplitude;
  }
}

class _LessonNodeV3 extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final double progress;
  final VoidCallback onTap;

  const _LessonNodeV3({
    required this.label,
    required this.icon,
    required this.color,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = progress <= 0
        ? 'Başlanmadı'
        : progress >= 1
        ? 'Tamamlandı'
        : '%${(progress * 100).toInt()}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 3),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress > 0 ? progress : 0,
                  strokeWidth: 5,
                  color: color.withValues(alpha: 0.35),
                  backgroundColor: Colors.transparent,
                ),
                Icon(icon, color: color, size: 30),
              ],
            ),
          ),
          const SizedBox(height: 11),
          Container(
            constraints: const BoxConstraints(maxWidth: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _CompactStatsCard extends StatelessWidget {
  final int lessonCount;
  final double overallProgress;

  const _CompactStatsCard({
    required this.lessonCount,
    required this.overallProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Genel Durum',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$lessonCount ders',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: overallProgress,
              color: const Color(0xFF2563EB),
              backgroundColor: const Color(0xFFE2E8F0),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '%${(overallProgress * 100).toInt()}',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D4ED8),
              ),
            ),
          ),
        ],
      ),
    ).animate().slideX(begin: 0.2, end: 0).fadeIn(duration: 300.ms);
  }
}

class _BottomContinueCard extends StatelessWidget {
  final bool isLoggedIn;
  final Map<String, dynamic>? nextLesson;
  final VoidCallback onTap;

  const _BottomContinueCard({
    required this.isLoggedIn,
    required this.nextLesson,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = isLoggedIn
        ? 'Kaldığın yerden devam et'
        : 'Öğrenme yolculuğunu başlat';
    final subtitle = (isLoggedIn && nextLesson != null)
        ? (nextLesson!['lesson_name'] as String? ?? 'Ders')
        : 'Haritadan bir ders seç';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFB6C5DD),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: Text(isLoggedIn ? 'Devam Et' : 'Derslere Git'),
          ),
        ],
      ),
    ).animate().slideY(begin: 0.2, end: 0).fadeIn(duration: 360.ms);
  }
}

int _safeMax(int a, int b) => a > b ? a : b;
