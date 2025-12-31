// lib/models/grade_with_lessons_model.dart

import 'package:egitim_uygulamasi/models/grade_model.dart';
import 'package:egitim_uygulamasi/models/lesson_model.dart';

/// A data class to hold the nested structure for the curriculum's left panel.
class GradeWithLessons {
  final Grade grade;
  final List<Lesson> lessons;

  GradeWithLessons(this.grade, this.lessons);
}
