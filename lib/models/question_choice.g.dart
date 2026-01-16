// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question_choice.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuestionChoice _$QuestionChoiceFromJson(Map<String, dynamic> json) =>
    QuestionChoice(
      id: json['id'] as int,
      choiceText: json['choice_text'] as String,
      isCorrect: json['is_correct'] as bool? ?? false, // GERİ EKLENDİ
    );

Map<String, dynamic> _$QuestionChoiceToJson(QuestionChoice instance) =>
    <String, dynamic>{
      'id': instance.id,
      'choice_text': instance.choiceText,
      'is_correct': instance.isCorrect, // GERİ EKLENDİ
    };
