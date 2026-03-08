// lib/models/lesson_model.dart

import 'lesson_step_model.dart';

class Lesson {
  final int id;
  final String name;
  final String? icon;

  Lesson({
    required this.id,
    required this.name,
    this.icon,
  });

  factory Lesson.fromMap(Map<String, dynamic> map) {
    return Lesson(
      id: map['id'] as int,
      name: map['name'] as String,
      icon: map['icon'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
    };
  }
}

class EngineLessonModel {
  final String lessonId;
  final String title;
  final String description;
  final String estimatedTime;
  final String difficultyLevel;
  final List<LessonStepModel> steps;
  final Map<String, dynamic> metadata;

  const EngineLessonModel({
    required this.lessonId,
    required this.title,
    required this.description,
    required this.estimatedTime,
    required this.difficultyLevel,
    required this.steps,
    required this.metadata,
  });

  factory EngineLessonModel.fromJson(Map<String, dynamic> json) {
    final metadata =
        Map<String, dynamic>.from(json['metadata'] as Map<String, dynamic>? ?? {});

    final rawSteps = (json['steps'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();

    return EngineLessonModel(
      lessonId: (json['lesson_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? 'Untitled Lesson').toString(),
      description: (json['description'] ?? metadata['description'] ?? '').toString(),
      estimatedTime:
          (json['estimated_time'] ?? metadata['estimated_duration_min'] ?? '')
              .toString(),
      difficultyLevel:
          (json['difficulty_level'] ?? metadata['difficulty_level'] ?? '')
              .toString(),
      steps: rawSteps.map(LessonStepModel.fromJson).toList(growable: false),
      metadata: metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'lesson_id': lessonId,
        'title': title,
        'description': description,
        'estimated_time': estimatedTime,
        'difficulty_level': difficultyLevel,
        'metadata': metadata,
        'steps': steps.map((e) => e.toJson()).toList(),
      };
}
