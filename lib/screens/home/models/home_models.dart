// lib/screens/home/models/home_models.dart

enum NextStepsDisplayState { hidden, collapsed, expanded }

class HomeUnit {
  final int id;
  final String title;
  final int lessonId;
  final String lessonName;
  final int totalQuestions;
  final int solvedQuestions;
  final int correctCount;
  final int wrongCount;
  final int unsolvedCount;
  final double progress;
  final double successRate;
  final int? startWeek;
  final int? endWeek;
  final int orderNo;
  final String? gradeName;

  HomeUnit({
    required this.id,
    required this.title,
    required this.lessonId,
    required this.lessonName,
    required this.totalQuestions,
    required this.solvedQuestions,
    required this.correctCount,
    required this.wrongCount,
    required this.unsolvedCount,
    required this.progress,
    required this.successRate,
    this.startWeek,
    this.endWeek,
    required this.orderNo,
    this.gradeName,
  });

  factory HomeUnit.fromMap(Map<String, dynamic> map) {
    // get_weekly_dashboard_agenda'dan gelen map yapısına göre eşleştiriyoruz
    final int total = (map['total_questions'] as num?)?.toInt() ?? 0;
    final int solved = (map['solved_questions'] as num?)?.toInt() ?? 0;
    final int correct = (map['correct_count'] as num?)?.toInt() ?? 0;
    final int wrong = (map['wrong_count'] as num?)?.toInt() ?? 0;
    final int unsolved = total - solved;

    return HomeUnit(
      id: map['lesson_id'] as int? ?? 0,
      title: map['topic_title'] as String? ?? (map['lesson_name'] as String? ?? 'İsimsiz Ünite'),
      lessonId: map['lesson_id'] as int? ?? 0,
      lessonName: map['lesson_name'] as String? ?? 'Ders',
      totalQuestions: total,
      solvedQuestions: solved,
      correctCount: correct,
      wrongCount: wrong,
      unsolvedCount: unsolved,
      progress: (map['progress_percentage'] ?? 0.0).toDouble() / 100.0,
      successRate: (map['success_rate'] ?? 0.0).toDouble(),
      startWeek: map['curriculum_week'] as int?,
      endWeek: map['curriculum_week'] as int?,
      orderNo: map['lesson_id'] as int? ?? 0,
      gradeName: map['grade_name'] as String?,
    );
  }
}
