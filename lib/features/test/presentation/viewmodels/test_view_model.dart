import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:egitim_uygulamasi/features/test/data/models/test_question.dart';
import 'package:egitim_uygulamasi/features/test/domain/repositories/test_repository.dart';
import 'package:egitim_uygulamasi/models/question_model.dart';
import 'package:collection/collection.dart';
import 'package:egitim_uygulamasi/models/question_blank_option.dart';

class TestViewModel extends ChangeNotifier {
  final TestRepository _repository;

  // State
  List<TestQuestion> _questionQueue = [];
  TestQuestion? _currentTestQuestion;
  int? _sessionId;
  bool _isLoading = true;
  String? _error;
  int _score = 0;
  int _answeredCount = 0;
  int _totalQuestions = 0;
  final Stopwatch _questionTimer = Stopwatch();
  bool _isPrefetching = false;
  TestMode _testMode = TestMode.normal;
  int _unitId = 0;
  String? _userId;
  String? _clientId;

  // Getters
  TestQuestion? get currentTestQuestion => _currentTestQuestion;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get score => _score;
  int get answeredCount => _answeredCount;
  int get totalQuestions => _totalQuestions;
  List<TestQuestion> get questionQueue => _questionQueue;
  int? get sessionId => _sessionId;
  Stopwatch get questionTimer => _questionTimer;
  TestMode get testMode => _testMode;
  int get unitId => _unitId;

  TestViewModel(this._repository);

  // ========== TEST BAŞLATMA METODLARI ==========

  Future<void> startNewTest({
    required TestMode testMode,
    required int unitId,
    int? weekNo,
    required String? userId,
    required String clientId,
  }) async {
    if (userId == null || userId.isEmpty) {
      _setError("Kullanıcı kimliği bulunamadı. Lütfen tekrar giriş yapın.");
      return;
    }

    if (clientId.isEmpty) {
      _setError("Cihaz kimliği bulunamadı. Lütfen uygulamayı yeniden başlatın.");
      return;
    }

    log('TestViewModel.startNewTest: unitId=$unitId, testMode=$testMode, userId=$userId');

    _isLoading = true;
    _error = null;
    _testMode = testMode;
    _unitId = unitId;
    _userId = userId;
    _clientId = clientId;

    notifyListeners();

    try {
      _sessionId = await _repository.startTestSession(
        testMode: testMode,
        unitId: unitId,
        weekNo: weekNo,
        clientId: clientId,
        userId: userId,
      );

      log('TestViewModel.startNewTest: Yeni sessionId = $_sessionId');

      await _fetchInitialQuestion();
    } catch (e, stackTrace) {
      log('TestViewModel.startNewTest ERROR: $e', error: e, stackTrace: stackTrace);
      _setError("Test başlatılamadı: ${_getErrorMessage(e)}");
    }
  }

  Future<void> resumeTest({
    required int sessionId,
    required String? userId,
    required String clientId,
  }) async {
    log('TestViewModel.resumeTest: sessionId=$sessionId');

    _isLoading = true;
    _error = null;
    _sessionId = sessionId;
    _userId = userId;
    _clientId = clientId;
    notifyListeners();

    try {
      final isValid = await _repository.resumeTestSession(sessionId);

      if (!isValid) {
        _setError("Bu test oturumu artık geçerli değil. Yeni bir test başlatın.");
        return;
      }

      await _fetchInitialQuestion();
    } catch (e, stackTrace) {
      log('TestViewModel.resumeTest ERROR: $e', error: e, stackTrace: stackTrace);
      _setError("Teste devam edilemedi: ${_getErrorMessage(e)}");
    }
  }

  // ========== SORU YÜKLEME METODLARI ==========

  Future<void> _fetchInitialQuestion() async {
    if (_sessionId == null) {
      _setError("Test oturumu bulunamadı");
      return;
    }

    try {
      log('TestViewModel._fetchInitialQuestion: sessionId=$_sessionId, userId=$_userId');

      final response = await _repository.getNextQuestion(_sessionId!, _userId);
      final questionData = response['question'];
      final answeredCount = response['answered_count'] as int;
      final correctCount = response['correct_count'] as int;

      log('TestViewModel._fetchInitialQuestion: answeredCount=$answeredCount, correctCount=$correctCount');

      if (questionData == null) {
        log('TestViewModel._fetchInitialQuestion: Tüm sorular tamamlandı');
        await finishTest();
        return;
      }

      final question = Question.fromMap(questionData as Map<String, dynamic>);
      _currentTestQuestion = TestQuestion(question: question);
      _answeredCount = answeredCount;
      _score = correctCount;
      _isLoading = false;
      _error = null;

      log('TestViewModel._fetchInitialQuestion: Soru yüklendi - id=${question.id}, type=${question.type}');

      _questionTimer.reset();
      _questionTimer.start();

      notifyListeners();

      _prefetchRestOfQuestions();
    } catch (e, stackTrace) {
      log('TestViewModel._fetchInitialQuestion ERROR: $e', error: e, stackTrace: stackTrace);
      _setError("İlk soru yüklenemedi: ${_getErrorMessage(e)}");
    }
  }

