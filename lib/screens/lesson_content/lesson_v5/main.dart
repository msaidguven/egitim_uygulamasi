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
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const AiSecurityApp());
}

class AiSecurityApp extends StatelessWidget {
  const AiSecurityApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Yapay Zekâda Güvenlik',
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

  Map<String, dynamic> _contentOf(LessonStep step) =>
      (step.data['content'] as Map<String, dynamic>?) ?? <String, dynamic>{};
  Map<String, dynamic> _activitiesOf(LessonStep step) =>
      (step.data['activities'] as Map<String, dynamic>?) ?? <String, dynamic>{};
  Map<String, dynamic> _assessmentOf(LessonStep step) =>
      (step.data['assessment'] as Map<String, dynamic>?) ?? <String, dynamic>{};
  Map<String, dynamic> _teacherNotesOf(LessonStep step) =>
      (step.data['teacher_notes'] as Map<String, dynamic>?) ??
      <String, dynamic>{};

  List<String> _stringList(dynamic raw) {
    return (raw as List<dynamic>? ?? const <dynamic>[])
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  List<String> _miniGameOptions(List<Map<String, dynamic>> items) {
    final explicitOptions = items
        .expand(
          (item) => (item['options'] as List<dynamic>? ?? const <dynamic>[])
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty),
        )
        .toSet()
        .toList();
    if (explicitOptions.isNotEmpty) return explicitOptions;

    final derivedOptions = items
        .map((item) => (item['correct_answer'] ?? '').toString().trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    if (derivedOptions.length >= 2) return derivedOptions;
    if (derivedOptions.length == 1) {
      return <String>[derivedOptions.first, 'Emin değilim'];
    }
    return const <String>['Evet', 'Hayır'];
  }

  List<ConceptItem> _conceptItemsFromStep(LessonStep step) {
    final cards = (_activitiesOf(step)['cards'] as List<dynamic>? ?? const []);
    return cards
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
          final text = c.toString();
          return ConceptItem(icon: '🧩', title: text, desc: text);
        })
        .where((e) => e.title.trim().isNotEmpty)
        .toList();
  }

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
            (activities['word_bank'] as Map<String, dynamic>?) ??
            <String, dynamic>{};
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
          color: const Color(0xFFF59E0B),
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
        final feedbacks = choices
            .map((e) => (e['feedback'] ?? '').toString())
            .toList();
        final correct = choices.indexWhere((e) => e['correct'] == true);
        return ScenarioChoiceScreen(
          context: scenario,
          question: (content['explanation'] ?? 'Dogru secimi yap.').toString(),
          options: options,
          correct: correct < 0 ? 0 : correct,
          feedbacks: feedbacks,
          explanation:
              _stringList(
                assessment['evaluation_tasks'] ??
                    activities['evaluation_tasks'],
              ).join('\n').trim().isEmpty
              ? 'Aciklamayi tartisalim.'
              : _stringList(
                  assessment['evaluation_tasks'] ??
                      activities['evaluation_tasks'],
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
          description: (content['explanation'] ?? 'Durumlari degerlendir.')
              .toString(),
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
          final options = (q['options'] as List<dynamic>? ?? const <dynamic>[])
              .map((e) => e.toString())
              .toList();
          final correct = (q['correct_answer'] ?? '').toString();
          var ans = options.indexOf(correct);
          if (ans < 0) ans = 0;
          return QuizQuestion(
            q: question,
            exp: 'Doğru cevap: $correct',
            opts: options.isEmpty ? <String>['Seçenek yok'] : options,
            ans: ans,
          );
        }).toList();

        return MultiQuizScreen(
          questions: parsedQuestions.isNotEmpty
              ? parsedQuestions
              : const [
                  QuizQuestion(q: 'Soru bulunamadı', exp: '', opts: [], ans: 0),
                ],
          onComplete: _complete,
          onBadge: _awardBadge,
        );
      case 'security_score':
        final choices = (activities['choices'] as List<dynamic>? ?? const []);
        final questions = choices.isNotEmpty
            ? choices
                  .map((e) => e.toString())
                  .where((e) => e.trim().isNotEmpty)
                  .map((e) => ScoreQuestion(text: e, icon: '🧪', points: 10))
                  .toList()
            : <ScoreQuestion>[];
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
          activities['discussion_prompts'] ??
              assessment['reflective_questions'],
        );
        return ReflectionScreen(
          onComplete: _complete,
          questions: prompts,
          title: (step.data['title'] ?? 'Kendini Değerlendir').toString(),
          intro: (content['explanation'] ?? '').toString(),
          note:
              _stringList(
                activities['evaluation_tasks'],
              ).join('\n').trim().isEmpty
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
          discussion: discussion.isNotEmpty
              ? discussion
              : defaultCriticalDiscussion,
          tasks: tasks,
        );
      case 'certificate':
        final msg = (activities['certificate_message'] ?? 'Tebrikler!')
            .toString();
        final takeaways = _stringList(
          content['key_points'] ?? content['examples'],
        );
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
            'Desteklenmeyen adim tipi: ${step.type}',
            style: const TextStyle(color: Colors.white),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _lessonLoadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Ders yuklenemedi: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        if (lessonSteps.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('Ders adimlari bulunamadi.')),
          );
        }

        final safeStepCount = lessonSteps.length <= 1
            ? 1
            : lessonSteps.length - 1;
        final pct = _stepIdx / safeStepCount;
        return Scaffold(
          backgroundColor: AppTheme.surface,
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    // ── HEADER ──────────────────────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.card,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    '🛡️',
                                    style: TextStyle(fontSize: 20),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        lessonTitle,
                                        style: TextStyle(
                                          color: AppTheme.textBody,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Adim ${_stepIdx + 1} / ${lessonSteps.length}',
                                        style: const TextStyle(
                                          color: AppTheme.muted,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                XpChip(xp: _xp),
                              ],
                            ),
                          ),
                          // progress bar
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct,
                                backgroundColor: AppTheme.card,
                                color: AppTheme.primary,
                                minHeight: 6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ── CONTENT ─────────────────────────────────────────────────
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        switchInCurve: Curves.easeOutQuart,
                        switchOutCurve: Curves.easeInQuart,
                        transitionBuilder: (child, anim) => SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.05, 0),
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

                // ── XP TOAST ────────────────────────────────────────────────
                if (_showXPToast)
                  Positioned(
                    top: 110,
                    right: 24,
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

class _XPToastState extends State<_XPToast>
    with SingleTickerProviderStateMixin {
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
    _opacity = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.6, 1)));
    _slide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.8),
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGrad,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt, color: Colors.yellow, size: 24),
            const SizedBox(width: 8),
            Text(
              '+${widget.amount} XP',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
