import 'dart:convert';

import 'package:egitim_uygulamasi/models/lesson_model.dart';
import 'package:egitim_uygulamasi/models/lesson_step_model.dart';

class LessonParser {
  static const Map<String, String> _typeAliases = {
    'info_list': 'risk_cards',
    'misconceptions': 'concept_cards',
    'interactive_activity': 'reflection',
    'analysis': 'risk_cards',
    'critical_thinking': 'reflection',
    'keywords': 'concept_cards',
    'progress_tracker': 'summary',
    'infographic': 'summary',
    'case_studies': 'risk_cards',
  };

  EngineLessonModel parseJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Lesson JSON root must be an object.');
    }
    return parseMap(decoded);
  }

  EngineLessonModel parseMap(Map<String, dynamic> source) {
    final lesson = EngineLessonModel.fromJson(source);
    final normalizedSteps = lesson.steps.map(_normalizeStep).toList(growable: false);

    return EngineLessonModel(
      lessonId: lesson.lessonId,
      title: lesson.title,
      description: lesson.description,
      estimatedTime: lesson.estimatedTime,
      difficultyLevel: lesson.difficultyLevel,
      steps: normalizedSteps,
      metadata: lesson.metadata,
    );
  }

  LessonStepModel _normalizeStep(LessonStepModel step) {
    final normalizedType = _typeAliases[step.type] ?? step.type;

    final interaction = Map<String, dynamic>.from(step.interaction);
    interaction.putIfAbsent('required', () {
      const requiresInteraction = {
        'concept_cards',
        'risk_cards',
        'scenario_choice',
        'role_play',
        'mini_game',
        'quiz',
        'security_score',
        'reflection',
      };
      return requiresInteraction.contains(normalizedType);
    });

    final content = Map<String, dynamic>.from(step.content);
    if (normalizedType == 'quiz') {
      final rawQuestions = (content['questions'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map((q) {
        final copy = Map<String, dynamic>.from(q);
        copy['answer'] = copy['answer'] ?? copy['correct'] ?? copy['correct_index'];
        return copy;
      }).toList();
      content['questions'] = rawQuestions;
    }

    return LessonStepModel(
      id: step.id,
      type: normalizedType,
      title: step.title,
      content: content,
      interaction: interaction,
      xp: step.xp,
    );
  }

  List<String> validate(Map<String, dynamic> source) {
    final issues = <String>[];

    if (source['title'] == null) {
      issues.add('Missing top-level `title`.');
    }
    if (source['steps'] is! List) {
      issues.add('Missing or invalid `steps` array.');
      return issues;
    }

    final steps = (source['steps'] as List)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);

    for (final step in steps) {
      if (step['id'] == null) issues.add('A step is missing `id`.');
      if (step['type'] == null) issues.add('Step `${step['id']}` is missing `type`.');
      if (step['title'] == null) issues.add('Step `${step['id']}` is missing `title`.');
      if (step['data'] == null && step['content'] == null) {
        issues.add('Step `${step['id']}` is missing `data/content`.');
      }
    }

    return issues;
  }
}
