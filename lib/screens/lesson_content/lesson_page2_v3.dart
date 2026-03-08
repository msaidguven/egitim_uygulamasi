import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import './models/lesson_models_v3.dart';

// ════════════════════════════════════════════════════════════
// SUPABASE STUB  (replace with real supabase_flutter import)
// ════════════════════════════════════════════════════════════
// To use real Supabase:
//   1. Add supabase_flutter to pubspec.yaml
//   2. Replace this stub with:
//        import 'package:supabase_flutter/supabase_flutter.dart';
//   3. Initialize in main(): await Supabase.initialize(url: '...', anonKey: '...');
//   4. Use: Supabase.instance.client
class _SupabaseStub {
  Future<void> upsert(String table, Map<String, dynamic> data) async {
    // TODO: await Supabase.instance.client.from(table).upsert(data);
    debugPrint('[Supabase] upsert $table: $data');
  }

  Future<List<Map<String, dynamic>>> select(
    String table,
    String eq,
    dynamic val,
  ) async {
    // TODO: return await Supabase.instance.client.from(table).select().eq(eq, val);
    debugPrint('[Supabase] select $table where $eq=$val');
    return [];
  }

  Future<void> delete(String table, String eq, dynamic val) async {
    // TODO: await Supabase.instance.client.from(table).delete().eq(eq, val);
    debugPrint('[Supabase] delete $table where $eq=$val');
  }
}

final _supabase = _SupabaseStub();

// Lesson content is now loaded from assets/lessons/fotosentez_v3.json

// ════════════════════════════════════════════════════════════
// MODELS
// ════════════════════════════════════════════════════════════

// ════════════════════════════════════════════════════════════
// THEME
// ════════════════════════════════════════════════════════════
class AppTheme {
  static const Color primary = Color(0xFF6C63FF);
  static const Color secondary = Color(0xFF43E97B);
  static const Color accent = Color(0xFFFF6B6B);
  static const Color gold = Color(0xFFFFD700);
  static const Color darkBg = Color(0xFF121212);
  static const Color darkCard = Color(0xFF2A2A3E);
  static const Color lightBg = Color(0xFFF0F4FF);
  static const Color lightCard = Colors.white;
}

// ════════════════════════════════════════════════════════════
// GAME STATE
// ════════════════════════════════════════════════════════════
class GameState extends ChangeNotifier {
  int lives = 3;
  int score = 0;
  int streak = 0;
  int maxStreak = 0;
  bool streakFire = false;
  int bonusMultiplier = 1;
  bool isFavorite = false;
  final DateTime startTime = DateTime.now();
  final Map<String, _StepMastery> _mastery = {};

  _StepMastery masteryFor(String id) =>
      _mastery.putIfAbsent(id, () => _StepMastery());

  bool canAdvance(StepV3 step) {
    if (step.type == 'content' ||
        step.type == 'intro' ||
        step.type == 'summary' ||
        step.type == 'concept_cards') {
      return true;
    }
    final m = masteryFor(step.id);
    if (step.type == 'matching' || step.type == 'activity') {
      return m.correct >= 1;
    }
    final questionCount = (step.data['questions'] as List?)?.length ?? 3;
    final requiredAttempts = questionCount < 3 ? questionCount : 3;
    return m.total >= requiredAttempts && (m.correct / m.total) >= 0.65;
  }

  void recordCorrect(String id, int pts) {
    final mastery = masteryFor(id);
    mastery.correct++;
    mastery.total++;
    streak++;
    if (streak > maxStreak) maxStreak = streak;
    if (streak >= 3 && !streakFire) {
      streakFire = true;
      notifyListeners();
      Future.delayed(const Duration(seconds: 2), () {
        streakFire = false;
        notifyListeners();
      });
    }
    score += pts * bonusMultiplier;
    notifyListeners();
  }

  void recordWrong(String id) {
    masteryFor(id).total++;
    streak = 0;
    bonusMultiplier = 1;
    lives = (lives - 1).clamp(0, 3);
    notifyListeners();
  }

  void restoreLives() {
    lives = 3;
    notifyListeners();
  }

  void setFavorite(bool v) {
    isFavorite = v;
    notifyListeners();
  }

  Duration get elapsed => DateTime.now().difference(startTime);

  String get badgeEmoji => score >= 160
      ? '🥇'
      : score >= 100
      ? '🥈'
      : '🥉';
  String get badgeLabel => score >= 160
      ? 'Gold'
      : score >= 100
      ? 'Silver'
      : 'Bronze';
}

class _StepMastery {
  int correct = 0, total = 0;
}

// ════════════════════════════════════════════════════════════
// SHARED STEP DATA
// ════════════════════════════════════════════════════════════
class _S {
  final Color card, text, sub;
  final bool dark;
  final GameState game;
  final void Function(String, int) onCorrect;
  final void Function(String) onWrong;
  final VoidCallback onNext;

  const _S({
    required this.card,
    required this.text,
    required this.sub,
    required this.dark,
    required this.game,
    required this.onCorrect,
    required this.onWrong,
    required this.onNext,
  });
}

// ════════════════════════════════════════════════════════════
// MAIN PAGE
// ════════════════════════════════════════════════════════════
class LessonPageV3 extends StatefulWidget {
  const LessonPageV3({super.key});
  @override
  State<LessonPageV3> createState() => _LessonPageV3State();
}

