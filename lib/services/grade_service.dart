// lib/services/grade_service.dart

import 'package:egitim_uygulamasi/models/grade_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GradeService {
  final _client = Supabase.instance.client;

  /// Tüm sınıfları veritabanından çeker.
  Future<List<Grade>> getGrades() async {
    final response = await _client
        .from('grades')
        .select()
        .order('order_no', ascending: true);

    return response.map((map) => Grade.fromMap(map)).toList();
  }
}
