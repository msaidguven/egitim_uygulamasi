import 'package:egitim_uygulamasi/models/topic_lesson_v11_content.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TopicLessonV11ContentService {
  final _client = Supabase.instance.client;

  static const _table = 'topic_lesson_v11_contents';
  static const _selectColumns = '''
id,
topic_id,
lesson_id,
version_no,
title,
payload,
source,
is_published,
created_by,
created_at,
updated_at
''';

  Future<List<TopicLessonV11Content>> listVersionsForTopic(int topicId) async {
    final response = await _client
        .from(_table)
        .select(_selectColumns)
        .eq('topic_id', topicId)
        .order('version_no', ascending: false);

    return (response as List)
        .map((row) => TopicLessonV11Content.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<TopicLessonV11Content?> getLatestPublishedForTopic(int topicId) async {
    final response = await _client
        .from(_table)
        .select(_selectColumns)
        .eq('topic_id', topicId)
        .eq('is_published', true)
        .order('version_no', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return TopicLessonV11Content.fromMap(Map<String, dynamic>.from(response));
  }

  Future<TopicLessonV11Content?> getLatestDraftOrPublishedForTopic(int topicId) async {
    final response = await _client
        .from(_table)
        .select(_selectColumns)
        .eq('topic_id', topicId)
        .order('version_no', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return TopicLessonV11Content.fromMap(Map<String, dynamic>.from(response));
  }

  Future<int> getNextVersionNumber(int topicId) async {
    final latest = await getLatestDraftOrPublishedForTopic(topicId);
    return (latest?.versionNo ?? 0) + 1;
  }

  Future<TopicLessonV11Content> create({
    required int topicId,
    required int lessonId,
    required Map<String, dynamic> payload,
    String? title,
    String source = 'lesson_v11_ai',
    bool isPublished = false,
  }) async {
    try {
      final nextVersion = await getNextVersionNumber(topicId);
      final userId = _client.auth.currentUser?.id;

      final response = await _client
          .from(_table)
          .insert({
            'topic_id': topicId,
            'lesson_id': lessonId,
            'version_no': nextVersion,
            'title': title,
            'payload': payload,
            'source': source,
            'is_published': isPublished,
            if (userId != null) 'created_by': userId,
          })
          .select(_selectColumns)
          .single();

      return TopicLessonV11Content.fromMap(
        Map<String, dynamic>.from(response),
      );
    } on PostgrestException catch (e) {
      debugPrint(
        'Supabase PostgrestException (TopicLessonV11ContentService.create): ${e.message}, Details: ${e.details}, Hint: ${e.hint}',
      );
      throw 'Veritabanı hatası: ${e.message}';
    } catch (e) {
      debugPrint('Beklenmedik hata (TopicLessonV11ContentService.create): $e');
      throw 'Lesson V11 içeriği kaydedilirken beklenmedik bir hata oluştu: $e';
    }
  }

  Future<TopicLessonV11Content> update({
    required int id,
    required Map<String, dynamic> payload,
    String? title,
    bool? isPublished,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'payload': payload,
        if (title != null) 'title': title,
        if (isPublished != null) 'is_published': isPublished,
      };

      final response = await _client
          .from(_table)
          .update(updateData)
          .eq('id', id)
          .select(_selectColumns)
          .single();

      return TopicLessonV11Content.fromMap(
        Map<String, dynamic>.from(response),
      );
    } on PostgrestException catch (e) {
      debugPrint(
        'Supabase PostgrestException (TopicLessonV11ContentService.update): ${e.message}, Details: ${e.details}, Hint: ${e.hint}',
      );
      throw 'Veritabanı hatası: ${e.message}';
    } catch (e) {
      debugPrint('Beklenmedik hata (TopicLessonV11ContentService.update): $e');
      throw 'Lesson V11 içeriği güncellenirken beklenmedik bir hata oluştu: $e';
    }
  }

  Future<void> publishOnly(int id, int topicId) async {
    try {
      await _client.from(_table).update({'is_published': false}).eq('topic_id', topicId);
      await _client.from(_table).update({'is_published': true}).eq('id', id);
    } on PostgrestException catch (e) {
      debugPrint(
        'Supabase PostgrestException (TopicLessonV11ContentService.publishOnly): ${e.message}, Details: ${e.details}, Hint: ${e.hint}',
      );
      throw 'Yayınlama sırasında veritabanı hatası oluştu: ${e.message}';
    } catch (e) {
      debugPrint(
        'Beklenmedik hata (TopicLessonV11ContentService.publishOnly): $e',
      );
      throw 'Lesson V11 içeriği yayınlanırken beklenmedik bir hata oluştu: $e';
    }
  }

  Future<void> delete(int id) async {
    try {
      await _client.from(_table).delete().eq('id', id);
    } on PostgrestException catch (e) {
      debugPrint(
        'Supabase PostgrestException (TopicLessonV11ContentService.delete): ${e.message}, Details: ${e.details}, Hint: ${e.hint}',
      );
      throw 'Silme sırasında veritabanı hatası oluştu: ${e.message}';
    } catch (e) {
      debugPrint('Beklenmedik hata (TopicLessonV11ContentService.delete): $e');
      throw 'Lesson V11 içeriği silinirken beklenmedik bir hata oluştu: $e';
    }
  }
}
