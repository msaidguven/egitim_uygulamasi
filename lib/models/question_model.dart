// lib/models/question_model.dart

import 'package:egitim_uygulamasi/models/question_blank_option.dart';

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
      id: map['id'] as int,
      text: map['choice_text'] as String,
      isCorrect: map['is_correct'] as bool,
    );
  }
}

class MatchingPair {
  final int id;
  final String left_text;
  final String right_text;

  MatchingPair({
    required this.id,
    required this.left_text,
    required this.right_text,
  });

  factory MatchingPair.fromMap(Map<String, dynamic> map) {
    return MatchingPair(
      id: map['id'] as int,
      left_text: map['left_text'] as String,
      right_text: map['right_text'] as String,
    );
  }
}

class Question {
  final int id;
  final String text;
  final int difficulty;
  final int score;
  final QuestionType type;
  final List<QuestionChoice> choices;
  final bool? correctAnswer; // For true/false types
  final List<QuestionBlankOption> blankOptions;
  final String? modelAnswer; // For classical type
  final List<MatchingPair>? matchingPairs;

  Question({
    required this.id,
    required this.text,
    required this.difficulty,
    required this.score,
    required this.type,
    this.choices = const [],
    this.correctAnswer,
    this.blankOptions = const [],
    this.modelAnswer,
    this.matchingPairs,
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

    bool? correctAnswer;
    if (questionType == QuestionType.true_false) {
      correctAnswer = map['correct_answer'] as bool?;
    }

    return Question(
      id: map['id'] as int,
      text: map['question_text'] as String? ?? '',
      difficulty: map['difficulty'] as int? ?? 1,
      score: map['score'] as int? ?? 1,
      type: questionType,
      choices: choicesList,
      correctAnswer: correctAnswer,
      blankOptions: blankOptionsList,
      modelAnswer: modelAnswer,
      matchingPairs: matchingPairsList,
    );
  }
}
