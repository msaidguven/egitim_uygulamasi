import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'written_practice_models.dart';

class WrittenPracticeRepository {
  // ── Singleton ──────────────────────────────────────────────────────────
  WrittenPracticeRepository._();
  static final WrittenPracticeRepository instance =
      WrittenPracticeRepository._();

  final _client = Supabase.instance.client;

  // ── Subjects ───────────────────────────────────────────────────────────
  Future<List<Subject>> getSubjects() async {
    final rows = await _client.from('lessons').select('id, name, slug');
    return (rows as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .map(
          (j) => Subject(
            id: j['id'] as int,
            title: (j['name'] as String? ?? '').trim(),
            slug: (j['slug'] as String? ?? '').trim(),
          ),
        )
        .toList();
  }

  // ── Units by lesson (optionally grade) ────────────────────────────────
  Future<List<Unit>> getUnitsForLesson(int lessonId, {int? gradeId}) async {
    final base = _client
        .from('units')
        .select('id, lesson_id, title, slug, order_no')
        .eq('lesson_id', lessonId);
    final rows = gradeId == null
        ? await base.order('order_no', ascending: true)
        : await base.eq('grade_id', gradeId).order('order_no', ascending: true);
    return (rows as List)
        .map((e) => Unit.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // ── Topics by unit ─────────────────────────────────────────────────────
  Future<List<Topic>> getTopics(int unitId) async {
    final rows = await _client
        .from('topics')
        .select('id, unit_id, title, slug, order_no, is_active')
        .eq('unit_id', unitId)
        .eq('is_active', true)
        .order('order_no', ascending: true);
    return (rows as List)
        .map((e) => Topic.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // ── Questions for selected topic ids ──────────────────────────────────
  // DB: only classical (question_type_id = 4)
  Future<List<Question>> getQuestionsForTopics(List<int> topicIds) async {
    if (topicIds.isEmpty) return const [];

    final rows = await _client
        .from('question_usages')
        .select('''
question_id,
topic_id,
order_no,
questions!inner(
  id,
  question_type_id,
  question_text,
  difficulty,
  score,
  solution_text,
  question_classical(question_id, model_answer, answer_words)
)
''')
        .inFilter('topic_id', topicIds)
        .eq('questions.question_type_id', 4)
        .order('topic_id', ascending: true)
        .order('order_no', ascending: true);

    final result = <Question>[];
    final seen = <int>{};
    for (final raw in (rows as List)) {
      final row = Map<String, dynamic>.from(raw as Map);
      final questionMapRaw = row['questions'];
      if (questionMapRaw is! Map) continue;
      final questionMap = Map<String, dynamic>.from(questionMapRaw);
      final questionId = questionMap['id'] as int?;
      if (questionId == null || seen.contains(questionId)) continue;

      final classicalRaw = questionMap['question_classical'];
      Map<String, dynamic>? classicalMap;
      if (classicalRaw is Map) {
        classicalMap = Map<String, dynamic>.from(classicalRaw);
      } else if (classicalRaw is List && classicalRaw.isNotEmpty) {
        final first = classicalRaw.first;
        if (first is Map) {
          classicalMap = Map<String, dynamic>.from(first);
        }
      }
      if (classicalMap == null) continue;
      var answerWords = (classicalMap['answer_words'] as List? ?? const [])
          .whereType<String>()
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final modelAnswer = (classicalMap['model_answer'] as String? ?? '')
          .trim();
      if (answerWords.isEmpty && modelAnswer.isNotEmpty) {
        answerWords = modelAnswer
            .split(RegExp(r'\s+'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      if (answerWords.isEmpty) continue;

      final classical = QuestionClassical(
        questionId: questionId,
        modelAnswer: modelAnswer,
        answerWords: answerWords,
      );
      result.add(Question.fromJson(questionMap, classical));
      seen.add(questionId);
    }
    return result;
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
