// lib/services/lesson_service.dart

import 'package:egitim_uygulamasi/models/lesson_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter/foundation.dart'; // debugPrint için eklendi

class LessonService {
  final _client = Supabase.instance.client;

  /// Veritabanındaki tüm dersleri çeker.
  Future<List<Lesson>> getLessons() async {
    // Admin panelindeki diğer kullanımlarla tutarlı olması için
    // sınıf ilişkisi olmadan sadece dersleri çekiyoruz.
    final response = await _client
        .from('lessons')
        .select()
        .eq('is_active', true)
        .order('id', ascending: true);

    return response.map((map) => Lesson.fromMap(map)).toList();
  }

  /// Yeni bir ders oluşturur ve belirtilen sınıfa atar.
  ///
  /// 1. 'lessons' tablosuna yeni dersi ekler.
  /// 2. Oluşturulan dersin ID'sini ve verilen gradeId'yi kullanarak 'lesson_grades'
  ///    tablosuna bir ilişki kaydı ekler.
  Future<void> createLesson(String name, int gradeId) async {
    try {
      // 1. Adım: Dersi 'lessons' tablosuna ekle ve yeni oluşturulan dersin verisini geri al.
      // .select() ile eklenen satırı geri döndürüyoruz, böylece ID'sini alabiliriz.
      final lessonResponse = await _client
          .from('lessons')
          .insert({'name': name})
          .select()
          .single();

      final newLessonId = lessonResponse['id'];

      // 2. Adım: 'lesson_grades' tablosuna ilişkiyi ekle.
      await _client.from('lesson_grades').insert({
        'lesson_id': newLessonId,
        'grade_id': gradeId,
      });
    } on PostgrestException catch (e) {
      // Veritabanı hatası oluşursa, bunu daha anlaşılır bir şekilde yukarıya fırlat.
      debugPrint(
        'Supabase PostgrestException (createLesson): ${e.message}, Details: ${e.details}, Hint: ${e.hint}',
      );
      throw 'Veritabanı hatası: ${e.message}';
    } catch (e) {
      // Diğer beklenmedik hatalar için.
      debugPrint('Beklenmedik hata (createLesson): $e');
      throw 'Ders oluşturulurken beklenmedik bir hata oluştu: $e';
    }
  }

  /// Mevcut bir dersi ve sınıf ilişkisini günceller.
  Future<void> updateLesson(int id, String name, int gradeId) async {
    try {
      // 1. Adım: Dersin adını 'lessons' tablosunda güncelle.
      await _client.from('lessons').update({'name': name}).eq('id', id);

      // 2. Adım: 'lesson_grades' tablosundaki sınıf ilişkisini güncelle.
      // Bu ders için mevcut ilişkiyi bul.
      final existingRelation = await _client
          .from('lesson_grades')
          .select('id')
          .eq('lesson_id', id)
          .maybeSingle();

      if (existingRelation != null) {
        // Eğer zaten bir ilişki varsa, onu yeni gradeId ile güncelle.
        await _client
            .from('lesson_grades')
            .update({'grade_id': gradeId})
            .eq('lesson_id', id);
      } else {
        // Eğer bir ilişki yoksa (örneğin eski veriden kalma), yenisini oluştur.
        await _client.from('lesson_grades').insert({
          'lesson_id': id,
          'grade_id': gradeId,
        });
      }
    } on PostgrestException catch (e) {
      debugPrint(
        'Supabase PostgrestException (updateLesson): ${e.message}, Details: ${e.details}, Hint: ${e.hint}',
      );
      throw 'Veritabanı hatası: ${e.message}';
    } catch (e) {
      debugPrint('Beklenmedik hata (updateLesson): $e');
      throw 'Ders güncellenirken beklenmedik bir hata oluştu: $e';
    }
  }

  /// Belirtilen ID'ye sahip dersi siler.
  Future<void> deleteLesson(int id) async {
    try {
      // 1. Adım: Önce 'lesson_grades' tablosundaki ilişkili kayıtları sil.
      // Bu, foreign key kısıtlaması hatasını önler.
      await _client.from('lesson_grades').delete().eq('lesson_id', id);

      // 2. Adım: 'lessons' tablosundan asıl dersi sil.
      await _client.from('lessons').delete().eq('id', id);
    } on PostgrestException catch (e) {
      debugPrint(
        'Supabase PostgrestException (deleteLesson): ${e.message}, Details: ${e.details}, Hint: ${e.hint}',
      );
      throw 'Ders silinirken veritabanı hatası oluştu: ${e.message}';
    } catch (e) {
      debugPrint('Beklenmedik hata (deleteLesson): $e');
      throw 'Ders silinirken beklenmedik bir hata oluştu: $e';
    }
  }
}
