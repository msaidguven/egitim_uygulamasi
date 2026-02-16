// lib/models/question_model.dart

import 'package:egitim_uygulamasi/models/question_blank_option.dart';

// YENİ: Kullanıcının bir soruyla olan geçmişini tutan model
class UserQuestionStats {
  final int totalAttempts;
  final int correctAttempts;
  final int wrongAttempts;
  final DateTime? lastAnswerAt;

  UserQuestionStats({
    required this.totalAttempts,
    required this.correctAttempts,
    required this.wrongAttempts,
    this.lastAnswerAt,
  });

  factory UserQuestionStats.fromMap(Map<String, dynamic> map) {
    return UserQuestionStats(
      totalAttempts: map['total_attempts'] as int? ?? 0,
      correctAttempts: map['correct_attempts'] as int? ?? 0,
      wrongAttempts: map['wrong_attempts'] as int? ?? 0,
      lastAnswerAt: map['last_answer_at'] != null
          ? DateTime.parse(map['last_answer_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'total_attempts': totalAttempts,
      'correct_attempts': correctAttempts,
      'wrong_attempts': wrongAttempts,
      'last_answer_at': lastAnswerAt?.toIso8601String(),
    };
  }
}


enum QuestionType {
  multiple_choice,
  true_false,
  fill_blank,
  classical,
  matching,
  unknown;

  static QuestionType fromString(String? type) {
    switch (type) {
      case 'multiple_choice':
        return QuestionType.multiple_choice;
      case 'true_false':
        return QuestionType.true_false;
      case 'fill_blank':
        return QuestionType.fill_blank;
      case 'classical':
        return QuestionType.classical;
      case 'matching':
        return QuestionType.matching;
      default:
        return QuestionType.unknown;
    }
  }
  
  String toJson() => name;
  static QuestionType fromJson(String json) => QuestionType.fromString(json);


  static QuestionType fromId(int? id) {
    switch (id) {
      case 1:
        return QuestionType.multiple_choice;
      case 2:
        return QuestionType.true_false;
      case 3:
        return QuestionType.fill_blank;
      case 4:
        return QuestionType.classical;
      case 5:
        return QuestionType.matching;
      default:
        return QuestionType.unknown;
    }
  }
}

class QuestionChoice {
  final int id;
  final String text;
  final bool isCorrect;

  QuestionChoice({
    required this.id,
    required this.text,
    required this.isCorrect,
  });

  factory QuestionChoice.fromMap(Map<String, dynamic> map) {
    return QuestionChoice(
      id: map['id'] as int? ?? 0,
      text: map['choice_text'] as String? ?? '',
      isCorrect: map['is_correct'] as bool? ?? false,
    );
  }

  factory QuestionChoice.fromJson(Map<String, dynamic> json) {
    return QuestionChoice(
      id: json['id'] as int? ?? 0,
      text: json['option_text'] as String? ?? json['choice_text'] as String? ?? '',
      isCorrect: json['is_correct'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'choice_text': text,
      'is_correct': isCorrect,
    };
  }
}

class MatchingPair {
  final int id;
  final String leftText;
  final String rightText;

  MatchingPair({
    required this.id,
    required this.leftText,
    required this.rightText,
  });

  factory MatchingPair.fromMap(Map<String, dynamic> map) {
    return MatchingPair(
      id: map['id'] as int? ?? 0,
      leftText: map['left_text'] as String? ?? '',
      rightText: map['right_text'] as String? ?? '',
    );
  }

  factory MatchingPair.fromJson(Map<String, dynamic> json) {
    return MatchingPair(
      id: json['id'] as int? ?? 0,
      leftText: json['left_text'] as String? ?? '',
      rightText: json['right_text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'left_text': leftText,
      'right_text': rightText,
    };
  }
}

class Question {
  final int id;
  final String text;
  final int difficulty;
  final int score;
  final QuestionType type;
  final List<QuestionChoice> choices;
  final List<QuestionBlankOption> blankOptions;
  final String? modelAnswer;
  final List<MatchingPair>? matchingPairs;
  final String? solutionText; // YENİ: Çözüm açıklaması
  final UserQuestionStats? userStats; // YENİ: Kullanıcı istatistikleri alanı

  Question({
    required this.id,
    required this.text,
    required this.difficulty,
    required this.score,
    required this.type,
    this.choices = const [],
    this.blankOptions = const [],
    this.modelAnswer,
    this.matchingPairs,
    this.solutionText, // YENİ
    this.userStats, // YENİ
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    QuestionType questionType;
    if (map['question_type'] != null && map['question_type'] is Map) {
      questionType = QuestionType.fromString(map['question_type']['code'] as String?);
    } else if (map['question_type_id'] != null) {
      questionType = QuestionType.fromId(map['question_type_id'] as int?);
    } else {
      questionType = QuestionType.unknown;
    }
        
    final choicesList = (map['question_choices'] as List<dynamic>?)
            ?.map((choiceMap) =>
                QuestionChoice.fromMap(choiceMap as Map<String, dynamic>))
            .toList() ??
        [];

    final matchingPairsList = (map['question_matching_pairs'] as List<dynamic>?)
            ?.map((pairMap) =>
                MatchingPair.fromMap(pairMap as Map<String, dynamic>))
            .toList();

    final blankOptionsList = (map['question_blank_options'] as List<dynamic>?)
            ?.map((optionMap) =>
                QuestionBlankOption.fromMap(optionMap as Map<String, dynamic>))
            .toList() ??
        [];

    String? modelAnswer;
     if (questionType == QuestionType.classical && map['question_classical'] != null && (map['question_classical'] as List).isNotEmpty) {
        modelAnswer = (map['question_classical'] as List).first['model_answer'] as String?;
    }

    // YENİ: Gelen user_stats verisini parse et
    final userStatsData = map['user_stats'] as Map<String, dynamic>?;
    final userStats = userStatsData != null ? UserQuestionStats.fromMap(userStatsData) : null;

    return Question(
      id: map['id'] as int? ?? 0,
      text: map['question_text'] as String? ?? '',
      difficulty: map['difficulty'] as int? ?? 1,
      score: map['score'] as int? ?? 1,
      type: questionType,
      choices: choicesList,
      blankOptions: blankOptionsList,
      modelAnswer: modelAnswer,
      matchingPairs: matchingPairsList,
      solutionText: map['solution_text'] as String?, // YENİ
      userStats: userStats, // YENİ
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question_text': text,
      'difficulty': difficulty,
      'score': score,
      'question_type_id': type.index + 1,
      'question_choices': choices.map((c) => c.toMap()).toList(),
      'question_blank_options': blankOptions.map((b) => b.toMap()).toList(),
      'question_matching_pairs': matchingPairs?.map((p) => p.toMap()).toList(),
      'question_classical': modelAnswer != null ? [{'model_answer': modelAnswer}] : null,
      'solution_text': solutionText, // YENİ
      'user_stats': userStats?.toMap(),
    };
  }
}
