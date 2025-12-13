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

  Future<void> fetchLessonsForGrade(String gradeName) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // gradeName'den (örn: "5. Sınıf") sayısal değeri (5) çıkaralım.
    int? gradeNumber;
    gradeNumber = int.tryParse(gradeName.split('.').first);

    // Eğer gradeName'den sayısal bir değer çıkaramazsak, hata verip işlemi durduralım.
    if (gradeNumber == null) {
      _errorMessage = "Geçersiz sınıf formatı: $gradeName";
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      // lesson_grades tablosu üzerinden, belirtilen sınıf numarasına sahip dersleri çekiyoruz.
      final response = await supabase
          .from('lesson_grades')
          .select('lessons!inner(*)') // !inner belirsizliği giderir
          .eq('grade', gradeNumber)
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