  // DÜZELTME: _prefetchRestOfQuestions artık cevaplanmış soruları filtreliyor.
  Future<void> _prefetchRestOfQuestions() async {
    if (_sessionId == null || _isPrefetching) return;

    _isPrefetching = true;

    try {
      log('TestViewModel._prefetchRestOfQuestions: Başlıyor...');

      // 1. Oturumdaki tüm soruları ve cevaplanmış soru ID'lerini aynı anda çek.
      final results = await Future.wait([
        _repository.getAllSessionQuestions(_sessionId!, _userId),
        _repository.getAnsweredQuestionIds(_sessionId!),
      ]);

      final allQuestions = results[0] as List<Question>;
      final answeredQuestionIds = results[1] as Set<int>;

      _totalQuestions = allQuestions.length;
      log('TestViewModel._prefetchRestOfQuestions: Toplam $totalQuestions soru bulundu. ${answeredQuestionIds.length} tanesi cevaplanmış.');

      // 2. Hem mevcut soruyu hem de daha önce cevaplanmış soruları filtrele.
      final currentQuestionId = _currentTestQuestion?.question.id;
      _questionQueue = allQuestions
          .where((q) =>
              q.id != currentQuestionId && !answeredQuestionIds.contains(q.id))
          .map((q) => TestQuestion(question: q))
          .toList();

      log('TestViewModel._prefetchRestOfQuestions: ${allQuestions.length} sorudan, ${answeredQuestionIds.length} cevaplanmış ve 1 mevcut soru filtrelendi. Kuyrukta ${_questionQueue.length} soru kaldı.');

      notifyListeners();
    } catch (e, stackTrace) {
      log('TestViewModel._prefetchRestOfQuestions ERROR: $e', error: e, stackTrace: stackTrace);
    } finally {
      _isPrefetching = false;
    }
  }

  // ========== CEVAP İŞLEMLERİ ==========

  Future<void> checkAnswer() async {
    if (_currentTestQuestion == null ||
        _currentTestQuestion!.isChecked ||
        _currentTestQuestion!.userAnswer == null) {
      return;
    }

    log('TestViewModel.checkAnswer: Cevap kontrol ediliyor...');

    _questionTimer.stop();
    final duration = _questionTimer.elapsed.inSeconds;

    final isCorrect = _checkIfAnswerIsCorrect();

    log('TestViewModel.checkAnswer: Cevap ${isCorrect ? 'DOĞRU' : 'YANLIŞ'}, duration=$duration saniye');

    _currentTestQuestion = _currentTestQuestion!.copyWith(
      isChecked: true,
      isCorrect: isCorrect,
    );

    if (isCorrect) {
      _score++;
      log('TestViewModel.checkAnswer: Yeni skor=$_score');
    }

    notifyListeners();

    await _saveAnswer(isCorrect, duration);
  }

  bool _checkIfAnswerIsCorrect() {
    final testQuestion = _currentTestQuestion!;
    final question = testQuestion.question;

    try {
      switch (question.type) {
        case QuestionType.multiple_choice:
        case QuestionType.true_false:
          final correctChoice = question.choices.firstWhereOrNull((c) => c.isCorrect);
          if (correctChoice == null) return false;
          return (testQuestion.userAnswer == correctChoice.id);

        case QuestionType.fill_blank:
          if (testQuestion.userAnswer is! Map<int, dynamic>) return false;
          final userAnswer = testQuestion.userAnswer as Map<int, dynamic>;

          final correctOptions = question.blankOptions.where((opt) => opt.isCorrect).toList();

          for (int i = 0; i < userAnswer.length; i++) {
            final userOption = userAnswer[i];
            if (userOption == null) return false;

            if (userOption is QuestionBlankOption) {
              final correctOption = correctOptions.firstWhereOrNull((opt) => opt.id == userOption.id);
              if (correctOption == null) return false;
            } else if (userOption is String) {
              final correctOption = correctOptions.firstWhereOrNull((opt) => opt.id.toString() == userOption);
              if (correctOption == null) return false;
            }
          }
          return true;

        case QuestionType.matching:
          if (testQuestion.userAnswer is! Map<String, dynamic>) return false;
          final userMatches = testQuestion.userAnswer as Map<String, dynamic>;

          if (question.matchingPairs == null) return false;

          for (final pair in question.matchingPairs!) {
            final userRightText = userMatches[pair.left_text];
            if (userRightText?.toString() != pair.right_text) {
              return false;
            }
          }
          return true;

        default:
          return false;
      }
    } catch (e) {
      log('TestViewModel._checkIfAnswerIsCorrect ERROR: $e');
      return false;
    }
  }

