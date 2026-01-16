// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Question _$QuestionFromJson(Map<String, dynamic> json) => Question(
      id: json['id'] as int,
      questionText: json['question_text'] as String,
      difficulty: json['difficulty'] as int,
      questionTypeId: json['question_type_id'] as int,
      choices: (json['choices'] as List<dynamic>?)
              ?.map((e) => QuestionChoice.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$QuestionToJson(Question instance) => <String, dynamic>{
      'id': instance.id,
      'question_text': instance.questionText,
      'difficulty': instance.difficulty,
      'question_type_id': instance.questionTypeId,
      'choices': instance.choices,
    };
