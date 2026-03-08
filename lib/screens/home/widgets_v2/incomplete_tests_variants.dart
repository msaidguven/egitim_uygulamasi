import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ═══════════════════════════════════════════════════════════════════
// ÖRNEK VERİ MODELİ — kendi modelinle değiştir
// ═══════════════════════════════════════════════════════════════════

class IncompleteTest {
  final int testId;
  final String testName;
  final String lessonName;
  final int answeredQuestions;
  final int totalQuestions;
  final int earnedPoints;

  const IncompleteTest({
    required this.testId,
    required this.testName,
    required this.lessonName,
    required this.answeredQuestions,
    required this.totalQuestions,
    required this.earnedPoints,
  });

  double get progress => (answeredQuestions / totalQuestions).clamp(0.0, 1.0);
  int get remainingQuestions => totalQuestions - answeredQuestions;
}

// Örnek mock veri — gerçek verini buraya bağla
final _mockTests = [
  const IncompleteTest(testId: 1, testName: 'Kesirler Testi', lessonName: 'Matematik', answeredQuestions: 6, totalQuestions: 10, earnedPoints: 120),
  const IncompleteTest(testId: 2, testName: 'Hücre Yapısı', lessonName: 'Fen Bilimleri', answeredQuestions: 3, totalQuestions: 8, earnedPoints: 60),
  const IncompleteTest(testId: 3, testName: 'Sözcük Türleri', lessonName: 'Türkçe', answeredQuestions: 7, totalQuestions: 12, earnedPoints: 140),
  const IncompleteTest(testId: 4, testName: 'İpek Yolu', lessonName: 'Sosyal Bilgiler', answeredQuestions: 2, totalQuestions: 10, earnedPoints: 40),
];

// Dünya temasından renk al — mevcut _getWorld ile eşleştir
Color _getLessonAccent(String lesson) {
  final l = lesson.toLowerCase();
  if (l.contains('mat')) return const Color(0xFFFFD700);
  if (l.contains('fen')) return const Color(0xFF7FFF00);
  if (l.contains('türk')) return const Color(0xFFFF6B6B);
  if (l.contains('sos')) return const Color(0xFFFFF176);
  if (l.contains('ing')) return const Color(0xFFFFFF99);
  return const Color(0xFFE040FB);
}

Color _getLessonSky(String lesson) {
  final l = lesson.toLowerCase();
  if (l.contains('mat')) return const Color(0xFF3030CC);
  if (l.contains('fen')) return const Color(0xFF006400);
  if (l.contains('türk')) return const Color(0xFFCC0000);
  if (l.contains('sos')) return const Color(0xFFCC7700);
  if (l.contains('ing')) return const Color(0xFF008080);
  return const Color(0xFF4A148C);
}

IconData _getLessonIcon(String lesson) {
  final l = lesson.toLowerCase();
  if (l.contains('mat')) return Icons.calculate_rounded;
  if (l.contains('fen')) return Icons.science_rounded;
  if (l.contains('türk')) return Icons.menu_book_rounded;
  if (l.contains('sos')) return Icons.public_rounded;
  if (l.contains('ing')) return Icons.translate_rounded;
  return Icons.school_rounded;
}

// ═══════════════════════════════════════════════════════════════════
// SEÇENEK 1: YATAY SCROLL "GÖREV KARTI" ŞERİDİ
// QuestBar'ın hemen üstüne yerleştir
// ═══════════════════════════════════════════════════════════════════

class IncompleteTestsHorizontalStrip extends StatelessWidget {
  final List<IncompleteTest> tests;
  final void Function(IncompleteTest) onTap;

