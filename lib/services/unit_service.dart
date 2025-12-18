// lib/services/unit_service.dart

import 'package:egitim_uygulamasi/models/unit_model.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UnitService {
  final _client = Supabase.instance.client;

  /// Yeni bir ünite oluşturur ve belirtilen sınıfa atar.
  Future<void> createUnit(String title, int lessonId, int gradeId) async {
    try {
      // 1. Adım: Üniteyi 'units' tablosuna ekle ve ID'sini al.
      final unitResponse = await _client
          .from('units')
          .insert({'title': title, 'lesson_id': lessonId})
          .select()
          .single();

      final newUnitId = unitResponse['id'];

      // 2. Adım: 'unit_grades' tablosuna sınıf ilişkisini ekle.
      await _client.from('unit_grades').insert({
        'unit_id': newUnitId,
        'grade_id': gradeId,
      });
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
      // 1. Adım: Ünitenin başlığını ve dersini 'units' tablosunda güncelle.
      await _client
          .from('units')
          .update({'title': title, 'lesson_id': lessonId})
          .eq('id', id);

      // 2. Adım: 'unit_grades' tablosundaki sınıf ilişkisini güncelle.
      final existingRelation = await _client
          .from('unit_grades')
          .select('unit_id')
          .eq('unit_id', id)
          .maybeSingle();

      if (existingRelation != null) {
        // İlişki varsa, gradeId'yi güncelle.
        await _client
            .from('unit_grades')
            .update({'grade_id': gradeId})
            .eq('unit_id', id);
      } else {
        // İlişki yoksa, yenisini oluştur.
        await _client.from('unit_grades').insert({
          'unit_id': id,
          'grade_id': gradeId,
        });
      }
    } on PostgrestException catch (e) {
      debugPrint('Supabase Hatası (updateUnit): ${e.message}');
      throw 'Veritabanı hatası: ${e.message}';
    } catch (e) {
      debugPrint('Beklenmedik hata (updateUnit): $e');
      throw 'Ünite güncellenirken beklenmedik bir hata oluştu.';
    }
  }

  /// Belirtilen ID'ye sahip üniteyi siler.
  /// ÖNEMLİ: Bu işlemin doğru çalışması için Supabase veritabanınızda
  /// 'unit_grades' tablosundaki 'unit_id' foreign key'inde
  /// 'ON DELETE CASCADE' ayarının yapılmış olması gerekir.
  Future<void> deleteUnit(int id) async {
    await _client.from('units').delete().eq('id', id);
  }
}
