import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'theme.dart';
import 'theme.dart' as lesson_theme;
import 'lesson_data.dart';
import 'models.dart';
import 'screens.dart';

final FontSizeNotifier _fontSizeNotifier = lesson_theme.fontSizeNotifier;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const LessonApp());
}

class LessonApp extends StatelessWidget {
  const LessonApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Ders',
    theme: AppTheme.theme,
    debugShowCheckedModeBanner: false,
    home: const LessonPage(),
  );
}

// ─── LESSON PAGE ──────────────────────────────────────────────────────────────
class LessonPage extends StatefulWidget {
  const LessonPage({super.key});
  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  late final Future<void> _lessonLoadFuture;
  int _stepIdx = 0;
  int _xp = 0;
  final Set<String> _earnedBadges = {'digital_citizen'};
  final Set<String> _completedStepIds = {};
  bool _showXPToast = false;
  int _toastAmount = 0;

  // ── Müzik ─────────────────────────────────────────────────────────────────
  // assets/audio/ klasörüne koyduğun mp3 dosyasının adını buraya yaz:
  static const String _musicAsset = 'audio/bg_music.mp3';

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _musicOn = false; // varsayılan: sessiz

  @override
  void initState() {
    super.initState();
    _lessonLoadFuture = loadLessonDataFromJsonAsset(kDefaultLessonAssetPath);
    _startMusic();
  }