  Future<void> _saveAnswer(bool isCorrect, int duration) async {
    if (_sessionId == null || _currentTestQuestion == null || _userId == null || _clientId == null) {
      log('TestViewModel._saveAnswer: Kaydetme işlemi iptal edildi. Eksik bilgi var. SessionId: $_sessionId, UserId: $_userId');
      return;
    }

    try {
      await _repository.saveAnswer(
        sessionId: _sessionId!,
        questionId: _currentTestQuestion!.question.id,
        userId: _userId,
        clientId: _clientId!,
        userAnswer: _currentTestQuestion!.userAnswer,
        isCorrect: isCorrect,
        durationSeconds: duration,
      );

      log('TestViewModel._saveAnswer: Cevap kaydedildi - questionId=${_currentTestQuestion!.question.id}, isCorrect=$isCorrect, duration=$duration');
    } catch (e, stackTrace) {
      log('TestViewModel._saveAnswer ERROR: $e', error: e, stackTrace: stackTrace);
    }
  }

  // ========== TEST NAVİGASYONU ==========

  Future<void> nextQuestion() async {
    if (_questionQueue.isNotEmpty) {
      log('TestViewModel.nextQuestion: Kuyruktan yeni soru yükleniyor...');

      _currentTestQuestion = _questionQueue.removeAt(0);
      _answeredCount++;

      log('TestViewModel.nextQuestion: Yeni soru - id=${_currentTestQuestion!.question.id}, answeredCount=$_answeredCount');

      _questionTimer.reset();
      _questionTimer.start();

      notifyListeners();
    } else {
      log('TestViewModel.nextQuestion: Kuyruk boş, test tamamlanıyor...');
      await finishTest();
    }
  }

  Future<void> finishTest() async {
    if (_sessionId == null) return;

    log('TestViewModel.finishTest: sessionId=$_sessionId, testMode=$_testMode');

    try {
      await _repository.finishTestSession(_sessionId!, _testMode);

      _currentTestQuestion = null;
      _isLoading = false;

      log('TestViewModel.finishTest: Test başarıyla tamamlandı');

      notifyListeners();
    } catch (e, stackTrace) {
      log('TestViewModel.finishTest ERROR: $e', error: e, stackTrace: stackTrace);
      _error = "Test bitirilirken hata: ${_getErrorMessage(e)}";
      notifyListeners();
    }
  }

  // ========== YARDIMCI METODLAR ==========

  void updateUserAnswer(dynamic answer) {
    if (_currentTestQuestion == null || _currentTestQuestion!.isChecked) return;

    _currentTestQuestion = _currentTestQuestion!.copyWith(userAnswer: answer);

    log('TestViewModel.updateUserAnswer: Cevap güncellendi - type=${answer.runtimeType}');

    notifyListeners();
  }

  void resetTimer() {
    _questionTimer.reset();
    _questionTimer.start();
  }

  void _setError(String message) {
    _error = message;
    _isLoading = false;
    log('TestViewModel._setError: $message');
    notifyListeners();
  }

  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString();

    if (errorStr.contains('network') || errorStr.contains('internet') || errorStr.contains('Connection')) {
      return 'İnternet bağlantınızı kontrol edin.';
    } else if (errorStr.contains('auth') || errorStr.contains('login') || errorStr.contains('unauthorized')) {
      return 'Oturumunuz sonlandırılmış. Lütfen tekrar giriş yapın.';
    } else if (errorStr.contains('no questions') || errorStr.contains('soru bulunamadı')) {
      return 'Bu ünitede çözülebilecek soru bulunamadı.';
    } else if (errorStr.contains('timeout') || errorStr.contains('time out')) {
      return 'Sunucuya bağlanılamıyor. Lütfen tekrar deneyin.';
    } else {
      return errorStr.length > 100 ? errorStr.substring(0, 100) + '...' : errorStr;
    }
  }

  void reset() {
    log('--- TestViewModel.reset() ÇAĞRILDI ---');
    _questionQueue.clear();
    _currentTestQuestion = null;
    _sessionId = null;
    _isLoading = true;
    _error = null;
    _score = 0;
    _answeredCount = 0;
    _totalQuestions = 0;
    _questionTimer.stop();
    _isPrefetching = false;
    _testMode = TestMode.normal;
    _unitId = 0;
    _userId = null;
    _clientId = null;
    notifyListeners();
  }
}