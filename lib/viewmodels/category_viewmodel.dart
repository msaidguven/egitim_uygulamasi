// lib/viewmodels/category_viewmodel.dart

import 'package:flutter/material.dart';
import 'package:egitim_uygulamasi/main.dart';
import 'package:egitim_uygulamasi/models/category_model.dart';

// ChangeNotifier, dinleyicilerini (listener) değişikliklerden haberdar eder.
class CategoryViewModel extends ChangeNotifier {
  // View'ın dinleyeceği durumlar (state)
  bool _isLoading = false;
  List<Category> _categories = [];
  String? _errorMessage;

  // View'ın bu durumlara güvenli bir şekilde erişmesi için getter'lar
  bool get isLoading => _isLoading;
  List<Category> get categories => _categories;
  String? get errorMessage => _errorMessage;

  // Kategorileri getiren ve durumu güncelleyen metot
  Future<void> fetchCategories() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // Arayüzü "yükleniyor" durumu için güncelle

    try {
      final response = await supabase
          .from('categories')
          .select()
          .order('id', ascending: true);
      _categories = response.map((data) => Category.fromMap(data)).toList();
    } catch (e) {
      _errorMessage = "Kategoriler yüklenirken bir hata oluştu: $e";
    }

    _isLoading = false;
    notifyListeners(); // Arayüzü son durum (veri veya hata) için güncelle
  }
}
