// lib/services/question_service.dart

import 'dart:convert';
import 'package:egitim_uygulamasi/models/question_model.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuestionService {
  final _client = Supabase.instance.client;

  Future<List<Question>> getQuestionsForWeek(int topicId, int curriculumWeek) async {
    try {
      // Adım 1: Haftaya ait soru ID'lerini al.
      final usageResponse = await _client
          .from('question_usages')
          .select('question_id')
          .eq('topic_id', topicId)
          .eq('usage_type', 'weekly')
          .eq('curriculum_week', curriculumWeek);

      if (usageResponse.isEmpty) {
        return [];
      }

      final questionIds = usageResponse.map((usage) => usage['question_id'] as int).toList();

      // Adım 2: Tüm soru ID'leri için yeni RPC'yi tek bir çağrıda kullan.
      return await _getQuestionsDetailsByIds(questionIds);

    } catch (e) {
      debugPrint('Error fetching questions for week: $e');
      rethrow;
    }
  }

  Future<List<Question>> getQuestionsForUnit(int unitId) async {
    try {
      // Adım 1: Üniteye ait temel soru bilgilerini (sadece ID) al.
      final questionsResponse = await _client.rpc(
        'get_questions_for_unit',
        params: {'unit_id_param': unitId},
      );

      if (questionsResponse is! List || questionsResponse.isEmpty) {
        return [];
      }

      final questionIds = questionsResponse.map((q) => q['id'] as int).toList();

      // Adım 2: Tüm soru ID'leri için detayları getiren RPC'yi kullan.
      return await _getQuestionsDetailsByIds(questionIds);

    } catch (e) {
      debugPrint('Error fetching questions for unit: $e');
      rethrow;
    }
  }

  // Helper method to get full question details from a list of IDs
  Future<List<Question>> _getQuestionsDetailsByIds(List<int> questionIds) async {
    if (questionIds.isEmpty) return [];
    
    try {
      final response = await _client.rpc(
        'get_questions_details',
        params: {'p_question_ids': questionIds},
      );

      if (response is List) {
        final questions = response
            .map((data) => Question.fromMap(data as Map<String, dynamic>))
            .toList();
        return questions;
      }
      return [];
    } catch (e) {
      debugPrint('Error in _getQuestionsDetailsByIds: $e');
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
