import 'dart:math';

import 'package:egitim_uygulamasi/screens/home/map/models/map_progress_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProgressService {
  ProgressService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static final Map<String, ClassMapData> _classCache = {};
  static final Map<String, SubjectMapData> _subjectCache = {};
  static final Map<String, List<TopicNodeData>> _timelineCache = {};

  String _classKey(String userId, int gradeId) => '$userId:$gradeId';
  String _subjectKey(String userId, int gradeId, int lessonId) => '$userId:$gradeId:$lessonId';
  String _timelineKey(String userId, int unitId) => '$userId:$unitId';

  void clearAllCache() {
    _classCache.clear();
    _subjectCache.clear();
    _timelineCache.clear();
  }

  Future<ClassMapData> fetchClassMapData({
    required String userId,
    required int gradeId,
    required String gradeName,
    required int currentWeek,
    bool forceRefresh = false,
  }) async {
    final key = _classKey(userId, gradeId);
    if (!forceRefresh && _classCache.containsKey(key)) {
      return _classCache[key]!;
    }

    final agendaResponse = await _client.rpc(
      'get_weekly_dashboard_agenda',
      params: {
        'p_user_id': userId,
        'p_grade_id': gradeId,
        'p_curriculum_week': currentWeek,
      },
    );

    final lessonRows = (agendaResponse as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((row) => row['lesson_id'] != null)
        .toList()
      ..sort((a, b) {
        final left = (a['lesson_id'] as num?)?.toInt() ?? 0;
        final right = (b['lesson_id'] as num?)?.toInt() ?? 0;
        return left.compareTo(right);
      });

    final subjects = await Future.wait(
      lessonRows.map((lessonRow) async {
        final lessonId = (lessonRow['lesson_id'] as num).toInt();
        final lessonName = lessonRow['lesson_name']?.toString() ?? 'Ders';

        final subjectMap = await fetchSubjectMapData(
          userId: userId,
          gradeId: gradeId,
          lessonId: lessonId,
          lessonName: lessonName,
          currentWeek: currentWeek,
          forceRefresh: forceRefresh,
        );

        final totalQuestions = subjectMap.units.fold<int>(0, (acc, u) => acc + u.totalQuestions);
        final solvedQuestions = subjectMap.units.fold<int>(0, (acc, u) => acc + u.solvedQuestions);
        final unitsTotal = subjectMap.units.length;
        final unitsConquered = subjectMap.conqueredCount;
        final progress = unitsTotal > 0
            ? (unitsConquered / unitsTotal).clamp(0.0, 1.0)
            : (totalQuestions > 0
                ? (solvedQuestions / totalQuestions).clamp(0.0, 1.0)
                : 0.0);

        final state = unitsConquered == unitsTotal && unitsTotal > 0
            ? ConquestState.conquered
            : solvedQuestions > 0
                ? ConquestState.inProgress
                : ConquestState.notStarted;

        return SubjectNodeData(
          lessonId: lessonId,
          lessonName: lessonName,
          unitsTotal: unitsTotal,
          unitsConquered: unitsConquered,
          totalQuestions: totalQuestions,
          solvedQuestions: solvedQuestions,
          progressRate: progress,
          state: state,
        );
      }),
    );

    final result = ClassMapData(
      gradeId: gradeId,
      gradeName: gradeName,
      subjects: subjects,
    );

    _classCache[key] = result;
    return result;
  }

  Future<SubjectMapData> fetchSubjectMapData({
    required String userId,
    required int gradeId,
    required int lessonId,
    required String lessonName,
    required int currentWeek,
    bool forceRefresh = false,
  }) async {
    final key = _subjectKey(userId, gradeId, lessonId);
    if (!forceRefresh && _subjectCache.containsKey(key)) {
      return _subjectCache[key]!;
    }

    final response = await _client.rpc(
      'get_subject_unit_map_data',
      params: {
        'p_user_id': userId,
        'p_lesson_id': lessonId,
        'p_grade_id': gradeId,
        'p_current_week': currentWeek,
      },
    );

    final rows = (response as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final units = rows.map((row) {
      final topicsTotal = (row['topics_total'] as num? ?? 0).toInt();
      final topicsCompleted = (row['topics_completed'] as num? ?? 0).toInt();
      final solvedQuestions = (row['solved_questions'] as num? ?? 0).toInt();

      final state = topicsTotal > 0 && topicsCompleted == topicsTotal
          ? ConquestState.conquered
          : solvedQuestions > 0 || topicsCompleted > 0
              ? ConquestState.inProgress
              : ConquestState.notStarted;

      return UnitNodeData(
        unitId: (row['unit_id'] as num).toInt(),
        title: row['unit_title']?.toString() ?? 'Ünite',
        orderNo: (row['order_no'] as num? ?? 0).toInt(),
        startWeek: max(0, (row['start_week'] as num? ?? 0).toInt()),
        endWeek: max(0, (row['end_week'] as num? ?? 0).toInt()),
        totalQuestions: (row['total_questions'] as num? ?? 0).toInt(),
        solvedQuestions: solvedQuestions,
        topicsTotal: topicsTotal,
        topicsCompleted: topicsCompleted,
        isCurrentWeek: row['is_current_week'] as bool? ?? false,
        state: state,
      );
    }).toList()
      ..sort((a, b) => a.orderNo.compareTo(b.orderNo));

    final result = SubjectMapData(
      lessonId: lessonId,
      lessonName: lessonName,
      gradeId: gradeId,
      units: units,
    );

    _subjectCache[key] = result;
    return result;
  }

  Future<UnitNodeData?> fetchSingleUnitProgress({
    required String userId,
    required int gradeId,
    required int lessonId,
    required int unitId,
    required int currentWeek,
  }) async {
    final response = await _client.rpc(
      'get_subject_unit_map_data',
      params: {
        'p_user_id': userId,
        'p_lesson_id': lessonId,
        'p_grade_id': gradeId,
        'p_current_week': currentWeek,
        'p_unit_id': unitId,
      },
    );

    final rows = (response as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    if (rows.isEmpty) return null;
    final row = rows.first;

    final topicsTotal = (row['topics_total'] as num? ?? 0).toInt();
    final topicsCompleted = (row['topics_completed'] as num? ?? 0).toInt();
    final solvedQuestions = (row['solved_questions'] as num? ?? 0).toInt();

    final state = topicsTotal > 0 && topicsCompleted == topicsTotal
        ? ConquestState.conquered
        : solvedQuestions > 0 || topicsCompleted > 0
            ? ConquestState.inProgress
            : ConquestState.notStarted;

    return UnitNodeData(
      unitId: (row['unit_id'] as num).toInt(),
      title: row['unit_title']?.toString() ?? 'Ünite',
      orderNo: (row['order_no'] as num? ?? 0).toInt(),
      startWeek: max(0, (row['start_week'] as num? ?? 0).toInt()),
      endWeek: max(0, (row['end_week'] as num? ?? 0).toInt()),
      totalQuestions: (row['total_questions'] as num? ?? 0).toInt(),
      solvedQuestions: solvedQuestions,
      topicsTotal: topicsTotal,
      topicsCompleted: topicsCompleted,
      isCurrentWeek: row['is_current_week'] as bool? ?? false,
      state: state,
    );
  }

  Future<List<TopicNodeData>> fetchUnitTimeline({
    required String userId,
    required int unitId,
    required int currentWeek,
    bool forceRefresh = false,
  }) async {
    final key = _timelineKey(userId, unitId);
    if (!forceRefresh && _timelineCache.containsKey(key)) {
      return _timelineCache[key]!;
    }

    final response = await _client.rpc(
      'get_unit_timeline_topic_data',
      params: {
        'p_user_id': userId,
        'p_unit_id': unitId,
        'p_current_week': currentWeek,
      },
    );

    final rows = (response as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final topics = rows.map((row) {
      return TopicNodeData(
        topicId: (row['topic_id'] as num).toInt(),
        unitId: (row['unit_id'] as num).toInt(),
        title: row['topic_title']?.toString() ?? 'Konu',
        weekIndex: (row['week_index'] as num? ?? 0).toInt(),
        gainOrder: (row['gain_order'] as num? ?? 0).toInt(),
        totalQuestions: (row['total_questions'] as num? ?? 0).toInt(),
        solvedQuestions: (row['solved_questions'] as num? ?? 0).toInt(),
        isCompleted: row['is_completed'] as bool? ?? false,
        isInProgress: row['is_in_progress'] as bool? ?? false,
      );
    }).toList()
      ..sort((a, b) {
        final byWeek = a.weekIndex.compareTo(b.weekIndex);
        if (byWeek != 0) return byWeek;
        return a.gainOrder.compareTo(b.gainOrder);
      });

    _timelineCache[key] = topics;
    return topics;
  }

  Future<TopicNodeData?> fetchSingleTopic({
    required String userId,
    required int unitId,
    required int topicId,
    required int currentWeek,
  }) async {
    final response = await _client.rpc(
      'get_unit_timeline_topic_data',
      params: {
        'p_user_id': userId,
        'p_unit_id': unitId,
        'p_current_week': currentWeek,
        'p_topic_id': topicId,
      },
    );

    final rows = (response as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    if (rows.isEmpty) return null;

    final row = rows.first;
    return TopicNodeData(
      topicId: (row['topic_id'] as num).toInt(),
      unitId: (row['unit_id'] as num).toInt(),
      title: row['topic_title']?.toString() ?? 'Konu',
      weekIndex: (row['week_index'] as num? ?? 0).toInt(),
      gainOrder: (row['gain_order'] as num? ?? 0).toInt(),
      totalQuestions: (row['total_questions'] as num? ?? 0).toInt(),
      solvedQuestions: (row['solved_questions'] as num? ?? 0).toInt(),
      isCompleted: row['is_completed'] as bool? ?? false,
      isInProgress: row['is_in_progress'] as bool? ?? false,
    );
  }
}
