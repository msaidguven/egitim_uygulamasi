// lesson_engine.dart
// Flutter Ders Motoru — lesson_engine.json dosyasını okur ve tüm step tiplerini render eder.
//
// KURULUM:
//   1. Bu dosyayı lib/ klasörüne koy.
//   2. lesson_engine.json dosyasını projenin assets/ klasörüne koy.
//   3. pubspec.yaml'a ekle:
//        flutter:
//          assets:
//            - assets/lesson_engine.json
//   4. pubspec.yaml dependencies:
//        flutter_markdown: ^0.6.18   (isteğe bağlı, açıklama metinleri için)
//
// ÇALIŞTIRMA:
//   main() içinde:  runApp(const LessonApp());

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────
// JSON LOADER
// ─────────────────────────────────────────────

class LessonV12Preview extends StatefulWidget {
  const LessonV12Preview({super.key});

  @override
  State<LessonV12Preview> createState() => _LessonV12PreviewState();
}

class _LessonV12PreviewState extends State<LessonV12Preview> {
  LessonData? _lesson;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLesson();
  }

  Future<void> _loadLesson() async {
    try {
      final raw = await rootBundle.loadString('assets/lessons/lesson_engine.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      setState(() {
        _lesson = LessonData.fromJson(json['lesson'] as Map<String, dynamic>);
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Hata: $_error',
                style: const TextStyle(color: Colors.red)),
          ),
        ),
      );
    }
    if (_lesson == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return LessonScreen(lesson: _lesson!);
  }
}

// ─────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────

class LessonData {
  final String grade, subject, unit, topic, title, description, difficultyLevel;
  final List<String> learningObjectives, keywords;
  final List<StepData> steps;

  LessonData({
    required this.grade,
    required this.subject,
    required this.unit,
    required this.topic,
    required this.title,
    required this.description,
    required this.difficultyLevel,
    required this.learningObjectives,
    required this.keywords,
    required this.steps,
  });

  factory LessonData.fromJson(Map<String, dynamic> j) => LessonData(
        grade: j['grade'] ?? '',
        subject: j['subject'] ?? '',
        unit: j['unit'] ?? '',
        topic: j['topic'] ?? '',
        title: j['title'] ?? '',
        description: j['description'] ?? '',
        difficultyLevel: j['difficulty_level'] ?? '',
        learningObjectives:
            List<String>.from(j['learning_objectives'] ?? []),
        keywords: List<String>.from(j['keywords'] ?? []),
        steps: (j['steps'] as List? ?? [])
            .map((s) => StepData.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}

class StepData {
  final String id, type, title;
  final int durationMinutes;
  final Map<String, dynamic> content;
  final Map<String, dynamic> activities;
  final Map<String, dynamic> assessment;
  final Map<String, dynamic> teacherNotes;

  StepData({
    required this.id,
    required this.type,
    required this.title,
    required this.durationMinutes,
    required this.content,
    required this.activities,
    required this.assessment,
    required this.teacherNotes,
  });

  factory StepData.fromJson(Map<String, dynamic> j) => StepData(
        id: j['id'] ?? '',
        type: j['type'] ?? '',
        title: j['title'] ?? '',
        durationMinutes: j['duration_minutes'] ?? 0,
        content: j['content'] as Map<String, dynamic>? ?? {},
        activities: j['activities'] as Map<String, dynamic>? ?? {},
        assessment: j['assessment'] as Map<String, dynamic>? ?? {},
        teacherNotes: j['teacher_notes'] as Map<String, dynamic>? ?? {},
      );
}

// ─────────────────────────────────────────────
// LESSON SCREEN — step listesi + progress
// ─────────────────────────────────────────────

class LessonScreen extends StatefulWidget {
  final LessonData lesson;
  const LessonScreen({super.key, required this.lesson});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  void _goTo(int index) {
    setState(() => _currentStep = index);
    _pageController.animateToPage(index,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut);
  }

  void _next() {
    if (_currentStep < widget.lesson.steps.length - 1) {
      _goTo(_currentStep + 1);
    }
  }

  void _prev() {
    if (_currentStep > 0) {
      _goTo(_currentStep - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final steps = lesson.steps;
    final step = steps[_currentStep];
    final color = _stepColor(step.type);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4FF),
      appBar: AppBar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lesson.title,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold)),
            Text('${lesson.grade} · ${lesson.subject}',
                style:
                    const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                '${_currentStep + 1}/${steps.length}',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / steps.length,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation(Colors.white),
          ),
        ),
      ),
      body: Column(
        children: [
          // Step chips
          _StepChipBar(
            steps: steps,
            current: _currentStep,
            onTap: _goTo,
          ),
          // Content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentStep = i),
              itemCount: steps.length,
              itemBuilder: (_, i) => _StepView(step: steps[i]),
            ),
          ),
          // Nav buttons
          _NavBar(
            onPrev: _currentStep > 0 ? _prev : null,
            onNext: _currentStep < steps.length - 1 ? _next : null,
            stepType: step.type,
          ),
        ],
      ),
      drawer: _LessonDrawer(lesson: lesson, onSelect: _goTo),
    );
  }
}

