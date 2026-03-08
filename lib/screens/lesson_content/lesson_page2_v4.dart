import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class LessonPageV4 extends StatefulWidget {
  const LessonPageV4({super.key});

  @override
  State<LessonPageV4> createState() => _LessonPageV4State();
}

class _LessonPageV4State extends State<LessonPageV4> {
  final PageController _pageController = PageController();
  LessonV4? _lesson;
  bool _loading = true;
  bool _dark = true;
  int _currentStep = 0;
  int _score = 0;
  final Set<String> _completedSteps = <String>{};
  final Set<String> _scoredSteps = <String>{};

  @override
  void initState() {
    super.initState();
    _loadLesson();
  }

  Future<void> _loadLesson() async {
    try {
      final raw = await rootBundle.loadString(
        'assets/lessons/lesson_engine.json',
      );
      if (!mounted) return;
      setState(() {
        _lesson = LessonV4.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _canGoNext(LessonStepV4 step) {
    if (_completedSteps.contains(step.id)) return true;
    switch (step.type) {
      case 'concept_cards':
      case 'scenario_choice':
      case 'reflection':
      case 'quiz':
      case 'interactive_activity':
      case 'security_score':
      case 'role_play':
      case 'mini_game':
      case 'analysis':
      case 'misconceptions':
      case 'critical_thinking':
      case 'infographic':
      case 'parent_guide':
      case 'keywords':
      case 'progress_tracker':
      case 'certificate':
        return false;
      default:
        return true;
    }
  }

  void _completeStep(LessonStepV4 step, {int points = 0}) {
    if (!_completedSteps.contains(step.id)) {
      _completedSteps.add(step.id);
      if (points > 0 && !_scoredSteps.contains(step.id)) {
        _scoredSteps.add(step.id);
        _score += points;
      }
      setState(() {});
    }
  }

  void _next() {
    final lesson = _lesson;
    if (lesson == null) return;
    if (_currentStep >= lesson.steps.length - 1) return;

    final step = lesson.steps[_currentStep];
    if (!_canGoNext(step)) return;

    setState(() => _currentStep++);
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prev() {
    if (_currentStep == 0) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _currentStep--);
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Color get _bg => _dark ? const Color(0xFF0D1321) : const Color(0xFFF4F7FB);
  Color get _card => _dark ? const Color(0xFF1D2D44) : Colors.white;
  Color get _text => _dark ? Colors.white : const Color(0xFF0E1A2B);
  Color get _sub => _dark ? Colors.white70 : Colors.black54;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: CircularProgressIndicator(
            color: _dark ? const Color(0xFF58A6FF) : const Color(0xFF1E5EFF),
          ),
        ),
      );
    }

    final lesson = _lesson;
    if (lesson == null) {
      return Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: Text(
            'Ders yüklenemedi.',
            style: TextStyle(color: _text, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    final progress = (_currentStep + 1) / lesson.steps.length;
    const scale = 1.0;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  _IconBtn(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: _prev,
                    color: _text,
                    bg: _card,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _text,
                            fontSize: 16 * scale,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Tek mod • Tutarlı ders deneyimi',
                          style: TextStyle(
                            color: _sub,
                            fontSize: 11 * scale,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Skor: $_score',
                      style: TextStyle(
                        color: const Color(0xFF10B981),
                        fontWeight: FontWeight.w800,
                        fontSize: 12 * scale,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _IconBtn(
                    icon: _dark ? Icons.light_mode : Icons.dark_mode,
                    onTap: () => setState(() => _dark = !_dark),
                    color: _text,
                    bg: _card,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 9,
                        backgroundColor: _dark
                            ? Colors.white12
                            : Colors.black12,
                        valueColor: AlwaysStoppedAnimation(
                          const Color(0xFF5B6CFF),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${_currentStep + 1}/${lesson.steps.length}',
                    style: TextStyle(
                      color: _sub,
                      fontWeight: FontWeight.w700,
                      fontSize: 11 * scale,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: lesson.steps.length,
                itemBuilder: (_, i) {
                  final step = lesson.steps[i];
                  return _StepRenderer(
                    step: step,
                    dark: _dark,
                    card: _card,
                    text: _text,
                    sub: _sub,
                    fontScale: scale,
                    onComplete: (points) => _completeStep(step, points: points),
                    isCompleted: _completedSteps.contains(step.id),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _currentStep == 0 ? null : _prev,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _text,
                        side: BorderSide(color: _sub.withOpacity(0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Geri',
                        style: TextStyle(fontSize: 13 * scale),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _canGoNext(lesson.steps[_currentStep])
                          ? _next
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        _currentStep == lesson.steps.length - 1
                            ? 'Ders Tamamlandı'
                            : 'Devam Et',
                        style: TextStyle(
                          fontSize: 13 * scale,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepRenderer extends StatelessWidget {
  const _StepRenderer({
    required this.step,
    required this.dark,
    required this.card,
    required this.text,
    required this.sub,
    required this.fontScale,
    required this.onComplete,
    required this.isCompleted,
  });

  final LessonStepV4 step;
  final bool dark;
  final Color card;
  final Color text;
  final Color sub;
  final double fontScale;
  final void Function(int points) onComplete;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final content = switch (step.type) {
      'intro' => _IntroStep(
        step: step,
        text: text,
        sub: sub,
        fontScale: fontScale,
      ),
      'concept_cards' => _ConceptCardsStep(
        step: step,
        text: text,
        sub: sub,
        fontScale: fontScale,
        onComplete: () => onComplete(10),
        isCompleted: isCompleted,
      ),
      'info_list' => _InfoListStep(
        step: step,
        text: text,
        sub: sub,
        fontScale: fontScale,
      ),
      'example' => _ExampleStep(
        step: step,
        text: text,
        sub: sub,
        fontScale: fontScale,
      ),
      'case_studies' => _CaseStudiesStep(
        step: step,
        text: text,
        sub: sub,
        fontScale: fontScale,
      ),
      'interactive_activity' => _InteractiveActivityStep(
        step: step,
        text: text,
        sub: sub,
        fontScale: fontScale,
        onComplete: () => onComplete(12),
        isCompleted: isCompleted,
      ),
      'security_score' => _SecurityScoreStep(
        step: step,
        text: text,
        sub: sub,
        fontScale: fontScale,
        onComplete: () => onComplete(20),
        isCompleted: isCompleted,
      ),
      'role_play' => _RolePlayStep(
        step: step,
        text: text,
        sub: sub,
        fontScale: fontScale,
        onComplete: (pts) => onComplete(pts),
        isCompleted: isCompleted,
      ),
      'mini_game' => _MiniGameStep(
        step: step,
        text: text,
        sub: sub,
        fontScale: fontScale,
        onComplete: () => onComplete(15),
        isCompleted: isCompleted,
      ),
      'analysis' => _AnalysisStep(
        step: step,
        text: text,
        sub: sub,
        fontScale: fontScale,
        onComplete: () => onComplete(8),
        isCompleted: isCompleted,
      ),
      'misconceptions' => _MisconceptionsStep(
        step: step,
        text: text,
        sub: sub,
        fontScale: fontScale,
        onComplete: () => onComplete(8),
        isCompleted: isCompleted,
      ),
      'critical_thinking' => _CriticalThinkingStep(
        step: step,
        text: text,
        sub: sub,
        fontScale: fontScale,
        onComplete: () => onComplete(10),
        isCompleted: isCompleted,
      ),
      'infographic' => _InfographicStep(
        step: step,
        text: text,
        sub: sub,
        fontScale: fontScale,
        onComplete: () => onComplete(7),
        isCompleted: isCompleted,
      ),
      'parent_guide' => _ParentGuideStep(
        step: step,
        text: text,
        sub: sub,
        fontScale: fontScale,
        onComplete: () => onComplete(7),
        isCompleted: isCompleted,
      ),
      'keywords' => _KeywordsStep(
        step: step,
        text: text,
        sub: sub,
        fontScale: fontScale,
        onComplete: () => onComplete(8),
        isCompleted: isCompleted,
      ),
      'progress_tracker' => _ProgressTrackerStep(
        step: step,
        text: text,
        sub: sub,
        fontScale: fontScale,
        onComplete: () => onComplete(6),
        isCompleted: isCompleted,
      ),
      'certificate' => _CertificateStep(
        step: step,
        text: text,
        sub: sub,
        fontScale: fontScale,
        onComplete: () => onComplete(6),
        isCompleted: isCompleted,
      ),
      'scenario_choice' => _ScenarioChoiceStep(
        step: step,
        text: text,
        sub: sub,
        fontScale: fontScale,
        onComplete: () => onComplete(15),
        isCompleted: isCompleted,
      ),
      'reflection' => _ReflectionStep(
        step: step,
        text: text,
        sub: sub,
        fontScale: fontScale,
        onComplete: () => onComplete(10),
        isCompleted: isCompleted,
      ),
      'quiz' => _QuizStep(
        step: step,
        text: text,
        sub: sub,
        fontScale: fontScale,
        onComplete: () => onComplete(20),
        isCompleted: isCompleted,
      ),
      'summary' => _SummaryStep(
        step: step,
        text: text,
        sub: sub,
        fontScale: fontScale,
      ),
      _ => _GenericStructuredStep(
        step: step,
        text: text,
        sub: sub,
        fontScale: fontScale,
      ),
    };

    const maxWidth = 900.0;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: dark ? Colors.white12 : Colors.black12),
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

class _IntroStep extends StatelessWidget {
  const _IntroStep({
    required this.step,
    required this.text,
    required this.sub,
    required this.fontScale,
  });

  final LessonStepV4 step;
  final Color text;
  final Color sub;
  final double fontScale;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🛡️', style: TextStyle(fontSize: 56 * fontScale)),
          const SizedBox(height: 12),
          Text(
            step.title ?? 'Giriş',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: text,
              fontSize: 24 * fontScale,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            step.text ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: sub,
              fontSize: 16 * fontScale,
              height: 1.6,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConceptCardsStep extends StatefulWidget {
  const _ConceptCardsStep({
    required this.step,
    required this.text,
    required this.sub,
    required this.fontScale,
    required this.onComplete,
    required this.isCompleted,
  });

  final LessonStepV4 step;
  final Color text;
  final Color sub;
  final double fontScale;
  final VoidCallback onComplete;
  final bool isCompleted;

  @override
  State<_ConceptCardsStep> createState() => _ConceptCardsStepState();
}

class _ConceptCardsStepState extends State<_ConceptCardsStep> {
  final Set<int> _opened = <int>{};
  bool _completionSent = false;

  @override
  Widget build(BuildContext context) {
    final items = widget.step.concepts;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.step.title ?? 'Temel Bilgiler',
            style: TextStyle(
              color: widget.text,
              fontSize: 20 * widget.fontScale,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Her karta dokunup kavramı aç.',
            style: TextStyle(
              color: widget.sub,
              fontSize: 12 * widget.fontScale,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 260,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.05,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                final opened = _opened.contains(i);
                return GestureDetector(
                  onTap: () {
                    if (opened) return;
                    setState(() => _opened.add(i));
                    if (!_completionSent &&
                        !widget.isCompleted &&
                        _opened.length == items.length) {
                      _completionSent = true;
                      widget.onComplete();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: opened
                          ? const Color(0xFF1E3A8A).withOpacity(0.22)
                          : const Color(0xFF2563EB).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: opened
                            ? const Color(0xFF60A5FA)
                            : const Color(0xFF93C5FD).withOpacity(0.4),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (item.icon != null && item.icon!.isNotEmpty) ...[
                          Text(
                            item.icon!,
                            style: TextStyle(fontSize: 22 * widget.fontScale),
                          ),
                          const SizedBox(height: 6),
                        ],
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: widget.text,
                            fontWeight: FontWeight.w800,
                            fontSize: 15 * widget.fontScale,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          opened ? item.description : 'Açmak için dokun',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: opened
                                ? widget.sub
                                : widget.sub.withOpacity(0.8),
                            fontSize: 12 * widget.fontScale,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoListStep extends StatelessWidget {
  const _InfoListStep({
    required this.step,
    required this.text,
    required this.sub,
    required this.fontScale,
  });

  final LessonStepV4 step;
  final Color text;
  final Color sub;
  final double fontScale;

  @override
  Widget build(BuildContext context) {
    final rawItems = (step.raw['items'] as List<dynamic>? ?? <dynamic>[]);
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          step.title ?? '',
          style: TextStyle(
            color: text,
            fontSize: 21 * fontScale,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        for (final item in rawItems)
          Builder(
            builder: (_) {
              final String main = item is String
                  ? item
                  : (item is Map<String, dynamic>
                        ? (item['text'] as String?) ??
                              (item['title'] as String?) ??
                              ''
                        : item.toString());
              final String? detail = item is Map<String, dynamic>
                  ? (item['example'] as String?) ??
                        (item['tips'] as String?) ??
                        (item['description'] as String?)
                  : null;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFFF59E0B).withOpacity(0.12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '• ',
                          style: TextStyle(color: Color(0xFFF59E0B)),
                        ),
                        Expanded(
                          child: Text(
                            main,
                            style: TextStyle(
                              color: sub,
                              fontSize: 14 * fontScale,
                              fontWeight: FontWeight.w600,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (detail != null && detail.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Örnek/İpucu: $detail',
                        style: TextStyle(
                          color: sub.withOpacity(0.85),
                          fontSize: 12 * fontScale,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

class _ExampleStep extends StatelessWidget {
  const _ExampleStep({
    required this.step,
    required this.text,
    required this.sub,
    required this.fontScale,
  });

  final LessonStepV4 step;
  final Color text;
  final Color sub;
  final double fontScale;

  @override
  Widget build(BuildContext context) {
    final takeAction = step.raw['take_action'] as String?;
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            step.title ?? '',
            style: TextStyle(
              color: text,
              fontSize: 21 * fontScale,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFF0891B2).withOpacity(0.14),
            ),
            child: Text(
              'Senaryo:\n${step.scenario}',
              style: TextStyle(
                color: text,
                fontSize: 14 * fontScale,
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFF10B981).withOpacity(0.14),
            ),
            child: Text(
              'Açıklama:\n${step.explanation}',
              style: TextStyle(
                color: sub,
                fontSize: 14 * fontScale,
                fontWeight: FontWeight.w600,
                height: 1.55,
              ),
            ),
          ),
          if (takeAction != null && takeAction.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: const Color(0xFF6366F1).withOpacity(0.14),
              ),
              child: Text(
                'Ne Yapabilirsin?\n$takeAction',
                style: TextStyle(
                  color: text,
                  fontSize: 13 * fontScale,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CaseStudiesStep extends StatefulWidget {
  const _CaseStudiesStep({
    required this.step,
    required this.text,
    required this.sub,
    required this.fontScale,
  });

  final LessonStepV4 step;
  final Color text;
  final Color sub;
  final double fontScale;

  @override
  State<_CaseStudiesStep> createState() => _CaseStudiesStepState();
}

class _CaseStudiesStepState extends State<_CaseStudiesStep> {
  late final PageController _controller = PageController(
    viewportFraction: 0.92,
  );
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rawCases = (widget.step.raw['cases'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();

    if (rawCases.isEmpty) {
      return Center(
        child: Text('Örnek bulunamadı.', style: TextStyle(color: widget.sub)),
      );
    }

    const gradients = <List<Color>>[
      [Color(0xFF2563EB), Color(0xFF1D4ED8)],
      [Color(0xFFDC2626), Color(0xFF991B1B)],
      [Color(0xFF059669), Color(0xFF047857)],
    ];
    const emojis = <String>['🔎', '🚨', '🎯', '🛡️', '📱'];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.step.title ?? 'Gerçek Hayattan Örnekler',
            style: TextStyle(
              color: widget.text,
              fontSize: 21 * widget.fontScale,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Kartları kaydırarak olayları incele.',
            style: TextStyle(
              color: widget.sub,
              fontSize: 12 * widget.fontScale,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: rawCases.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (_, i) {
                final c = rawCases[i];
                final title = (c['title'] as String?) ?? 'Örnek';
                final description = (c['description'] as String?) ?? '';
                final lesson = (c['lesson'] as String?) ?? '';
                final action = (c['take_action'] as String?) ?? '';
                final colors = gradients[i % gradients.length];
                final emoji = emojis[i % emojis.length];

                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: colors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: colors.first.withOpacity(0.28),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -20,
                          top: -20,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.09),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          left: -35,
                          bottom: -35,
                          child: Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.07),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: ListView(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.16),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        emoji,
                                        style: const TextStyle(fontSize: 22),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16 * widget.fontScale,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _CaseBlock(
                                title: 'Olay',
                                icon: '📰',
                                text: description,
                                scale: widget.fontScale,
                              ),
                              const SizedBox(height: 10),
                              _CaseBlock(
                                title: 'Bu Olaydan Ders',
                                icon: '💡',
                                text: lesson,
                                scale: widget.fontScale,
                              ),
                              if (action.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                _CaseBlock(
                                  title: 'Ne Yapmalıyım?',
                                  icon: '✅',
                                  text: action,
                                  scale: widget.fontScale,
                                  highlight: true,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(rawCases.length, (i) {
              final active = i == _index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFF2563EB)
                      : widget.sub.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _CaseBlock extends StatelessWidget {
  const _CaseBlock({
    required this.title,
    required this.icon,
    required this.text,
    required this.scale,
    this.highlight = false,
  });

  final String title;
  final String icon;
  final String text;
  final double scale;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight
            ? Colors.white.withOpacity(0.18)
            : Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12 * scale,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.96),
              fontSize: 13 * scale,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScenarioChoiceStep extends StatefulWidget {
  const _ScenarioChoiceStep({
    required this.step,
    required this.text,
    required this.sub,
    required this.fontScale,
    required this.onComplete,
    required this.isCompleted,
  });

  final LessonStepV4 step;
  final Color text;
  final Color sub;
  final double fontScale;
  final VoidCallback onComplete;
  final bool isCompleted;

  @override
  State<_ScenarioChoiceStep> createState() => _ScenarioChoiceStepState();
}

class _ScenarioChoiceStepState extends State<_ScenarioChoiceStep> {
  int? _selected;
  bool _showResult = false;
  bool _completionSent = false;

  void _revealResult() {
    if (_selected == null || _showResult) return;
    final correct = widget.step.correctIndex;
    setState(() => _showResult = true);
    if (!_completionSent && !widget.isCompleted && _selected == correct) {
      _completionSent = true;
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final correct = widget.step.correctIndex;

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          widget.step.title ?? '',
          style: TextStyle(
            color: widget.text,
            fontSize: 20 * widget.fontScale,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          widget.step.question,
          style: TextStyle(
            color: widget.text,
            fontSize: 16 * widget.fontScale,
            fontWeight: FontWeight.w700,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(widget.step.options.length, (i) {
          final isSel = i == _selected;
          final isCorrect = i == correct;
          final show = _showResult;
          final bg = show && isCorrect
              ? const Color(0xFF10B981).withOpacity(0.16)
              : show && isSel && !isCorrect
              ? const Color(0xFFEF4444).withOpacity(0.16)
              : Colors.transparent;
          final border = show && isCorrect
              ? const Color(0xFF10B981)
              : show && isSel && !isCorrect
              ? const Color(0xFFEF4444)
              : isSel
              ? const Color(0xFF3B82F6)
              : widget.sub.withOpacity(0.35);

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              onPressed: () => setState(() => _selected = i),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 12,
                ),
                side: BorderSide(color: border, width: 1.5),
                backgroundColor: bg,
                foregroundColor: widget.text,
                alignment: Alignment.centerLeft,
              ),
              child: Text(
                widget.step.options[i],
                style: TextStyle(
                  fontSize: 14 * widget.fontScale,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        if (_selected != null && !_showResult)
          ElevatedButton(
            onPressed: _revealResult,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D4ED8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Cevabı Kontrol Et'),
          ),
        if (_showResult)
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color:
                  (_selected == correct
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444))
                      .withOpacity(0.12),
            ),
            child: Text(
              widget.step.explanation ?? '',
              style: TextStyle(
                color: widget.text,
                fontSize: 13 * widget.fontScale,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
      ],
    );
  }
}

class _ReflectionStep extends StatefulWidget {
  const _ReflectionStep({
    required this.step,
    required this.text,
    required this.sub,
    required this.fontScale,
    required this.onComplete,
    required this.isCompleted,
  });

  final LessonStepV4 step;
  final Color text;
  final Color sub;
  final double fontScale;
  final VoidCallback onComplete;
  final bool isCompleted;

  @override
  State<_ReflectionStep> createState() => _ReflectionStepState();
}

class _ReflectionStepState extends State<_ReflectionStep> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prompts =
        (widget.step.raw['questions'] as List<dynamic>? ?? <dynamic>[])
            .whereType<String>()
            .toList();
    final note = widget.step.raw['note'] as String?;
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.step.title ?? '',
            style: TextStyle(
              color: widget.text,
              fontSize: 20 * widget.fontScale,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.step.question,
            style: TextStyle(
              color: widget.text,
              fontSize: 15 * widget.fontScale,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (prompts.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...prompts.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '• $p',
                  style: TextStyle(
                    color: widget.sub,
                    fontSize: 12 * widget.fontScale,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              note,
              style: TextStyle(
                color: widget.text,
                fontSize: 12 * widget.fontScale,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            maxLines: 4,
            style: TextStyle(color: widget.text),
            decoration: InputDecoration(
              hintText: 'Kısa cevabını yaz...',
              hintStyle: TextStyle(color: widget.sub),
              filled: true,
              fillColor: Colors.transparent,
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: widget.sub.withOpacity(0.4)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF3B82F6), width: 2),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: widget.isCompleted
                ? null
                : _controller.text.trim().isEmpty
                ? null
                : widget.onComplete,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0EA5E9),
              foregroundColor: Colors.white,
            ),
            child: const Text('Yansımayı Kaydet'),
          ),
        ],
      ),
    );
  }
}

class _QuizStep extends StatefulWidget {
  const _QuizStep({
    required this.step,
    required this.text,
    required this.sub,
    required this.fontScale,
    required this.onComplete,
    required this.isCompleted,
  });

  final LessonStepV4 step;
  final Color text;
  final Color sub;
  final double fontScale;
  final VoidCallback onComplete;
  final bool isCompleted;

  @override
  State<_QuizStep> createState() => _QuizStepState();
}

class _QuizStepState extends State<_QuizStep> {
  int _index = 0;
  int _correctCount = 0;
  int? _selected;
  bool _revealed = false;
  bool _completed = false;

  void _check() {
    if (_selected == null || _revealed) return;
    setState(() {
      _revealed = true;
      if (_selected == widget.step.questions[_index].answerIndex) {
        _correctCount++;
      }
    });
  }

  void _nextQuestion() {
    if (_index >= widget.step.questions.length - 1) {
      if (!_completed && !widget.isCompleted) widget.onComplete();
      setState(() => _completed = true);
      return;
    }
    setState(() {
      _index++;
      _selected = null;
      _revealed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.step.questions[_index];
    final done = _completed || widget.isCompleted;
    final ratio = (_index + 1) / widget.step.questions.length;

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.step.title ?? '',
            style: TextStyle(
              color: widget.text,
              fontSize: 20 * widget.fontScale,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: widget.sub.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF6366F1)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            q.question,
            style: TextStyle(
              color: widget.text,
              fontSize: 15 * widget.fontScale,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          ...List.generate(q.options.length, (i) {
            final isSel = i == _selected;
            final isCorrect = i == q.answerIndex;
            final show = _revealed;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                onPressed: show ? null : () => setState(() => _selected = i),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: show && isCorrect
                        ? const Color(0xFF10B981)
                        : show && isSel && !isCorrect
                        ? const Color(0xFFEF4444)
                        : isSel
                        ? const Color(0xFF4F46E5)
                        : widget.sub.withOpacity(0.35),
                    width: 1.5,
                  ),
                  backgroundColor: show && isCorrect
                      ? const Color(0xFF10B981).withOpacity(0.14)
                      : show && isSel && !isCorrect
                      ? const Color(0xFFEF4444).withOpacity(0.14)
                      : Colors.transparent,
                  foregroundColor: widget.text,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 12,
                  ),
                ),
                child: Text(
                  q.options[i],
                  style: TextStyle(
                    fontSize: 14 * widget.fontScale,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          if (!_revealed)
            ElevatedButton(
              onPressed: _selected == null ? null : _check,
              child: const Text('Cevabı Kontrol Et'),
            ),
          if (_revealed && !done)
            ElevatedButton(
              onPressed: _nextQuestion,
              child: Text(
                _index == widget.step.questions.length - 1
                    ? 'Quizi Bitir'
                    : 'Sonraki Soru',
              ),
            ),
          if (done)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFF10B981).withOpacity(0.16),
              ),
              child: Text(
                'Quiz tamamlandı: $_correctCount/${widget.step.questions.length} doğru.',
                style: TextStyle(
                  color: widget.text,
                  fontSize: 14 * widget.fontScale,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AnalysisStep extends StatefulWidget {
  const _AnalysisStep({
    required this.step,
    required this.text,
    required this.sub,
    required this.fontScale,
    required this.onComplete,
    required this.isCompleted,
  });

  final LessonStepV4 step;
  final Color text;
  final Color sub;
  final double fontScale;
  final VoidCallback onComplete;
  final bool isCompleted;

  @override
  State<_AnalysisStep> createState() => _AnalysisStepState();
}

class _AnalysisStepState extends State<_AnalysisStep> {
  final Set<int> _opened = <int>{};

  @override
  Widget build(BuildContext context) {
    final items = (widget.step.raw['items'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          widget.step.title ?? 'Analiz',
          style: TextStyle(
            color: widget.text,
            fontSize: 20 * widget.fontScale,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(items.length, (i) {
          final item = items[i];
          final opened = _opened.contains(i);
          return _TapCard(
            title: (item['title'] as String?) ?? 'Madde',
            subtitle: opened ? (item['explanation'] as String?) ?? '' : null,
            accent: const Color(0xFF2563EB),
            opened: opened,
            onTap: () {
              setState(() => opened ? _opened.remove(i) : _opened.add(i));
              if (!widget.isCompleted && _opened.length == items.length) {
                widget.onComplete();
              }
            },
            fontScale: widget.fontScale,
          );
        }),
      ],
    );
  }
}

class _MisconceptionsStep extends StatefulWidget {
  const _MisconceptionsStep({
    required this.step,
    required this.text,
    required this.sub,
    required this.fontScale,
    required this.onComplete,
    required this.isCompleted,
  });

  final LessonStepV4 step;
  final Color text;
  final Color sub;
  final double fontScale;
  final VoidCallback onComplete;
  final bool isCompleted;

  @override
  State<_MisconceptionsStep> createState() => _MisconceptionsStepState();
}

class _MisconceptionsStepState extends State<_MisconceptionsStep> {
  final Set<int> _flipped = <int>{};

  @override
  Widget build(BuildContext context) {
    final items = (widget.step.raw['items'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          widget.step.title ?? 'Kavram Yanılgıları',
          style: TextStyle(
            color: widget.text,
            fontSize: 20 * widget.fontScale,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(items.length, (i) {
          final m = items[i];
          final flipped = _flipped.contains(i);
          return GestureDetector(
            onTap: () {
              setState(() => flipped ? _flipped.remove(i) : _flipped.add(i));
              if (!widget.isCompleted && _flipped.length == items.length) {
                widget.onComplete();
              }
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color:
                    (flipped
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444))
                        .withOpacity(0.13),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '❌ Mit: ${(m['myth'] as String?) ?? ''}',
                    style: TextStyle(
                      color: widget.text,
                      fontSize: 14 * widget.fontScale,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (flipped) ...[
                    const SizedBox(height: 8),
                    Text(
                      '✅ Gerçek: ${(m['truth'] as String?) ?? ''}',
                      style: TextStyle(
                        color: widget.sub,
                        fontSize: 13 * widget.fontScale,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Örnek: ${(m['example'] as String?) ?? ''}',
                      style: TextStyle(
                        color: widget.sub.withOpacity(0.9),
                        fontSize: 12 * widget.fontScale,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _InteractiveActivityStep extends StatefulWidget {
  const _InteractiveActivityStep({
    required this.step,
    required this.text,
    required this.sub,
    required this.fontScale,
    required this.onComplete,
    required this.isCompleted,
  });
  final LessonStepV4 step;
  final Color text;
  final Color sub;
  final double fontScale;
  final VoidCallback onComplete;
  final bool isCompleted;

  @override
  State<_InteractiveActivityStep> createState() =>
      _InteractiveActivityStepState();
}

class _InteractiveActivityStepState extends State<_InteractiveActivityStep> {
  final Map<int, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final qs = (widget.step.raw['questions'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();
    final reflection = widget.step.raw['reflection'] as String?;
    final allFilled =
        qs.isNotEmpty &&
        List.generate(
          qs.length,
          (i) => _controllers[i]?.text.trim().isNotEmpty ?? false,
        ).every((e) => e);
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          widget.step.title ?? 'Etkinlik',
          style: TextStyle(
            color: widget.text,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.step.raw['activity'] as String? ?? '',
          style: TextStyle(color: widget.sub, height: 1.5),
        ),
        const SizedBox(height: 10),
        ...List.generate(qs.length, (i) {
          final q = qs[i];
          _controllers.putIfAbsent(i, () => TextEditingController());
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFF2563EB).withOpacity(0.10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${q['time'] ?? ''} • ${q['prompt'] ?? ''}',
                  style: TextStyle(
                    color: widget.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _controllers[i],
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: q['example'] as String? ?? 'Cevabını yaz',
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          );
        }),
        if (reflection != null) ...[
          const SizedBox(height: 4),
          Text('Düşün: $reflection', style: TextStyle(color: widget.sub)),
        ],
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: widget.isCompleted
              ? null
              : allFilled
              ? widget.onComplete
              : null,
          child: const Text('Etkinliği Tamamla'),
        ),
      ],
    );
  }
}

class _SecurityScoreStep extends StatefulWidget {
  const _SecurityScoreStep({
    required this.step,
    required this.text,
    required this.sub,
    required this.fontScale,
    required this.onComplete,
    required this.isCompleted,
  });

  final LessonStepV4 step;
  final Color text;
  final Color sub;
  final double fontScale;
  final VoidCallback onComplete;
  final bool isCompleted;

  @override
  State<_SecurityScoreStep> createState() => _SecurityScoreStepState();
}

class _SecurityScoreStepState extends State<_SecurityScoreStep> {
  final Set<int> _checked = <int>{};
  bool _submitted = false;
  int _score = 0;

  @override
  Widget build(BuildContext context) {
    final questions =
        (widget.step.raw['questions'] as List<dynamic>? ?? <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .toList();
    final results =
        (widget.step.raw['results'] as List<dynamic>? ?? <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .toList();

    Map<String, dynamic>? result;
    if (_submitted) {
      for (final r in results) {
        final min = (r['min_score'] as num?)?.toInt() ?? 0;
        final max = (r['max_score'] as num?)?.toInt() ?? 999;
        if (_score >= min && _score <= max) {
          result = r;
          break;
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          widget.step.title ?? 'Güvenlik Skoru',
          style: TextStyle(
            color: widget.text,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(questions.length, (i) {
          final q = questions[i];
          final selected = _checked.contains(i);
          return CheckboxListTile(
            value: selected,
            onChanged: (_) {
              if (_submitted) return;
              setState(() => selected ? _checked.remove(i) : _checked.add(i));
            },
            title: Text('${q['icon'] ?? '•'} ${q['text'] ?? ''}'),
            subtitle: Text('+${q['points'] ?? 0} puan'),
          );
        }),
        ElevatedButton(
          onPressed: _submitted
              ? null
              : () {
                  var total = 0;
                  for (final i in _checked) {
                    total += (questions[i]['points'] as num?)?.toInt() ?? 0;
                  }
                  setState(() {
                    _score = total;
                    _submitted = true;
                  });
                  if (!widget.isCompleted) widget.onComplete();
                },
          child: const Text('Skorumu Hesapla'),
        ),
        if (_submitted && result != null)
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Skor: $_score\n${result['title']}\n${result['description']}',
              style: TextStyle(color: widget.text, height: 1.45),
            ),
          ),
      ],
    );
  }
}

class _RolePlayStep extends StatefulWidget {
  const _RolePlayStep({
    required this.step,
    required this.text,
    required this.sub,
    required this.fontScale,
    required this.onComplete,
    required this.isCompleted,
  });
  final LessonStepV4 step;
  final Color text;
  final Color sub;
  final double fontScale;
  final void Function(int points) onComplete;
  final bool isCompleted;
  @override
  State<_RolePlayStep> createState() => _RolePlayStepState();
}

class _RolePlayStepState extends State<_RolePlayStep> {
  int? _selected;
  bool _locked = false;

  @override
  Widget build(BuildContext context) {
    final choices =
        (widget.step.raw['choices'] as List<dynamic>? ?? <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .toList();
    final choice = _selected != null ? choices[_selected!] : null;
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          widget.step.title ?? 'Rol Yapma',
          style: TextStyle(
            color: widget.text,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.step.raw['character'] as String? ?? '',
          style: TextStyle(color: widget.sub),
        ),
        const SizedBox(height: 6),
        Text(
          widget.step.raw['scenario'] as String? ?? '',
          style: TextStyle(color: widget.text),
        ),
        const SizedBox(height: 10),
        ...List.generate(choices.length, (i) {
          final c = choices[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              onPressed: _locked ? null : () => setState(() => _selected = i),
              child: Text(c['text'] as String? ?? ''),
            ),
          );
        }),
        if (_selected != null && !_locked)
          ElevatedButton(
            onPressed: () {
              final pts = (choice?['points'] as num?)?.toInt() ?? 0;
              setState(() => _locked = true);
              if (!widget.isCompleted) widget.onComplete(pts < 0 ? 0 : pts);
            },
            child: const Text('Kararı Uygula'),
          ),
        if (choice != null) ...[
          const SizedBox(height: 8),
          Text(
            choice['feedback'] as String? ?? '',
            style: TextStyle(color: widget.text),
          ),
          const SizedBox(height: 6),
          Text(
            choice['consequence'] as String? ?? '',
            style: TextStyle(color: widget.sub),
          ),
        ],
      ],
    );
  }
}

class _MiniGameStep extends StatefulWidget {
  const _MiniGameStep({
    required this.step,
    required this.text,
    required this.sub,
    required this.fontScale,
    required this.onComplete,
    required this.isCompleted,
  });
  final LessonStepV4 step;
  final Color text;
  final Color sub;
  final double fontScale;
  final VoidCallback onComplete;
  final bool isCompleted;

  @override
  State<_MiniGameStep> createState() => _MiniGameStepState();
}

class _MiniGameStepState extends State<_MiniGameStep> {
  final Set<int> _selected = <int>{};
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    final levels = (widget.step.raw['levels'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();
    final level = levels.isNotEmpty ? levels.first : <String, dynamic>{};
    final perms = (level['permissions'] as List<dynamic>? ?? <dynamic>[])
        .whereType<String>()
        .toList();
    final required = (level['correct_answers'] as num?)?.toInt() ?? 0;
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          widget.step.title ?? 'Mini Oyun',
          style: TextStyle(
            color: widget.text,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.step.raw['game'] as String? ?? '',
          style: TextStyle(color: widget.sub),
        ),
        const SizedBox(height: 8),
        ...List.generate(perms.length, (i) {
          final selected = _selected.contains(i);
          return ListTile(
            onTap: () {
              if (_checked) return;
              setState(() => selected ? _selected.remove(i) : _selected.add(i));
            },
            leading: Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? const Color(0xFF10B981) : widget.sub,
            ),
            title: Text(perms[i]),
          );
        }),
        ElevatedButton(
          onPressed: _checked
              ? null
              : () {
                  setState(() => _checked = true);
                  if (!widget.isCompleted) widget.onComplete();
                },
          child: const Text('Kontrol Et'),
        ),
        if (_checked)
          Text(
            _selected.length == required
                ? 'Harika! Doğru sayıda ihlal buldun.'
                : 'İpucu: ${level['hint'] ?? ''}',
            style: TextStyle(color: widget.text),
          ),
      ],
    );
  }
}

class _CriticalThinkingStep extends StatefulWidget {
  const _CriticalThinkingStep({
    required this.step,
    required this.text,
    required this.sub,
    required this.fontScale,
    required this.onComplete,
    required this.isCompleted,
  });
  final LessonStepV4 step;
  final Color text;
  final Color sub;
  final double fontScale;
  final VoidCallback onComplete;
  final bool isCompleted;
  @override
  State<_CriticalThinkingStep> createState() => _CriticalThinkingStepState();
}

class _CriticalThinkingStepState extends State<_CriticalThinkingStep> {
  final Set<int> _openedHints = <int>{};
  final TextEditingController _answer = TextEditingController();

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hints = (widget.step.raw['hints'] as List<dynamic>? ?? <dynamic>[])
        .whereType<String>()
        .toList();
    final discussions =
        (widget.step.raw['discussion_points'] as List<dynamic>? ?? <dynamic>[])
            .whereType<String>()
            .toList();
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          widget.step.title ?? 'Kritik Düşünme',
          style: TextStyle(
            color: widget.text,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(widget.step.question, style: TextStyle(color: widget.text)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: List.generate(hints.length, (i) {
            final opened = _openedHints.contains(i);
            return ChoiceChip(
              selected: opened,
              label: Text(opened ? hints[i] : 'İpucu ${i + 1}'),
              onSelected: (_) => setState(() => _openedHints.add(i)),
            );
          }),
        ),
        const SizedBox(height: 10),
        ...discussions.map(
          (d) => Text('• $d', style: TextStyle(color: widget.sub)),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _answer,
          maxLines: 4,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Kısa analizini yaz...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: widget.isCompleted || _answer.text.trim().isEmpty
              ? null
              : widget.onComplete,
          child: const Text('Analizi Kaydet'),
        ),
      ],
    );
  }
}

class _InfographicStep extends StatefulWidget {
  const _InfographicStep({
    required this.step,
    required this.text,
    required this.sub,
    required this.fontScale,
    required this.onComplete,
    required this.isCompleted,
  });
  final LessonStepV4 step;
  final Color text;
  final Color sub;
  final double fontScale;
  final VoidCallback onComplete;
  final bool isCompleted;

  @override
  State<_InfographicStep> createState() => _InfographicStepState();
}

class _InfographicStepState extends State<_InfographicStep> {
  final Set<int> _opened = <int>{};
  @override
  Widget build(BuildContext context) {
    final layers = (widget.step.raw['layers'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          widget.step.title ?? 'İnfografik',
          style: TextStyle(
            color: widget.text,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.step.raw['description'] as String? ?? '',
          style: TextStyle(color: widget.sub),
        ),
        const SizedBox(height: 8),
        ...List.generate(layers.length, (i) {
          final l = layers[i];
          final opened = _opened.contains(i);
          final items = (l['items'] as List<dynamic>? ?? <dynamic>[])
              .whereType<String>()
              .toList();
          return ExpansionTile(
            initiallyExpanded: opened,
            onExpansionChanged: (v) {
              setState(() => v ? _opened.add(i) : _opened.remove(i));
              if (!widget.isCompleted && _opened.length == layers.length) {
                widget.onComplete();
              }
            },
            title: Text(l['name'] as String? ?? 'Katman'),
            children: items.map((e) => ListTile(title: Text(e))).toList(),
          );
        }),
      ],
    );
  }
}

class _ParentGuideStep extends StatefulWidget {
  const _ParentGuideStep({
    required this.step,
    required this.text,
    required this.sub,
    required this.fontScale,
    required this.onComplete,
    required this.isCompleted,
  });
  final LessonStepV4 step;
  final Color text;
  final Color sub;
  final double fontScale;
  final VoidCallback onComplete;
  final bool isCompleted;
  @override
  State<_ParentGuideStep> createState() => _ParentGuideStepState();
}

class _ParentGuideStepState extends State<_ParentGuideStep> {
  final Set<int> _checked = <int>{};
  @override
  Widget build(BuildContext context) {
    final tips = (widget.step.raw['tips'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          widget.step.title ?? 'Aile Rehberi',
          style: TextStyle(
            color: widget.text,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.step.raw['intro'] as String? ?? '',
          style: TextStyle(color: widget.sub),
        ),
        const SizedBox(height: 8),
        ...List.generate(tips.length, (i) {
          final t = tips[i];
          return CheckboxListTile(
            value: _checked.contains(i),
            onChanged: (_) {
              setState(
                () =>
                    _checked.contains(i) ? _checked.remove(i) : _checked.add(i),
              );
              if (!widget.isCompleted && _checked.length == tips.length) {
                widget.onComplete();
              }
            },
            title: Text(t['title'] as String? ?? ''),
            subtitle: Text(t['description'] as String? ?? ''),
          );
        }),
      ],
    );
  }
}

class _KeywordsStep extends StatefulWidget {
  const _KeywordsStep({
    required this.step,
    required this.text,
    required this.sub,
    required this.fontScale,
    required this.onComplete,
    required this.isCompleted,
  });
  final LessonStepV4 step;
  final Color text;
  final Color sub;
  final double fontScale;
  final VoidCallback onComplete;
  final bool isCompleted;
  @override
  State<_KeywordsStep> createState() => _KeywordsStepState();
}

class _KeywordsStepState extends State<_KeywordsStep> {
  final Set<int> _opened = <int>{};
  @override
  Widget build(BuildContext context) {
    final items = (widget.step.raw['items'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          widget.step.title ?? 'Anahtar Kavramlar',
          style: TextStyle(
            color: widget.text,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(items.length, (i) {
            final o = _opened.contains(i);
            final item = items[i];
            return ActionChip(
              label: Text(
                o
                    ? '${item['term']}: ${item['definition']}'
                    : '${item['term']}',
              ),
              onPressed: () {
                setState(() => _opened.add(i));
                if (!widget.isCompleted && _opened.length == items.length) {
                  widget.onComplete();
                }
              },
            );
          }),
        ),
      ],
    );
  }
}

class _ProgressTrackerStep extends StatefulWidget {
  const _ProgressTrackerStep({
    required this.step,
    required this.text,
    required this.sub,
    required this.fontScale,
    required this.onComplete,
    required this.isCompleted,
  });
  final LessonStepV4 step;
  final Color text;
  final Color sub;
  final double fontScale;
  final VoidCallback onComplete;
  final bool isCompleted;
  @override
  State<_ProgressTrackerStep> createState() => _ProgressTrackerStepState();
}

class _ProgressTrackerStepState extends State<_ProgressTrackerStep> {
  final Set<int> _earned = <int>{};
  @override
  Widget build(BuildContext context) {
    final badges = (widget.step.raw['badges'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          widget.step.title ?? 'Rozetler',
          style: TextStyle(
            color: widget.text,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        ...List.generate(badges.length, (i) {
          final b = badges[i];
          final earned = _earned.contains(i);
          return ListTile(
            leading: Text((b['icon'] as String?) ?? '🏅'),
            title: Text(b['name'] as String? ?? ''),
            subtitle: Text(b['condition'] as String? ?? ''),
            trailing: Icon(
              earned ? Icons.check_circle : Icons.radio_button_unchecked,
              color: earned ? const Color(0xFF10B981) : widget.sub,
            ),
            onTap: () {
              setState(() => earned ? _earned.remove(i) : _earned.add(i));
              if (!widget.isCompleted && _earned.isNotEmpty) {
                widget.onComplete();
              }
            },
          );
        }),
      ],
    );
  }
}

class _CertificateStep extends StatefulWidget {
  const _CertificateStep({
    required this.step,
    required this.text,
    required this.sub,
    required this.fontScale,
    required this.onComplete,
    required this.isCompleted,
  });
  final LessonStepV4 step;
  final Color text;
  final Color sub;
  final double fontScale;
  final VoidCallback onComplete;
  final bool isCompleted;
  @override
  State<_CertificateStep> createState() => _CertificateStepState();
}

class _CertificateStepState extends State<_CertificateStep> {
  final Set<int> _checked = <int>{};
  @override
  Widget build(BuildContext context) {
    final reqs =
        (widget.step.raw['requirements'] as List<dynamic>? ?? <dynamic>[])
            .whereType<String>()
            .toList();
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          widget.step.title ?? 'Sertifika',
          style: TextStyle(
            color: widget.text,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.step.raw['description'] as String? ?? '',
          style: TextStyle(color: widget.sub),
        ),
        const SizedBox(height: 8),
        ...List.generate(reqs.length, (i) {
          return CheckboxListTile(
            value: _checked.contains(i),
            onChanged: (_) {
              setState(
                () =>
                    _checked.contains(i) ? _checked.remove(i) : _checked.add(i),
              );
              if (!widget.isCompleted && _checked.length == reqs.length) {
                widget.onComplete();
              }
            },
            title: Text(reqs[i]),
          );
        }),
      ],
    );
  }
}

class _TapCard extends StatelessWidget {
  const _TapCard({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.opened,
    required this.onTap,
    required this.fontScale,
  });

  final String title;
  final String? subtitle;
  final Color accent;
  final bool opened;
  final VoidCallback onTap;
  final double fontScale;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: accent.withOpacity(0.10),
          border: Border.all(color: accent.withOpacity(0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14 * fontScale,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (opened && subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(subtitle!, style: TextStyle(fontSize: 13 * fontScale)),
            ],
          ],
        ),
      ),
    );
  }
}

class _GenericStructuredStep extends StatelessWidget {
  const _GenericStructuredStep({
    required this.step,
    required this.text,
    required this.sub,
    required this.fontScale,
  });

  final LessonStepV4 step;
  final Color text;
  final Color sub;
  final double fontScale;

  @override
  Widget build(BuildContext context) {
    final rows = <MapEntry<String, dynamic>>[];
    for (final entry in step.raw.entries) {
      if (entry.key == 'type' || entry.key == 'title') continue;
      rows.add(MapEntry(entry.key, entry.value));
    }

    String toReadable(dynamic value) {
      if (value == null) return '';
      if (value is String || value is num || value is bool) return '$value';
      if (value is List) {
        return value
            .map((e) {
              if (e is Map<String, dynamic>) {
                final parts = e.entries
                    .map((it) => '${it.key}: ${toReadable(it.value)}')
                    .toList();
                return parts.join(' | ');
              }
              return toReadable(e);
            })
            .join('\n• ');
      }
      if (value is Map<String, dynamic>) {
        return value.entries
            .map((e) => '${e.key}: ${toReadable(e.value)}')
            .join('\n');
      }
      return value.toString();
    }

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          step.title ?? step.type,
          style: TextStyle(
            color: text,
            fontSize: 20 * fontScale,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        ...rows.map(
          (entry) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key,
                  style: TextStyle(
                    color: text,
                    fontSize: 12 * fontScale,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  toReadable(entry.value),
                  style: TextStyle(
                    color: sub,
                    fontSize: 13 * fontScale,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryStep extends StatelessWidget {
  const _SummaryStep({
    required this.step,
    required this.text,
    required this.sub,
    required this.fontScale,
  });

  final LessonStepV4 step;
  final Color text;
  final Color sub;
  final double fontScale;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('✅', style: TextStyle(fontSize: 54 * fontScale)),
          const SizedBox(height: 10),
          Text(
            step.title ?? 'Özet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: text,
              fontSize: 24 * fontScale,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            step.text ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: sub,
              fontSize: 15 * fontScale,
              fontWeight: FontWeight.w600,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.onTap,
    required this.color,
    required this.bg,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

class LessonV4 {
  LessonV4({required this.id, required this.title, required this.steps});

  final String id;
  final String title;
  final List<LessonStepV4> steps;

  factory LessonV4.fromJson(Map<String, dynamic> json) {
    final rawSteps = (json['steps'] as List<dynamic>? ?? <dynamic>[])
        .cast<Map<String, dynamic>>();
    return LessonV4(
      id: (json['lesson_id'] as String?) ?? 'lesson_v4',
      title: (json['title'] as String?) ?? 'Ders',
      steps: List.generate(
        rawSteps.length,
        (i) => LessonStepV4.fromJson(rawSteps[i], index: i),
      ),
    );
  }
}

class LessonStepV4 {
  LessonStepV4({
    required this.id,
    required this.type,
    required this.raw,
    this.title,
    this.text,
    this.items = const <String>[],
    this.concepts = const <ConceptItemV4>[],
    this.scenario,
    this.explanation,
    this.question = '',
    this.options = const <String>[],
    this.correctIndex = -1,
    this.questions = const <QuizQuestionV4>[],
  });

  final String id;
  final String type;
  final Map<String, dynamic> raw;
  final String? title;
  final String? text;
  final List<String> items;
  final List<ConceptItemV4> concepts;
  final String? scenario;
  final String? explanation;
  final String question;
  final List<String> options;
  final int correctIndex;
  final List<QuizQuestionV4> questions;

  factory LessonStepV4.fromJson(
    Map<String, dynamic> json, {
    required int index,
  }) {
    final type = (json['type'] as String?) ?? 'content';
    final conceptItems = (json['items'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(ConceptItemV4.fromJson)
        .toList();
    final listItems = (json['items'] as List<dynamic>? ?? <dynamic>[])
        .map((e) {
          if (e is String) return e;
          if (e is Map<String, dynamic>) {
            return (e['text'] as String?) ?? (e['title'] as String?) ?? '';
          }
          return '';
        })
        .where((e) => e.isNotEmpty)
        .toList();
    final quizQuestions = (json['questions'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(QuizQuestionV4.fromJson)
        .toList();

    return LessonStepV4(
      id: 'step_$index',
      type: type,
      raw: json,
      title: json['title'] as String?,
      text: json['text'] as String?,
      items: listItems,
      concepts: conceptItems,
      scenario: json['scenario'] as String?,
      explanation: json['explanation'] as String?,
      question: (json['question'] as String?) ?? '',
      options: (json['options'] as List<dynamic>? ?? <dynamic>[])
          .whereType<String>()
          .toList(),
      correctIndex: (json['correct'] as num?)?.toInt() ?? -1,
      questions: quizQuestions,
    );
  }
}

class ConceptItemV4 {
  ConceptItemV4({required this.title, required this.description, this.icon});

  final String title;
  final String description;
  final String? icon;

  factory ConceptItemV4.fromJson(Map<String, dynamic> json) {
    return ConceptItemV4(
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      icon: json['icon'] as String?,
    );
  }
}

class QuizQuestionV4 {
  QuizQuestionV4({
    required this.question,
    required this.options,
    required this.answerIndex,
  });

  final String question;
  final List<String> options;
  final int answerIndex;

  factory QuizQuestionV4.fromJson(Map<String, dynamic> json) {
    return QuizQuestionV4(
      question: (json['question'] as String?) ?? '',
      options: (json['options'] as List<dynamic>? ?? <dynamic>[])
          .whereType<String>()
          .toList(),
      answerIndex: (json['answer'] as num?)?.toInt() ?? -1,
    );
  }
}
