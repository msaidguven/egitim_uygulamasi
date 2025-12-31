// lib/models/grade_model.dart

import 'package:egitim_uygulamasi/models/lesson_model.dart';

class Grade {
  final int id;
  final String name;
  final int orderNo;
  final bool isActive;
  final List<Lesson> lessons; // Derslerin listesi

  Grade({
    required this.id,
    required this.name,
    required this.orderNo,
    required this.isActive,
    this.lessons = const [], // Varsayılan olarak boş liste
  });

  factory Grade.fromMap(Map<String, dynamic> map) {
    // 'lessons' alanı null ise boş bir liste kullan
    var lessonList = (map['lessons'] as List<dynamic>?)
            ?.map((lessonMap) =>
                Lesson.fromMap(lessonMap as Map<String, dynamic>))
            .toList() ??
        [];

    return Grade(
      id: map['id'] as int,
      name: map['name'] as String,
      orderNo: map['order_no'] as int,
      isActive: map['is_active'] as bool? ?? true,
      lessons: lessonList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'order_no': orderNo,
      'is_active': isActive,
    };
  }
}
