import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
import 'lesson_data.dart';
import 'models.dart';
import 'screens.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
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

  @override
  void initState() {
    super.initState();
    _lessonLoadFuture = loadLessonDataFromJsonAsset(kDefaultLessonAssetPath);
  }

  void _complete() {
    final step = lessonSteps[_stepIdx];
    if (_completedStepIds.contains(step.id)) return;
    _completedStepIds.add(step.id);
    final earned = step.xp;

    if (step.type == 'quiz') _earnedBadges.add('security_master');
    if (step.type == 'scenario_choice' || step.type == 'role_play') {
      _earnedBadges.add('detective');
    }
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
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted) setState(() => _showXPToast = false);
      });
    }
  }

  void _awardBadge(String id) {
    setState(() => _earnedBadges.add(id));
  }

  void _restart() {
    setState(() {
      _stepIdx = 0;
      _xp = 0;
      _earnedBadges.clear();
      _earnedBadges.add('digital_citizen');
      _completedStepIds.clear();
    });
  }

  // ── Yardımcılar ─────────────────────────────────────────────────────────────
  Map<String, dynamic> _contentOf(LessonStep step) =>
      (step.data['content'] as Map<String, dynamic>?) ?? <String, dynamic>{};
  Map<String, dynamic> _activitiesOf(LessonStep step) =>
      (step.data['activities'] as Map<String, dynamic>?) ?? <String, dynamic>{};
  Map<String, dynamic> _assessmentOf(LessonStep step) =>
      (step.data['assessment'] as Map<String, dynamic>?) ?? <String, dynamic>{};
  Map<String, dynamic> _teacherNotesOf(LessonStep step) =>
      (step.data['teacher_notes'] as Map<String, dynamic>?) ?? <String, dynamic>{};

  List<String> _stringList(dynamic raw) {
    return (raw as List<dynamic>? ?? const <dynamic>[])
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  List<String> _miniGameOptions(List<Map<String, dynamic>> items) {
    final explicit = items
        .expand(
          (item) => (item['options'] as List<dynamic>? ?? const <dynamic>[])
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
    if (derived.length == 1) return <String>[derived.first, 'Emin değilim'];
    return const <String>['Evet', 'Hayır'];
  }

  List<ConceptItem> _conceptItemsFromStep(LessonStep step) {
    final cards = (_activitiesOf(step)['cards'] as List<dynamic>? ?? const []);
    return cards
        .map((c) {
          if (c is Map<String, dynamic>) {
            final title = (c['item'] ?? c['title'] ?? '').toString();
            final desc =
                (c['label'] ?? c['type'] ?? c['description'] ?? '').toString();
            return ConceptItem(
              icon: '🧩',
              title: title.isEmpty ? 'Kart' : title,
              desc: desc.isEmpty ? title : desc,
            );
          }
          final text = c.toString();
          return ConceptItem(icon: '🧩', title: text, desc: text);
        })
        .where((e) => e.title.trim().isNotEmpty)
        .toList();
  }

  // ── Step rengi & emojisi (header için) ──────────────────────────────────────
  Color _stepColor(String type) {
    switch (type) {
      case 'intro':           return AppTheme.intro;
      case 'concept_cards':   return AppTheme.concept;
      case 'risk_analysis':   return AppTheme.risk;
      case 'scenario_choice': return AppTheme.scenario;
      case 'role_play':       return AppTheme.scenario;
      case 'mini_game':       return AppTheme.game;
      case 'word_bank':       return AppTheme.word;
      case 'quiz':            return AppTheme.quiz;
      case 'critical_thinking': return AppTheme.quiz;
      case 'summary':         return AppTheme.primary;
      case 'reflection':      return AppTheme.reflect;
      case 'certificate':     return AppTheme.cert;
      default:                return AppTheme.primary;
    }
  }

  String _stepEmoji(String type) {
    switch (type) {
      case 'intro':           return '🚀';
      case 'concept_cards':   return '📚';
      case 'risk_analysis':   return '⚠️';
      case 'scenario_choice': return '🎯';
      case 'role_play':       return '🎭';
      case 'mini_game':       return '🎮';
      case 'word_bank':       return '🧩';
      case 'quiz':            return '❓';
      case 'critical_thinking': return '🧠';
      case 'summary':         return '📋';
      case 'reflection':      return '🌱';
      case 'certificate':     return '🏆';
      default:                return '📖';
    }
  }

  // ── Step widget yönlendirici ─────────────────────────────────────────────────
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
          items: _conceptItemsFromStep(step),
          title: (step.data['title'] ?? '').toString(),
          onComplete: _complete,
        );

      case 'word_bank':
        final wordBank =
            (activities['word_bank'] as Map<String, dynamic>?) ?? <String, dynamic>{};
        final words = _stringList(wordBank['words']);
        final template = (wordBank['template'] ?? '').toString();
        final blanks =
            (wordBank['blanks'] as List<dynamic>? ?? const <dynamic>[])
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
          template: template,
          words: words,
          blanks: blanks,
          onComplete: _complete,
        );

      case 'risk_analysis':
        return InfoListScreen(
          items: (activities['cards'] as List<dynamic>? ?? const [])
              .map((e) {
                if (e is Map<String, dynamic>) {
                  return InfoItem(
                    text: (e['item'] ?? '').toString(),
                    example: (e['label'] ?? '').toString(),
                  );
                }
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
        final scenario = (activities['scenario'] ?? '').toString();
        final choices =
            (activities['choices'] as List<dynamic>? ?? const <dynamic>[])
                .whereType<Map<String, dynamic>>()
                .toList();
        final options = choices
            .map((e) => (e['text'] ?? '').toString())
            .where((e) => e.trim().isNotEmpty)
            .toList();
        final feedbacks = choices.map((e) => (e['feedback'] ?? '').toString()).toList();
        final correct = choices.indexWhere((e) => e['correct'] == true);
        return ScenarioChoiceScreen(
          context: scenario,
          question: (content['explanation'] ?? 'Doğru seçimi yap.').toString(),
          options: options,
          correct: correct < 0 ? 0 : correct,
          feedbacks: feedbacks,
          explanation: _stringList(
                    assessment['evaluation_tasks'] ?? activities['evaluation_tasks'],
                  ).join('\n').trim().isEmpty
              ? 'Açıklamayı tartışalım.'
              : _stringList(
                  assessment['evaluation_tasks'] ?? activities['evaluation_tasks'],
                ).join('\n'),
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
          description: (content['explanation'] ?? 'Durumları değerlendir.').toString(),
        );

      case 'quiz':
        final qs =
            ((assessment['quiz_questions'] ?? activities['quiz_questions'])
                        as List<dynamic>? ??
                    const <dynamic>[])
                .whereType<Map<String, dynamic>>()
                .toList();
        final parsedQuestions = qs.map((q) {
          final question = (q['question'] ?? '').toString();
          final opts = (q['options'] as List<dynamic>? ?? const <dynamic>[])
              .map((e) => e.toString())
              .toList();
          final correct = (q['correct_answer'] ?? '').toString();
          var ans = opts.indexOf(correct);
          if (ans < 0) ans = 0;
          return QuizQuestion(
            q: question,
            exp: 'Doğru cevap: $correct',
            opts: opts.isEmpty ? <String>['Seçenek yok'] : opts,
            ans: ans,
          );
        }).toList();
        return MultiQuizScreen(
          questions: parsedQuestions.isNotEmpty
              ? parsedQuestions
              : const [QuizQuestion(q: 'Soru bulunamadı', exp: '', opts: [], ans: 0)],
          onComplete: _complete,
          onBadge: _awardBadge,
        );

      case 'security_score':
        final choices = (activities['choices'] as List<dynamic>? ?? const []);
        final questions = choices
            .map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .map((e) => ScoreQuestion(text: e, icon: '🧪', points: 10))
            .toList();
        return SecurityScoreScreen(onComplete: _complete, questions: questions);

      case 'summary':
        final points = _stringList(
          activities['summary_points'] ?? content['key_points'],
        );
        return InfographicScreen(
          onComplete: _complete,
          points: points,
          title: (step.data['title'] ?? 'Ders Özeti').toString(),
          description: (content['explanation'] ?? '').toString(),
        );

      case 'reflection':
        final prompts = _stringList(
          activities['discussion_prompts'] ?? assessment['reflective_questions'],
        );
        return ReflectionScreen(
          onComplete: _complete,
          questions: prompts,
          title: (step.data['title'] ?? 'Kendini Değerlendir').toString(),
          intro: (content['explanation'] ?? '').toString(),
          note: _stringList(activities['evaluation_tasks']).join('\n').trim().isEmpty
              ? 'Öğrendiklerini kendi cümlelerinle tekrar etmeyi dene.'
              : _stringList(activities['evaluation_tasks']).join('\n'),
        );

      case 'critical_thinking':
        final prompts = _stringList(
          activities['discussion_prompts'] ?? assessment['evaluation_tasks'],
        );
        final hints = _stringList(content['key_points']);
        final discussion = _stringList(teacherNotes['classroom_discussion']);
        final tasks = _stringList(
          activities['evaluation_tasks'] ?? assessment['evaluation_tasks'],
        );
        return CriticalThinkingScreen(
          onComplete: _complete,
          prompts: prompts,
          title: (step.data['title'] ?? 'Kritik Düşünme').toString(),
          hints: hints.isNotEmpty ? hints : defaultCriticalHints,
          discussion: discussion.isNotEmpty ? discussion : defaultCriticalDiscussion,
          tasks: tasks,
        );

      case 'certificate':
        final msg = (activities['certificate_message'] ?? 'Tebrikler!').toString();
        final takeaways = _stringList(content['key_points'] ?? content['examples']);
        return CertificateScreen(
          xp: _xp,
          onRestart: _restart,
          title: (step.data['title'] ?? 'Tebrikler!').toString(),
          message: msg,
          takeaways: takeaways.isNotEmpty ? takeaways : defaultTakeaways,
        );

      default:
        return Center(
          child: Text(
            'Desteklenmeyen adım tipi: ${step.type}',
            style: const TextStyle(color: AppTheme.textMuted),
          ),
        );
    }
  }

  // ── Header ───────────────────────────────────────────────────────────────────
  Widget _buildHeader(double pct) {
    final step = lessonSteps.isNotEmpty ? lessonSteps[_stepIdx] : null;
    final stepColor = _stepColor(step?.type ?? '');

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: stepColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _stepEmoji(step?.type ?? ''),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lessonTitle,
                        style: const TextStyle(
                          color: AppTheme.textBody,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Adım ${_stepIdx + 1} / ${lessonSteps.length}',
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                XpChip(xp: _xp),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 7,
                backgroundColor: AppTheme.border,
                color: stepColor,
              ),
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
              child: CircularProgressIndicator(color: AppTheme.primary),
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

        final safeStepCount = lessonSteps.length <= 1 ? 1 : lessonSteps.length - 1;
        final pct = _stepIdx / safeStepCount;

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

// ─── XP TOAST ─────────────────────────────────────────────────────────────────
class _XPToast extends StatefulWidget {
  final int amount;
  const _XPToast({required this.amount});

  @override
  State<_XPToast> createState() => _XPToastState();
}

class _XPToastState extends State<_XPToast> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();
    _opacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.6, 1)),
    );
    _slide = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -0.8)).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: AppTheme.certGrad,
          borderRadius: BorderRadius.circular(99),
          boxShadow: [
            BoxShadow(
              color: AppTheme.cert.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⚡', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              '+${widget.amount} XP',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