  Future<void> _startMusic() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.setVolume(0.35);
    await _audioPlayer.play(AssetSource(_musicAsset));
    await _audioPlayer.pause(); // varsayılan: durdurulmuş
  }

  Future<void> _toggleMusic() async {
    if (_musicOn) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
    setState(() => _musicOn = !_musicOn);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // ── Ders tamamlama ─────────────────────────────────────────────────────────
  void _complete() {
    final step = lessonSteps[_stepIdx];
    if (_completedStepIds.contains(step.id)) return;
    _completedStepIds.add(step.id);
    final earned = step.xp;

    if (step.type == 'quiz') _earnedBadges.add('security_master');
    if (step.type == 'scenario_choice' || step.type == 'role_play')
      _earnedBadges.add('detective');
    if (step.type == 'reflection') _earnedBadges.add('ethic_hacker');

    setState(() {
      _xp += earned;
      if (earned > 0) {
        _toastAmount = earned;
        _showXPToast = true;
      }
      if (_stepIdx < lessonSteps.length - 1) _stepIdx++;
    });

    if (earned > 0) {
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) setState(() => _showXPToast = false);
      });
    }
  }

  void _awardBadge(String id) => setState(() => _earnedBadges.add(id));

  void _restart() => setState(() {
    _stepIdx = 0;
    _xp = 0;
    _earnedBadges.clear();
    _earnedBadges.add('digital_citizen');
    _completedStepIds.clear();
  });

  // ── Yardımcılar ─────────────────────────────────────────────────────────────
  Map<String, dynamic> _contentOf(LessonStep s) =>
      (s.data['content'] as Map<String, dynamic>?) ?? {};
  Map<String, dynamic> _activitiesOf(LessonStep s) =>
      (s.data['activities'] as Map<String, dynamic>?) ?? {};
  Map<String, dynamic> _assessmentOf(LessonStep s) =>
      (s.data['assessment'] as Map<String, dynamic>?) ?? {};
  Map<String, dynamic> _teacherNotesOf(LessonStep s) =>
      (s.data['teacher_notes'] as Map<String, dynamic>?) ?? {};

  List<String> _strList(dynamic raw) => (raw as List<dynamic>? ?? [])
      .map((e) => e.toString().trim())
      .where((e) => e.isNotEmpty)
      .toList();

  List<String> _miniGameOptions(List<Map<String, dynamic>> items) {
    final explicit = items
        .expand(
          (item) => (item['options'] as List<dynamic>? ?? [])
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty),
        )
        .toSet()
        .toList();
    if (explicit.isNotEmpty) return explicit;
    final derived = items
        .map((item) => (item['correct_answer'] ?? '').toString().trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    if (derived.length >= 2) return derived;
    if (derived.length == 1) return [derived.first, 'Emin değilim'];
    return const ['Evet', 'Hayır'];
  }

  List<ConceptItem> _conceptItems(LessonStep step) =>
      (_activitiesOf(step)['cards'] as List<dynamic>? ?? [])
          .map((c) {
            if (c is Map<String, dynamic>) {
              final title = (c['item'] ?? c['title'] ?? '').toString();
              final desc = (c['label'] ?? c['type'] ?? c['description'] ?? '')
                  .toString();
              return ConceptItem(
                icon: '🧩',
                title: title.isEmpty ? 'Kart' : title,
                desc: desc.isEmpty ? title : desc,
              );
            }
            return ConceptItem(
              icon: '🧩',
              title: c.toString(),
              desc: c.toString(),
            );
          })
          .where((e) => e.title.trim().isNotEmpty)
          .toList();

  // ── Step rengi & emojisi ────────────────────────────────────────────────────
  Color _stepColor(String type) => switch (type) {
    'intro' => AppTheme.intro,
    'concept_cards' => AppTheme.concept,
    'risk_analysis' => AppTheme.risk,
    'scenario_choice' => AppTheme.scenario,
    'role_play' => AppTheme.scenario,
    'mini_game' => AppTheme.game,
    'word_bank' => AppTheme.word,
    'quiz' => AppTheme.quiz,
    'critical_thinking' => AppTheme.quiz,
    'summary' => AppTheme.primaryGlow,
    'reflection' => AppTheme.reflect,
    'certificate' => AppTheme.cert,
    _ => AppTheme.primaryGlow,
  };

  String _stepEmoji(String type) => switch (type) {
    'intro' => '🚀',
    'concept_cards' => '📚',
    'risk_analysis' => '⚠️',
    'scenario_choice' => '🎯',
    'role_play' => '🎭',
    'mini_game' => '🎮',
    'word_bank' => '🧩',
    'quiz' => '❓',
    'critical_thinking' => '🧠',
    'summary' => '📋',
    'reflection' => '🌱',
    'certificate' => '🏆',
    _ => '📖',
  };

  // ── Step yönlendirici ───────────────────────────────────────────────────────
  Widget _buildStep() {
    final step = lessonSteps[_stepIdx];
    final content = _contentOf(step);
    final activities = _activitiesOf(step);
    final assessment = _assessmentOf(step);
    final teacherNotes = _teacherNotesOf(step);

    switch (step.type) {
      case 'intro':
        return IntroScreen(
          onComplete: _complete,
          title: (step.data['title'] ?? '').toString(),
          content: (content['explanation'] ?? '').toString(),
        );

      case 'concept_cards':
        return ConceptCardsScreen(
          items: _conceptItems(step),
          title: (step.data['title'] ?? '').toString(),
          onComplete: _complete,
        );

      case 'word_bank':
        final wb = (activities['word_bank'] as Map<String, dynamic>?) ?? {};
        final blanks = (wb['blanks'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(
              (e) => WordBankBlank(
                id: (e['id'] ?? '').toString(),
                correctAnswer: (e['correct_answer'] ?? '').toString(),
              ),
            )
            .where((e) => e.correctAnswer.trim().isNotEmpty)
            .toList();
        return WordBankScreen(
          title: (step.data['title'] ?? 'Kelime Bankası').toString(),
          description: (content['explanation'] ?? '').toString(),
          template: (wb['template'] ?? '').toString(),
          words: _strList(wb['words']),
          blanks: blanks,
          onComplete: _complete,
        );

      case 'risk_analysis':
        return InfoListScreen(
          items: (activities['cards'] as List<dynamic>? ?? [])
              .map((e) {
                if (e is Map<String, dynamic>)
                  return InfoItem(
                    text: (e['item'] ?? '').toString(),
                    example: (e['label'] ?? '').toString(),
                  );
                return InfoItem(text: e.toString(), example: '');
              })
              .where((e) => e.text.trim().isNotEmpty)
              .toList(),
          title: (step.data['title'] ?? '').toString(),
          icon: '⚠️',
          color: AppTheme.risk,
          onComplete: _complete,
        );

      case 'scenario_choice':
        final choices = (activities['choices'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();
        final options = choices
            .map((e) => (e['text'] ?? '').toString())
            .where((e) => e.trim().isNotEmpty)
            .toList();
        final feedbacks = choices
            .map((e) => (e['feedback'] ?? '').toString())
            .toList();
        final correct = choices.indexWhere((e) => e['correct'] == true);
        final evalTasks = _strList(
          assessment['evaluation_tasks'] ?? activities['evaluation_tasks'],
        );
        return ScenarioChoiceScreen(
          context: (activities['scenario'] ?? '').toString(),
          question: (content['explanation'] ?? 'Doğru seçimi yap.').toString(),
          options: options,
          correct: correct < 0 ? 0 : correct,
          feedbacks: feedbacks,
          explanation: evalTasks.isEmpty
              ? 'Açıklamayı tartışalım.'
              : evalTasks.join('\n'),
          onComplete: _complete,
        );

      case 'role_play':
        final script = (activities['role_play'] as List<dynamic>? ?? [])
            .map((e) => Map<String, String>.from(e as Map))
            .toList();
        return RolePlayScreen(onComplete: _complete, script: script);

      case 'mini_game':
        final items = (activities['mini_game'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        return PermissionDetectiveScreen(
          onComplete: _complete,
          items: items,
          answerOptions: _miniGameOptions(items),
          title: (step.data['title'] ?? 'Mini Oyun').toString(),
          description: (content['explanation'] ?? 'Durumları değerlendir.')
              .toString(),
        );

      case 'quiz':
        final qs =
            ((assessment['quiz_questions'] ?? activities['quiz_questions'])
                        as List<dynamic>? ??
                    [])
                .whereType<Map<String, dynamic>>()
                .toList();
        final parsed = qs.map((q) {
          final opts = (q['options'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toList();
          final correct = (q['correct_answer'] ?? '').toString();
          var ans = opts.indexOf(correct);
          if (ans < 0) ans = 0;
          return QuizQuestion(
            q: (q['question'] ?? '').toString(),
            exp: 'Doğru: $correct',
            opts: opts.isEmpty ? ['Seçenek yok'] : opts,
            ans: ans,
          );
        }).toList();
        return MultiQuizScreen(
          questions: parsed.isNotEmpty
              ? parsed
              : [
                  const QuizQuestion(
                    q: 'Soru bulunamadı',
                    exp: '',
                    opts: [],
                    ans: 0,
                  ),
                ],
          onComplete: _complete,
          onBadge: _awardBadge,
        );

      case 'security_score':
        final questions = (activities['choices'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .map((e) => ScoreQuestion(text: e, icon: '🧪', points: 10))
            .toList();
        return SecurityScoreScreen(onComplete: _complete, questions: questions);

      case 'summary':
        return InfographicScreen(
          onComplete: _complete,
          points: _strList(
            activities['summary_points'] ?? content['key_points'],
          ),
          title: (step.data['title'] ?? 'Ders Özeti').toString(),
          description: (content['explanation'] ?? '').toString(),
        );

      case 'reflection':
        final evalTasks = _strList(activities['evaluation_tasks']);
        return ReflectionScreen(
          onComplete: _complete,
          questions: _strList(
            activities['discussion_prompts'] ??
                assessment['reflective_questions'],
          ),
          title: (step.data['title'] ?? 'Kendini Değerlendir').toString(),
          intro: (content['explanation'] ?? '').toString(),
          note: evalTasks.isEmpty
              ? 'Öğrendiklerini kendi cümlelerinle tekrar etmeyi dene.'
              : evalTasks.join('\n'),
        );

      case 'critical_thinking':
        final hints = _strList(content['key_points']);
        final discussion = _strList(teacherNotes['classroom_discussion']);
        return CriticalThinkingScreen(
          onComplete: _complete,
          prompts: _strList(
            activities['discussion_prompts'] ?? assessment['evaluation_tasks'],
          ),
          title: (step.data['title'] ?? 'Kritik Düşünme').toString(),
          hints: hints.isNotEmpty ? hints : defaultCriticalHints,
          discussion: discussion.isNotEmpty
              ? discussion
              : defaultCriticalDiscussion,
          tasks: _strList(
            activities['evaluation_tasks'] ?? assessment['evaluation_tasks'],
          ),
        );

      case 'certificate':
        final takeaways = _strList(
          content['key_points'] ?? content['examples'],
        );
        return CertificateScreen(
          xp: _xp,
          onRestart: _restart,
          title: (step.data['title'] ?? 'Tebrikler!').toString(),
          message: (activities['certificate_message'] ?? 'Tebrikler!')
              .toString(),
          takeaways: takeaways.isNotEmpty ? takeaways : defaultTakeaways,
        );

      default:
        return Center(
          child: Text(
            'Desteklenmeyen adım: ${step.type}',
            style: const TextStyle(color: AppTheme.textMuted),
          ),
        );
    }
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(double pct) {
    final step = lessonSteps.isNotEmpty ? lessonSteps[_stepIdx] : null;
    final col = _stepColor(step?.type ?? '');

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          bottom: BorderSide(color: col.withValues(alpha: 0.3), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: col.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                // Step emoji kutusu
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: col.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: col.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: col.withValues(alpha: 0.35),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _stepEmoji(step?.type ?? ''),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),

                // Ders adı + adım sayacı
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lessonTitle,
                        style: TextStyle(
                          color: AppTheme.textBody,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          shadows: [
                            Shadow(
                              color: col.withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ADIM ${_stepIdx + 1} / ${lessonSteps.length}',
                        style: TextStyle(
                          color: col,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          shadows: [Shadow(color: col, blurRadius: 4)],
                        ),
                      ),
                    ],
                  ),
                ),

                // Font boyutu butonları
                _FontSizeButtons(color: col),
                const SizedBox(width: 8),

                // Müzik toggle butonu
                _MusicToggle(isOn: _musicOn, onTap: _toggleMusic, color: col),
                const SizedBox(width: 10),

                // XP chip
                XpChip(xp: _xp),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Neon progress bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Stack(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: pct.clamp(0.0, 1.0),
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [col, col.withValues(alpha: 0.6)],
                      ),
                      borderRadius: BorderRadius.circular(99),
                      boxShadow: [
                        BoxShadow(
                          color: col.withValues(alpha: 0.7),
                          blurRadius: 8,
                        ),
                        BoxShadow(
                          color: col.withValues(alpha: 0.3),
                          blurRadius: 16,
                        ),
                      ],
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

  // ── Ana build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _lessonLoadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            backgroundColor: AppTheme.bg,
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGlow),
            ),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: AppTheme.bg,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Ders yüklenemedi: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textMuted),
                ),
              ),
            ),
          );
        }
        if (lessonSteps.isEmpty) {
          return const Scaffold(
            body: Center(
              child: Text(
                'Ders adımları bulunamadı.',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            ),
          );
        }

        final safeCount = lessonSteps.length <= 1 ? 1 : lessonSteps.length - 1;
        final pct = _stepIdx / safeCount;

        return Scaffold(
          backgroundColor: AppTheme.bg,
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildHeader(pct),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        switchInCurve: Curves.easeOutQuart,
                        switchOutCurve: Curves.easeInQuart,
                        transitionBuilder: (child, anim) => SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.04, 0),
                            end: Offset.zero,
                          ).animate(anim),
                          child: FadeTransition(opacity: anim, child: child),
                        ),
                        child: KeyedSubtree(
                          key: ValueKey(_stepIdx),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 920),
                              child: _buildStep(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // XP toast
                if (_showXPToast)
                  Positioned(
                    top: 110,
                    right: 20,
                    child: _XPToast(amount: _toastAmount),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── FONT BOYUTU BUTONLARI ────────────────────────────────────────────────────
class _FontSizeButtons extends StatelessWidget {
  final Color color;
  const _FontSizeButtons({required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fontSizeNotifier,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FSBtn(
            label: 'A−',
            enabled: _fontSizeNotifier.canDecrease,
            color: color,
            onTap: () => _fontSizeNotifier.decrease(),
          ),
          const SizedBox(width: 4),
          _FSBtn(
            label: 'A+',
            enabled: _fontSizeNotifier.canIncrease,
            color: color,
            onTap: () => _fontSizeNotifier.increase(),
          ),
        ],
      ),
    );
  }
}

class _FSBtn extends StatelessWidget {
  final String label;
  final bool enabled;
  final Color color;
  final VoidCallback onTap;
  const _FSBtn({
    required this.label,
    required this.enabled,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: enabled ? color.withValues(alpha: 0.15) : AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: enabled ? color.withValues(alpha: 0.6) : AppTheme.border,
          width: 1.5,
        ),
        boxShadow: enabled
            ? [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 8)]
            : [],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: enabled ? color : AppTheme.muted,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          shadows: enabled ? [Shadow(color: color, blurRadius: 4)] : null,
        ),
      ),
    ),
  );
}

