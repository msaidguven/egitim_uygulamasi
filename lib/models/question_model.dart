// lib/models/question_model.dart

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
  final String? correctAnswer; // For blank and true/false types
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
    this.modelAnswer,
    this.matchingPairs,
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    final questionType =
        QuestionType.fromString(map['question_type_code'] as String?);
        
    final choicesList = (map['question_choices'] as List<dynamic>?)
            ?.map((choiceMap) =>
                QuestionChoice.fromMap(choiceMap as Map<String, dynamic>))
            .toList() ??
        [];

    final matchingPairsList = (map['question_matching_pairs'] as List<dynamic>?)
            ?.map((pairMap) =>
                MatchingPair.fromMap(pairMap as Map<String, dynamic>))
            .toList(); // Removed ?? []
    
    String? correctAnswer;
    if ((questionType == QuestionType.fill_blank || questionType == QuestionType.true_false) &&
        map['question_blanks'] != null && 
        (map['question_blanks'] as List).isNotEmpty) {
      correctAnswer = (map['question_blanks'] as List).first['correct_answer'] as String?;
    }

    String? modelAnswer;
     if (questionType == QuestionType.classical && map['question_classical'] != null && (map['question_classical'] as List).isNotEmpty) {
        modelAnswer = (map['question_classical'] as List).first['model_answer'] as String?;
    }

    return Question(
      id: map['id'] as int,
      text: map['question_text'] as String,
      difficulty: map['difficulty'] as int? ?? 1,
      score: map['score'] as int? ?? 1,
      type: questionType,
      choices: choicesList,
      correctAnswer: correctAnswer,
      modelAnswer: modelAnswer,
      matchingPairs: matchingPairsList,
    );
  }
}
