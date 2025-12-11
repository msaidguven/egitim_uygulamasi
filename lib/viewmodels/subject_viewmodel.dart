// lib/viewmodels/subject_viewmodel.dart

import 'package:flutter/material.dart';
import 'package:egitim_uygulamasi/main.dart';
import 'package:egitim_uygulamasi/models/subject_model.dart';

class SubjectViewModel extends ChangeNotifier {
  bool _isLoading = false;
  List<Subject> _subjects = [];
  String? _errorMessage;

  bool get isLoading => _isLoading;
  List<Subject> get subjects => _subjects;
  String? get errorMessage => _errorMessage;

  Future<void> fetchSubjectsByGrade(int gradeId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await supabase
          .from('subjects')
          .select()
          .eq('grade_id', gradeId)
          .order('order_no', ascending: true);
      _subjects = response.map((data) => Subject.fromMap(data)).toList();
    } catch (e) {
      _errorMessage = "Dersler yüklenirken bir hata oluştu: $e";
    }

    _isLoading = false;
    notifyListeners();
  }
}