class _LessonPageV3State extends State<LessonPageV3> {
  LessonV3? _lesson;
  late PageController _pc;
  final GameState _g = GameState();
  int _step = 0;
  bool _dark = true;
  bool _showAd = false;
  final List<_FloatingScore> _scores = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _pc = PageController();
    _g.addListener(() => setState(() {}));
    _loadLesson();
  }

  Future<void> _loadLesson() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final raw = await rootBundle.loadString(
        'assets/lessons/fotosentez_v3.json',
      );
      if (!mounted) return;
      setState(() {
        _lesson = LessonV3.fromJson(jsonDecode(raw));
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading lesson asset: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _pc.dispose();
    _g.dispose();
    super.dispose();
  }

  void _next() {
    final lesson = _lesson;
    if (lesson != null && _step < lesson.steps.length - 1) {
      setState(() => _step++);
      _pc.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prev() {
    if (_step > 0) {
      setState(() => _step--);
      _pc.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onCorrect(String id, int pts) {
    _g.recordCorrect(id, pts);
    final fid = DateTime.now().millisecondsSinceEpoch;
    setState(() => _scores.add(_FloatingScore(pts, fid)));
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _scores.removeWhere((s) => s.id == fid));
    });
  }

  void _onWrong(String id) {
    _g.recordWrong(id);
    if (_g.lives == 0 && !_showAd) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        setState(() => _showAd = true);
      });
    }
  }

  Future<void> _toggleFav() async {
    _g.setFavorite(!_g.isFavorite);
    if (_g.isFavorite) {
      await _supabase.upsert('favorites', {
        'lesson_id': _lesson!.id,
        'title': _lesson!.title,
      });
    } else {
      await _supabase.delete('favorites', 'lesson_id', _lesson!.id);
    }
  }

  Color get _bg => _dark ? AppTheme.darkBg : AppTheme.lightBg;
  Color get _card => _dark ? AppTheme.darkCard : AppTheme.lightCard;
  Color get _txt => _dark ? Colors.white : const Color(0xFF1A1A2E);
  Color get _sub => _dark ? Colors.white60 : Colors.black54;

  _S get _shared => _S(
    card: _card,
    text: _txt,
    sub: _sub,
    dark: _dark,
    game: _g,
    onCorrect: _onCorrect,
    onWrong: _onWrong,
    onNext: _next,
  );

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppTheme.primary),
              const SizedBox(height: 20),
              Text(
                'Ders Yükleniyor...',
                style: TextStyle(color: _txt.withOpacity(0.7), fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (_lesson == null) {
      return Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: Text('Ders bulunamadı 😕', style: TextStyle(color: _txt)),
        ),
      );
    }

    final steps = _lesson!.steps;
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          Column(
            children: [
              _topBar(),
              _progress(),
              Expanded(
                child: PageView.builder(
                  key: const PageStorageKey('lesson_page_v3_pv'),
                  controller: _pc,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: steps.length,
                  itemBuilder: (_, i) => _route(steps[i]),
                ),
              ),
            ],
          ),
          if (_g.streakFire) _StreakBanner(),
          ..._scores.map((s) => _FloatingScoreWidget(score: s)),
          if (_showAd)
            Positioned.fill(
              child: _AdScreen(
                onDone: () => setState(() {
                  _showAd = false;
                  _g.restoreLives();
                }),
                isDark: _dark,
              ),
            ),
        ],
      ),
    );
  }

  // ── TOP BAR ──────────────────────────────────────────────
  Widget _topBar() => SafeArea(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          _Btn(
            icon: Icons.arrow_back_ios_new_rounded,
            color: AppTheme.primary,
            bg: _card,
            onTap: () {
              if (_step > 0) {
                _prev();
                return;
              }
              Navigator.of(context).maybePop();
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _lesson!.subject,
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _lesson!.title,
                  style: TextStyle(
                    color: _txt,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _LivesBadge(lives: _g.lives, bg: _card),
          const SizedBox(width: 6),
          _ScorePill(score: _g.score),
          const SizedBox(width: 6),
          _Btn(
            icon: _g.isFavorite
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            color: _g.isFavorite ? AppTheme.gold : _sub,
            bg: _card,
            onTap: _toggleFav,
          ),
          const SizedBox(width: 4),
          _Btn(
            icon: _dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            color: _dark ? AppTheme.gold : AppTheme.primary,
            bg: _card,
            onTap: () => setState(() => _dark = !_dark),
          ),
        ],
      ),
    ),
  );

  // ── PROGRESS ─────────────────────────────────────────────
  Widget _progress() {
    final pct = (_step + 1) / _lesson!.steps.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${_step + 1} / ${_lesson!.steps.length}',
                style: TextStyle(color: _sub, fontSize: 10),
              ),
              Text(
                '${(pct * 100).round()}%',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: pct),
              duration: const Duration(milliseconds: 500),
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                minHeight: 7,
                backgroundColor: _dark ? Colors.white12 : Colors.black12,
                valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _lesson!.steps.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: i == _step ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: i < _step
                      ? AppTheme.secondary
                      : i == _step
                      ? AppTheme.primary
                      : (_dark ? Colors.white24 : Colors.black26),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ── STEP ROUTER ───────────────────────────────────────────
  Widget _route(StepV3 step) {
    final s = _shared;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.04, 0),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey(step.id),
        child: switch (step.type) {
          'intro' => _IntroStep(step: step, s: s),
          'content' => _ContentStep(step: step, s: s),
          'concept_cards' => _ConceptCardsStep(step: step, s: s),
          'quiz' => _MultiQuizStep(step: step, s: s),
          'true_false' => _MultiTFStep(step: step, s: s),
          'fill_in_the_blank' => _MultiFillStep(step: step, s: s),
          'matching' => _MatchingStep(step: step, s: s),
          'activity' => _ActivityStep(step: step, s: s),
          'summary' => _SummaryStep(step: step, s: s, lesson: _lesson!),
          _ => _FallbackStep(s: s),
        },
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// MASTERY GATE
// ════════════════════════════════════════════════════════════
class _MasteryGate extends StatelessWidget {
  final StepV3 step;
  final _S s;
  final Widget child;

