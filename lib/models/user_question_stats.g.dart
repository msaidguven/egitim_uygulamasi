// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_question_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserQuestionStats _$UserQuestionStatsFromJson(Map<String, dynamic> json) =>
    UserQuestionStats(
      userId: json['user_id'] as String,
      questionId: json['question_id'] as int,
      lastAnswerCorrect: json['last_answer_correct'] as bool?,
      lastAnswerAt: json['last_answer_at'] == null
          ? null
          : DateTime.parse(json['last_answer_at'] as String),
      totalAttempts: json['total_attempts'] as int? ?? 0,
      correctAttempts: json['correct_attempts'] as int? ?? 0,
      wrongAttempts: json['wrong_attempts'] as int? ?? 0,
      nextReviewAt: json['next_review_at'] == null
          ? null
          : DateTime.parse(json['next_review_at'] as String),
    );

Map<String, dynamic> _$UserQuestionStatsToJson(UserQuestionStats instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'question_id': instance.questionId,
      'last_answer_correct': instance.lastAnswerCorrect,
      'last_answer_at': instance.lastAnswerAt?.toIso8601String(),
      'total_attempts': instance.totalAttempts,
      'correct_attempts': instance.correctAttempts,
      'wrong_attempts': instance.wrongAttempts,
      'next_review_at': instance.nextReviewAt?.toIso8601String(),
    };
