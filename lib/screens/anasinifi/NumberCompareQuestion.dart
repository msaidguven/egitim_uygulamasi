class NumberCompareQuestion {
  final int id;
  final String questionSpeech;
  final String leftDisplay;
  final String leftSpeech;
  final String rightDisplay;
  final String rightSpeech;
  final String correctSide;
  final int level;

  NumberCompareQuestion({
    required this.id,
    required this.questionSpeech,
    required this.leftDisplay,
    required this.leftSpeech,
    required this.rightDisplay,
    required this.rightSpeech,
    required this.correctSide,
    required this.level,
  });

  factory NumberCompareQuestion.fromJson(Map<String, dynamic> json) {
    return NumberCompareQuestion(
      id: json['id'],
      questionSpeech: json['question_speech'],
      leftDisplay: json['left_display'],
      leftSpeech: json['left_speech'],
      rightDisplay: json['right_display'],
      rightSpeech: json['right_speech'],
      correctSide: json['correct_side'],
      level: json['level'],
    );
  }
}
