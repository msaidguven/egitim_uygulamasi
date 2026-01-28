// lib/features/test/data/models/test_session.dart

class TestSession {
  final int id;
  final String? userId;
  final int? unitId;
  final DateTime createdAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? settings;
  final List<int>? questionIds;
  final String clientId;
  final int? lessonId;
  final int? gradeId;

  // UI için zenginleştirilmiş alanlar (join ile gelir)
  final String? lessonName;
  final String? unitName;

  TestSession({
    required this.id,
    this.userId,
    this.unitId,
    required this.createdAt,
    this.completedAt,
    this.settings,
    this.questionIds,
    required this.clientId,
    this.lessonId,
    this.gradeId,
    this.lessonName,
    this.unitName,
  });

  factory TestSession.fromMap(Map<String, dynamic> map) {
    final units = (map['units'] is Map) ? (map['units'] as Map) : null;
    final lessons = (map['lessons'] is Map) ? (map['lessons'] as Map) : null;

    final unitTitle = units?['title']?.toString();
    final lessonNameFromLessonFk = lessons?['name']?.toString();
    final lessonNameFromUnitsJoin = (units?['lessons'] is Map)
        ? (units?['lessons']['name']?.toString())
        : null;

    final qIdsRaw = map['question_ids'];
    List<int>? questionIds;
    if (qIdsRaw is List) {
      questionIds = qIdsRaw
          .where((e) => e != null)
          .map((e) => int.tryParse(e.toString()))
          .whereType<int>()
          .toList();
    }

    final createdAt = DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now();
    final completedAtStr = map['completed_at']?.toString();
    final completedAt = completedAtStr == null ? null : DateTime.tryParse(completedAtStr);

    return TestSession(
      id: map['id'] as int,
      userId: map['user_id']?.toString(),
      unitId: map['unit_id'] as int?,
      createdAt: createdAt,
      completedAt: completedAt,
      settings: (map['settings'] is Map<String, dynamic>)
          ? (map['settings'] as Map<String, dynamic>)
          : (map['settings'] is Map ? Map<String, dynamic>.from(map['settings'] as Map) : null),
      questionIds: questionIds,
      clientId: map['client_id']?.toString() ?? '',
      lessonId: map['lesson_id'] as int?,
      gradeId: map['grade_id'] as int?,
      lessonName: lessonNameFromLessonFk ?? lessonNameFromUnitsJoin,
      unitName: unitTitle,
    );
  }
}

