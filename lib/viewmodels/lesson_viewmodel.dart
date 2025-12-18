// lib/viewmodels/subject_viewmodel.dart

import 'package:flutter/material.dart';
import 'package:egitim_uygulamasi/main.dart';
import 'package:egitim_uygulamasi/models/lesson_model.dart'; // Model adını da değiştirdiğinizi varsayıyorum.

class LessonViewModel extends ChangeNotifier {
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
      // lesson_grades tablosu üzerinden, belirtilen sınıf numarasına sahip dersleri çekiyoruz.
      // Hata düzeltildi: 'grade' kolonu 'grade_id' olarak güncellendi.
      // Metod artık doğrudan 'gradeId' parametresi alıyor.
      final response = await supabase
          .from('lesson_grades')
          .select('lessons!inner(*)') // !inner belirsizliği giderir
          .eq('grade_id', gradeId)
          .order('order_no', referencedTable: 'lessons', ascending: true);

      // Gelen veri `[{'lessons': {...}}, ...]` formatında olacağı için 'lessons' anahtarını alıyoruz.
      _lessons = response
          .map((data) => Lesson.fromMap(data['lessons']))
          .toList();
    } catch (e) {
      _errorMessage = "Dersler yüklenirken bir hata oluştu: $e";
      _lessons = []; // Hata durumunda listeyi boşalt
    }

    _isLoading = false;
    notifyListeners();
  }
}
