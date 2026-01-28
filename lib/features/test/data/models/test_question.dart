// lib/features/test/data/models/test_question.dart

import 'package:egitim_uygulamasi/models/question_model.dart';

enum TestMode { normal, weekly }

class TestQuestion {
  final Question question;
  dynamic userAnswer;
  bool isChecked;
  bool isCorrect;

  TestQuestion({
    required this.question,
    this.userAnswer,
    this.isChecked = false,
    this.isCorrect = false,
  });

  /// İmmutable bir kopya oluşturur
  TestQuestion copyWith({
    Question? question,
    dynamic userAnswer,
    bool? isChecked,
    bool? isCorrect,
  }) {
    return TestQuestion(
      question: question ?? this.question,
      userAnswer: userAnswer ?? this.userAnswer,
      isChecked: isChecked ?? this.isChecked,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }

  /// Kullanıcı cevabını güncelleyen yardımcı metod
  TestQuestion withUserAnswer(dynamic newAnswer) {
    return TestQuestion(
      question: question,
      userAnswer: newAnswer,
      isChecked: isChecked,
      isCorrect: isCorrect,
    );
  }

  /// Kontrol durumunu güncelleyen yardımcı metod
  TestQuestion withChecked(bool checked, {bool? correct}) {
    return TestQuestion(
      question: question,
      userAnswer: userAnswer,
      isChecked: checked,
      isCorrect: correct ?? isCorrect,
    );
  }

  /// Doğruluk durumunu güncelleyen yardımcı metod
  TestQuestion withCorrect(bool correct) {
    return TestQuestion(
      question: question,
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
