class NumberCompositionQuestion {
  final int id;
  final String questionSpeech;
  final String correctAnswer;
  final int level;

  NumberCompositionQuestion({
    required this.id,
    required this.questionSpeech,
    required this.correctAnswer,
    required this.level,
  });

  factory NumberCompositionQuestion.fromJson(Map<String, dynamic> json) {
    return NumberCompositionQuestion(
      id: json['id'],
      questionSpeech: json['question_speech'],
      correctAnswer: json['correct_answer'],
      level: json['level'],
    );
  }
}
