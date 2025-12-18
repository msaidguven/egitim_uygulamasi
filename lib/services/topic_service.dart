// lib/services/topic_service.dart

import 'package:egitim_uygulamasi/models/topic_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TopicService {
  final _client = Supabase.instance.client;

  /// Belirli bir üniteye ait tüm konuları çeker.
  Future<List<Topic>> getTopicsForUnit(int unitId) async {
    final response = await _client
        .from('topics')
        .select()
        .eq('unit_id', unitId)
        .order('id', ascending: true);

    return response.map((map) => Topic.fromMap(map)).toList();
  }

  /// Yeni bir konu oluşturur.
  Future<void> createTopic(String name, int unitId) async {
    await _client.from('topics').insert({'name': name, 'unit_id': unitId});
  }

  /// Mevcut bir konuyu günceller.
  Future<void> updateTopic(int id, String name) async {
    await _client.from('topics').update({'name': name}).eq('id', id);
  }

  /// Belirtilen ID'ye sahip konuyu siler.
  Future<void> deleteTopic(int id) async {
    await _client.from('topics').delete().eq('id', id);
  }
}
