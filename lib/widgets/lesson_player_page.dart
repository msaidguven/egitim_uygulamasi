import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:egitim_uygulamasi/models/lesson_model.dart';
import 'package:egitim_uygulamasi/models/lesson_step_model.dart';
import 'package:egitim_uygulamasi/services/lesson_parser.dart';
import 'package:egitim_uygulamasi/step_widgets/certificate_widget.dart';
import 'package:egitim_uygulamasi/step_widgets/concept_cards_widget.dart';
import 'package:egitim_uygulamasi/step_widgets/intro_step_widget.dart';
import 'package:egitim_uygulamasi/step_widgets/mini_game_widget.dart';
import 'package:egitim_uygulamasi/step_widgets/quiz_widget.dart';
import 'package:egitim_uygulamasi/step_widgets/reflection_widget.dart';
import 'package:egitim_uygulamasi/step_widgets/risk_cards_widget.dart';
import 'package:egitim_uygulamasi/step_widgets/role_play_widget.dart';
import 'package:egitim_uygulamasi/step_widgets/scenario_choice_widget.dart';
import 'package:egitim_uygulamasi/step_widgets/security_score_widget.dart';
import 'package:egitim_uygulamasi/step_widgets/summary_widget.dart';

class LessonPlayerPage extends StatefulWidget {
  final String? lessonAssetPath;
  final Map<String, dynamic>? lessonJson;

  const LessonPlayerPage({super.key, this.lessonAssetPath, this.lessonJson});

  @override
  State<LessonPlayerPage> createState() => _LessonPlayerPageState();
}

class _LessonPlayerPageState extends State<LessonPlayerPage> {
  final PageController _pageController = PageController();
  final LessonParser _parser = LessonParser();

  EngineLessonModel? _lesson;
  int _index = 0;
  bool _loading = true;
  String? _error;
  final Set<String> _completedSteps = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      Map<String, dynamic> json;
      if (widget.lessonJson != null) {
        json = widget.lessonJson!;
      } else {
        final path =
            widget.lessonAssetPath ?? 'assets/lessons/lesson_engine.json';
        final source = await rootBundle.loadString(path);
        final parsed = _parser.parseJsonString(source);
        setState(() {
          _lesson = parsed;
          _loading = false;
        });
        return;
      }

      final issues = _parser.validate(json);
      if (issues.isNotEmpty) {
        // keep parsing, but surface message
        _error = 'JSON validation warnings:\n${issues.join('\n')}';
      }
      final lesson = _parser.parseMap(json);
      setState(() {
        _lesson = lesson;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load lesson: $e';
        _loading = false;
      });
    }
  }

  bool _isCurrentComplete() {
    final step = _currentStep;
    if (step == null) return false;
    final required = (step.interaction['required'] as bool?) ?? false;
    if (!required) return true;
    return _completedSteps.contains(step.id);
  }

  void _markCompleted(String stepId) {
    if (_completedSteps.contains(stepId)) return;
    setState(() => _completedSteps.add(stepId));
  }

  LessonStepModel? get _currentStep {
    final lesson = _lesson;
    if (lesson == null || lesson.steps.isEmpty) return null;
    if (_index < 0 || _index >= lesson.steps.length) return null;
    return lesson.steps[_index];
  }

  void _next() {
    final lesson = _lesson;
    if (lesson == null) return;
    if (_index >= lesson.steps.length - 1) return;
    if (!_isCurrentComplete()) return;

    setState(() => _index++);
    _pageController.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  void _prev() {
    if (_index == 0) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _index--);
    _pageController.previousPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  Widget _buildStepWidget(LessonStepModel step) {
    switch (step.type) {
      case 'intro':
        return IntroStepWidget(
          step: step,
          onCompleted: () => _markCompleted(step.id),
        );
      case 'concept_cards':
        return ConceptCardsWidget(
          step: step,
          isCompleted: _completedSteps.contains(step.id),
          onCompleted: () => _markCompleted(step.id),
        );
      case 'risk_cards':
        return RiskCardsWidget(
          step: step,
          isCompleted: _completedSteps.contains(step.id),
          onCompleted: () => _markCompleted(step.id),
        );
      case 'scenario_choice':
        return ScenarioChoiceWidget(
          step: step,
          isCompleted: _completedSteps.contains(step.id),
          onCompleted: () => _markCompleted(step.id),
        );
      case 'role_play':
        return RolePlayWidget(
          step: step,
          isCompleted: _completedSteps.contains(step.id),
          onCompleted: () => _markCompleted(step.id),
        );
      case 'mini_game':
        return MiniGameWidget(
          step: step,
          isCompleted: _completedSteps.contains(step.id),
          onCompleted: () => _markCompleted(step.id),
        );
      case 'quiz':
        return QuizWidget(
          step: step,
          isCompleted: _completedSteps.contains(step.id),
          onCompleted: () => _markCompleted(step.id),
        );
      case 'security_score':
        return SecurityScoreWidget(
          step: step,
          isCompleted: _completedSteps.contains(step.id),
          onCompleted: () => _markCompleted(step.id),
        );
      case 'reflection':
        return ReflectionWidget(
          step: step,
          isCompleted: _completedSteps.contains(step.id),
          onCompleted: () => _markCompleted(step.id),
        );
      case 'summary':
        return SummaryWidget(
          step: step,
          onCompleted: () => _markCompleted(step.id),
        );
      case 'certificate':
        return CertificateWidget(
          step: step,
          onCompleted: () => _markCompleted(step.id),
        );
      default:
        return SummaryWidget(
          step: step,
          onCompleted: () => _markCompleted(step.id),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_lesson == null) {
      return Scaffold(
        body: Center(child: Text(_error ?? 'Lesson unavailable')),
      );
    }

    final lesson = _lesson!;
    final progress = lesson.steps.isEmpty
        ? 0.0
        : (_index + 1) / lesson.steps.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(lesson.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(8),
          child: LinearProgressIndicator(value: progress),
        ),
      ),
      body: Column(
        children: [
          if (_error != null)
            Container(
              width: double.infinity,
              color: Colors.amber.shade100,
              padding: const EdgeInsets.all(8),
              child: Text(_error!, style: const TextStyle(fontSize: 12)),
            ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: lesson.steps.length,
              itemBuilder: (_, i) => _buildStepWidget(lesson.steps[i]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _prev,
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _isCurrentComplete() ? _next : null,
                    child: Text(
                      _index == lesson.steps.length - 1 ? 'Completed' : 'Next',
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