Color _stepColor(String type) {
  switch (type) {
    case 'intro':
      return const Color(0xFF5B4FCC);
    case 'concept_explanation':
      return const Color(0xFF1976D2);
    case 'scenario_activity':
      return const Color(0xFF00897B);
    case 'mini_game':
      return const Color(0xFFE53935);
    case 'critical_thinking':
      return const Color(0xFF6A1B9A);
    case 'word_bank':
      return const Color(0xFFF57C00);
    case 'risk_analysis':
      return const Color(0xFFAD1457);
    case 'quiz':
      return const Color(0xFF2E7D32);
    case 'summary':
      return const Color(0xFF37474F);
    case 'certificate':
      return const Color(0xFFFFB300);
    default:
      return const Color(0xFF546E7A);
  }
}

String _stepIcon(String type) {
  switch (type) {
    case 'intro':
      return '🚀';
    case 'concept_explanation':
      return '📖';
    case 'scenario_activity':
      return '🎭';
    case 'mini_game':
      return '🎮';
    case 'critical_thinking':
      return '🧠';
    case 'word_bank':
      return '📝';
    case 'risk_analysis':
      return '⚠️';
    case 'quiz':
      return '✅';
    case 'summary':
      return '📋';
    case 'certificate':
      return '🏆';
    default:
      return '📌';
  }
}

// ─────────────────────────────────────────────
// STEP CHIP BAR
// ─────────────────────────────────────────────

class _StepChipBar extends StatelessWidget {
  final List<StepData> steps;
  final int current;
  final ValueChanged<int> onTap;