  const _MasteryGate({
    required this.step,
    required this.s,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final m = s.game.masteryFor(step.id);
    final ok = s.game.canAdvance(step);
    return Column(
      children: [
        Expanded(child: child),
        if (m.total > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (m.correct / m.total).clamp(0.0, 1.0),
                          minHeight: 9,
                          backgroundColor: Colors.black12,
                          valueColor: AlwaysStoppedAnimation(
                            ok ? AppTheme.secondary : AppTheme.accent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${m.correct}/${m.total}',
                      style: TextStyle(
                        color: s.sub,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  ok
                      ? '✅ Mastered! You can continue.'
                      : 'Need min 3 questions & 65% accuracy',
                  style: TextStyle(
                    color: ok ? AppTheme.secondary : s.sub,
                    fontSize: 10,
                  ),
                ),
                // Progress bar only — each step's own button handles navigation
              ],
            ),
          ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// STEP: CONTENT (LEARN FIRST)
// ════════════════════════════════════════════════════════════
class _ContentStep extends StatelessWidget {
  final StepV3 step;
  final _S s;
  const _ContentStep({required this.step, required this.s});

  @override
  Widget build(BuildContext context) {
    final d = step.data;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (step.title != null) ...[
            Text(
              step.title!,
              style: TextStyle(
                color: s.text,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
          ],
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: s.card,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.explanation ?? step.instruction ?? '',
                  style: TextStyle(
                    color: s.text,
                    fontSize: 20,
                    height: 1.7,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (d['bulletPoints'] != null) ...[
                  const SizedBox(height: 16),
                  ...(d['bulletPoints'] as List).map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• ',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              p,
                              style: TextStyle(
                                color: s.sub,
                                fontSize: 17,
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
          _BigBtn(label: 'Anladım, Devam Et →', onTap: s.onNext),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// STEP: INTRO
// ════════════════════════════════════════════════════════════
class _IntroStep extends StatefulWidget {
  final StepV3 step;
  final _S s;
  const _IntroStep({required this.step, required this.s});
  @override
  State<_IntroStep> createState() => _IntroStepState();
}

class _IntroStepState extends State<_IntroStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );
  late final Animation<double> _sc = Tween<double>(
    begin: 0.6,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.elasticOut));
  late final Animation<double> _fa = Tween<double>(
    begin: 0.0,
    end: 1.0,
  ).animate(_c);
  @override
  void initState() {
    super.initState();
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.step.data;
    final s = widget.s;
    return FadeTransition(
      opacity: _fa,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _sc,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, Color(0xFF43CBFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    d['icon'] ?? '📚',
                    style: const TextStyle(fontSize: 52),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              d['title'] ?? '',
              style: TextStyle(
                color: s.text,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: s.card,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Text(
                d['description'] ?? '',
                style: TextStyle(
                  color: s.text,
                  fontSize: 17,
                  height: 1.65,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            _BigBtn(label: "Let's Start! 🚀", onTap: s.onNext),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// STEP: CONCEPT CARDS
// ════════════════════════════════════════════════════════════
class _ConceptCardsStep extends StatefulWidget {
  final StepV3 step;
  final _S s;
  const _ConceptCardsStep({required this.step, required this.s});
  @override
  State<_ConceptCardsStep> createState() => _ConceptCardsStepState();
}

class _ConceptCardsStepState extends State<_ConceptCardsStep> {
  int _flipped = -1;
  final Set<int> _reviewed = <int>{};
  @override
  Widget build(BuildContext context) {
    final d = widget.step.data;
    final s = widget.s;
    final cards = d['cards'] as List;
    final allReviewed = _reviewed.length == cards.length;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            d['title'] ?? '',
            style: TextStyle(
              color: s.text,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            allReviewed
                ? 'Tum kavramlari inceledin. Devam edebilirsin.'
                : 'Kartlara dokunup tanimlari incele (${_reviewed.length}/${cards.length})',
            style: TextStyle(color: s.sub, fontSize: 11),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 920),
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 240,
                            crossAxisSpacing: 11,
                            mainAxisSpacing: 11,
                            childAspectRatio: 0.9,
                          ),
                      itemCount: cards.length,
                      itemBuilder: (_, i) {
                        final card = cards[i];
                        final flipped = _flipped == i;
                        final color = _hex(card['color']) ?? AppTheme.primary;
                        final reviewed = _reviewed.contains(i);
                        return GestureDetector(
                          onTap: () => setState(() {
                            _flipped = flipped ? -1 : i;
                            _reviewed.add(i);
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 280),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: flipped
                                    ? [color.withOpacity(0.9), color]
                                    : [
                                        color.withOpacity(0.12),
                                        color.withOpacity(0.28),
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: reviewed
                                    ? AppTheme.secondary
                                    : color.withOpacity(0.45),
                                width: reviewed ? 2.4 : 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.2),
                                  blurRadius: 9,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(13),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    card['icon'] ?? '📌',
                                    style: const TextStyle(fontSize: 30),
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    card['term'],
                                    style: TextStyle(
                                      color: flipped ? Colors.white : s.text,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (flipped) ...[
                                    const SizedBox(height: 5),
                                    Text(
                                      card['definition'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        height: 1.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          _BigBtn(
            label: allReviewed ? 'Devam Et →' : 'Tum Kartlari Incele',
            onTap: allReviewed ? s.onNext : () {},
            color: allReviewed ? AppTheme.primary : Colors.grey,
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// MULTI-Q BASE
// ════════════════════════════════════════════════════════════
abstract class _MQState<W extends StatefulWidget> extends State<W>
    with SingleTickerProviderStateMixin {
  late List<Map<String, dynamic>> _q;
  int _idx = 0;
  bool _answered = false, _wasOk = false, _hint = false;
  final Set<int> _failedIndices = {};
  late final AnimationController shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  List<Map<String, dynamic>> get sourceQ;
  String get stepId;
  _S get s;
  int get pts;

  @override
  void initState() {
    super.initState();
    _q = List.from(sourceQ);
  }

  @override
  void dispose() {
    shake.dispose();
    super.dispose();
  }

  Map<String, dynamic> get cur => _q[_idx];

  void submit(bool ok, [int? index]) {
    if (_answered) return;
    if (index != null && _failedIndices.contains(index)) return;

    if (ok) {
      setState(() {
        _answered = true;
        _wasOk = true;
      });
      s.onCorrect(stepId, pts);
    } else {
      if (index != null) {
        setState(() => _failedIndices.add(index));
      }
      s.onWrong(stepId);
      shake.forward(from: 0);
      setState(() => _hint = true);
    }
  }

  void nextQuestion() {
    setState(() {
      _advance();
    });
  }

  void _advance() {
    if (_idx < _q.length - 1) {
      _idx++;
      _answered = false;
      _wasOk = false;
      _hint = false;
      _failedIndices.clear();
    } else {
      s.onNext();
    }
  }
}

// ════════════════════════════════════════════════════════════
// STEP: MULTI QUIZ
// ════════════════════════════════════════════════════════════
class _MultiQuizStep extends StatefulWidget {
  final StepV3 step;
  final _S s;
  const _MultiQuizStep({required this.step, required this.s});
  @override
  State<_MultiQuizStep> createState() => _MQSQuiz();
}

class _MQSQuiz extends _MQState<_MultiQuizStep> {
  @override
  List<Map<String, dynamic>> get sourceQ =>
      List.from(widget.step.data['questions'] as List);
  @override
  String get stepId => widget.step.id;
  @override
  _S get s => widget.s;
  @override
  int get pts => widget.step.data['points'] as int? ?? 20;

  @override
  Widget build(BuildContext context) {
    final q = cur;
    final opts = List<String>.from(q['options']);
    final ci = q['correctIndex'] as int;
    return _MasteryGate(
      step: widget.step,
      s: s,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _QProg(idx: _idx, total: _q.length, color: AppTheme.primary),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Badge(label: 'Quiz', icon: '❓', color: AppTheme.primary),
                if (!_hint) _HintBtn(onTap: () => setState(() => _hint = true)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                q['question'] ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(opts.length, (i) {
              Color? bg;
              Color border = Colors.transparent;
              final failed = _failedIndices.contains(i);
              if (_answered && i == ci) {
                bg = AppTheme.secondary.withOpacity(0.18);
                border = AppTheme.secondary;
              } else if (failed) {
                bg = AppTheme.accent.withOpacity(0.14);
                border = AppTheme.accent;
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: GestureDetector(
                  onTap: () => submit(i == ci, i),
                  child: _ShakeW(
                    shake: failed,
                    ctrl: shake,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: bg ?? s.card,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: border, width: 2),
                      ),
                      child: Row(
                        children: [
                          _Bubble(
                            lbl: String.fromCharCode(65 + i),
                            answered: _answered,
                            correct: i == ci,
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Text(
                              opts[i],
                              style: TextStyle(
                                color: s.text,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            if (_answered) ...[
              const SizedBox(height: 20),
              _Explain(ok: _wasOk, text: q['explanation'] ?? '', tc: s.text),
              const SizedBox(height: 16),
              _BigBtn(
                label: _idx < _q.length - 1 ? 'Sonraki Soru →' : 'Bitir →',
                onTap: nextQuestion,
              ),
            ],
            if (_hint && !_answered)
              _Hint(hint: '💡 Biraz daha dikkatli bak!', tc: s.text),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// STEP: MULTI TRUE/FALSE
// ════════════════════════════════════════════════════════════
class _MultiTFStep extends StatefulWidget {
  final StepV3 step;
  final _S s;
  const _MultiTFStep({required this.step, required this.s});
  @override
  State<_MultiTFStep> createState() => _MQSTF();
}

class _MQSTF extends _MQState<_MultiTFStep> {
  @override
  List<Map<String, dynamic>> get sourceQ =>
      List.from(widget.step.data['questions'] as List);
  @override
  String get stepId => widget.step.id;
  @override
  _S get s => widget.s;
  @override
  int get pts => widget.step.data['points'] as int? ?? 15;

  @override
  Widget build(BuildContext context) {
    final q = cur;
    final correct = q['correct'] as bool;
    return _MasteryGate(
      step: widget.step,
      s: s,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _QProg(idx: _idx, total: _q.length, color: const Color(0xFF9B59B6)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Badge(
                  label: 'True or False',
                  icon: '⚖️',
                  color: const Color(0xFF9B59B6),
                ),
                if (!_hint && !_answered)
                  _HintBtn(onTap: () => setState(() => _hint = true)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF9B59B6), Color(0xFF6C3483)],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                q['question'] ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 26),
            Row(
              children: [
                Expanded(
                  child: _ShakeW(
                    shake: _failedIndices.contains(0),
                    ctrl: shake,
                    child: _TFBtn(
                      lbl: 'TRUE',
                      emoji: '✅',
                      color: AppTheme.secondary,
                      sel: _answered && correct,
                      wrong: _failedIndices.contains(0),
                      onTap: () => submit(correct == true, 0),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ShakeW(
                    shake: _failedIndices.contains(1),
                    ctrl: shake,
                    child: _TFBtn(
                      lbl: 'FALSE',
                      emoji: '❌',
                      color: AppTheme.accent,
                      sel: _answered && !correct,
                      wrong: _failedIndices.contains(1),
                      onTap: () => submit(correct == false, 1),
                    ),
                  ),
                ),
              ],
            ),
            if (_answered) ...[
              const SizedBox(height: 20),
              _Explain(ok: _wasOk, text: q['explanation'] ?? '', tc: s.text),
              const SizedBox(height: 16),
              _BigBtn(
                label: _idx < _q.length - 1 ? 'Sonraki Soru →' : 'Bitir →',
                onTap: nextQuestion,
              ),
            ],
            if (_hint && !_answered)
              _Hint(hint: '💡 Biraz daha dikkatli bak!', tc: s.text),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// STEP: FILL IN THE BLANK  (multi-question)
// ════════════════════════════════════════════════════════════
class _MultiFillStep extends StatefulWidget {
  final StepV3 step;
  final _S s;
  const _MultiFillStep({required this.step, required this.s});
  @override
  State<_MultiFillStep> createState() => _MultiFillState();
}

class _MultiFillState extends State<_MultiFillStep>
    with SingleTickerProviderStateMixin {
  late List<Map<String, dynamic>> _qs;
  int _idx = 0;
  bool _checked = false, _ok = false, _hint = false;
  late List<String?> _filled;
  late List<String> _pool;
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );

  @override
  void initState() {
    super.initState();
    _qs = List.from(widget.step.data['questions'] as List);
    _load();
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  void _load() {
    final q = _qs[_idx];
    _filled = List.filled(q['blanks'] as int, null);
    _pool = List<String>.from(q['wordPool'])..shuffle();
    _checked = false;
    _ok = false;
    _hint = false;
  }

  void _tap(String w) {
    if (_checked) return;
    final e = _filled.indexWhere((b) => b == null);
    if (e != -1) {
      setState(() {
        _filled[e] = w;
        _pool.remove(w);
      });
    }
  }

  void _rem(int i) {
    if (_checked) return;
    final w = _filled[i];
    if (w != null) {
      setState(() {
        _pool.add(w);
        _filled[i] = null;
      });
    }
  }

  void _check() {
    final ans = List<String>.from(_qs[_idx]['answers']);
    // Order-insensitive: compare as sorted lowercase sets
    final userAns = _filled
        .whereType<String>()
        .map((s) => s.toLowerCase().trim())
        .toList()
      ..sort();
    final expAns = ans.map((s) => s.toLowerCase().trim()).toList()..sort();
    final ok =
        userAns.length == expAns.length &&
        List.generate(userAns.length, (i) => userAns[i] == expAns[i])
            .every((v) => v);
    setState(() {
      _checked = true;
      _ok = ok;
    });
    if (ok) {
      widget.s.onCorrect(
        widget.step.id,
        widget.step.data['points'] as int? ?? 25,
      );
    } else {
      widget.s.onWrong(widget.step.id);
      _shake.forward(from: 0);
      setState(() => _hint = true);
    }
  }

  void _next() {
    if (_idx < _qs.length - 1) {
      setState(() {
        _idx++;
        _load();
      });
    } else {
      widget.s.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final q = _qs[_idx];
    final parts = (q['template'] as String).split('___');
    final hint = q['hint'] as String?;
    return _MasteryGate(
      step: widget.step,
      s: s,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _QProg(
              idx: _idx,
              total: _qs.length,
              color: const Color(0xFFE67E22),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Badge(
                  label: 'Fill in the Blank',
                  icon: '✍️',
                  color: const Color(0xFFE67E22),
                ),
                if (!_hint && !_checked)
                  _HintBtn(onTap: () => setState(() => _hint = true)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: s.card,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 7,
                  ),
                ],
              ),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 7,
                children: _buildParts(parts, s),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Word Bank',
              style: TextStyle(
                color: s.sub,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 7),
            _ShakeW(
              shake: _checked && !_ok,
              ctrl: _shake,
              child: Wrap(
                spacing: 7,
                runSpacing: 7,
                children: _pool
                    .map(
                      (w) => GestureDetector(
                        onTap: () => _tap(w),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(0.25),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            w,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            if (_hint && hint != null) _Hint(hint: '💡 $hint', tc: s.text),
            if (!_checked && _filled.every((b) => b != null))
              _BigBtn(
                label: 'Check ✓',
                onTap: _check,
                color: const Color(0xFFE67E22),
              ),
            if (_checked) ...[
              const SizedBox(height: 16),
              _Explain(
                ok: _ok,
                text: _ok
                    ? (q['explanation'] ?? 'Mükemmel! 🎉')
                    : (q['explanation'] ?? 'Pek sayılmaz — tekrar dene!'),
                tc: s.text,
              ),
              if (_ok) ...[
                const SizedBox(height: 16),
                _BigBtn(
                  label: _idx < _qs.length - 1 ? 'Sonraki Soru →' : 'Bitir →',
                  onTap: _next,
                ),
              ] else ...[
                const SizedBox(height: 16),
                _BigBtn(
                  label: 'Tekrar Dene ↻',
                  onTap: () => setState(_load),
                  color: AppTheme.accent,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildParts(List<String> parts, _S s) {
    final ws = <Widget>[];
    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        ws.add(
          Text(
            parts[i],
            style: TextStyle(
              color: s.text,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }
      if (i < _filled.length) {
        final f = _filled[i];
        ws.add(
          GestureDetector(
            onTap: () => _rem(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              constraints: const BoxConstraints(minWidth: 68),
              decoration: BoxDecoration(
                color: f != null
                    ? AppTheme.primary.withOpacity(0.16)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                border: Border(
                  bottom: BorderSide(
                    color: f != null ? AppTheme.primary : s.sub,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                f ?? '   ',
                style: TextStyle(
                  color: f != null ? s.text : s.sub,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      }
    }
    return ws;
  }
}

// ════════════════════════════════════════════════════════════
// STEP: MATCHING
// ════════════════════════════════════════════════════════════
class _MatchingStep extends StatefulWidget {
  final StepV3 step;
  final _S s;
  const _MatchingStep({required this.step, required this.s});
  @override
  State<_MatchingStep> createState() => _MatchingState();
}

class _MatchingState extends State<_MatchingStep>
    with SingleTickerProviderStateMixin {
  late List<Map<String, String>> _pairs;
  late List<int> _rOrd;
  int? _selL;
  final Map<int, int> _matches = {};
  bool _checked = false, _allOk = false, _hint = false;
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );

  @override
  void initState() {
    super.initState();
    _pairs = List<Map<String, String>>.from(
      (widget.step.data['pairs'] as List).map(
        (p) => Map<String, String>.from(p),
      ),
    );
    _rOrd = List.generate(_pairs.length, (i) => i)..shuffle();
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  void _selRight(int ri) {
    if (_checked || _selL == null || _matches.containsValue(ri)) return;

    final i = _selL!;
    final cor = ri == _rOrd.indexOf(i);

    if (cor) {
      setState(() {
        _matches[i] = ri;
        _selL = null;
      });
      if (_matches.length == _pairs.length) {
        setState(() {
          _checked = true;
          _allOk = true;
        });
        widget.s.onCorrect(
          widget.step.id,
          widget.step.data['points'] as int? ?? 30,
        );
      }
    } else {
      widget.s.onWrong(widget.step.id);
      _shake.forward(from: 0);
      setState(() {
        _selL = null;
        _hint = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final d = widget.step.data;
    return _MasteryGate(
      step: widget.step,
      s: s,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Badge(
              label: 'Matching',
              icon: '🔗',
              color: const Color(0xFF1ABC9C),
            ),
            const SizedBox(height: 12),
            Text(
              d['title'] ?? '',
              style: TextStyle(
                color: s.text,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Select a term, then tap its match.',
              style: TextStyle(color: s.sub, fontSize: 11),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT
                Expanded(
                  child: Column(
                    children: List.generate(_pairs.length, (i) {
                      final sel = _selL == i;
                      final mat = _matches.containsKey(i);
                      return GestureDetector(
                        onTap: () {
                          if (!_checked && !mat) {
                            setState(() => _selL = sel ? null : i);
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 9),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppTheme.primary.withOpacity(0.20)
                                : mat
                                ? AppTheme.secondary.withOpacity(0.11)
                                : s.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: sel
                                  ? AppTheme.primary
                                  : mat
                                  ? AppTheme.secondary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            _pairs[i]['left'] ?? '',
                            style: TextStyle(
                              color: s.text,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 9),
                // RIGHT
                Expanded(
                  child: Column(
                    children: List.generate(_rOrd.length, (ri) {
                      final orig = _rOrd[ri];
                      final used = _matches.containsValue(ri);
                      final ml = _matches.entries
                          .where((e) => e.value == ri)
                          .firstOrNull
                          ?.key;
                      final cor =
                          _checked && ml != null && _rOrd.indexOf(ml) == ri;
                      return _ShakeW(
                        shake: _checked && ml != null && !cor,
                        ctrl: _shake,
                        child: GestureDetector(
                          onTap: () => _selRight(ri),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(bottom: 9),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: _checked && ml != null
                                  ? (cor
                                        ? AppTheme.secondary.withOpacity(0.16)
                                        : AppTheme.accent.withOpacity(0.16))
                                  : used
                                  ? AppTheme.primary.withOpacity(0.11)
                                  : s.card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _checked && ml != null
                                    ? (cor
                                          ? AppTheme.secondary
                                          : AppTheme.accent)
                                    : used
                                    ? AppTheme.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              _pairs[orig]['right'] ?? '',
                              style: TextStyle(
                                color: s.text,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
            if (_hint && !_checked)
              _Hint(hint: '💡 Check your connections!', tc: s.text),
            if (_checked) ...[
              const SizedBox(height: 16),
              _Explain(
                ok: _allOk,
                text: _allOk
                    ? (widget.step.data['explanation'] ??
                          'Mükemmel! Hepsini doğru eşleştirdin. 🎉')
                    : (widget.step.data['explanation'] ??
                          'Bazı eşleştirmeler hatalı — tekrar dene!'),
                tc: s.text,
              ),
              if (_allOk) ...[
                _BigBtn(label: 'Bitir →', onTap: s.onNext),
              ] else ...[
                const SizedBox(height: 16),
                _BigBtn(
                  label: 'Tekrar Dene ↻',
                  onTap: () => setState(() {
                    _checked = false;
                    _matches.clear();
                    _selL = null;
                    _hint = false;
                  }),
                  color: AppTheme.accent,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// STEP: ACTIVITY (word sequence)
// ════════════════════════════════════════════════════════════
class _ActivityStep extends StatefulWidget {
  final StepV3 step;
  final _S s;
  const _ActivityStep({required this.step, required this.s});
  @override
  State<_ActivityStep> createState() => _ActivityState();
}

class _ActivityState extends State<_ActivityStep>
    with SingleTickerProviderStateMixin {
  late List<String> _pool;
  List<String> _sel = []; // Only content words + '->' separators (no '+')
  bool _checked = false, _ok = false, _hint = false;
  late bool _hasArrow; // Whether correctSequence uses '->'
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );

  @override
  void initState() {
    super.initState();
    final rawPool = List<String>.from(widget.step.data['wordPool']);
    // Remove '+' and '->' from pool — they are structural, not selectable
    _pool = rawPool.where((w) => w != '+' && w != '->' && w != '=>').toSet().toList()..shuffle();
    final seq = List<String>.from(widget.step.data['correctSequence']);
    _hasArrow = seq.contains('->') || seq.contains('=>');
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  void _add(String w) {
    if (!_checked) {
      setState(() {
        _sel.add(w);
        _pool.remove(w);
      });
    }
  }

  void _addArrow() {
    if (!_checked && !_sel.contains('->')) {
      setState(() => _sel.add('->'));
    }
  }

  void _rem(int i) {
    if (!_checked) {
      setState(() {
        final removed = _sel.removeAt(i);
        if (removed != '->') _pool.add(removed);
      });
    }
  }

  void _check() {
    final exp = List<String>.from(widget.step.data['correctSequence']);
    // Always use smart compare (+ signs are auto-inserted in UI, not in _sel)
    final ok = _smartCompare(_sel, exp);

    setState(() {
      _checked = true;
      _ok = ok;
    });

    if (ok) {
      widget.s.onCorrect(
        widget.step.id,
        widget.step.data['points'] as int? ?? 35,
      );
    } else {
      widget.s.onWrong(widget.step.id);
      _shake.forward(from: 0);
      setState(() => _hint = true);
    }
  }

  bool _smartCompare(List<String> user, List<String> target) {
    // Split a list into segments separated by '->', '=>', '='
    // Within each segment, '+' signs are ignored and remaining words are sorted
    // so that A + B == B + A (commutativity). Extra/missing '+' signs don't matter.
    const separators = ['->',  '=>', '='];

    List<List<List<String>>> _tokenize(List<String> list) {
      // Returns list of [separator_or_null, sorted_words] pairs
      List<List<List<String>>> result = [];
      List<String> currentWords = [];
      for (final item in list) {
        if (separators.contains(item)) {
          result.add([currentWords..sort(), [item]]);
          currentWords = [];
        } else if (item != '+') {
          currentWords.add(item);
        }
      }
      // Push last segment
      result.add([currentWords..sort(), []]);
      return result;
    }

    final t1 = _tokenize(user);
    final t2 = _tokenize(target);

    if (t1.length != t2.length) return false;
    for (int i = 0; i < t1.length; i++) {
      // Compare separators
      if (t1[i][1].toString() != t2[i][1].toString()) return false;
      // Compare sorted words in segment
      final w1 = t1[i][0];
      final w2 = t2[i][0];
      if (w1.length != w2.length) return false;
      for (int j = 0; j < w1.length; j++) {
        if (w1[j] != w2[j]) return false;
      }
    }
    return true;
  }

  void _reset() {
    final rawPool = List<String>.from(widget.step.data['wordPool']);
    setState(() {
      _pool = rawPool.where((w) => w != '+' && w != '->' && w != '=>').toSet().toList()..shuffle();
      _sel = [];
      _checked = false;
      _ok = false;
      _hint = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final d = widget.step.data;
    final hint = d['hint'] as String?;
    return _MasteryGate(
      step: widget.step,
      s: s,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Badge(
                  label: 'Activity',
                  icon: '🧩',
                  color: const Color(0xFF3498DB),
                ),
                if (!_hint) _HintBtn(onTap: () => setState(() => _hint = true)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              d['title'] ?? '',
              style: TextStyle(
                color: s.text,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              d['instruction'] ?? '',
              style: TextStyle(color: s.sub, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 60),
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: s.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _checked
                      ? (_ok ? AppTheme.secondary : AppTheme.accent)
                      : AppTheme.primary.withOpacity(0.35),
                  width: 2,
                ),
              ),
              // Auto-render: show content words with auto '+' between them,
              // '->' shown as a styled divider token
              child: _sel.isEmpty
                  ? Center(
                      child: Text(
                        'Aşağıdan kelimeleri seç',
                        style: TextStyle(color: s.sub, fontSize: 12),
                      ),
                    )
                  : Wrap(
                      spacing: 4,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: () {
                        final widgets = <Widget>[];
                        for (int i = 0; i < _sel.length; i++) {
                          final token = _sel[i];
                          final isArrow = token == '->';
                          // Auto '+' before a content word (if previous was also content)
                          if (i > 0 && !isArrow && _sel[i - 1] != '->') {
                            widgets.add(
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                child: Text(
                                  '+',
                                  style: TextStyle(
                                    color: s.sub,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          }
                          widgets.add(
                            GestureDetector(
                              onTap: () => _rem(i),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isArrow ? 14 : 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isArrow
                                      ? const Color(0xFFE67E22).withOpacity(0.18)
                                      : AppTheme.primary.withOpacity(0.16),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isArrow
                                        ? const Color(0xFFE67E22)
                                        : AppTheme.primary,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      isArrow ? '→' : token,
                                      style: TextStyle(
                                        color: isArrow
                                            ? const Color(0xFFE67E22)
                                            : s.text,
                                        fontWeight: FontWeight.bold,
                                        fontSize: isArrow ? 14 : 11,
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    Icon(
                                      Icons.close_rounded,
                                      color: s.sub,
                                      size: 11,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                        return widgets;
                      }(),
                    ),
            ),
            const SizedBox(height: 14),
            Text(
              'Kelime Havuzu',
              style: TextStyle(
                color: s.sub,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 7),
            _ShakeW(
              shake: _checked && !_ok,
              ctrl: _shake,
              child: Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  // Content word chips
                  ..._pool.map(
                    (w) => GestureDetector(
                      onTap: () => _add(w),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
                          ),
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3498DB).withOpacity(0.26),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          w,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Arrow divider button (only if correctSequence has '->')
                  if (_hasArrow && !_sel.contains('->'))
                    GestureDetector(
                      onTap: _addArrow,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE67E22), Color(0xFFD35400)],
                          ),
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE67E22).withOpacity(0.3),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          '→ Ayraç',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (_hint && hint != null) _Hint(hint: '💡 $hint', tc: s.text),
            if (_checked) ...[
              const SizedBox(height: 16),
              _Explain(
                ok: _ok,
                text: _ok
                    ? (widget.step.data['explanation'] ??
                          'Harika! Doğru sıralama. 🎉')
                    : (widget.step.data['explanation'] ??
                          'Sanki bir şeyler yanlış yerde — tekrar dene!'),
                tc: s.text,
              ),
              if (_ok) ...[
                _BigBtn(label: 'Bitir →', onTap: s.onNext),
              ] else ...[
                const SizedBox(height: 16),
                _BigBtn(
                  label: 'Tekrar Dene ↻',
                  onTap: _reset,
                  color: AppTheme.accent,
                ),
              ],
            ] else ...[
              if (_sel.isNotEmpty)
                _BigBtn(
                  label: 'Kontrol Et ✓',
                  onTap: _check,
                  color: const Color(0xFFE67E22),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// STEP: SUMMARY
// ════════════════════════════════════════════════════════════
class _SummaryStep extends StatefulWidget {
  final StepV3 step;
  final _S s;
  final LessonV3 lesson;
  const _SummaryStep({
    required this.step,
    required this.s,
    required this.lesson,
  });
  @override
  State<_SummaryStep> createState() => _SummaryState();
}

class _SummaryState extends State<_SummaryStep> with TickerProviderStateMixin {
  late final AnimationController _badge = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final AnimationController _conf = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();
  late final Animation<double> _sc = Tween<double>(
    begin: 0.0,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _badge, curve: Curves.elasticOut));
  final List<_Conf> _parts = [];

  @override
  void initState() {
    super.initState();
    final rng = Random();
    for (int i = 0; i < 35; i++) {
      _parts.add(
        _Conf(
          x: rng.nextDouble(),
          y: rng.nextDouble(),
          sz: rng.nextDouble() * 9 + 4,
          sp: rng.nextDouble() * 0.25 + 0.08,
          c: [
            AppTheme.primary,
            AppTheme.secondary,
            AppTheme.accent,
            AppTheme.gold,
          ][rng.nextInt(4)],
        ),
      );
    }
    Future.delayed(const Duration(milliseconds: 200), () => _badge.forward());
    _saveStats();
  }

  Future<void> _saveStats() async {
    final g = widget.s.game;
    await _supabase.upsert('lesson_stats', {
      'lesson_id': widget.lesson.id,
      'score': g.score,
      'max_streak': g.maxStreak,
      'elapsed_seconds': g.elapsed.inSeconds,
      'badge': g.badgeLabel,
    });
  }

  @override
  void dispose() {
    _badge.dispose();
    _conf.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final g = s.game;
    final d = widget.step.data;
    final pts = List<String>.from(d['points'] ?? []);
    final el = g.elapsed;
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _conf,
          builder: (_, __) => CustomPaint(
            painter: _ConfPainter(_parts, _conf.value),
            size: Size.infinite,
          ),
        ),
        SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 10),
              ScaleTransition(
                scale: _sc,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.gold.withOpacity(0.5),
                        blurRadius: 22,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      g.badgeEmoji,
                      style: const TextStyle(fontSize: 58),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                g.badgeLabel,
                style: const TextStyle(
                  color: AppTheme.gold,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                d['title'] ?? '',
                style: TextStyle(
                  color: s.text,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // stat row
              Row(
                children: [
                  _SC(
                    icon: '⭐',
                    label: 'Score',
                    val: '${g.score}',
                    color: AppTheme.gold,
                    card: s.card,
                    tc: s.text,
                    sub: s.sub,
                  ),
                  const SizedBox(width: 9),
                  _SC(
                    icon: '🔥',
                    label: 'Streak',
                    val: '${g.maxStreak}x',
                    color: AppTheme.accent,
                    card: s.card,
                    tc: s.text,
                    sub: s.sub,
                  ),
                  const SizedBox(width: 9),
                  _SC(
                    icon: '⏱️',
                    label: 'Time',
                    val: '${el.inMinutes}m ${el.inSeconds % 60}s',
                    color: AppTheme.primary,
                    card: s.card,
                    tc: s.text,
                    sub: s.sub,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: s.card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What You Learned 📖',
                      style: TextStyle(
                        color: s.text,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...pts.map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 5),
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppTheme.secondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                p,
                                style: TextStyle(
                                  color: s.sub,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _BigBtn(
                label: '🔁 Restart Lesson',
                onTap: () {},
                color: AppTheme.secondary,
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// MOCK AD SCREEN
// ════════════════════════════════════════════════════════════
class _AdScreen extends StatefulWidget {
  final VoidCallback onDone;
  final bool isDark;
  const _AdScreen({required this.onDone, required this.isDark});
  @override
  State<_AdScreen> createState() => _AdScreenState();
}

class _AdScreenState extends State<_AdScreen> {
  int _rem = 5;
  Timer? _t;
  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_rem <= 1) {
        t.cancel();
        widget.onDone();
      } else {
        setState(() => _rem--);
      }
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final tc = widget.isDark ? Colors.white : const Color(0xFF1A1A2E);
    return Material(
      color: bg,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: double.infinity,
                  height: 210,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🎬', style: TextStyle(fontSize: 56)),
                      SizedBox(height: 10),
                      Text(
                        'Advertisement',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Your ad appears here',
                        style: TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                const Text('❤️❤️❤️', style: TextStyle(fontSize: 30)),
                const SizedBox(height: 10),
                Text(
                  'You ran out of lives!',
                  style: TextStyle(
                    color: tc,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Watch to earn 3 lives back',
                  style: TextStyle(color: tc.withOpacity(0.55), fontSize: 13),
                ),
                const SizedBox(height: 26),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 26,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accent.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    'Resuming in ${_rem}s...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// FALLBACK
// ════════════════════════════════════════════════════════════
class _FallbackStep extends StatelessWidget {
  final _S s;
  const _FallbackStep({required this.s});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🚧', style: TextStyle(fontSize: 52)),
        const SizedBox(height: 12),
        Text(
          'Step coming soon!',
          style: TextStyle(color: s.text, fontSize: 15),
        ),
        const SizedBox(height: 18),
        _BigBtn(label: 'Next →', onTap: s.onNext),
      ],
    ),
  );
}

// ════════════════════════════════════════════════════════════
// SMALL REUSABLE WIDGETS
// ════════════════════════════════════════════════════════════
class _BigBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _BigBtn({
    required this.label,
    required this.onTap,
    this.color = AppTheme.primary,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.70)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 9,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}

class _HintBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _HintBtn({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.gold.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.gold, width: 1),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('💡', style: TextStyle(fontSize: 12)),
            SizedBox(width: 4),
            Text(
              'İpucu Al',
              style: TextStyle(
                color: AppTheme.gold,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label, icon;
  final Color color;
  const _Badge({required this.label, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: color.withOpacity(0.35)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

class _Hint extends StatelessWidget {
  final String hint;
  final Color tc;
  const _Hint({required this.hint, required this.tc});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: AppTheme.gold.withOpacity(0.09),
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: AppTheme.gold.withOpacity(0.32)),
    ),
    child: Text(hint, style: TextStyle(color: tc, fontSize: 12, height: 1.4)),
  );
}

class _Explain extends StatelessWidget {
  final bool ok;
  final String text;
  final Color tc;
  const _Explain({required this.ok, required this.text, required this.tc});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: (ok ? AppTheme.secondary : AppTheme.accent).withOpacity(0.11),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: ok ? AppTheme.secondary : AppTheme.accent,
        width: 1.5,
      ),
    ),
    child: Row(
      children: [
        Text(ok ? '🎉' : '❌', style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: tc,
              fontSize: 15,
              height: 1.55,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _QProg extends StatelessWidget {
  final int idx, total;
  final Color color;
  const _QProg({required this.idx, required this.total, required this.color});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        'Q${idx + 1}/$total',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(width: 7),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: (idx + 1) / total,
            minHeight: 4,
            backgroundColor: Colors.black12,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ),
    ],
  );
}

class _Bubble extends StatelessWidget {
  final String lbl;
  final bool answered, correct;
  const _Bubble({
    required this.lbl,
    required this.answered,
    required this.correct,
  });
  @override
  Widget build(BuildContext context) => Container(
    width: 28,
    height: 28,
    decoration: BoxDecoration(
      color: answered && correct
          ? AppTheme.secondary
          : AppTheme.primary.withOpacity(0.13),
      shape: BoxShape.circle,
    ),
    child: Center(
      child: answered && correct
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
          : Text(
              lbl,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
    ),
  );
}

class _TFBtn extends StatelessWidget {
  final String lbl, emoji;
  final Color color;
  final bool sel, wrong;
  final VoidCallback onTap;
  const _TFBtn({
    required this.lbl,
    required this.emoji,
    required this.color,
    required this.sel,
    required this.wrong,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      height: 92,
      decoration: BoxDecoration(
        color: sel
            ? color.withOpacity(0.16)
            : wrong
            ? AppTheme.accent.withOpacity(0.16)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: sel
              ? color
              : wrong
              ? AppTheme.accent
              : Colors.grey.withOpacity(0.28),
          width: 2.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 5),
          Text(
            lbl,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    ),
  );
}

class _SC extends StatelessWidget {
  final String icon, label, val;
  final Color color, card, tc, sub;
  const _SC({
    required this.icon,
    required this.label,
    required this.val,
    required this.color,
    required this.card,
    required this.tc,
    required this.sub,
  });
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 3),
          Text(
            val,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          Text(label, style: TextStyle(color: sub, fontSize: 9)),
        ],
      ),
    ),
  );
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final Color color, bg;
  final VoidCallback onTap;
  const _Btn({
    required this.icon,
    required this.color,
    required this.bg,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.09),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 16),
    ),
  );
}

class _LivesBadge extends StatelessWidget {
  final int lives;
  final Color bg;
  const _LivesBadge({required this.lives, required this.bg});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (i) =>
            Text(i < lives ? '❤️' : '🖤', style: const TextStyle(fontSize: 13)),
      ),
    ),
  );
}

class _ScorePill extends StatelessWidget {
  final int score;
  const _ScorePill({required this.score});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
      ),
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: AppTheme.gold.withOpacity(0.28),
          blurRadius: 5,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('⭐', style: TextStyle(fontSize: 11)),
        const SizedBox(width: 3),
        Text(
          '$score',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

// ════════════════════════════════════════════════════════════
// STREAK BANNER
// ════════════════════════════════════════════════════════════
class _StreakBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Positioned(
    top: 100,
    left: 0,
    right: 0,
    child: Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 380),
        builder: (_, v, child) => Opacity(
          opacity: v,
          child: Transform.scale(scale: v, child: child),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B35), Color(0xFFFF0000)],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.38),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🔥', style: TextStyle(fontSize: 22)),
              SizedBox(width: 7),
              Text(
                '3x Streak!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 5),
              Text('🔥', style: TextStyle(fontSize: 22)),
            ],
          ),
        ),
      ),
    ),
  );
}

// ════════════════════════════════════════════════════════════
// SHAKE WIDGET
// ════════════════════════════════════════════════════════════
class _ShakeW extends StatelessWidget {
  final Widget child;
  final bool shake;
  final AnimationController ctrl;
  const _ShakeW({required this.child, required this.shake, required this.ctrl});
  @override
  Widget build(BuildContext context) {
    if (!shake) return child;
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, ch) => Transform.translate(
        offset: Offset(sin(ctrl.value * pi * 6) * 7, 0),
        child: ch,
      ),
      child: child,
    );
  }
}

// ════════════════════════════════════════════════════════════
// FLOATING +SCORE
// ════════════════════════════════════════════════════════════
class _FloatingScore {
  final int points, id;
  _FloatingScore(this.points, this.id);
}

class _FloatingScoreWidget extends StatefulWidget {
  final _FloatingScore score;
  const _FloatingScoreWidget({required this.score});
  @override
  State<_FloatingScoreWidget> createState() => _FSState();
}

class _FSState extends State<_FloatingScoreWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  );
  late final Animation<double> _op = Tween<double>(
    begin: 1.0,
    end: 0.0,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  late final Animation<Offset> _pos = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(0, -65),
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  @override
  void initState() {
    super.initState();
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Positioned(
    right: 20,
    top: 125,
    child: AnimatedBuilder(
      animation: _c,
      builder: (_, ch) => Opacity(
        opacity: _op.value,
        child: Transform.translate(offset: _pos.value, child: ch),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.gold,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: AppTheme.gold.withOpacity(0.38), blurRadius: 6),
          ],
        ),
        child: Text(
          '+${widget.score.points}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    ),
  );
}

// ════════════════════════════════════════════════════════════
// CONFETTI
// ════════════════════════════════════════════════════════════
class _Conf {
  final double x, y, sz, sp;
  final Color c;
  _Conf({
    required this.x,
    required this.y,
    required this.sz,
    required this.sp,
    required this.c,
  });
}

class _ConfPainter extends CustomPainter {
  final List<_Conf> ps;
  final double prog;
  _ConfPainter(this.ps, this.prog);
  @override
  void paint(Canvas canvas, Size size) {
    for (final p in ps) {
      canvas.drawCircle(
        Offset(p.x * size.width, ((p.y + prog * p.sp) % 1.0) * size.height),
        p.sz / 2,
        Paint()..color = p.c.withOpacity(0.68),
      );
    }
  }

  @override
  bool shouldRepaint(_) => true;
}

// ════════════════════════════════════════════════════════════
// HELPERS
// ════════════════════════════════════════════════════════════
Color? _hex(String? h) {
  if (h == null) return null;
  final c = h.replaceAll('#', '');
  return c.length == 6 ? Color(int.parse('FF$c', radix: 16)) : null;
}
