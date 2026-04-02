import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'written_practice_models.dart';
import 'written_practice_repository.dart';

final _repo = WrittenPracticeRepository.instance;
const _writtenPracticeTextScaleKey = 'written_practice_text_scale';

// ── Data providers ─────────────────────────────────────────────────────────

final selectedLessonIdProvider = StateProvider<int?>((_) => null);
final selectedGradeIdProvider = StateProvider<int?>((_) => null);

final lessonUnitsProvider = FutureProvider<List<Unit>>((ref) async {
  final lessonId = ref.watch(selectedLessonIdProvider);
  final gradeId = ref.watch(selectedGradeIdProvider);
  if (lessonId == null) return const [];
  return _repo.getUnitsForLesson(lessonId, gradeId: gradeId);
});

final topicsProvider = FutureProvider.family<List<Topic>, int>(
  (_, unitId) => _repo.getTopics(unitId),
);

// ── Selection state ────────────────────────────────────────────────────────
final selectedTopicIdsProvider = StateProvider<Set<int>>((_) => {});

// ── Session provider ───────────────────────────────────────────────────────

final writtenSessionProvider =
    StateNotifierProvider<WrittenSessionNotifier, WrittenSession?>(
      (_) => WrittenSessionNotifier(),
    );

final writtenPracticeTextScaleProvider =
    StateNotifierProvider<WrittenPracticeTextScaleNotifier, double>(
      (_) => WrittenPracticeTextScaleNotifier(),
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
    if (!isCorrect) {
      attempt.incorrectAttempts++;
    }
    attempt.status = isCorrect ? AnswerStatus.correct : AnswerStatus.incorrect;
    state = _copySession(session);
  }

  // Reveal one more hint word
  void useHint() {
    final session = state;
    if (session == null) return;
    final attempt = session.current;
    if (attempt.status != AnswerStatus.unanswered) return;
    if (attempt.allHintsRevealed) return;

    attempt.revealedHintCount++;
    state = _copySession(session);
  }

  // Reorder a placed word via drag & drop (fromIndex → toIndex)
  void reorderWord(int fromIndex, int toIndex) {
    final session = state;
    if (session == null) return;
    final attempt = session.current;
    if (attempt.status != AnswerStatus.unanswered) return;

    final updated = [...attempt.placedWords];
    final word = updated.removeAt(fromIndex);
    final insertAt = (toIndex > fromIndex ? toIndex - 1 : toIndex).clamp(
      0,
      updated.length,
    );
    updated.insert(insertAt, word);
    attempt.placedWords = updated;
    state = _copySession(session);
  }

  // Move to next question
  void nextQuestion() {
    final session = state;
    if (session == null || session.isLast) return;
    if (session.current.status != AnswerStatus.correct) return;
    session.currentIndex++;
    state = _copySession(session);
  }

  void previousQuestion() {
    final session = state;
    if (session == null || !session.hasPrevious) return;
    session.currentIndex--;
    state = _copySession(session);
  }

  void retryCurrentQuestion() {
    final session = state;
    if (session == null) return;

    final attempt = session.current;
    attempt.placedWords = [];
    attempt.status = AnswerStatus.unanswered;
    attempt.revealedHintCount = 0;
    attempt.shuffledWords.shuffle();
    state = _copySession(session);
  }

  void reset() => state = null;

  // Force Riverpod to detect change (WrittenSession is mutable)
  WrittenSession _copySession(WrittenSession s) =>
      WrittenSession(attempts: s.attempts, currentIndex: s.currentIndex);
}

class WrittenPracticeTextScaleNotifier extends StateNotifier<double> {
  WrittenPracticeTextScaleNotifier() : super(1.0) {
    _load();
  }

  static const double _minScale = 0.85;
  static const double _maxScale = 5.0;
  static const double _step = 0.10;

  Future<void> increase() => _updateScale(state + _step);

  Future<void> decrease() => _updateScale(state - _step);

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedScale = prefs.getDouble(_writtenPracticeTextScaleKey);
    if (savedScale != null) {
      state = savedScale.clamp(_minScale, _maxScale);
    }
  }

  Future<void> _updateScale(double newValue) async {
    final nextValue = newValue.clamp(_minScale, _maxScale);
    state = nextValue;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_writtenPracticeTextScaleKey, nextValue);
  }
}
