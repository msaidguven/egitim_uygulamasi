// lib/services/outcome_service.dart

import 'package:egitim_uygulamasi/models/outcome_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OutcomeService {
  final _client = Supabase.instance.client;

  /// Belirli bir konuya ait tüm kazanımları çeker.
  Future<List<Outcome>> getOutcomesForTopic(int topicId) async {
    final response = await _client
        .from('outcomes')
        .select()
        .eq('topic_id', topicId)
        .order('id', ascending: true);

    return response.map((map) => Outcome.fromMap(map)).toList();
  }

  /// Yeni bir kazanım oluşturur.
  Future<void> createOutcome(String text, int topicId) async {
    await _client.from('outcomes').insert({'text': text, 'topic_id': topicId});
  }

  /// Mevcut bir kazanımı günceller.
  Future<void> updateOutcome(int id, String text) async {
    await _client.from('outcomes').update({'text': text}).eq('id', id);
  }

  /// Belirtilen ID'ye sahip kazanımı siler.
  Future<void> deleteOutcome(int id) async {
    await _client.from('outcomes').delete().eq('id', id);
  }
}
