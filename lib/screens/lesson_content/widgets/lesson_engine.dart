import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/lesson_models.dart';
import 'branching_path.dart';
import 'category_matcher.dart';
import 'cause_effect_match.dart';
import 'error_hunt.dart';
import 'experiment_sequence.dart';
import 'hotspot_image.dart';
import 'info_highlights.dart';
import 'logic_builder.dart';
import 'mastery_overview.dart';
import 'memory_grid.dart';
import 'micro_review.dart';
import 'quiz_single_choice.dart';
import 'reflection_prompt.dart';
import 'sequence_sorter.dart';
import 'step_text.dart';
import 'summary_step.dart';
import 'timeline_builder.dart';
import 'variable_simulator.dart';
import 'word_selector.dart';

class LessonEngine extends StatefulWidget {
  final String lessonKey;

  const LessonEngine({super.key, required this.lessonKey});

  @override
  State<LessonEngine> createState() => _LessonEngineState();
}

class _LessonEngineState extends State<LessonEngine> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, _ConceptStat> _conceptStats = {};

  LessonDefinition? lesson;
  final List<LessonStep> _visibleSteps = [];

  int _currentStepIndex = 0;
  bool _isLoading = true;
  int _earnedPoints = 0;
  int _maxPoints = 0;

  @override
  void initState() {
    super.initState();
    _loadLessonData();
  }

  Future<void> _loadLessonData() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/lessons/${widget.lessonKey}.json',
      );
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final parsed = LessonDefinition.fromJson(data);

      setState(() {
        lesson = parsed;
        if (parsed.steps.isNotEmpty) {
          _visibleSteps.add(parsed.steps.first);
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Ders verisi yuklenirken hata olustu: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _completeStep(
    LessonStep step, {
    int wrongAttempts = 0,
    bool awardScore = true,
    String? branchTargetId,
  }) {
    if (awardScore) {
      final points = (step.data['points'] as num?)?.toInt() ?? 100;
      final earned = (points - (wrongAttempts * 15)).clamp(points ~/ 3, points);
      _maxPoints += points;
      _earnedPoints += earned;

      final concepts =
          (step.data['concepts'] as List?)
              ?.map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const <String>[];

      for (final concept in concepts) {
        final stat = _conceptStats.putIfAbsent(concept, _ConceptStat.new);
        stat.successes += 1;
        stat.wrongAttempts += wrongAttempts;
        stat.totalAttempts += wrongAttempts + 1;
      }
    }

    if (branchTargetId != null && branchTargetId.isNotEmpty) {
      final branchIndex = _stepIndexById(branchTargetId);
      if (branchIndex != null) {
        _goToIndex(branchIndex);
        return;
      }
    }

    _goToIndex(_currentStepIndex + 1);
  }

  int? _stepIndexById(String id) {
    final steps = lesson?.steps;
    if (steps == null) return null;
    for (var i = 0; i < steps.length; i++) {
      if (steps[i].id == id) return i;
    }
    return null;
  }

  void _goToIndex(int targetIndex) {
    final steps = lesson?.steps;
    if (steps == null || steps.isEmpty) return;
    if (targetIndex < 0 || targetIndex >= steps.length) return;

    setState(() {
      _currentStepIndex = targetIndex;
      final targetStep = steps[targetIndex];
      if (!_visibleSteps.contains(targetStep)) {
        _visibleSteps.add(targetStep);
      }
    });

    Future.delayed(const Duration(milliseconds: 280), () {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 560),
        curve: Curves.easeOutCubic,
      );
    });
  }

  double get _masteryPercent {
    if (_maxPoints == 0) return 0;
    return (_earnedPoints / _maxPoints) * 100;
  }

  List<Map<String, dynamic>> _selectedMicroReviewQuestions(LessonStep step) {
    final allQuestions =
        (step.data['questionBank'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        <Map<String, dynamic>>[];
    if (allQuestions.isEmpty) return const <Map<String, dynamic>>[];

    final count = (step.data['count'] as num?)?.toInt() ?? 3;

    final weakConcepts = _conceptStats.entries.toList()
      ..sort((a, b) => b.value.wrongAttempts.compareTo(a.value.wrongAttempts));

    final selected = <Map<String, dynamic>>[];

    for (final concept in weakConcepts) {
      for (final q in allQuestions) {
        final qConcept = q['concept']?.toString();
        if (qConcept == concept.key && !selected.contains(q)) {
          selected.add(q);
        }
        if (selected.length >= count) break;
      }
      if (selected.length >= count) break;
    }

    if (selected.length < count) {
      for (final q in allQuestions) {
        if (!selected.contains(q)) {
          selected.add(q);
        }
        if (selected.length >= count) break;
      }
    }

    return selected;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final currentLesson = lesson;
    if (currentLesson == null || currentLesson.steps.isEmpty) {
      return const Center(child: Text('Ders icerigi bulunamadi.'));
    }

    return Column(
      children: [
        _buildProgressBar(currentLesson),
        Expanded(
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final step = _visibleSteps[index];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                    child: _renderStep(step, index),
                  );
                }, childCount: _visibleSteps.length),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(LessonDefinition currentLesson) {
    final steps = currentLesson.steps;
    final progressValue = (_currentStepIndex + 1) / steps.length;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: const Color(0xFF4F46E5),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    currentLesson.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  '${math.min(_currentStepIndex + 1, steps.length)} / ${steps.length}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          LinearProgressIndicator(
            value: progressValue,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFBBF24)),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _renderStep(LessonStep step, int index) {
    final isCompleted = index < _currentStepIndex;
    final badgeStep = '${index + 1}. Adim';

    switch (step.type) {
      case 'text':
        return StepText(
          step: {...step.data, 'badge': badgeStep},
          isActive: !isCompleted,
          onComplete: () => _completeStep(step, awardScore: false),
        );
      case 'word_selector':
        return WordSelector(
          step: {...step.data, 'badge': badgeStep},
          isActive: !isCompleted,
          onComplete: () => _completeStep(step, awardScore: false),
        );
      case 'sequence_sorter':
        return SequenceSorter(
          step: {...step.data, 'badge': badgeStep},
          isActive: !isCompleted,
          onComplete: () => _completeStep(step, awardScore: false),
        );
      case 'category_matcher':
        return CategoryMatcher(
          step: {...step.data, 'badge': badgeStep},
          isActive: !isCompleted,
          onComplete: () => _completeStep(step, awardScore: false),
        );
      case 'info_highlights':
        return InfoHighlightsStep(
          step: {...step.data, 'badge': badgeStep},
          isActive: !isCompleted,
          onComplete: () => _completeStep(step, awardScore: false),
        );
      case 'quiz_single_choice':
        return QuizSingleChoiceStep(
          step: {...step.data, 'badge': badgeStep},
          isActive: !isCompleted,
          onComplete: () => _completeStep(step, awardScore: false),
        );
      case 'logic_builder':
        return LogicBuilderStep(
          step: {...step.data, 'badge': badgeStep},
          isActive: !isCompleted,
          onComplete: () => _completeStep(step, awardScore: false),
        );
      case 'experiment_sequence':
        return ExperimentSequenceStep(
          step: {...step.data, 'badge': badgeStep},
          isActive: !isCompleted,
          onComplete: () => _completeStep(step, awardScore: false),
        );
      case 'reflection_prompt':
        return ReflectionPromptStep(
          step: {...step.data, 'badge': badgeStep},
          isActive: !isCompleted,
          onComplete: () => _completeStep(step, awardScore: false),
        );
      case 'hotspot_image':
        return HotspotImageStep(
          step: {...step.data, 'badge': badgeStep},
          isActive: !isCompleted,
          onSolved: (wrongAttempts) =>
              _completeStep(step, wrongAttempts: wrongAttempts),
        );
      case 'timeline_builder':
        return TimelineBuilderStep(
          step: {...step.data, 'badge': badgeStep},
          isActive: !isCompleted,
          onSolved: (wrongAttempts) =>
              _completeStep(step, wrongAttempts: wrongAttempts),
        );
      case 'cause_effect_match':
        return CauseEffectMatchStep(
          step: {...step.data, 'badge': badgeStep},
          isActive: !isCompleted,
          onSolved: (wrongAttempts) =>
              _completeStep(step, wrongAttempts: wrongAttempts),
        );
      case 'variable_simulator':
        return VariableSimulatorStep(
          step: {...step.data, 'badge': badgeStep},
          isActive: !isCompleted,
          onSolved: (wrongAttempts) =>
              _completeStep(step, wrongAttempts: wrongAttempts),
        );
      case 'error_hunt':
        return ErrorHuntStep(
          step: {...step.data, 'badge': badgeStep},
          isActive: !isCompleted,
          onSolved: (wrongAttempts) =>
              _completeStep(step, wrongAttempts: wrongAttempts),
        );
      case 'memory_grid':
        return MemoryGridStep(
          step: {...step.data, 'badge': badgeStep},
          isActive: !isCompleted,
          onSolved: (wrongAttempts) =>
              _completeStep(step, wrongAttempts: wrongAttempts),
        );
      case 'branching_path':
        return BranchingPathStep(
          step: {...step.data, 'badge': badgeStep},
          isActive: !isCompleted,
          masteryPercent: _masteryPercent,
          onBranch: (targetId) =>
              _completeStep(step, awardScore: false, branchTargetId: targetId),
        );
      case 'micro_review':
        return MicroReviewStep(
          step: {...step.data, 'badge': badgeStep},
          isActive: !isCompleted,
          questions: _selectedMicroReviewQuestions(step),
          onSolved: (wrongAttempts) =>
              _completeStep(step, wrongAttempts: wrongAttempts),
        );
      case 'mastery_overview':
        return MasteryOverviewStep(
          step: step.data,
          earnedPoints: _earnedPoints,
          maxPoints: _maxPoints,
          onComplete: () => Navigator.pop(context),
        );
      case 'summary':
        return SummaryStep(
          step: step.data,
          onComplete: () => Navigator.pop(context),
        );
      default:
        return _UnknownStepCard(
          step: step,
          onSkip: () => _completeStep(step, awardScore: false),
        );
    }
  }
}

class _UnknownStepCard extends StatelessWidget {
  final LessonStep step;
  final VoidCallback onSkip;

  const _UnknownStepCard({required this.step, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Desteklenmeyen step tipi: ${step.type}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text('Bu adim atlanarak derse devam edilebilir.'),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onSkip, child: const Text('Atla')),
        ],
      ),
    );
  }
}

class _ConceptStat {
  int totalAttempts = 0;
  int wrongAttempts = 0;
  int successes = 0;
}
