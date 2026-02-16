// lib/services/outcome_service.dart

import 'package:egitim_uygulamasi/models/outcome_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OutcomeService {
  final _client = Supabase.instance.client;

  /// Belirli bir konuya ait tüm kazanımları çeker.
  Future<List<Outcome>> getOutcomesForTopic(int topicId) async {
    final response = await _client
        .from('outcomes')
        .select('id, description, topic_id, order_index')
        .eq('topic_id', topicId)
        .order('order_index', ascending: true);

    return response.map((map) => Outcome.fromMap(map)).toList();
  }

  /// Fetches outcomes for a specific topic and week using the RPC.
  Future<List<Outcome>> getOutcomesForTopicAndWeek(
    int gradeId,
    int lessonId,
    int topicId,
    int curriculumWeek,
  ) async {
    final response = await _client.rpc(
      'get_weekly_curriculum',
      params: {
        'p_grade_id': gradeId,
        'p_lesson_id': lessonId,
        'p_curriculum_week': curriculumWeek,
        'p_is_admin': false,
      },
    );

    // The RPC returns a list of all curriculum items for the week.
    // We need to filter for the specific topic and map to Outcome objects.
    final outcomes = (response as List)
        .where((item) => item['topic_id'] == topicId)
        .map(
          (item) => Outcome.fromMap({
            'id': item['outcome_id'],
            'description': item['outcome_description'],
            'topic_id': item['topic_id'],
            // 'order_index' is not returned by the RPC, so we can't use it here.
            // If ordering is important, the RPC should be updated to include it.
          }),
        )
        .toList();

    // Since the RPC might return duplicates if an outcome spans multiple weeks
    // and is fetched multiple times, let's ensure the list is distinct.
    final distinctOutcomes = <int, Outcome>{};
    for (var outcome in outcomes) {
      distinctOutcomes[outcome.id] = outcome;
    }

    return distinctOutcomes.values.toList();
  }

  /// Yeni bir kazanım oluşturur.
  Future<Outcome> createOutcome(
    String description,
    int topicId, {
    int? curriculumWeek,
    int? startWeek,
    int? endWeek,
  }) async {
    final resolvedStartWeek = startWeek ?? curriculumWeek;
    final resolvedEndWeek = endWeek ?? curriculumWeek;

    final response = await _client.from('outcomes').insert({
      'description': description,
      'topic_id': topicId,
    }).select();

    if (response.isEmpty) {
      throw Exception('Failed to create outcome.');
    }

    final outcome = Outcome.fromMap(response.first);

    if (resolvedStartWeek != null && resolvedEndWeek != null) {
      await _client.from('outcome_weeks').insert({
        'outcome_id': outcome.id,
        'start_week': resolvedStartWeek,
        'end_week': resolvedEndWeek,
      });
    }

    return outcome;
  }

  /// Mevcut bir kazanımın metnini günceller.
  Future<void> updateOutcome(int id, String description) async {
    await _client
        .from('outcomes')
        .update({'description': description})
        .eq('id', id);
  }

  /// Belirtilen ID'ye sahip kazanımı siler.
  Future<void> deleteOutcome(int id) async {
    await _client.from('outcomes').delete().eq('id', id);
  }
}
