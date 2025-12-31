// lib/viewmodels/grade_viewmodel.dart

import 'package:flutter/material.dart';
import 'package:egitim_uygulamasi/main.dart';
import 'package:egitim_uygulamasi/models/grade_model.dart';

class GradeViewModel extends ChangeNotifier {
  bool _isLoading = false;
  List<Grade> _grades = [];
  String? _errorMessage;

  bool get isLoading => _isLoading;
  List<Grade> get grades => _grades;
  String? get errorMessage => _errorMessage;

  Future<void> fetchGrades() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await supabase
          .from('grades')
          .select()
          .eq('is_active', true)
          .order('order_no', ascending: true);
      _grades = response.map((data) => Grade.fromMap(data)).toList();
    } catch (e) {
      _errorMessage = "Sınıflar yüklenirken bir hata oluştu: $e";
    }

    _isLoading = false;
    notifyListeners();
  }
}
