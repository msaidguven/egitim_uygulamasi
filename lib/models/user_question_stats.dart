import 'package:json_annotation/json_annotation.dart';

part 'user_question_stats.g.dart';

@JsonSerializable()
class UserQuestionStats {
  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'question_id')
  final int questionId;

  @JsonKey(name: 'last_answer_correct')
  final bool? lastAnswerCorrect;

  @JsonKey(name: 'last_answer_at')
  final DateTime? lastAnswerAt;

  @JsonKey(name: 'total_attempts', defaultValue: 0)
  final int totalAttempts;

  @JsonKey(name: 'correct_attempts', defaultValue: 0)
  final int correctAttempts;

  @JsonKey(name: 'wrong_attempts', defaultValue: 0)
  final int wrongAttempts;

  @JsonKey(name: 'next_review_at')
  final DateTime? nextReviewAt;

  UserQuestionStats({
    required this.userId,
    required this.questionId,
    this.lastAnswerCorrect,
    this.lastAnswerAt,
    required this.totalAttempts,
    required this.correctAttempts,
    required this.wrongAttempts,
    this.nextReviewAt,
  });

  factory UserQuestionStats.fromJson(Map<String, dynamic> json) =>
      _$UserQuestionStatsFromJson(json);

  Map<String, dynamic> toJson() => _$UserQuestionStatsToJson(this);
}
