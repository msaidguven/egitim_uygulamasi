// lib/features/test/data/models/test_question.dart

import 'package:egitim_uygulamasi/models/question_blank_option.dart';
import 'package:egitim_uygulamasi/models/question_model.dart';

enum TestMode { normal, weekly, srs }

class TestQuestion {
  final Question question;
  final List<QuestionChoice> shuffledChoices;
  final List<QuestionBlankOption> shuffledBlankOptions;
  final List<MatchingPair> shuffledMatchingPairsRight;
  final List<String> shuffledMatchingLeftTexts;
  dynamic userAnswer;
  bool isChecked;
  bool isCorrect;

  TestQuestion({
    required this.question,
    List<QuestionChoice>? shuffledChoices,
    List<QuestionBlankOption>? shuffledBlankOptions,
    List<MatchingPair>? shuffledMatchingPairsRight,
    List<String>? shuffledMatchingLeftTexts,
    this.userAnswer,
    this.isChecked = false,
    this.isCorrect = false,
  })  : shuffledChoices = shuffledChoices ?? _shuffleChoices(question.choices),
        shuffledBlankOptions =
            shuffledBlankOptions ?? _shuffleBlankOptions(question.blankOptions),
        shuffledMatchingPairsRight = shuffledMatchingPairsRight ??
            _shuffleMatchingPairsRight(question.matchingPairs),
        shuffledMatchingLeftTexts = shuffledMatchingLeftTexts ??
            _shuffleMatchingLeftTexts(question.matchingPairs);

  static List<QuestionChoice> _shuffleChoices(List<QuestionChoice> choices) {
    if (choices.length <= 1) return List<QuestionChoice>.from(choices);
    final shuffled = List<QuestionChoice>.from(choices);
    shuffled.shuffle();
    return shuffled;
  }

  static List<QuestionBlankOption> _shuffleBlankOptions(
    List<QuestionBlankOption> options,
  ) {
    if (options.length <= 1) return List<QuestionBlankOption>.from(options);
    final shuffled = List<QuestionBlankOption>.from(options);
    shuffled.shuffle();
    return shuffled;
  }

  static List<MatchingPair> _shuffleMatchingPairsRight(
    List<MatchingPair>? pairs,
  ) {
    if (pairs == null || pairs.length <= 1) {
      return List<MatchingPair>.from(pairs ?? const []);
    }
    final shuffled = List<MatchingPair>.from(pairs);
    shuffled.shuffle();
    return shuffled;
  }

  static List<String> _shuffleMatchingLeftTexts(
    List<MatchingPair>? pairs,
  ) {
    if (pairs == null || pairs.isEmpty) return const [];
    final shuffled = pairs.map((p) => p.leftText).toList();
    if (shuffled.length <= 1) return shuffled;
    shuffled.shuffle();
    return shuffled;
  }

  /// İmmutable bir kopya oluşturur
  TestQuestion copyWith({
    Question? question,
    List<QuestionChoice>? shuffledChoices,
    List<QuestionBlankOption>? shuffledBlankOptions,
    List<MatchingPair>? shuffledMatchingPairsRight,
    List<String>? shuffledMatchingLeftTexts,
    dynamic userAnswer,
    bool? isChecked,
    bool? isCorrect,
  }) {
    return TestQuestion(
      question: question ?? this.question,
      shuffledChoices: shuffledChoices ?? this.shuffledChoices,
      shuffledBlankOptions: shuffledBlankOptions ?? this.shuffledBlankOptions,
      shuffledMatchingPairsRight:
          shuffledMatchingPairsRight ?? this.shuffledMatchingPairsRight,
      shuffledMatchingLeftTexts:
          shuffledMatchingLeftTexts ?? this.shuffledMatchingLeftTexts,
      userAnswer: userAnswer ?? this.userAnswer,
      isChecked: isChecked ?? this.isChecked,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }

  /// Kullanıcı cevabını güncelleyen yardımcı metod
  TestQuestion withUserAnswer(dynamic newAnswer) {
    return TestQuestion(
      question: question,
      shuffledChoices: shuffledChoices,
      shuffledBlankOptions: shuffledBlankOptions,
      shuffledMatchingPairsRight: shuffledMatchingPairsRight,
      shuffledMatchingLeftTexts: shuffledMatchingLeftTexts,
      userAnswer: newAnswer,
      isChecked: isChecked,
      isCorrect: isCorrect,
    );
  }

  /// Kontrol durumunu güncelleyen yardımcı metod
  TestQuestion withChecked(bool checked, {bool? correct}) {
    return TestQuestion(
      question: question,
      shuffledChoices: shuffledChoices,
      shuffledBlankOptions: shuffledBlankOptions,
      shuffledMatchingPairsRight: shuffledMatchingPairsRight,
      shuffledMatchingLeftTexts: shuffledMatchingLeftTexts,
      userAnswer: userAnswer,
      isChecked: checked,
      isCorrect: correct ?? isCorrect,
    );
  }

  /// Doğruluk durumunu güncelleyen yardımcı metod
  TestQuestion withCorrect(bool correct) {
    return TestQuestion(
      question: question,
      shuffledChoices: shuffledChoices,
      shuffledBlankOptions: shuffledBlankOptions,
      shuffledMatchingPairsRight: shuffledMatchingPairsRight,
      shuffledMatchingLeftTexts: shuffledMatchingLeftTexts,
      userAnswer: userAnswer,
      isChecked: isChecked,
      isCorrect: correct,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TestQuestion &&
        other.question.id == question.id &&
        other.userAnswer == userAnswer &&
        other.isChecked == isChecked &&
        other.isCorrect == isCorrect;
  }

  @override
  int get hashCode {
    return question.id.hashCode ^
        (userAnswer?.hashCode ?? 0) ^
        isChecked.hashCode ^
        isCorrect.hashCode;
  }

  @override
  String toString() {
    return 'TestQuestion(questionId: ${question.id}, userAnswer: $userAnswer, isChecked: $isChecked, isCorrect: $isCorrect)';
  }
}
