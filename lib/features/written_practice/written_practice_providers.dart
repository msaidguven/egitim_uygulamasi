import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'written_practice_models.dart';
import 'written_practice_repository.dart';

final _repo = WrittenPracticeRepository.instance;

// ── Data providers ─────────────────────────────────────────────────────────

final subjectsProvider = FutureProvider<List<Subject>>(
  (_) => _repo.getSubjects(),
);

final unitsProvider = FutureProvider.family<List<Unit>, int>(
  (_, subjectId) => _repo.getUnits(subjectId),
);

final topicsProvider = FutureProvider.family<List<Topic>, int>(
  (_, unitId) => _repo.getTopics(unitId),
);

// ── Selection state ────────────────────────────────────────────────────────

final selectedSubjectProvider = StateProvider<Subject?>((_) => null);
final selectedTopicIdsProvider = StateProvider<Set<int>>((_) => {});

// ── Session provider ───────────────────────────────────────────────────────

final writtenSessionProvider =
    StateNotifierProvider<WrittenSessionNotifier, WrittenSession?>(
      (_) => WrittenSessionNotifier(),
    );

class WrittenSessionNotifier extends StateNotifier<WrittenSession?> {
  WrittenSessionNotifier() : super(null);

  Future<void> startSession(List<int> topicIds) async {
    final questions = await _repo.getQuestionsForTopics(topicIds);
    if (questions.isEmpty) return;
    state = _repo.buildSession(questions);
  }

  // Place a word from bank into answer area
  void placeWord(String word) {
    final session = state;
    if (session == null) return;
    final attempt = session.current;
    if (attempt.isComplete) return;

    attempt.placedWords = [...attempt.placedWords, word];
    state = _copySession(session);
  }

  // Remove a word from answer area back to bank
  void removeWord(int index) {
    final session = state;
    if (session == null) return;
    final attempt = session.current;
    if (attempt.status != AnswerStatus.unanswered) return;

    final updated = [...attempt.placedWords];
    updated.removeAt(index);
    attempt.placedWords = updated;
    state = _copySession(session);
  }

  // Confirm answer for current question
  void confirmAnswer() {
    final session = state;
    if (session == null) return;
    final attempt = session.current;
    if (!attempt.isComplete) return;

    final isCorrect = attempt.checkAnswer();
    attempt.status = isCorrect ? AnswerStatus.correct : AnswerStatus.incorrect;
    state = _copySession(session);
  }

  // Move to next question
  void nextQuestion() {
    final session = state;
    if (session == null || session.isLast) return;
    session.currentIndex++;
    state = _copySession(session);
  }

  void reset() => state = null;

  // Force Riverpod to detect change (WrittenSession is mutable)
  WrittenSession _copySession(WrittenSession s) =>
      WrittenSession(attempts: s.attempts, currentIndex: s.currentIndex);
}
