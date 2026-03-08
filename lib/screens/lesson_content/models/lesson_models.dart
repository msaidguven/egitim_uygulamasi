class LessonDefinition {
  final String id;
  final String title;
  final List<LessonStep> steps;

  const LessonDefinition({
    required this.id,
    required this.title,
    required this.steps,
  });

  factory LessonDefinition.fromJson(Map<String, dynamic> json) {
    final rawSteps = json['steps'];
    final parsedSteps = rawSteps is List
        ? rawSteps
              .whereType<Map>()
              .map((raw) => LessonStep.fromJson(Map<String, dynamic>.from(raw)))
              .toList()
        : <LessonStep>[];

    return LessonDefinition(
      id: (json['lesson_id'] ?? json['id'] ?? 'lesson_unknown').toString(),
      title: (json['title'] ?? 'Ders').toString(),
      steps: parsedSteps,
    );
  }
}

class LessonStep {
  final String id;
  final String type;
  final String? title;
  final String? subtitle;
  final Map<String, dynamic> data;

  const LessonStep({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.data,
  });

  factory LessonStep.fromJson(Map<String, dynamic> json) {
    return LessonStep(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      title: json['title']?.toString(),
      subtitle: json['subtitle']?.toString(),
      data: json,
    );
  }
}
