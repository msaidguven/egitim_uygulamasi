// lib/models/question_blank_option.dart

import 'package:flutter/foundation.dart';

class QuestionBlankOption {
  final int id;
  final int questionId;
  final String optionText;
  final bool isCorrect;
  final int orderNo;

  QuestionBlankOption({
    required this.id,
    required this.questionId,
    required this.optionText,
    required this.isCorrect,
    required this.orderNo,
  });

  factory QuestionBlankOption.fromMap(Map<String, dynamic> map) {
    return QuestionBlankOption(
      id: map['id'] as int,
      questionId: map['question_id'] as int,
      optionText: map['option_text'] as String,
      isCorrect: map['is_correct'] as bool,
      orderNo: map['order_no'] ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is QuestionBlankOption &&
      other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
