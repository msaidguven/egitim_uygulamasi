import 'package:egitim_uygulamasi/models/question_choice.dart'; // EKLENDİ
import 'package:json_annotation/json_annotation.dart';

part 'question.g.dart';

@JsonSerializable()
class Question {
  final int id;
  @JsonKey(name: 'question_text')
  final String questionText;
  final int difficulty;
  @JsonKey(name: 'solution_text')
  final String? solutionText;

  Question({
    required this.id,
    required this.questionText,
    required this.difficulty,
    required this.questionTypeId,
    required this.choices,
    this.solutionText,
  });

  factory Question.fromJson(Map<String, dynamic> json) =>
      _$QuestionFromJson(json);

  Map<String, dynamic> toJson() => _$QuestionToJson(this);
}
