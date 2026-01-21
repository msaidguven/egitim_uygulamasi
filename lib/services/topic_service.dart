// lib/services/topic_service.dart

import 'package:egitim_uygulamasi/models/topic_content.dart';
import 'package:egitim_uygulamasi/models/topic_model.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TopicService {
  final _client = Supabase.instance.client;

  /// Belirli bir üniteye ait tüm konuları çeker.
  Future<List<Topic>> getTopicsForUnit(int unitId) async {
    try {
      final response = await _client
          .from('topics')
          .select(
              'id, unit_id, title, slug, order_no, is_active, created_at')
          .eq('unit_id', unitId)
          .eq('is_active', true)
          .order('order_no', ascending: true);

      return response.map((map) => Topic.fromMap(map)).toList();
    } catch (e, st) {
      debugPrint('##################################################');
      debugPrint('### ERROR IN TopicService.getTopicsForUnit ###');
      debugPrint('##################################################');
      debugPrint('Unit ID: $unitId');
      debugPrint('Error: $e');
      debugPrint('Stack Trace:\n$st');
      debugPrint('##################################################');
      rethrow; // Re-throw the error to be caught by the UI layer
    }
  }

  /// Yeni bir konu oluşturur.
  Future<void> createTopic({required String title, required int unitId}) async {
    try {
      await _client.from('topics').insert({'title': title, 'unit_id': unitId});
    } on PostgrestException catch (e) {
      debugPrint('Supabase Hatası (createTopic): ${e.message}');
      throw 'Konu oluşturulurken veritabanı hatası: ${e.message}';
    } catch (e) {
      debugPrint('Beklenmedik hata (createTopic): $e');
      throw 'Konu oluşturulurken beklenmedik bir hata oluştu.';
    }
  }

  /// Mevcut bir konuyu günceller.
  Future<void> updateTopic({required int id, required String title}) async {
    try {
      await _client.from('topics').update({'title': title}).eq('id', id);
    } on PostgrestException catch (e) {
      debugPrint('Supabase Hatası (updateTopic): ${e.message}');
      throw 'Konu güncellenirken veritabanı hatası: ${e.message}';
    } catch (e) {
      debugPrint('Beklenmedik hata (updateTopic): $e');
      throw 'Konu güncellenirken beklenmedik bir hata oluştu.';
    }
  }

  /// Belirtilen ID'ye sahip konuyu siler.
  Future<void> deleteTopic(int id) async {
    await _client.from('topics').delete().eq('id', id);
  }

  // --- Topic Content Methods ---

  /// Fetches topic contents for a specific topic and week using the new curriculum_week logic.
  Future<List<TopicContent>> getTopicContentsForTopicAndWeek(
      int topicId, int curriculumWeek) async {
    final response = await _client
        .from('topic_contents')
        .select(
            'id, topic_id, title, content, order_no, topic_content_weeks!inner(curriculum_week)')
        .eq('topic_id', topicId)
        .eq('topic_content_weeks.curriculum_week', curriculumWeek)
        .order('order_no', ascending: true);

    return response.map((map) => TopicContent.fromJson(map)).toList();
  }

  /// Creates a new topic content record. Returns the created record with its new ID.
  Future<TopicContent> createTopicContent(
      {required int topicId,
      required String title,
      required String content,
      required int order}) async {
    final response = await _client
        .from('topic_contents')
        .insert({
          'topic_id': topicId,
          'title': title,
          'content': content,
          'order_no': order,
        })
        .select('id, topic_id, title, content, order_no')
        .single();
    return TopicContent.fromJson(response);
  }

  /// Assigns a week to a topic content.
  Future<void> createTopicContentWeek(
      int topicContentId, int curriculumWeek) async {
    await _client.from('topic_content_weeks').insert({
      'topic_content_id': topicContentId,
      'curriculum_week': curriculumWeek,
    });
  }

  /// Deletes a topic content record.
  Future<void> deleteTopicContent(int id) async {
    await _client.from('topic_contents').delete().eq('id', id);
  }
}
