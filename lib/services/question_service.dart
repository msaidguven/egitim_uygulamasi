// lib/services/question_service.dart

import 'package:egitim_uygulamasi/models/question_model.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuestionService {
  final _client = Supabase.instance.client;

  Future<List<Question>> getQuestionsForWeek(
    int topicId,
    int curriculumWeek,
  ) async {
    try {
      // Yeni yol: kazanım bağlantısını önceleyen RPC.
      try {
        final rpcResponse = await _client.rpc(
          'get_weekly_question_ids',
          params: {
            'p_topic_id': topicId,
            'p_curriculum_week': curriculumWeek,
            'p_limit': 50,
          },
        );

        if (rpcResponse is List && rpcResponse.isNotEmpty) {
          final questionIds = rpcResponse
              .map((row) => row['question_id'])
              .whereType<int>()
              .toList();
          if (questionIds.isNotEmpty) {
            return await _getQuestionsDetailsByIds(questionIds);
          }
        }
      } catch (_) {
        // Migration henüz uygulanmadıysa legacy yönteme düş.
      }

      // Legacy fallback: hafta + konu bazlı question_usages.
      final usageResponse = await _client
          .from('question_usages')
          .select('question_id')
          .eq('topic_id', topicId)
          .eq('usage_type', 'weekly')
          .eq('curriculum_week', curriculumWeek);

      if (usageResponse.isEmpty) return [];

      final questionIds = usageResponse
          .map((usage) => usage['question_id'] as int)
          .toList();
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
  Future<List<Question>> _getQuestionsDetailsByIds(
    List<int> questionIds,
  ) async {
    if (questionIds.isEmpty) return [];

    try {
      final response = await _client
          .from('questions')
          .select('''
            id,
            question_text,
            difficulty,
            score,
            solution_text,
            question_type:question_types(code),
            question_choices(id, choice_text, is_correct),
            question_blank_options(id, option_text, is_correct, order_no),
            question_matching_pairs(id, left_text, right_text, order_no),
            question_classical(model_answer)
            ''')
          .inFilter('id', questionIds);

      final byId = <int, Question>{};
      for (final raw in response) {
        final question = Question.fromMap(Map<String, dynamic>.from(raw));
        byId[question.id] = question;
      }

      return questionIds
          .where(byId.containsKey)
          .map((id) => byId[id]!)
          .toList();
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
