// lib/services/grade_service.dart

import 'package:egitim_uygulamasi/models/grade_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GradeService {
  final _client = Supabase.instance.client;

  /// Tüm sınıfları ve ilişkili dersleri veritabanından çeker.
  Future<List<Grade>> getGradesWithLessons() async {
    final response = await _client
        .from('grades')
        .select('*, lessons(*)')
        .eq('is_active', true)
        .order('order_no', ascending: true);

    return response.map((map) => Grade.fromMap(map)).toList();
  }

  /// Tüm sınıfları veritabanından çeker.
  Future<List<Grade>> getGrades() async {
    final response = await _client
        .from('grades')
        .select()
        .order('order_no', ascending: true);

    return response.map((map) => Grade.fromMap(map)).toList();
  }

  /// Bir sınıfın aktif/pasif durumunu günceller.
  Future<void> updateGradeStatus(int gradeId, bool isActive) async {
    final response = await _client
        .from('grades')
        .update({'is_active': isActive})
        .eq('id', gradeId)
        .select();

    if (response.isEmpty) {
      throw Exception(
          'Güncelleme başarısız oldu. RLS kurallarını veya yetkileri kontrol edin.');
    }
  }
}
