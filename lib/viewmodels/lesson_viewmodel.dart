import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:egitim_uygulamasi/models/lesson_model.dart';

class LessonViewModel extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  bool _isLoading = false;
  List<Lesson> _lessons = [];
  String? _errorMessage;

  bool get isLoading => _isLoading;
  List<Lesson> get lessons => _lessons;
  String? get errorMessage => _errorMessage;

  Future<void> fetchLessonsForGrade(int gradeId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('lesson_grades')
          .select('lessons!inner(*)')
          .eq('grade_id', gradeId)
          .eq('lessons.is_active', true)
          .order('order_no', referencedTable: 'lessons', ascending: true);

      _lessons = response
          .map((data) => Lesson.fromMap(data['lessons']))
          .toList();
    } catch (e) {
      _errorMessage = "Dersler yüklenirken bir hata oluştu: $e";
      _lessons = [];
    }

    _isLoading = false;
    notifyListeners();
  }
}