// ─── MÜZİK TOGGLE BUTONU ──────────────────────────────────────────────────────
class _MusicToggle extends StatelessWidget {
  final bool isOn;
  final VoidCallback onTap;
  final Color color;

  const _MusicToggle({
    required this.isOn,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isOn ? color.withValues(alpha: 0.15) : AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isOn ? color.withValues(alpha: 0.6) : AppTheme.border,
            width: 1.5,
          ),
          boxShadow: isOn
              ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10)]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(isOn ? '🔊' : '🔇', style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}

// ─── XP TOAST ─────────────────────────────────────────────────────────────────
class _XPToast extends StatefulWidget {
  final int amount;
  const _XPToast({required this.amount});
  @override
  State<_XPToast> createState() => _XPToastState();
}

class _XPToastState extends State<_XPToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..forward();
    _opacity = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.55, 1)));
    _slide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1.0),
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.15), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SlideTransition(
    position: _slide,
    child: FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            gradient: AppTheme.certGrad,
            borderRadius: BorderRadius.circular(99),
            boxShadow: [
              BoxShadow(
                color: AppTheme.cert.withValues(alpha: 0.7),
                blurRadius: 20,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: AppTheme.cert.withValues(alpha: 0.3),
                blurRadius: 40,
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⚡', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                '+${widget.amount} XP',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
