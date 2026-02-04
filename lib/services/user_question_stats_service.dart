import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:egitim_uygulamasi/models/user_question_stats.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Kullanıcının soru istatistiklerini yöneten ve güncellemeleri dinleyen servis.
class UserQuestionStatsService {
  final SupabaseClient _client;

  UserQuestionStatsService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Belirli bir kullanıcının soru istatistiklerini dinler.
  ///
  /// Supabase Realtime kullanarak `user_question_stats` tablosundaki
  /// değişiklikleri dinler ve güncel veriyi bir Stream olarak yayınlar.
  /// RLS (Row Level Security) sayesinde, bu stream sadece oturum açmış
  /// kullanıcının kendi istatistiklerini döndürür.
  ///
  /// Dönen Değer:
  /// - `UserQuestionStats` listesini içeren bir Stream.
  Stream<List<UserQuestionStats>> watchUserStats() {
    // Realtime stream'i doğrudan Supabase'den oluşturulur.
    // .stream() metodu, RLS kurallarını dikkate alarak sadece izin verilen
    // satırları dinler. `primaryKey` belirtmek, değişikliklerin doğru
    // şekilde işlenmesini sağlar.
    final stream = _client
        .from('user_question_stats')
        .stream(primaryKey: ['user_id', 'question_id']);

    // Supabase'den gelen `List<Map<String, dynamic>>` verisini
    // `List<UserQuestionStats>` listesine dönüştürür.
    return stream.map((payload) {
      return payload.map((item) => UserQuestionStats.fromJson(item)).toList();
    });
  }

  /// Tek bir sorunun istatistiğini getirmek için.
  ///
  /// Bu, bir sorunun detay sayfasında anlık veri almak için kullanılabilir.
  Future<UserQuestionStats?> getStatsForQuestion(int questionId) async {
    try {
      // RLS, bu sorgunun sadece mevcut kullanıcının verisini getirmesini sağlar.
      final response = await _client
          .from('user_question_stats')
          .select()
          .eq('question_id', questionId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return UserQuestionStats.fromJson(response);
    } catch (e) {
      debugPrint('Error getting stats for question $questionId: $e');
      rethrow;
    }
  }
}
