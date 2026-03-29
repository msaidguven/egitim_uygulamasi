// ─── MODELS ────────────────────────────────────────────────────────────────

class Subject {
  final int id;
  final String title;
  final String slug;

  const Subject({required this.id, required this.title, required this.slug});

  factory Subject.fromJson(Map<String, dynamic> j) =>
      Subject(id: j['id'], title: j['title'], slug: j['slug']);
}

class Unit {
  final int id;
  final int lessonId;
  final String title;
  final String slug;
  final int orderNo;

  const Unit({
    required this.id,
    required this.lessonId,
    required this.title,
    required this.slug,
    required this.orderNo,
  });

  factory Unit.fromJson(Map<String, dynamic> j) => Unit(
    id: j['id'],
    lessonId: j['lesson_id'] ?? j['subject_id'],
    title: j['title'],
    slug: (j['slug'] ?? '').toString(),
    orderNo: j['order_no'] ?? 0,
  );
}

class Topic {
  final int id;
  final int unitId;
  final String title;
  final String slug;
  final int orderNo;
  final bool isActive;

  const Topic({
    required this.id,
    required this.unitId,
    required this.title,
    required this.slug,
    required this.orderNo,
    required this.isActive,
  });

  factory Topic.fromJson(Map<String, dynamic> j) => Topic(
    id: j['id'],
    unitId: j['unit_id'],
    title: j['title'],
    slug: j['slug'],
    orderNo: j['order_no'],
    isActive: j['is_active'] ?? true,
  );
}

class QuestionClassical {
  final int questionId;
  final String modelAnswer;
  final List<String> answerWords; // shuffled at runtime

  const QuestionClassical({
    required this.questionId,
    required this.modelAnswer,
    required this.answerWords,
  });

  factory QuestionClassical.fromJson(Map<String, dynamic> j) =>
      QuestionClassical(
        questionId: j['question_id'],
        modelAnswer: j['model_answer'],
        answerWords: List<String>.from(j['answer_words']),
      );
}

class Question {
  final int id;
  final int questionTypeId;
  final String questionText;
  final int difficulty;
  final int score;
  final String? solutionText;
  final QuestionClassical? classical;

  const Question({
    required this.id,
    required this.questionTypeId,
    required this.questionText,
    required this.difficulty,
    required this.score,
    this.solutionText,
    this.classical,
  });

  factory Question.fromJson(
    Map<String, dynamic> j,
    QuestionClassical? classical,
  ) => Question(
    id: j['id'],
    questionTypeId: j['question_type_id'],
    questionText: j['question_text'],
    difficulty: j['difficulty'] ?? 1,
    score: j['score'] ?? 1,
    solutionText: j['solution_text'],
    classical: classical,
  );
}

// ─── SESSION STATE ─────────────────────────────────────────────────────────

enum AnswerStatus { unanswered, correct, incorrect }

class QuestionAttempt {
  final Question question;
  final List<String> shuffledWords;
  List<String> placedWords;
  AnswerStatus status;
  int revealedHintCount; // kaç kelime ipucu olarak açıldı

  QuestionAttempt({
    required this.question,
    required this.shuffledWords,
    this.placedWords = const [],
    this.status = AnswerStatus.unanswered,
    this.revealedHintCount = 0,
  });

  bool get isComplete => placedWords.length == shuffledWords.length;
  bool get hasHint => revealedHintCount > 0;
  bool get allHintsRevealed {
    final total = question.classical?.answerWords.length ?? 0;
    return revealedHintCount >= total;
  }

  // Checks placed order against model answer words
  bool checkAnswer() {
    final correct = question.classical?.answerWords ?? [];
    if (placedWords.length != correct.length) return false;
    for (int i = 0; i < correct.length; i++) {
      if (placedWords[i] != correct[i]) return false;
    }
    return true;
  }
}

class WrittenSession {
  final List<QuestionAttempt> attempts;
  int currentIndex;

  WrittenSession({required this.attempts, this.currentIndex = 0});

  QuestionAttempt get current => attempts[currentIndex];
  bool get isLast => currentIndex == attempts.length - 1;
  int get totalQuestions => attempts.length;
  int get correctCount =>
      attempts.where((a) => a.status == AnswerStatus.correct).length;
  int get incorrectCount =>
      attempts.where((a) => a.status == AnswerStatus.incorrect).length;
  int get totalScore => attempts
      .where((a) => a.status == AnswerStatus.correct)
      .fold(0, (sum, a) => sum + a.question.score);
}