  const IncompleteTestsHorizontalStrip({
    super.key,
    required this.tests,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (tests.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Başlık
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Container(
                width: 6, height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFF4D4D),
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(begin: const Offset(1, 1), end: const Offset(1.5, 1.5), duration: 700.ms),
              const SizedBox(width: 8),
              const Text(
                'YARIM KALAN GÖREVLER',
                style: TextStyle(
                  color: Color(0xFFFF4D4D),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4D4D).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: const Color(0xFFFF4D4D).withOpacity(0.5)),
                ),
                child: Text(
                  '${tests.length}',
                  style: const TextStyle(
                    color: Color(0xFFFF4D4D),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Yatay kart listesi
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: tests.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final test = tests[index];
              return _HorizontalTestCard(
                test: test,
                index: index,
                onTap: () => onTap(test),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
      ],
    );
  }
}

class _HorizontalTestCard extends StatefulWidget {
  final IncompleteTest test;
  final int index;
  final VoidCallback onTap;

  const _HorizontalTestCard({required this.test, required this.index, required this.onTap});

  @override
  State<_HorizontalTestCard> createState() => _HorizontalTestCardState();
}

class _HorizontalTestCardState extends State<_HorizontalTestCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final accent = _getLessonAccent(widget.test.lessonName);
    final sky = _getLessonSky(widget.test.lessonName);
    final icon = _getLessonIcon(widget.test.lessonName);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [sky.withOpacity(0.9), sky.withOpacity(0.5)],
            ),
            border: Border.all(color: accent.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(color: accent.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withOpacity(0.2),
                      border: Border.all(color: accent.withOpacity(0.6)),
                    ),
                    child: Icon(icon, color: accent, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.test.lessonName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  // Kalan soru rozeti
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4D4D).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: const Color(0xFFFF4D4D).withOpacity(0.6)),
                    ),
                    child: Text(
                      '${widget.test.remainingQuestions} kaldı',
                      style: const TextStyle(color: Color(0xFFFF4D4D), fontSize: 9, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.test.testName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              // Progress bar
              Stack(
                children: [
                  Container(height: 5, decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(99))),
                  FractionallySizedBox(
                    widthFactor: widget.test.progress,
                    child: Container(height: 5, decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99), color: accent,
                      boxShadow: [BoxShadow(color: accent.withOpacity(0.6), blurRadius: 4)],
                    )),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${widget.test.answeredQuestions}/${widget.test.totalQuestions} soru',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 12),
                      const SizedBox(width: 2),
                      Text('${widget.test.earnedPoints}',
                          style: const TextStyle(color: Color(0xFFFFD700), fontSize: 10, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        )
            .animate(delay: Duration(milliseconds: 80 * widget.index))
            .fadeIn(duration: 350.ms)
            .slideX(begin: 0.1, end: 0),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SEÇENEK 2: BOTTOM SHEET — WorldCard'a basınca açılır
// showIncompleteTestsSheet() fonksiyonunu çağır
// ═══════════════════════════════════════════════════════════════════

void showIncompleteTestsSheet(
  BuildContext context, {
  required String lessonName,
  required List<IncompleteTest> tests,
  required void Function(IncompleteTest) onTap,
}) {
  final lessonTests = tests.where((t) =>
    t.lessonName.toLowerCase().contains(lessonName.toLowerCase()) ||
    lessonName.toLowerCase().contains(t.lessonName.toLowerCase())
  ).toList();

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _IncompleteTestsSheet(
      lessonName: lessonName,
      tests: lessonTests.isNotEmpty ? lessonTests : tests,
      onTap: onTap,
    ),
  );
}

class _IncompleteTestsSheet extends StatelessWidget {
  final String lessonName;
  final List<IncompleteTest> tests;
  final void Function(IncompleteTest) onTap;

  const _IncompleteTestsSheet({
    required this.lessonName,
    required this.tests,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _getLessonAccent(lessonName);
    final sky = _getLessonSky(lessonName);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [sky, const Color(0xFF0D001A)],
        ),
        border: Border.all(color: accent.withOpacity(0.5), width: 2),
        boxShadow: [BoxShadow(color: accent.withOpacity(0.2), blurRadius: 30)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(99))),
          const SizedBox(height: 16),
          // Başlık
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withOpacity(0.2),
                    border: Border.all(color: accent.withOpacity(0.6), width: 2),
                  ),
                  child: Icon(_getLessonIcon(lessonName), color: accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lessonName,
                          style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w800)),
                      const Text('Yarım Kalan Görevler',
                          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4D4D).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: const Color(0xFFFF4D4D).withOpacity(0.5)),
                  ),
                  child: Text('${tests.length} görev',
                      style: const TextStyle(color: Color(0xFFFF4D4D), fontSize: 11, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Test listesi
          ...tests.asMap().entries.map((e) => _SheetTestRow(
            test: e.value,
            index: e.key,
            accent: accent,
            onTap: () { Navigator.pop(context); onTap(e.value); },
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SheetTestRow extends StatefulWidget {
  final IncompleteTest test;
  final int index;
  final Color accent;
  final VoidCallback onTap;

  const _SheetTestRow({required this.test, required this.index, required this.accent, required this.onTap});

  @override
  State<_SheetTestRow> createState() => _SheetTestRowState();
}

class _SheetTestRowState extends State<_SheetTestRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withOpacity(0.06),
            border: Border.all(color: widget.accent.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              // Progress circle
              SizedBox(
                width: 48, height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: widget.test.progress,
                      strokeWidth: 4,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      color: widget.accent,
                    ),
                    Text(
                      '%${(widget.test.progress * 100).toInt()}',
                      style: TextStyle(color: widget.accent, fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.test.testName,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.help_outline_rounded, size: 12, color: Colors.white.withOpacity(0.4)),
                        const SizedBox(width: 4),
                        Text('${widget.test.remainingQuestions} soru kaldı',
                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 12),
                        const Icon(Icons.star_rounded, size: 12, color: Color(0xFFFFD700)),
                        const SizedBox(width: 3),
                        Text('${widget.test.earnedPoints} XP',
                            style: const TextStyle(color: Color(0xFFFFD700), fontSize: 11, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ],
                ),
              ),
              // Devam et butonu
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.accent,
                  boxShadow: [BoxShadow(color: widget.accent.withOpacity(0.4), blurRadius: 10)],
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
              ),
            ],
          ),
        )
            .animate(delay: Duration(milliseconds: 60 * widget.index))
            .fadeIn(duration: 300.ms)
            .slideX(begin: 0.05, end: 0),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SEÇENEK 3: HEADER ALTINDA "YANIP SÖNEN" BANNER + TAM EKRAN OVERLAY
// Banner'a basınca tüm testleri gösteren bir overlay açılır
// ═══════════════════════════════════════════════════════════════════

class IncompleteTestsBanner extends StatefulWidget {
  final List<IncompleteTest> tests;
  final void Function(IncompleteTest) onTap;

  const IncompleteTestsBanner({super.key, required this.tests, required this.onTap});

  @override
  State<IncompleteTestsBanner> createState() => _IncompleteTestsBannerState();
}

class _IncompleteTestsBannerState extends State<IncompleteTestsBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this, duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() { _glowController.dispose(); super.dispose(); }

  void _showOverlay() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (ctx) => _IncompleteTestsOverlay(tests: widget.tests, onTap: (t) {
        Navigator.pop(ctx);
        widget.onTap(t);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tests.isEmpty) return const SizedBox.shrink();

    final totalRemaining = widget.tests.fold<int>(0, (s, t) => s + t.remainingQuestions);
    final totalXP = widget.tests.fold<int>(0, (s, t) => s + t.earnedPoints);

    return GestureDetector(
      onTap: _showOverlay,
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (_, child) => Container(
          margin: const EdgeInsets.fromLTRB(14, 6, 14, 0),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF3D0000), Color(0xFF1A0010)],
            ),
            border: Border.all(
              color: Color.lerp(const Color(0xFFFF4D4D), const Color(0xFFFF8C00), _glowController.value)!
                  .withOpacity(0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF4D4D).withOpacity(0.1 + _glowController.value * 0.15),
                blurRadius: 16,
              ),
            ],
          ),
          child: child,
        ),
        child: Row(
          children: [
            // Yanıp sönen uyarı ikonu
            AnimatedBuilder(
              animation: _glowController,
              builder: (_, __) => Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF4D4D).withOpacity(0.15 + _glowController.value * 0.15),
                  border: Border.all(
                    color: const Color(0xFFFF4D4D).withOpacity(0.5 + _glowController.value * 0.4),
                  ),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF4D4D), size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Yarım kalan görevlerin var!',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.tests.length} test • $totalRemaining soru kaldı • $totalXP XP kazanıldı',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFF4D4D).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFF4D4D).withOpacity(0.5)),
              ),
              child: const Text('Gör', style: TextStyle(color: Color(0xFFFF4D4D), fontSize: 12, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms)
        .slideY(begin: -0.1, end: 0);
  }
}

