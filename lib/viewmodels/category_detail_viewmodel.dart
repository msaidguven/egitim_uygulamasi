// lib/viewmodels/category_detail_viewmodel.dart

import 'package:flutter/material.dart';
import 'package:egitim_uygulamasi/main.dart';
import 'package:egitim_uygulamasi/models/course_model.dart';

class CategoryDetailViewModel extends ChangeNotifier {
  bool _isLoading = false;
  List<Course> _courses = [];
  String? _errorMessage;

  bool get isLoading => _isLoading;
  List<Course> get courses => _courses;
  String? get errorMessage => _errorMessage;

  Future<void> fetchCourses(int categoryId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await supabase
          .from('courses')
          .select()
          .eq('category_id', categoryId); // Kategori ID'sine göre filtrele
      _courses = response.map((data) => Course.fromMap(data)).toList();
    } catch (e) {
      _errorMessage = "Kurslar yüklenirken bir hata oluştu: $e";
    }

    _isLoading = false;
    notifyListeners();
  }
}
