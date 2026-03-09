import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'theme.dart';
import 'lesson_data.dart';
import 'models.dart';
import 'screens.dart';
import 'slide_screen.dart';

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

class LessonApp extends StatefulWidget {
  const LessonApp({super.key});
  @override
  State<LessonApp> createState() => _LessonAppState();
}

class _LessonAppState extends State<LessonApp> {
  @override
  void initState() {
    super.initState();
    themeNotifier.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Ders',
    theme: themeNotifier.isDark ? AppTheme.theme : AppTheme.lightTheme,
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

  // ── Müzik ──────────────────────────────────────────────────────────────────
  static const String _musicAsset = 'audio/bg_music.mp3';

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _musicOn = false;

  @override
  void initState() {
    super.initState();
    _lessonLoadFuture = loadLessonDataFromJsonAsset(kDefaultLessonAssetPath);
    _initMusic();
    themeNotifier.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _initMusic() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.setVolume(0.35);
    await _audioPlayer.play(AssetSource(_musicAsset));
    await _audioPlayer.pause();
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

  // ── Tamamlama ──────────────────────────────────────────────────────────────
  void _complete() {
    final step = lessonSteps[_stepIdx];
    if (_completedStepIds.contains(step.id)) {
      if (_stepIdx < lessonSteps.length - 1) {
        setState(() => _stepIdx++);
      }
      return;
    }
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
      Future.delayed(const Duration(milliseconds: 2200), () {
        if (mounted) setState(() => _showXPToast = false);
      });
    }
  }

  void _goPrevious() {
    if (_stepIdx <= 0) return;
    setState(() => _stepIdx--);
  }

  Future<void> _handleHeaderMenuAction(String value) async {
    switch (value) {
      case 'font_decrease':
        fontSizeNotifier.decrease();
        break;
      case 'font_increase':
        fontSizeNotifier.increase();
        break;
      case 'toggle_theme':
        themeNotifier.toggle();
        break;
      case 'toggle_music':
        await _toggleMusic();
        break;
    }
  }

  void _awardBadge(String id) => setState(() => _earnedBadges.add(id));

  void _restart() => setState(() {
    _stepIdx = 0;
    _xp = 0;
    _earnedBadges
      ..clear()
      ..add('digital_citizen');
    _completedStepIds.clear();
  });

  // ── Veri yardımcıları ──────────────────────────────────────────────────────
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

  /// JSON'daki content.slides listesini okur.
  /// Her eleman { "type": "...", "text": "..." } formatında olmalı.
  List<Map<String, String>> _slidesOf(LessonStep step) {
    final raw = _contentOf(step)['slides'];
    if (raw is! List) return [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(
          (e) => {
            'type': (e['type'] ?? 'fact').toString(),
            'text': (e['text'] ?? '').toString(),
          },
        )
        .where((e) => e['text']!.trim().isNotEmpty)
        .toList();
  }

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

  /// content.notebook alanından tanım ve maddeleri okur
  String _notebookDefinition(LessonStep step) {
    final nb = (_contentOf(step)['notebook'] as Map<String, dynamic>?) ?? {};
    return (nb['definition'] ?? '').toString().trim();
  }

  List<String> _notebookItems(LessonStep step) {
    final nb = (_contentOf(step)['notebook'] as Map<String, dynamic>?) ?? {};
    return _strList(nb['summary_items']);
  }

  // ── Renk & emoji ───────────────────────────────────────────────────────────
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

  // ── Step yönlendirici ──────────────────────────────────────────────────────
  Widget _buildStep() {
    final step = lessonSteps[_stepIdx];
    final content = _contentOf(step);
    final activities = _activitiesOf(step);
    final assessment = _assessmentOf(step);
    final teacherNotes = _teacherNotesOf(step);

    switch (step.type) {

      // ── INTRO ──────────────────────────────────────────────────────────────
      case 'intro':
        final slides = _slidesOf(step);
        if (slides.isNotEmpty) {
          return SlideStepScreen(
            slides: slides,
            accentColor: AppTheme.intro,
            accentColorLt: AppTheme.introLt,
            stepLabel: 'GİRİŞ',
            stepEmoji: '🚀',
            title: (step.data['title'] ?? '').toString(),
            onComplete: _complete,
          );
        }
        // Slides yoksa eski davranış (geriye dönük uyumluluk)
        return IntroScreen(
          onComplete: _complete,
          title: (step.data['title'] ?? '').toString(),
          content: (content['explanation'] ?? '').toString(),
        );

      // ── CONCEPT CARDS ───────────────────────────────────────────────────────
      case 'concept_cards':
        final slides = _slidesOf(step);
        final conceptItems = _conceptItems(step);
        final nbDef = _notebookDefinition(step);
        final nbItems = _notebookItems(step);
        if (slides.isNotEmpty) {
          return _SlidesThenCardsScreen(
            slides: slides,
            items: conceptItems,
            title: (step.data['title'] ?? '').toString(),
            onComplete: _complete,
            notebookDefinition: nbDef,
            notebookItems: nbItems,
          );
        }
        return ConceptCardsScreen(
          items: conceptItems,
          title: (step.data['title'] ?? '').toString(),
          onComplete: _complete,
          notebookDefinition: nbDef,
          notebookItems: nbItems,
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

      // ── SUMMARY ─────────────────────────────────────────────────────────────
      case 'summary':
        final slides = _slidesOf(step);
        if (slides.isNotEmpty) {
          return SlideStepScreen(
            slides: slides,
            accentColor: AppTheme.primaryGlow,
            accentColorLt: AppTheme.primaryLt,
            stepLabel: 'ÖZET',
            stepEmoji: '📋',
            title: (step.data['title'] ?? 'Ders Özeti').toString(),
            onComplete: _complete,
          );
        }
        // Slides yoksa eski davranış (geriye dönük uyumluluk)
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
        final tc = TC.of(context);
        return Center(
          child: Text(
            'Desteklenmeyen adım: ${step.type}',
            style: TextStyle(color: tc.textMuted),
          ),
        );
    }
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(double pct) {
    final step = lessonSteps.isNotEmpty ? lessonSteps[_stepIdx] : null;
    final col = _stepColor(step?.type ?? '');
    final tc = TC.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: tc.surface,
        border: Border(
          bottom: BorderSide(color: col.withValues(alpha: 0.4), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: col.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Row(
              children: [
                _HeaderIconButton(
                  icon: Icons.home_rounded,
                  color: col,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 8),
                _HeaderIconButton(
                  icon: Icons.arrow_back_rounded,
                  color: col,
                  onTap: _goPrevious,
                ),
                const SizedBox(width: 10),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: col.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: col.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _stepEmoji(step?.type ?? ''),
                    style: const TextStyle(fontSize: 19),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lessonTitle,
                        style: TextStyle(
                          color: tc.textBody,
                          fontWeight: FontWeight.w800,
                          fontSize: AppFS.labelLg,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'ADIM ${_stepIdx + 1} / ${lessonSteps.length}',
                        style: TextStyle(
                          color: col,
                          fontSize: AppFS.small,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedBuilder(
                  animation: fontSizeNotifier,
                  builder: (_, __) => XpChip(xp: _xp),
                ),
                const SizedBox(width: 8),
                _HeaderActionsMenu(
                  color: col,
                  musicOn: _musicOn,
                  canDecreaseFont: fontSizeNotifier.canDecrease,
                  canIncreaseFont: fontSizeNotifier.canIncrease,
                  isDark: tc.isDark,
                  onSelected: _handleHeaderMenuAction,
                ),
              ],
            ),
          ),

          // Progress bar
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
            child: Stack(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: tc.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                if (lessonSteps.isNotEmpty)
                  FractionallySizedBox(
                    widthFactor: (_stepIdx /
                            (lessonSteps.length <= 1
                                ? 1
                                : lessonSteps.length - 1))
                        .clamp(0.0, 1.0),
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [col, col.withValues(alpha: 0.6)],
                        ),
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: [
                          BoxShadow(
                            color: col.withValues(alpha: 0.6),
                            blurRadius: 8,
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

  // ── Ana build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final tc = TC.of(context);
    return FutureBuilder<void>(
      future: _lessonLoadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            backgroundColor: tc.bg,
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGlow),
            ),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: tc.bg,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Ders yüklenemedi:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: tc.textMuted),
                ),
              ),
            ),
          );
        }
        if (lessonSteps.isEmpty) {
          return Scaffold(
            body: Center(
              child: Text(
                'Ders adımları bulunamadı.',
                style: TextStyle(color: tc.textMuted),
              ),
            ),
          );
        }

        final stepType = lessonSteps[_stepIdx].type;
        return Scaffold(
          backgroundColor: tc.bg,
          body: SafeArea(
            child: Stack(
              children: [
                // Light temada: cıvıl gradyan arka plan
                if (!tc.isDark)
                  Positioned.fill(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      decoration: tc.pageDecoration(stepType),
                    ),
                  ),
                Column(
                  children: [
                    _buildHeader(
                      (_stepIdx /
                              (lessonSteps.length <= 1
                                  ? 1
                                  : lessonSteps.length - 1))
                          .clamp(0.0, 1.0),
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        switchInCurve: Curves.easeOutQuart,
                        switchOutCurve: Curves.easeInQuart,
                        transitionBuilder: (child, anim) => SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.03, 0),
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
                    top: 108,
                    right: 18,
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

// ─── SLIDES → KARTLAR (concept_cards için) ───────────────────────────────────
// Önce slide'ları gösterir, bittikten sonra kart grid'ine geçer.
class _SlidesThenCardsScreen extends StatefulWidget {
  final List<Map<String, String>> slides;
  final List<ConceptItem> items;
  final String title;
  final VoidCallback onComplete;
  final String notebookDefinition;
  final List<String> notebookItems;

  const _SlidesThenCardsScreen({
    required this.slides,
    required this.items,
    required this.title,
    required this.onComplete,
    this.notebookDefinition = '',
    this.notebookItems = const [],
  });

  @override
  State<_SlidesThenCardsScreen> createState() => _SlidesThenCardsState();
}

class _SlidesThenCardsState extends State<_SlidesThenCardsScreen> {
  bool _slidesDone = false;

  @override
  Widget build(BuildContext context) {
    if (!_slidesDone) {
      return SlideStepScreen(
        slides: widget.slides,
        accentColor: AppTheme.concept,
        accentColorLt: AppTheme.conceptLt,
        stepLabel: 'KAVRAMLAR',
        stepEmoji: '📚',
        title: widget.title,
        onComplete: () => setState(() => _slidesDone = true),
      );
    }
    return ConceptCardsScreen(
      items: widget.items,
      title: widget.title,
      onComplete: widget.onComplete,
      notebookDefinition: widget.notebookDefinition,
      notebookItems: widget.notebookItems,
    );
  }
}

// ─── FONT BOYUTU BUTONU ───────────────────────────────────────────────────────
class _FontSizeBtn extends StatelessWidget {
  final String label;
  final bool enabled;
  final Color color;
  final VoidCallback onTap;
  const _FontSizeBtn({
    required this.label,
    required this.enabled,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: AnimatedBuilder(
      animation: fontSizeNotifier,
      builder: (_, __) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled
              ? color.withValues(alpha: 0.15)
              : TC.of(context).surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled
                ? color.withValues(alpha: 0.6)
                : TC.of(context).border,
            width: 1.5,
          ),
          boxShadow: enabled
              ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8)]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: enabled ? color : TC.of(context).muted,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    ),
  );
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: TC.of(context).isDark ? 0.15 : 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 1.4),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: 20),
    ),
  );
}

class _HeaderActionsMenu extends StatelessWidget {
  final Color color;
  final bool musicOn;
  final bool canDecreaseFont;
  final bool canIncreaseFont;
  final bool isDark;
  final Future<void> Function(String value) onSelected;

  const _HeaderActionsMenu({
    required this.color,
    required this.musicOn,
    required this.canDecreaseFont,
    required this.canIncreaseFont,
    required this.isDark,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final tc = TC.of(context);
    return PopupMenuButton<String>(
      tooltip: 'Ayarlar',
      color: tc.surface,
      elevation: 18,
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      constraints: const BoxConstraints(minWidth: 250, maxWidth: 280),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: color.withValues(alpha: 0.35), width: 1.4),
      ),
      onSelected: (value) {
        onSelected(value);
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          height: 58,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.65)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.28),
                      blurRadius: 14,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.tune_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Kontrol Paneli',
                      style: TextStyle(
                        color: tc.textBody,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Ders arayuzunu buradan ayarla',
                      style: TextStyle(
                        color: tc.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'font_decrease',
          enabled: canDecreaseFont,
          height: 64,
          child: _HeaderMenuAction(
            icon: Icons.text_decrease_rounded,
            accent: AppTheme.quiz,
            title: 'Yaziyi Kucult',
            subtitle: 'Metni biraz daha kompakt yap',
            trailing: 'A-',
            enabled: canDecreaseFont,
          ),
        ),
        PopupMenuItem<String>(
          value: 'font_increase',
          enabled: canIncreaseFont,
          height: 64,
          child: _HeaderMenuAction(
            icon: Icons.text_increase_rounded,
            accent: AppTheme.intro,
            title: 'Yaziyi Buyut',
            subtitle: 'Okuma boyutunu bir kademe arttir',
            trailing: 'A+',
            enabled: canIncreaseFont,
          ),
        ),
        PopupMenuItem<String>(
          value: 'toggle_theme',
          height: 64,
          child: _HeaderMenuAction(
            icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            accent: AppTheme.word,
            title: isDark ? 'Light Temaya Gec' : 'Dark Temaya Gec',
            subtitle: isDark
                ? 'Daha acik ve ferah gorunum'
                : 'Daha derin oyun modu gorunumu',
            trailing: isDark ? '☀️' : '🌙',
            enabled: true,
          ),
        ),
        PopupMenuItem<String>(
          value: 'toggle_music',
          height: 64,
          child: _HeaderMenuAction(
            icon: musicOn ? Icons.volume_off_rounded : Icons.music_note_rounded,
            accent: AppTheme.concept,
            title: musicOn ? 'Muzigi Kapat' : 'Muzigi Ac',
            subtitle: musicOn
                ? 'Arka plan sesini durdur'
                : 'Arka plan sesini baslat',
            trailing: musicOn ? 'OFF' : 'ON',
            enabled: true,
          ),
        ),
      ],
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: tc.isDark
                ? [color.withValues(alpha: 0.22), color.withValues(alpha: 0.12)]
                : [Colors.white, color.withValues(alpha: 0.14)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.55), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.18),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.tune_rounded, color: color, size: 20),
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppTheme.cert,
                  shape: BoxShape.circle,
                  border: Border.all(color: tc.surface, width: 1.3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderMenuAction extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final String trailing;
  final bool enabled;

  const _HeaderMenuAction({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final tc = TC.of(context);
    final body = Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: tc.isDark ? 0.16 : 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: accent.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: accent, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: tc.textBody,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: tc.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: tc.isDark ? 0.18 : 0.10),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: accent.withValues(alpha: 0.32)),
          ),
          child: Text(
            trailing,
            style: TextStyle(
              color: accent,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ],
    );

    return Opacity(opacity: enabled ? 1 : 0.45, child: body);
  }
}

// ─── TEMA TOGGLE ☀️/🌙 ───────────────────────────────────────────────────────
class _ThemeToggle extends StatelessWidget {
  final Color color;
  const _ThemeToggle({required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = TC.of(context).isDark;
    return GestureDetector(
      onTap: themeNotifier.toggle,
      child: AnimatedBuilder(
        animation: themeNotifier,
        builder: (_, __) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isDark
                ? color.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: color.withValues(alpha: 0.55),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 8),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            isDark ? '☀️' : '🌙',
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}

// ─── MÜZİK TOGGLE ─────────────────────────────────────────────────────────────
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
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isOn ? color.withValues(alpha: 0.15) : TC.of(context).surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOn ? color.withValues(alpha: 0.6) : TC.of(context).border,
          width: 1.5,
        ),
        boxShadow: isOn
            ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8)]
            : [],
      ),
      alignment: Alignment.center,
      child: Text(isOn ? '🔊' : '🔇', style: const TextStyle(fontSize: 16)),
    ),
  );
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
      duration: const Duration(milliseconds: 2200),
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
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.15), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 55),
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
                color: AppTheme.cert.withValues(alpha: 0.6),
                blurRadius: 20,
                spreadRadius: 2,
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
              AnimatedBuilder(
                animation: fontSizeNotifier,
                builder: (_, __) => Text(
                  '+${widget.amount} XP',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: AppFS.body + 2,
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