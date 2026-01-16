import 'package:json_annotation/json_annotation.dart';

part 'question_choice.g.dart';

@JsonSerializable()
class QuestionChoice {
  final int id;
  @JsonKey(name: 'choice_text')
  final String choiceText;
  @JsonKey(name: 'is_correct', defaultValue: false)
  final bool isCorrect; // GERİ EKLENDİ

  QuestionChoice({
    required this.id,
    required this.choiceText,
    required this.isCorrect, // GERİ EKLENDİ
  });

  factory QuestionChoice.fromJson(Map<String, dynamic> json) =>
      _$QuestionChoiceFromJson(json);

  Map<String, dynamic> toJson() => _$QuestionChoiceToJson(this);
}
