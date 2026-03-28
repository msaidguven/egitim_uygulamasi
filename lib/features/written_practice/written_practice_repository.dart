import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'written_practice_models.dart';

class WrittenPracticeRepository {
  // ── Singleton ──────────────────────────────────────────────────────────
  WrittenPracticeRepository._();
  static final WrittenPracticeRepository instance =
      WrittenPracticeRepository._();

  Map<String, dynamic>? _cache;

  Future<Map<String, dynamic>> _data() async {
    _cache ??= jsonDecode(
      await rootBundle.loadString(
        'lib/features/written_practice/mock_data.json',
      ),
    );
    return _cache!;
  }

  // ── Subjects ───────────────────────────────────────────────────────────
  Future<List<Subject>> getSubjects() async {
    final d = await _data();
    return (d['subjects'] as List).map((e) => Subject.fromJson(e)).toList();
  }

  // ── Units by subject ───────────────────────────────────────────────────
  Future<List<Unit>> getUnits(int subjectId) async {
    final d = await _data();
    return (d['units'] as List)
        .map((e) => Unit.fromJson(e))
        .where((u) => u.subjectId == subjectId)
        .toList()
      ..sort((a, b) => a.orderNo.compareTo(b.orderNo));
  }

  // ── Topics by unit ─────────────────────────────────────────────────────
  Future<List<Topic>> getTopics(int unitId) async {
    final d = await _data();
    return (d['topics'] as List)
        .map((e) => Topic.fromJson(e))
        .where((t) => t.unitId == unitId && t.isActive)
        .toList()
      ..sort((a, b) => a.orderNo.compareTo(b.orderNo));
  }

  // ── Questions for selected topic ids ──────────────────────────────────
  // Supabase equivalent:
  //   select questions.*, question_classical.*, question_usages.topic_id
  //   from question_usages
  //   join questions on questions.id = question_usages.question_id
  //   join question_classical on question_classical.question_id = questions.id
  //   where question_usages.topic_id in (:topicIds)
  //     and questions.question_type_id = 1  -- classical only
  //   order by question_usages.topic_id, question_usages.order_no
  Future<List<Question>> getQuestionsForTopics(List<int> topicIds) async {
    final d = await _data();

    // Build classical lookup
    final classicalMap = <int, QuestionClassical>{};
    for (final c in d['question_classical'] as List) {
      final qc = QuestionClassical.fromJson(c);
      classicalMap[qc.questionId] = qc;
    }

    // Find question ids via usages
    final usages = (d['question_usages'] as List)
        .where((u) => topicIds.contains(u['topic_id']))
        .toList();

    final questionIds = usages.map((u) => u['question_id'] as int).toSet();

    // Filter questions: classical type only (type_id == 1)
    final questions = (d['questions'] as List)
        .where(
          (q) => questionIds.contains(q['id']) && q['question_type_id'] == 1,
        )
        .map((q) => Question.fromJson(q, classicalMap[q['id']]))
        .where((q) => q.classical != null) // must have classical data
        .toList();

    return questions;
  }

  // ── Build session from questions ───────────────────────────────────────
  WrittenSession buildSession(List<Question> questions) {
    final rng = Random();
    final attempts = questions.map((q) {
      final words = List<String>.from(q.classical!.answerWords);
      words.shuffle(rng);
      return QuestionAttempt(
        question: q,
        shuffledWords: words,
        placedWords: [],
      );
    }).toList();

    return WrittenSession(attempts: attempts);
  }
}
