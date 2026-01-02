// lib/services/question_service.dart

import 'dart:convert';
import 'package:egitim_uygulamasi/models/question_model.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuestionService {
  final _client = Supabase.instance.client;

  Future<List<Question>> getQuestionsForWeek(int topicId, int weekNo) async {
    try {
      // Adım 1: Haftaya ait soru ID'lerini al.
      final usageResponse = await _client
          .from('question_usages')
          .select('question_id')
          .eq('topic_id', topicId)
          .eq('usage_type', 'weekly')
          .eq('display_week', weekNo);

      if (usageResponse.isEmpty) {
        return [];
      }

      final questionIds = usageResponse.map((usage) => usage['question_id'] as int).toList();

      // Adım 2: Tüm soru ID'leri için yeni RPC'yi tek bir çağrıda kullan.
      final questionsResponse = await _client.rpc(
        'get_questions_details',
        params: {'p_question_ids': questionIds},
      );

      // RPC'den bir JSON dizisi (List<dynamic>) dönmesini bekliyoruz.
      if (questionsResponse is List) {
        final questions = questionsResponse
            .map((data) => Question.fromMap(data as Map<String, dynamic>))
            .toList();
        return questions;
      }
      
      // Beklenmedik bir formatta veri gelirse boş liste döndür.
      return [];

    } catch (e) {
      debugPrint('Error fetching questions for week: $e');
      rethrow;
    }
  }

  Future<void> deleteQuestion(int questionId) async {
    try {
      // Bu fonksiyon değişmedi, olduğu gibi kalabilir.
      await _client.from('questions').delete().eq('id', questionId);
    } catch (e) {
      debugPrint('Error deleting question: $e');
      rethrow;
    }
  }
}
