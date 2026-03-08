// lib/screens/lesson_content/models/lesson_models_v3.dart

class LessonV3 {
  final String id;
  final String title;
  final String subject;
  final int totalPoints;
  final List<StepV3> steps;

  LessonV3({
    required this.id,
    required this.title,
    required this.subject,
    required this.totalPoints,
    required this.steps,
  });

  factory LessonV3.fromJson(Map<String, dynamic> json) => LessonV3(
        id: json['id'] as String,
        title: json['title'] as String,
        subject: json['subject'] as String,
        totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
        steps: (json['steps'] as List<dynamic>)
            .map((e) => StepV3.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class StepV3 {
  final String id;
  final String type;
  final String? title;
  final String? instruction;
  final String? explanation; // New field for "Learn" first
  final Map<String, dynamic> data;

  StepV3({
    required this.id,
    required this.type,
    this.title,
    this.instruction,
    this.explanation,
    required this.data,
  });

  factory StepV3.fromJson(Map<String, dynamic> json) => StepV3(
        id: json['id'] as String,
        type: json['type'] as String,
        title: json['title'] as String?,
        instruction: json['instruction'] as String?,
        explanation: json['explanation'] as String?,
        data: json,
      );
}
