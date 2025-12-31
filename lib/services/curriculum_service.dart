// lib/services/curriculum_service.dart

import 'package:egitim_uygulamasi/main.dart';
import 'package:egitim_uygulamasi/models/grade_model.dart';
import 'package:egitim_uygulamasi/models/grade_with_lessons_model.dart';
import 'package:egitim_uygulamasi/models/lesson_model.dart';

class CurriculumService {
  /// Fetches grades, lessons, and the links between them to build a nested list.
  Future<List<GradeWithLessons>> getGradesWithLessons() async {
    try {
      final gradesRes =
          await supabase.from('grades').select().order('order_no', ascending: true);
      final lessonsRes = await supabase.from('lessons').select();
      final lessonGradesRes = await supabase.from('lesson_grades').select();

      final allLessons =
          (lessonsRes as List).map((data) => Lesson.fromMap(data)).toList();
      final allGrades =
          (gradesRes as List).map((data) => Grade.fromMap(data)).toList();

      final List<GradeWithLessons> result = [];

      for (var grade in allGrades) {
        final lessonIdsForGrade = (lessonGradesRes as List)
            .where((link) => link['grade_id'] == grade.id)
            .map((link) => link['lesson_id'] as int)
            .toSet();

        if (lessonIdsForGrade.isNotEmpty) {
          final lessonsForGrade = allLessons
              .where((lesson) => lessonIdsForGrade.contains(lesson.id))
              .toList();
          lessonsForGrade.sort((a, b) => a.name.compareTo(b.name));
          result.add(GradeWithLessons(grade, lessonsForGrade));
        }
      }
      return result;
    } catch (e) {
      // In a real app, you might want to log this error to a service
      // instead of just throwing it.
      throw Exception('Müfredat verisi yüklenirken bir hata oluştu: $e');
    }
  }
}

