// lib/services/unit_service.dart
// Bu dosya, tüm üniteleri ve derslere göre filtrelenmiş üniteleri getiren metodları içerir.
// 'getUnits' metodu, "Akıllı İçerik Ekleme" sayfasının doğru çalışması için gereklidir.

import 'package:egitim_uygulamasi/models/unit_model.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UnitService {
  final _client = Supabase.instance.client;

  /// Belirli bir derse ait üniteleri getirir.
  Future<List<Unit>> getUnitsByLesson(int lessonId) async {
    try {
      final response = await _client
          .from('units')
          .select()
          .eq('lesson_id', lessonId)
          .eq('is_active', true)
          .order('id', ascending: true); // Veya 'title' gibi bir alana göre sıralama

      return response.map((map) => Unit.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Üniteler getirilirken hata: $e');
      throw 'Üniteler alınamadı.';
    }
  }

  /// Belirli bir sınıf ve derse ait üniteleri RPC kullanarak getirir.
  Future<List<Unit>> getUnitsForGradeAndLesson(int gradeId, int lessonId) async {
    try {
      final response = await _client.rpc(
        'get_units_for_grade_and_lesson',
        params: {
          'p_grade_id': gradeId,
          'p_lesson_id': lessonId,
        },
      );
      // RPC'den dönen veri bir liste olduğu için direkt olarak map edilebilir.
      return (response as List).map((map) => Unit.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Sınıf ve derse göre üniteler getirilirken hata: $e');
      throw 'Üniteler alınamadı.';
    }
  }

  /// **Tüm üniteleri getirir.**
  /// Bu metod, "Akıllı İçerik Ekleme" sayfasında mevcut üniteleri listelemek için kullanılır.
  Future<List<Unit>> getUnits() async {
    try {
      final response = await _client
          .from('units')
          .select()
          .eq('is_active', true)
          .order('id', ascending: true); // Veya 'title' gibi bir alana göre sıralama

      return response.map((map) => Unit.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Tüm üniteler getirilirken hata: $e');
      throw 'Tüm üniteler alınamadı.';
    }
  }

  /// Yeni bir ünite oluşturur ve belirtilen sınıfa atar.
  Future<void> createUnit(String title, int lessonId, int gradeId) async {
    try {
      await _client.rpc(
        'transactional_create_unit',
        params: {
          'p_title': title,
          'p_lesson_id': lessonId,
          'p_grade_id': gradeId,
        },
      );
    } on PostgrestException catch (e) {
      debugPrint('Supabase Hatası (createUnit): ${e.message}');
      throw 'Veritabanı hatası: ${e.message}';
    } catch (e) {
      debugPrint('Beklenmedik hata (createUnit): $e');
      throw 'Ünite oluşturulurken beklenmedik bir hata oluştu.';
    }
  }

  /// Mevcut bir üniteyi ve sınıf ilişkisini günceller.
  Future<void> updateUnit(
    int id,
    String title,
    int lessonId,
    int gradeId,
  ) async {
    try {
      await _client.rpc(
        'transactional_update_unit',
        params: {
          'p_unit_id': id,
          'p_title': title,
          'p_lesson_id': lessonId,
          'p_grade_id': gradeId,
        },
      );
    } on PostgrestException catch (e) {
      debugPrint('Supabase Hatası (updateUnit): ${e.message}');
      throw 'Veritabanı hatası: ${e.message}';
    } catch (e) {
      debugPrint('Beklenmedik hata (updateUnit): $e');
      throw 'Ünite güncellenirken beklenmedik bir hata oluştu.';
    }
  }

  /// Belirtilen ID'ye sahip üniteyi siler.
  Future<void> deleteUnit(int id) async {
    await _client.from('units').delete().eq('id', id);
  }
}
