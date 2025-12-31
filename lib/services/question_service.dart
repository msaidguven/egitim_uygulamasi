// lib/services/question_service.dart

import 'package:egitim_uygulamasi/models/question_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuestionService {
  final _client = Supabase.instance.client;

  /// Fetches all questions (and their related data) for a specific
  /// topic and week with a 'weekly' usage type.
  Future<List<Question>> getQuestionsForWeek(int topicId, int weekNo) async {
    try {
      final response = await _client
          .from('question_usages')
          .select(
              'id, topic_id, usage_type, start_week, end_week, questions:question_id(*, question_choices(*), question_blanks(*), question_classical(*), question_matching_pairs(*), question_type:question_type_id(code))')
          .eq('topic_id', topicId)
          .eq('usage_type', 'weekly')
          .lte('start_week', weekNo)
          .gte('end_week', weekNo);

      if (response.isEmpty) {
        return [];
      }
      
      final List<Question> questions = [];
      for (final usage in response) {
        final questionData = usage['questions'];
        if (questionData != null) {
          // Manually stitch the question type code into the question map
          // because the structure is nested.
          final typeData = questionData['question_type'];
          if (typeData != null) {
            questionData['question_type_code'] = typeData['code'];
          }
          questions.add(Question.fromMap(questionData));
        }
      }
      
      return questions;

    } catch (e) {
      print('Error fetching questions for week: $e');
      rethrow;
    }
  }

  Future<void> deleteQuestion(int questionId) async {
    try {
      await _client.from('questions').delete().eq('id', questionId);
    } catch (e) {
      print('Error deleting question: $e');
      rethrow;
    }
  }
}
