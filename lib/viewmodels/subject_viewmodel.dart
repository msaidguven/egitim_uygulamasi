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

  Future<void> fetchLessons() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 'lessons' tablosunda 'grade_id' olmadığı için tüm dersleri çekiyoruz.
      final response = await supabase
          .from('lessons')
          .select()
          .order('order_no', ascending: true);

      // Gelen veriyi güvenli bir şekilde işleyelim.
      final List<Lesson> loadedLessons = [];
      for (var item in response) {
        try {
          loadedLessons.add(Lesson.fromMap(item));
        } catch (e) {
          // Hangi verinin sorun çıkardığını anlamak için loglama yapalım.
          debugPrint(
            'Lesson.fromMap sırasında hata oluştu. Veri: $item, Hata: $e',
          );
        }
      }
      _lessons = loadedLessons;
    } catch (e) {
      _errorMessage = "Dersler yüklenirken bir hata oluştu: $e";
      _lessons = []; // Hata durumunda listeyi boşalt
    }

    _isLoading = false;
    notifyListeners();
  }
}
