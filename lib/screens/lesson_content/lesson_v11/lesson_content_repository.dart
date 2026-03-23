import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

class LessonV11AdminContext {
  const LessonV11AdminContext({
    required this.gradeId,
    required this.lessonId,
    required this.unitId,
    required this.topicId,
    required this.gradeName,
    required this.lessonName,
    required this.unitTitle,
    required this.topicTitle,
    required this.outcomes,
  });

  final int gradeId;
  final int lessonId;
  final int unitId;
  final int topicId;
  final String gradeName;
  final String lessonName;
  final String unitTitle;
  final String topicTitle;
  final List<Map<String, dynamic>> outcomes;
}

class LessonV11ContentRecord {
  const LessonV11ContentRecord({
    required this.id,
    required this.topicId,
    required this.versionNo,
    required this.isPublished,
    required this.payload,
  });

  final int id;
  final int topicId;
  final int versionNo;
  final bool isPublished;
  final Map<String, dynamic> payload;

  String get jsonString => jsonEncode(payload);
}

class LessonV11ContentRepository {
  LessonV11ContentRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<LessonV11ContentRecord?> fetchLatestPublishedContentForTopic(
    int topicId, {
    List<int>? outcomeIds,
  }) async {
    var query = _client.from('topic_contents_v11').select(
      outcomeIds != null && outcomeIds.isNotEmpty
          ? 'id, topic_id, version_no, is_published, payload, topic_content_outcomes_v11!inner(outcome_id)'
          : 'id, topic_id, version_no, is_published, payload',
    );

    query = query.eq('topic_id', topicId).eq('is_published', true);

    if (outcomeIds != null && outcomeIds.isNotEmpty) {
      query = query.inFilter('topic_content_outcomes_v11.outcome_id', outcomeIds);
    }

    final response = await query
        .order('version_no', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    final payload = response['payload'];
    if (payload is Map<String, dynamic>) {
      return LessonV11ContentRecord(
        id: response['id'] as int,
        topicId: response['topic_id'] as int,
        versionNo: response['version_no'] as int? ?? 1,
        isPublished: response['is_published'] as bool? ?? false,
        payload: payload,
      );
    }
    if (payload is Map) {
      return LessonV11ContentRecord(
        id: response['id'] as int,
        topicId: response['topic_id'] as int,
        versionNo: response['version_no'] as int? ?? 1,
        isPublished: response['is_published'] as bool? ?? false,
        payload: Map<String, dynamic>.from(payload),
      );
    }
    return null;
  }

  Future<String?> fetchLatestPublishedJsonForTopic(int topicId) async {
    final record = await fetchLatestPublishedContentForTopic(topicId);
    return record?.jsonString;
  }

  Future<LessonV11ContentRecord?> fetchLatestContentForTopic(
    int topicId,
  ) async {
    final response = await _client
        .from('topic_contents_v11')
        .select('id, topic_id, version_no, is_published, payload')
        .eq('topic_id', topicId)
        .order('version_no', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    final payload = response['payload'];
    if (payload is Map<String, dynamic>) {
      return LessonV11ContentRecord(
        id: response['id'] as int,
        topicId: response['topic_id'] as int,
        versionNo: response['version_no'] as int? ?? 1,
        isPublished: response['is_published'] as bool? ?? false,
        payload: payload,
      );
    }
    if (payload is Map) {
      return LessonV11ContentRecord(
        id: response['id'] as int,
        topicId: response['topic_id'] as int,
        versionNo: response['version_no'] as int? ?? 1,
        isPublished: response['is_published'] as bool? ?? false,
        payload: Map<String, dynamic>.from(payload),
      );
    }
    return null;
  }

  Future<bool> isCurrentUserAdmin() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    final row = await _client
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .maybeSingle();
    return (row?['role'] as String?) == 'admin';
  }

  Future<LessonV11AdminContext?> fetchAdminContextForTopic(int topicId) async {
    final topicRow = await _client
        .from('topics')
        .select(
          'id, title, unit_id, units!inner(id, title, lesson_id, grade_id, lessons!inner(id, name), grades!inner(id, name))',
        )
        .eq('id', topicId)
        .maybeSingle();

    if (topicRow == null) return null;

    final topic = Map<String, dynamic>.from(topicRow);
    final unit = Map<String, dynamic>.from(
      topic['units'] as Map? ?? const <String, dynamic>{},
    );
    final lesson = Map<String, dynamic>.from(
      unit['lessons'] as Map? ?? const <String, dynamic>{},
    );
    final grade = Map<String, dynamic>.from(
      unit['grades'] as Map? ?? const <String, dynamic>{},
    );

    final outcomesRow = await _client
        .from('outcomes')
        .select('id, description, order_index')
        .eq('topic_id', topicId)
        .order('order_index', ascending: true);

    final outcomes = (outcomesRow as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();

    final gradeId = grade['id'] as int?;
    final lessonId = lesson['id'] as int?;
    final unitId = unit['id'] as int?;
    if (gradeId == null || lessonId == null || unitId == null) {
      return null;
    }

    return LessonV11AdminContext(
      gradeId: gradeId,
      lessonId: lessonId,
      unitId: unitId,
      topicId: topicId,
      gradeName: (grade['name'] as String? ?? '').trim(),
      lessonName: (lesson['name'] as String? ?? '').trim(),
      unitTitle: (unit['title'] as String? ?? '').trim(),
      topicTitle: (topic['title'] as String? ?? '').trim(),
      outcomes: outcomes,
    );
  }

  Future<LessonV11ContentRecord?> publishLatestVersionForTopic(
    int topicId,
  ) async {
    final latest = await fetchLatestContentForTopic(topicId);
    if (latest == null) {
      return null;
    }

    await _client
        .from('topic_contents_v11')
        .update({'is_published': false})
        .eq('topic_id', topicId);

    await _client
        .from('topic_contents_v11')
        .update({'is_published': true})
        .eq('id', latest.id);

    return fetchLatestPublishedContentForTopic(topicId);
  }

  Future<void> unpublishContent(int contentId) async {
    await _client
        .from('topic_contents_v11')
        .update({'is_published': false})
        .eq('id', contentId);
  }
}