class _IncompleteTestsOverlay extends StatelessWidget {
  final List<IncompleteTest> tests;
  final void Function(IncompleteTest) onTap;

  const _IncompleteTestsOverlay({required this.tests, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2D0010), Color(0xFF0D001A)],
          ),
          border: Border.all(color: const Color(0xFFFF4D4D).withOpacity(0.6), width: 2),
          boxShadow: [BoxShadow(color: const Color(0xFFFF4D4D).withOpacity(0.2), blurRadius: 40)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            // Başlık
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF4D4D), size: 22),
                const SizedBox(width: 8),
                const Text(
                  'YARIM KALAN GÖREVLER',
                  style: TextStyle(color: Color(0xFFFF4D4D), fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Bunları tamamlayarak XP kazan!',
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
            const SizedBox(height: 16),
            // Test kartları — grid
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: tests.length,
                itemBuilder: (_, i) {
                  final test = tests[i];
                  final accent = _getLessonAccent(test.lessonName);
                  final sky = _getLessonSky(test.lessonName);
                  final icon = _getLessonIcon(test.lessonName);
                  return GestureDetector(
                    onTap: () => onTap(test),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [sky.withOpacity(0.8), sky.withOpacity(0.3)],
                        ),
                        border: Border.all(color: accent.withOpacity(0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(icon, color: accent, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(test.lessonName,
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: Text(test.testName,
                                maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${test.remainingQuestions} kaldı',
                                  style: const TextStyle(color: Color(0xFFFF4D4D), fontSize: 10, fontWeight: FontWeight.w800)),
                              Row(children: [
                                const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 11),
                                const SizedBox(width: 2),
                                Text('${test.earnedPoints}',
                                    style: const TextStyle(color: Color(0xFFFFD700), fontSize: 10, fontWeight: FontWeight.w800)),
                              ]),
                            ],
                          ),
                        ],
                      ),
                    ).animate(delay: Duration(milliseconds: 50 * i)).fadeIn(duration: 300.ms).scale(
                        begin: const Offset(0.9, 0.9), end: const Offset(1, 1), curve: Curves.easeOutBack),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Kapat
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withOpacity(0.08),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: const Center(
                  child: Text('Kapat', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// ÖNIZLEME — Bu widget'ı sil, sadece test için
// ═══════════════════════════════════════════════════════════════════

class IncompleteTestsPreview extends StatelessWidget {
  const IncompleteTestsPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D001A),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('3 Seçenek Önizleme',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text('SEÇENEK 1: Yatay Şerit',
                    style: TextStyle(color: Color(0xFFFFD700), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1)),
              ),
              IncompleteTestsHorizontalStrip(
                tests: _mockTests,
                onTap: (t) => debugPrint('Tapped: ${t.testName}'),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text('SEÇENEK 2: Bottom Sheet (butona bas)',
                    style: TextStyle(color: Color(0xFFFFD700), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: () => showIncompleteTestsSheet(
                    context,
                    lessonName: 'Matematik',
                    tests: _mockTests,
                    onTap: (t) => debugPrint('Sheet tapped: ${t.testName}'),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: const Color(0xFF6C63FF).withOpacity(0.15),
                      border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.5)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.touch_app_rounded, color: Color(0xFF6C63FF), size: 18),
                        SizedBox(width: 8),
                        Text('Bottom Sheet Aç', style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text('SEÇENEK 3: Yanıp Sönen Banner + Overlay',
                    style: TextStyle(color: Color(0xFFFFD700), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1)),
              ),
              IncompleteTestsBanner(
                tests: _mockTests,
                onTap: (t) => debugPrint('Banner tapped: ${t.testName}'),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