  const _StepChipBar(
      {required this.steps, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        itemCount: steps.length,
        itemBuilder: (_, i) {
          final active = i == current;
          final color = _stepColor(steps[i].type);
          return GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: active ? color : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: active ? color : color.withOpacity(0.3)),
              ),
              child: Text(
                '${_stepIcon(steps[i].type)} ${i + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      active ? FontWeight.bold : FontWeight.normal,
                  color: active ? Colors.white : color,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// NAV BAR
// ─────────────────────────────────────────────

class _NavBar extends StatelessWidget {
  final VoidCallback? onPrev, onNext;
  final String stepType;

  const _NavBar(
      {required this.onPrev,
      required this.onNext,
      required this.stepType});

  @override
  Widget build(BuildContext context) {
    final color = _stepColor(stepType);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (onPrev != null)
            OutlinedButton.icon(
              onPressed: onPrev,
              icon: const Icon(Icons.arrow_back_ios, size: 14),
              label: const Text('Geri'),
              style: OutlinedButton.styleFrom(foregroundColor: color),
            ),
          const Spacer(),
          if (onNext != null)
            ElevatedButton.icon(
              onPressed: onNext,
              icon: const Text('İleri'),
              label: const Icon(Icons.arrow_forward_ios, size: 14),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: null,
              icon: const Text('Tamamlandı'),
              label: const Icon(Icons.check_circle, size: 14),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// LESSON DRAWER
// ─────────────────────────────────────────────

class _LessonDrawer extends StatelessWidget {
  final LessonData lesson;
  final ValueChanged<int> onSelect;

  const _LessonDrawer({required this.lesson, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF5B4FCC)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(lesson.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${lesson.grade} · ${lesson.subject}',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: lesson.keywords
                      .take(5)
                      .map((k) => Chip(
                            label: Text(k,
                                style: const TextStyle(fontSize: 9)),
                            backgroundColor: Colors.white24,
                            labelStyle:
                                const TextStyle(color: Colors.white),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            padding: EdgeInsets.zero,
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: lesson.steps.length,
              itemBuilder: (_, i) {
                final s = lesson.steps[i];
                final color = _stepColor(s.type);
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color,
                    radius: 14,
                    child: Text(_stepIcon(s.type),
                        style: const TextStyle(fontSize: 12)),
                  ),
                  title: Text(s.title,
                      style: const TextStyle(fontSize: 13)),
                  subtitle: Text(
                      '${s.type.replaceAll('_', ' ')} · ${s.durationMinutes} dk',
                      style:
                          const TextStyle(fontSize: 11, color: Colors.grey)),
                  onTap: () {
                    Navigator.pop(context);
                    onSelect(i);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// STEP VIEW — type'a göre doğru widget'ı render eder
// ─────────────────────────────────────────────

class _StepView extends StatelessWidget {
  final StepData step;
  const _StepView({required this.step});

  @override
  Widget build(BuildContext context) {
    return switch (step.type) {
      'intro' => _IntroStep(step: step),
      'concept_explanation' => _ConceptStep(step: step),
      'scenario_activity' => _ScenarioStep(step: step),
      'mini_game' => _MiniGameStep(step: step),
      'critical_thinking' => _CriticalThinkingStep(step: step),
      'word_bank' => _WordBankStep(step: step),
      'risk_analysis' => _RiskAnalysisStep(step: step),
      'quiz' => _QuizStep(step: step),
      'summary' => _SummaryStep(step: step),
      'certificate' => _CertificateStep(step: step),
      _ => _GenericStep(step: step),
    };
  }
}

// ─────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────

class _StepHeader extends StatelessWidget {
  final StepData step;
  const _StepHeader({required this.step});

  @override
  Widget build(BuildContext context) {
    final color = _stepColor(step.type);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        border: Border(bottom: BorderSide(color: color.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          Text(_stepIcon(step.type), style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.title,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color)),
                Text(
                    '${step.type.replaceAll('_', ' ')} · ⏱ ${step.durationMinutes} dk',
                    style:
                        const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _sectionTitle(String title, Color color) => Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      child: Row(children: [
        Container(width: 4, height: 18, color: color,
            margin: const EdgeInsets.only(right: 8)),
        Text(title,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color)),
      ]),
    );

Widget _card({required Widget child, Color? color}) => Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: color?.withOpacity(0.25) ?? Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: child,
    );

// ─────────────────────────────────────────────
// SLIDE VIEWER (intro / concept / summary ortak)
// ─────────────────────────────────────────────

class _SlideViewer extends StatefulWidget {
  final List slides;
  final Color color;
  const _SlideViewer({required this.slides, required this.color});

  @override
  State<_SlideViewer> createState() => _SlideViewerState();
}

class _SlideViewerState extends State<_SlideViewer> {
  int _index = 0;

  Color get _slideColor {
    final type = widget.slides[_index]['type'] as String? ?? '';
    return switch (type) {
      'hook' => const Color(0xFF7B1FA2),
      'fact' => const Color(0xFF1565C0),
      'analogy' => const Color(0xFF2E7D32),
      'example' => const Color(0xFFE65100),
      'key' => const Color(0xFF37474F),
      'bridge' => const Color(0xFF00695C),
      _ => widget.color,
    };
  }

  String get _slideEmoji {
    final type = widget.slides[_index]['type'] as String? ?? '';
    return switch (type) {
      'hook' => '🤔',
      'fact' => '📌',
      'analogy' => '🔗',
      'example' => '💡',
      'key' => '🗝️',
      'bridge' => '➡️',
      _ => '📄',
    };
  }

  @override
  Widget build(BuildContext context) {
    final slide = widget.slides[_index] as Map<String, dynamic>;
    final text = slide['text'] as String? ?? '';
    final type = slide['type'] as String? ?? '';
    final c = _slideColor;

    return Column(
      children: [
        // Slide content
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Container(
              key: ValueKey(_index),
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [c.withOpacity(0.08), c.withOpacity(0.02)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.withOpacity(0.3)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_slideEmoji,
                      style: const TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(type.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: Colors.grey.shade800),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Dot indicators + buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              // Prev
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _index > 0
                    ? () => setState(() => _index--)
                    : null,
                color: c,
              ),
              // Dots
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.slides.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _index ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _index
                            ? c
                            : c.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              // Next
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _index < widget.slides.length - 1
                    ? () => setState(() => _index++)
                    : null,
                color: c,
              ),
            ],
          ),
        ),
        // Slide counter
        Text(
          '${_index + 1} / ${widget.slides.length}',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// INTRO STEP
// ─────────────────────────────────────────────

class _IntroStep extends StatelessWidget {
  final StepData step;
  const _IntroStep({required this.step});

  @override
  Widget build(BuildContext context) {
    final color = _stepColor(step.type);
    final slides = step.content['slides'] as List? ?? [];
    final prompts = step.activities['discussion_prompts'] as List? ?? [];

    return SingleChildScrollView(
      child: Column(
        children: [
          _StepHeader(step: step),
          if (slides.isNotEmpty)
            SizedBox(
              height: 320,
              child: _SlideViewer(slides: slides, color: color),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (prompts.isNotEmpty) ...[
                  _sectionTitle('💬 Tartışma Soruları', color),
                  ...prompts.map((p) => _card(
                        color: color,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('❓',
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(p.toString(),
                                  style: const TextStyle(
                                      fontSize: 13, height: 1.5)),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CONCEPT EXPLANATION STEP
// ─────────────────────────────────────────────

class _ConceptStep extends StatefulWidget {
  final StepData step;
  const _ConceptStep({required this.step});

  @override
  State<_ConceptStep> createState() => _ConceptStepState();
}

class _ConceptStepState extends State<_ConceptStep>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.step;
    final color = _stepColor(step.type);
    final slides = step.content['slides'] as List? ?? [];
    final explanation = step.content['explanation'] as String? ?? '';
    final keyPoints = step.content['key_points'] as List? ?? [];
    final examples = step.content['examples'] as List? ?? [];
    final realLife = step.content['real_life_connections'] as List? ?? [];
    final notebook = step.content['notebook'] as Map<String, dynamic>?;
    final cards = step.activities['cards'] as List? ?? [];

    return Column(
      children: [
        _StepHeader(step: step),
        TabBar(
          controller: _tabs,
          labelColor: color,
          unselectedLabelColor: Colors.grey,
          indicatorColor: color,
          labelStyle:
              const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Slaytlar'),
            Tab(text: 'Açıklama'),
            Tab(text: 'Defter'),
            Tab(text: 'Kartlar'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              // TAB 1: Slides
              slides.isNotEmpty
                  ? _SlideViewer(slides: slides, color: color)
                  : const Center(child: Text('Slayt yok')),

              // TAB 2: Explanation + key points + examples + real life
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (explanation.isNotEmpty) ...[
                      _sectionTitle('📖 Açıklama', color),
                      _card(
                        color: color,
                        child: Text(explanation,
                            style: const TextStyle(
                                fontSize: 13, height: 1.7)),
                      ),
                    ],
                    if (keyPoints.isNotEmpty) ...[
                      _sectionTitle('🗝️ Temel Noktalar', color),
                      ...keyPoints.map((kp) => _card(
                            color: color,
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.circle,
                                    size: 8, color: color),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(kp.toString(),
                                        style: const TextStyle(
                                            fontSize: 12,
                                            height: 1.5))),
                              ],
                            ),
                          )),
                    ],
                    if (examples.isNotEmpty) ...[
                      _sectionTitle('💡 Örnekler', color),
                      ...examples.map((e) => _card(
                            color: color,
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text('🔍',
                                    style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(e.toString(),
                                        style: const TextStyle(
                                            fontSize: 12,
                                            height: 1.5))),
                              ],
                            ),
                          )),
                    ],
                    if (realLife.isNotEmpty) ...[
                      _sectionTitle('🌍 Gerçek Hayat Bağlantıları', color),
                      ...realLife.map((r) => _card(
                            color: color,
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text('🔗',
                                    style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(r.toString(),
                                        style: const TextStyle(
                                            fontSize: 12,
                                            height: 1.5))),
                              ],
                            ),
                          )),
                    ],
                  ],
                ),
              ),

              // TAB 3: Notebook
              notebook != null
                  ? _NotebookView(notebook: notebook, color: color)
                  : const Center(child: Text('Defter notu yok')),

              // TAB 4: Cards
              cards.isNotEmpty
                  ? _CardGrid(cards: cards, color: color)
                  : const Center(child: Text('Kart yok')),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// NOTEBOOK VIEW
// ─────────────────────────────────────────────

class _NotebookView extends StatelessWidget {
  final Map<String, dynamic> notebook;
  final Color color;
  const _NotebookView({required this.notebook, required this.color});

  @override
  Widget build(BuildContext context) {
    final definition = notebook['definition'] as String? ?? '';
    final sections = notebook['sections'] as List? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Definition box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.4), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Text('📓', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text('Tanım',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: color)),
                ]),
                const SizedBox(height: 8),
                Text(definition,
                    style: const TextStyle(
                        fontSize: 13,
                        height: 1.6,
                        fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Sections
          ...sections.map((s) {
            final sec = Map<String, dynamic>.from(s as Map);
            final title = sec['title'] as String? ?? '';
            final items = sec['items'] as List? ?? [];
            final note = sec['note'] as String?;
            return _card(
              color: color,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: color)),
                  const Divider(height: 12),
                  ...items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('▸',
                                style: TextStyle(
                                    color: color, fontSize: 12)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(item.toString(),
                                  style: const TextStyle(
                                      fontSize: 12, height: 1.5)),
                            ),
                          ],
                        ),
                      )),
                  if (note != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(children: [
                        const Text('💡', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 6),
                        Expanded(
                            child: Text(note,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.brown))),
                      ]),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CARD GRID (concept kartları)
// ─────────────────────────────────────────────

class _CardGrid extends StatefulWidget {
  final List cards;
  final Color color;
  const _CardGrid({required this.cards, required this.color});

  @override
  State<_CardGrid> createState() => _CardGridState();
}

class _CardGridState extends State<_CardGrid> {
  final Set<int> _flipped = {};

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemCount: widget.cards.length,
      itemBuilder: (_, i) {
        final card = Map<String, dynamic>.from(widget.cards[i] as Map);
        final label = card['label'] as String? ?? '';
        final item = card['item'] as String? ?? '';
        final flipped = _flipped.contains(i);

        return GestureDetector(
          onTap: () => setState(() {
            if (flipped) {
              _flipped.remove(i);
            } else {
              _flipped.add(i);
            }
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: flipped
                  ? widget.color
                  : widget.color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: widget.color.withOpacity(0.4), width: 1.5),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(flipped ? '📖' : '🃏',
                    style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 8),
                Text(
                  flipped ? item : label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: flipped ? 11 : 13,
                    fontWeight: flipped
                        ? FontWeight.normal
                        : FontWeight.bold,
                    color: flipped
                        ? Colors.white
                        : widget.color,
                    height: 1.4,
                  ),
                ),
                if (!flipped) ...[
                  const SizedBox(height: 6),
                  Text('Çevir →',
                      style: TextStyle(
                          fontSize: 9,
                          color: widget.color.withOpacity(0.6))),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// SCENARIO ACTIVITY STEP
// ─────────────────────────────────────────────

class _ScenarioStep extends StatefulWidget {
  final StepData step;
  const _ScenarioStep({required this.step});

  @override
  State<_ScenarioStep> createState() => _ScenarioStepState();
}

class _ScenarioStepState extends State<_ScenarioStep> {
  int? _selected;
  bool _answered = false;

  @override
  Widget build(BuildContext context) {
    final color = _stepColor(widget.step.type);
    final scenario =
        widget.step.activities['scenario'] as String? ?? '';
    final choices =
        widget.step.activities['choices'] as List? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(step: widget.step),
          const SizedBox(height: 12),
          // Scenario text
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Text('📋', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text('Senaryo',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: color)),
                ]),
                const SizedBox(height: 10),
                Text(scenario,
                    style:
                        const TextStyle(fontSize: 13, height: 1.6)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Cevabını seç:',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700)),
          const SizedBox(height: 8),
          // Choices
          ...List.generate(choices.length, (i) {
            final choice =
                Map<String, dynamic>.from(choices[i] as Map);
            final text = choice['text'] as String? ?? '';
            final correct = choice['correct'] as bool? ?? false;
            final feedback =
                choice['feedback'] as String? ?? '';

            Color? bgColor;
            if (_answered && _selected == i) {
              bgColor = correct
                  ? Colors.green.shade50
                  : Colors.red.shade50;
            } else if (_answered && correct) {
              bgColor = Colors.green.shade50;
            }

            return GestureDetector(
              onTap: _answered
                  ? null
                  : () => setState(() {
                        _selected = i;
                        _answered = true;
                      }),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bgColor ?? Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _answered
                        ? (correct
                            ? Colors.green
                            : (_selected == i
                                ? Colors.red
                                : Colors.grey.shade200))
                        : (_selected == i
                            ? color
                            : Colors.grey.shade200),
                    width: _selected == i ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(
                        _answered
                            ? (correct
                                ? Icons.check_circle
                                : (_selected == i
                                    ? Icons.cancel
                                    : Icons.radio_button_unchecked))
                            : (_selected == i
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked),
                        color: _answered
                            ? (correct
                                ? Colors.green
                                : (_selected == i
                                    ? Colors.red
                                    : Colors.grey))
                            : (_selected == i ? color : Colors.grey),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(text,
                              style: const TextStyle(
                                  fontSize: 13, height: 1.4))),
                    ]),
                    if (_answered &&
                        (_selected == i || correct) &&
                        feedback.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: correct
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(feedback,
                            style: TextStyle(
                                fontSize: 11,
                                color: correct
                                    ? Colors.green.shade800
                                    : Colors.red.shade800,
                                height: 1.4)),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
          if (_answered) ...[
            const SizedBox(height: 12),
            Center(
              child: OutlinedButton.icon(
                onPressed: () =>
                    setState(() {
                      _selected = null;
                      _answered = false;
                    }),
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar Dene'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: color),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// MINI GAME STEP
// ─────────────────────────────────────────────

class _MiniGameStep extends StatefulWidget {
  final StepData step;
  const _MiniGameStep({required this.step});

  @override
  State<_MiniGameStep> createState() => _MiniGameStepState();
}

class _MiniGameStepState extends State<_MiniGameStep> {
  int _current = 0;
  bool _showAnswer = false;
  int _correct = 0;
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    final color = _stepColor(widget.step.type);
    final items =
        widget.step.activities['mini_game'] as List? ?? [];

    if (items.isEmpty) {
      return const Center(child: Text('Oyun verisi yok'));
    }
    if (_done) {
      return _GameResult(
          correct: _correct,
          total: items.length,
          color: color,
          onRestart: () => setState(() {
                _current = 0;
                _correct = 0;
                _done = false;
                _showAnswer = false;
              }));
    }

    final item = Map<String, dynamic>.from(items[_current] as Map);
    final situation = item['situation'] as String? ?? '';
    final answer = item['correct_answer'] as String? ?? '';
    final feedback = item['feedback'] as String? ?? '';

    return SingleChildScrollView(
      child: Column(
        children: [
          _StepHeader(step: widget.step),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Score bar
                Row(children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: _current / items.length,
                      backgroundColor: color.withOpacity(0.2),
                      color: color,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('$_current/${items.length}',
                      style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 20),
                // Situation
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Column(children: [
                    Text('🎮',
                        style: const TextStyle(fontSize: 32)),
                    const SizedBox(height: 12),
                    Text(situation,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 14, height: 1.6)),
                  ]),
                ),
                const SizedBox(height: 20),
                // Show answer / next
                if (!_showAnswer)
                  ElevatedButton.icon(
                    onPressed: () =>
                        setState(() => _showAnswer = true),
                    icon: const Icon(Icons.visibility),
                    label: const Text('Cevabı Gör'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        minimumSize:
                            const Size(double.infinity, 44)),
                  )
                else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.green.shade300),
                    ),
                    child: Column(children: [
                      Text('✅ Doğru Cevap',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700)),
                      const SizedBox(height: 6),
                      Text(answer,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800)),
                      if (feedback.isNotEmpty) ...[
                        const Divider(height: 12),
                        Text(feedback,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                                height: 1.4)),
                      ],
                    ]),
                  ),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final next = _current + 1;
                          setState(() {
                            _showAnswer = false;
                            if (next >= items.length) {
                              _done = true;
                            } else {
                              _current = next;
                            }
                          });
                        },
                        icon: const Icon(Icons.close),
                        label: const Text('Bilemedim'),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final next = _current + 1;
                          setState(() {
                            _correct++;
                            _showAnswer = false;
                            if (next >= items.length) {
                              _done = true;
                            } else {
                              _current = next;
                            }
                          });
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Bildim!'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white),
                      ),
                    ),
                  ]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GameResult extends StatelessWidget {
  final int correct, total;
  final Color color;
  final VoidCallback onRestart;
  const _GameResult(
      {required this.correct,
      required this.total,
      required this.color,
      required this.onRestart});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (correct / total * 100).round() : 0;
    final emoji = pct >= 80 ? '🏆' : pct >= 60 ? '👍' : '📚';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text('$correct / $total doğru',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 8),
            Text('%$pct başarı',
                style: const TextStyle(
                    fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRestart,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Oyna'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: color, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CRITICAL THINKING STEP
// ─────────────────────────────────────────────

class _CriticalThinkingStep extends StatelessWidget {
  final StepData step;
  const _CriticalThinkingStep({required this.step});

  @override
  Widget build(BuildContext context) {
    final color = _stepColor(step.type);
    final prompts =
        step.activities['discussion_prompts'] as List? ?? [];
    final tasks =
        step.activities['evaluation_tasks'] as List? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(step: step),
          const SizedBox(height: 12),
          if (prompts.isNotEmpty) ...[
            _sectionTitle('🧠 Düşünme Soruları', color),
            ...List.generate(prompts.length, (i) => _card(
                  color: color,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: color,
                        child: Text('${i + 1}',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(prompts[i].toString(),
                            style: const TextStyle(
                                fontSize: 13, height: 1.6)),
                      ),
                    ],
                  ),
                )),
          ],
          if (tasks.isNotEmpty) ...[
            _sectionTitle('📝 Değerlendirme Görevleri', color),
            ...List.generate(tasks.length, (i) => _card(
                  color: color,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('✏️',
                          style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(tasks[i].toString(),
                            style: const TextStyle(
                                fontSize: 13, height: 1.6)),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// WORD BANK STEP
// ─────────────────────────────────────────────

class _WordBankStep extends StatefulWidget {
  final StepData step;
  const _WordBankStep({required this.step});

  @override
  State<_WordBankStep> createState() => _WordBankStepState();
}

class _WordBankStepState extends State<_WordBankStep> {
  final Map<String, String?> _answers = {};
  bool _checked = false;

  List<String> get _words {
    final wb = widget.step.activities['word_bank']
        as Map<String, dynamic>?;
    return List<String>.from(wb?['words'] ?? []);
  }

  List<Map<String, dynamic>> get _blanks {
    final wb = widget.step.activities['word_bank']
        as Map<String, dynamic>?;
    return (wb?['blanks'] as List? ?? [])
        .map((b) => b as Map<String, dynamic>)
        .toList();
  }

  String get _template {
    final wb = widget.step.activities['word_bank']
        as Map<String, dynamic>?;
    return wb?['template'] as String? ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final color = _stepColor(widget.step.type);
    final words = _words;
    final blanks = _blanks;

    // Build template parts
    final parts = _template.split(RegExp(r'_{2,}'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(step: widget.step),
          const SizedBox(height: 12),

          // Word chips
          _sectionTitle('🔤 Kelime Bankası', color),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: words.map((w) {
              final used =
                  _answers.values.contains(w);
              return GestureDetector(
                onTap: used
                    ? null
                    : () {
                        // Find first unfilled blank
                        for (final b in blanks) {
                          final id = b['id'] as String;
                          if (_answers[id] == null) {
                            setState(() =>
                                _answers[id] = w);
                            break;
                          }
                        }
                      },
                child: AnimatedContainer(
                  duration:
                      const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: used
                        ? Colors.grey.shade200
                        : color.withOpacity(0.12),
                    borderRadius:
                        BorderRadius.circular(20),
                    border: Border.all(
                        color: used
                            ? Colors.grey.shade300
                            : color.withOpacity(0.4)),
                  ),
                  child: Text(w,
                      style: TextStyle(
                          fontSize: 13,
                          color: used
                              ? Colors.grey
                              : color,
                          decoration: used
                              ? TextDecoration.lineThrough
                              : null)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Template with blanks
          _sectionTitle('📝 Cümleyi Tamamla', color),
          _card(
            color: color,
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (int i = 0; i < parts.length; i++) ...[
                  Text(parts[i],
                      style: const TextStyle(
                          fontSize: 13, height: 1.8)),
                  if (i < blanks.length)
                    _BlankChip(
                      blankId:
                          blanks[i]['id'] as String,
                      answer: _answers[
                          blanks[i]['id'] as String],
                      correct: _checked
                          ? (_answers[blanks[i]['id']
                                  as String] ==
                              blanks[i]['correct_answer'])
                          : null,
                      onTap: _answers[blanks[i]['id']
                                  as String] !=
                              null
                          ? () => setState(() => _answers
                              .remove(blanks[i]['id']
                                  as String))
                          : null,
                      color: color,
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Check / Reset
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() {
                  _answers.clear();
                  _checked = false;
                }),
                icon: const Icon(Icons.refresh),
                label: const Text('Sıfırla'),
                style:
                    OutlinedButton.styleFrom(foregroundColor: color),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _answers.length < blanks.length
                    ? null
                    : () => setState(() => _checked = true),
                icon: const Icon(Icons.check),
                label: const Text('Kontrol Et'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white),
              ),
            ),
          ]),
          if (_checked) ...[
            const SizedBox(height: 12),
            _card(
              color: color,
              child: Row(children: [
                Icon(
                  _answers.entries.every((e) {
                    final blank = blanks.firstWhere(
                        (b) => b['id'] == e.key,
                        orElse: () => {});
                    return e.value ==
                        blank['correct_answer'];
                  })
                      ? Icons.celebration
                      : Icons.info_outline,
                  color: color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    () {
                      int c = 0;
                      for (final b in blanks) {
                        if (_answers[b['id']] ==
                            b['correct_answer']) c++;
                      }
                      return '$c/${blanks.length} doğru!';
                    }(),
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color),
                  ),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }
}

class _BlankChip extends StatelessWidget {
  final String blankId;
  final String? answer;
  final bool? correct;
  final VoidCallback? onTap;
  final Color color;

  const _BlankChip(
      {required this.blankId,
      this.answer,
      this.correct,
      this.onTap,
      required this.color});

  @override
  Widget build(BuildContext context) {
    Color bgColor = color.withOpacity(0.1);
    Color borderColor = color.withOpacity(0.5);
    if (correct == true) {
      bgColor = Colors.green.shade100;
      borderColor = Colors.green;
    } else if (correct == false) {
      bgColor = Colors.red.shade100;
      borderColor = Colors.red;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        constraints: const BoxConstraints(minWidth: 60),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Text(
          answer ?? '____',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: answer != null ? Colors.black87 : Colors.grey,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// RISK ANALYSIS STEP
// ─────────────────────────────────────────────

class _RiskAnalysisStep extends StatefulWidget {
  final StepData step;
  const _RiskAnalysisStep({required this.step});

  @override
  State<_RiskAnalysisStep> createState() => _RiskAnalysisStepState();
}

class _RiskAnalysisStepState extends State<_RiskAnalysisStep> {
  int? _expanded;

  @override
  Widget build(BuildContext context) {
    final color = _stepColor(widget.step.type);
    final cards =
        widget.step.activities['cards'] as List? ?? [];

    return SingleChildScrollView(
      child: Column(
        children: [
          _StepHeader(step: widget.step),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('⚠️ Yaygın Yanılgılar', color),
                ...List.generate(cards.length, (i) {
                  final card =
                      Map<String, dynamic>.from(cards[i] as Map);
                  final misconception =
                      card['misconception'] as String? ?? '';
                  final riskLevel =
                      card['risk_level'] as String? ?? '';
                  final why =
                      card['why_it_happens'] as String? ?? '';
                  final truth =
                      card['truth'] as String? ?? '';
                  final fix =
                      card['fix_tip'] as String? ?? '';
                  final check =
                      card['mini_check'] as String? ?? '';
                  final isExpanded = _expanded == i;

                  final riskColor =
                      riskLevel.contains('yüksek')
                          ? Colors.red
                          : riskLevel.contains('orta')
                              ? Colors.orange
                              : Colors.green;

                  return GestureDetector(
                    onTap: () => setState(() =>
                        _expanded = isExpanded ? null : i),
                    child: Container(
                      margin:
                          const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(12),
                        border: Border.all(
                            color: isExpanded
                                ? color
                                : Colors.grey.shade200,
                            width: isExpanded ? 2 : 1),
                        boxShadow: [
                          BoxShadow(
                              color:
                                  Colors.black.withOpacity(0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(children: [
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3),
                                decoration: BoxDecoration(
                                  color: riskColor
                                      .withOpacity(0.15),
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: Text(riskLevel,
                                    style: TextStyle(
                                        fontSize: 9,
                                        color: riskColor,
                                        fontWeight:
                                            FontWeight.bold)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(misconception,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight:
                                            FontWeight.bold)),
                              ),
                              Icon(
                                  isExpanded
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  color: Colors.grey),
                            ]),
                          ),
                          if (isExpanded) ...[
                            const Divider(height: 1),
                            Padding(
                              padding:
                                  const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  _RiskRow('🤔 Neden Oluşur',
                                      why, Colors.orange),
                                  const SizedBox(height: 8),
                                  _RiskRow(
                                      '✅ Doğrusu',
                                      truth,
                                      Colors.green),
                                  const SizedBox(height: 8),
                                  _RiskRow(
                                      '🔧 Düzeltme İpucu',
                                      fix,
                                      Colors.blue),
                                  if (check.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding:
                                          const EdgeInsets.all(
                                              10),
                                      decoration:
                                          BoxDecoration(
                                        color: color
                                            .withOpacity(0.07),
                                        borderRadius:
                                            BorderRadius.circular(
                                                8),
                                        border: Border.all(
                                            color: color
                                                .withOpacity(
                                                    0.3)),
                                      ),
                                      child: Row(children: [
                                        const Text('❓',
                                            style: TextStyle(
                                                fontSize: 14)),
                                        const SizedBox(
                                            width: 8),
                                        Expanded(
                                            child: Text(check,
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    fontStyle:
                                                        FontStyle
                                                            .italic))),
                                      ]),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskRow extends StatelessWidget {
  final String label, text;
  final Color color;
  const _RiskRow(this.label, this.text, this.color);

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color)),
          const SizedBox(width: 6),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 12, height: 1.4))),
        ],
      );
}

// ─────────────────────────────────────────────
// QUIZ STEP
// ─────────────────────────────────────────────

class _QuizStep extends StatefulWidget {
  final StepData step;
  const _QuizStep({required this.step});

  @override
  State<_QuizStep> createState() => _QuizStepState();
}

class _QuizStepState extends State<_QuizStep> {
  int _current = 0;
  String? _selected;
  bool _answered = false;
  int _score = 0;
  bool _done = false;

  List<Map<String, dynamic>> get _questions {
    return (widget.step.activities['quiz_questions'] as List? ?? [])
        .map((q) => q as Map<String, dynamic>)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final color = _stepColor(widget.step.type);
    final questions = _questions;
    if (questions.isEmpty) {
      return const Center(child: Text('Quiz sorusu yok'));
    }
    if (_done) {
      return _QuizResult(
          score: _score,
          total: questions.length,
          color: color,
          onRestart: () => setState(() {
                _current = 0;
                _selected = null;
                _answered = false;
                _score = 0;
                _done = false;
              }));
    }

    final q = questions[_current];
    final question = q['question'] as String? ?? '';
    final options =
        List<String>.from(q['options'] as List? ?? []);
    final correctAnswer = q['correct_answer'] as String? ?? '';
    final solution = q['solution_text'] as String? ?? '';

    return Column(
      children: [
        _StepHeader(step: widget.step),
        // Progress
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 8),
          child: Row(children: [
            Expanded(
              child: LinearProgressIndicator(
                value: (_current + 1) / questions.length,
                backgroundColor: color.withOpacity(0.2),
                color: color,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 10),
            Text('${_current + 1}/${questions.length}',
                style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.bold)),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Text(question,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          height: 1.6)),
                ),
                const SizedBox(height: 14),
                // Options
                ...options.map((opt) {
                  Color? bg;
                  Color? border;
                  if (_answered) {
                    if (opt == correctAnswer) {
                      bg = Colors.green.shade50;
                      border = Colors.green;
                    } else if (opt == _selected) {
                      bg = Colors.red.shade50;
                      border = Colors.red;
                    }
                  } else if (opt == _selected) {
                    bg = color.withOpacity(0.1);
                    border = color;
                  }

                  return GestureDetector(
                    onTap: _answered
                        ? null
                        : () => setState(() => _selected = opt),
                    child: Container(
                      margin:
                          const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: bg ?? Colors.white,
                        borderRadius:
                            BorderRadius.circular(10),
                        border: Border.all(
                            color: border ??
                                Colors.grey.shade200,
                            width: border != null ? 2 : 1),
                      ),
                      child: Row(children: [
                        Icon(
                          _answered
                              ? (opt == correctAnswer
                                  ? Icons.check_circle
                                  : (opt == _selected
                                      ? Icons.cancel
                                      : Icons
                                          .radio_button_unchecked))
                              : (opt == _selected
                                  ? Icons.radio_button_checked
                                  : Icons
                                      .radio_button_unchecked),
                          color: _answered
                              ? (opt == correctAnswer
                                  ? Colors.green
                                  : (opt == _selected
                                      ? Colors.red
                                      : Colors.grey))
                              : (opt == _selected
                                  ? color
                                  : Colors.grey),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(opt,
                                style: const TextStyle(
                                    fontSize: 13))),
                      ]),
                    ),
                  );
                }),
                // Solution
                if (_answered && solution.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.blue.shade200),
                    ),
                    child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text('💡',
                              style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(solution,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      height: 1.4))),
                        ]),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        // Bottom buttons
        Padding(
          padding: const EdgeInsets.all(16),
          child: _answered
              ? ElevatedButton.icon(
                  onPressed: () {
                    final correct = _selected == correctAnswer;
                    final next = _current + 1;
                    setState(() {
                      if (correct) _score++;
                      _answered = false;
                      _selected = null;
                      if (next >= questions.length) {
                        _done = true;
                      } else {
                        _current = next;
                      }
                    });
                  },
                  icon: const Text('Sonraki'),
                  label:
                      const Icon(Icons.arrow_forward_ios, size: 14),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      minimumSize:
                          const Size(double.infinity, 44)),
                )
              : ElevatedButton(
                  onPressed: _selected == null
                      ? null
                      : () =>
                          setState(() => _answered = true),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      minimumSize:
                          const Size(double.infinity, 44)),
                  child: const Text('Cevapla'),
                ),
        ),
      ],
    );
  }
}

class _QuizResult extends StatelessWidget {
  final int score, total;
  final Color color;
  final VoidCallback onRestart;
  const _QuizResult(
      {required this.score,
      required this.total,
      required this.color,
      required this.onRestart});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (score / total * 100).round() : 0;
    final msg = pct >= 80
        ? 'Harika! Tebrikler 🎉'
        : pct >= 60
            ? 'İyi iş çıkardın! 👍'
            : 'Biraz daha çalış 📚';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(pct >= 80 ? '🏆' : pct >= 60 ? '⭐' : '📖',
                style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text('$score / $total',
                style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 8),
            Text(msg,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('%$pct başarı',
                style: const TextStyle(
                    fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onRestart,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Çöz'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 44)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SUMMARY STEP
// ─────────────────────────────────────────────

class _SummaryStep extends StatelessWidget {
  final StepData step;
  const _SummaryStep({required this.step});

  @override
  Widget build(BuildContext context) {
    final color = _stepColor(step.type);
    final slides = step.content['slides'] as List? ?? [];
    final points =
        step.activities['summary_points'] as List? ?? [];

    return SingleChildScrollView(
      child: Column(
        children: [
          _StepHeader(step: step),
          if (slides.isNotEmpty)
            SizedBox(
              height: 280,
              child: _SlideViewer(slides: slides, color: color),
            ),
          if (points.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('📋 Özet Maddeler', color),
                  ...List.generate(
                    points.length,
                    (i) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: color.withOpacity(0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 11,
                            backgroundColor: color,
                            child: Text('${i + 1}',
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight:
                                        FontWeight.bold)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(points[i].toString(),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      height: 1.5))),
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
}

// ─────────────────────────────────────────────
// CERTIFICATE STEP
// ─────────────────────────────────────────────

class _CertificateStep extends StatelessWidget {
  final StepData step;
  const _CertificateStep({required this.step});

  @override
  Widget build(BuildContext context) {
    final color = _stepColor(step.type);
    final message =
        step.activities['certificate_message'] as String? ?? '';
    final badges =
        List<String>.from(step.activities['earned_badges'] ?? []);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _StepHeader(step: step),
          const SizedBox(height: 20),
          // Certificate card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6))
              ],
            ),
            child: Column(children: [
              const Text('🏆',
                  style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              const Text('TEBRİKLER!',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2)),
              const SizedBox(height: 12),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      height: 1.6)),
            ]),
          ),
          const SizedBox(height: 24),
          // Badges
          if (badges.isNotEmpty) ...[
            _sectionTitle('🎖️ Kazanılan Rozetler', color),
            ...badges.map((b) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: color.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6)
                    ],
                  ),
                  child: Row(children: [
                    Text(b.substring(0, 2),
                        style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(b.substring(2).trim(),
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500))),
                  ]),
                )),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// GENERIC FALLBACK STEP
// ─────────────────────────────────────────────

class _GenericStep extends StatelessWidget {
  final StepData step;
  const _GenericStep({required this.step});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _StepHeader(step: step),
          const SizedBox(height: 12),
          _card(
            child: Text(
              'Bu step tipi (${step.type}) için özel bir görünüm henüz eklenmedi.\n\nAktiviteler:\n${const JsonEncoder.withIndent('  ').convert(step.activities)}',
              style: const TextStyle(fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}