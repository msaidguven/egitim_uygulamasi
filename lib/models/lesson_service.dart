// lib/services/lesson_service.dart

import 'package:egitim_uygulamasi/models/lesson_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LessonService {
  final _client = Supabase.instance.client;

  /// Tüm dersleri, ilişkili oldukları sınıf adıyla birlikte çeker.
  Future<List<Lesson>> getLessons() async {
    // 'grades(name)' ifadesi, 'grade_id' üzerinden 'grades' tablosuna
    // bir JOIN sorgusu yapar ve sadece 'name' alanını getirir.
    final response = await _client
        .from('lessons')
        .select('*, grades(name)')
        .order('id', ascending: true);

    return response.map((map) => Lesson.fromMap(map)).toList();
  }

  /// Yeni bir ders oluşturur.
  Future<void> createLesson(String name, int gradeId) async {
    await _client.from('lessons').insert({'name': name, 'grade_id': gradeId});
  }

  /// Mevcut bir dersi günceller.
  Future<void> updateLesson(int id, String name, int gradeId) async {
    await _client
        .from('lessons')
        .update({'name': name, 'grade_id': gradeId})
        .eq('id', id);
  }

  /// Belirtilen ID'ye sahip dersi siler.
  Future<void> deleteLesson(int id) async {
    await _client.from('lessons').delete().eq('id', id);
  }
}
