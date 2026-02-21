import 'dart:async';
import 'dart:developer';
import 'package:egitim_uygulamasi/features/test/data/models/test_question.dart';
import 'package:egitim_uygulamasi/features/test/domain/repositories/test_repository.dart';
import 'package:egitim_uygulamasi/models/question_blank_option.dart';
import 'package:egitim_uygulamasi/models/question_model.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TestViewModel extends ChangeNotifier {
  final TestRepository _repository;

  // State
  static const int questionTimeLimitSeconds = 40;
  List<TestQuestion> _questionQueue = [];
  TestQuestion? _currentTestQuestion;
  int? _sessionId;
  bool _isLoading = true;
  String? _error;
  int _score = 0;
  bool _isSaving = false;
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
  int get correctCount => _score;
  int get incorrectCount {
    final incorrect = _answeredCount - _score;
    return incorrect < 0 ? 0 : incorrect;
  }

  double get successPercentage {
    final denominator = _answeredCount > 0 ? _answeredCount : _totalQuestions;
    if (denominator <= 0) return 0;
    return (_score / denominator) * 100;
  }

  bool get isSaving => _isSaving;
  int get answeredCount => _answeredCount;
  int get totalQuestions => _totalQuestions;
  List<TestQuestion> get questionQueue => _questionQueue;
  int? get sessionId => _sessionId;
  Stopwatch get questionTimer => _questionTimer;
  TestMode get testMode => _testMode;
  int get unitId => _unitId;
  int get timeLimitSeconds => questionTimeLimitSeconds;
  int get remainingSeconds {
    final elapsed = _questionTimer.elapsed.inSeconds;
    final remaining = questionTimeLimitSeconds - elapsed;
    if (remaining < 0) return 0;
    if (remaining > questionTimeLimitSeconds) return questionTimeLimitSeconds;
    return remaining;
  }

  TestViewModel(this._repository);

  // ========== TEST BAŞLATMA METODLARI ==========

  // SRS (Spaced Repetition) test başlat
  Future<void> startSrsTest({
    required int sessionId,
    required String userId,
    required String clientId,
  }) async {
    log('TestViewModel.startSrsTest: sessionId=$sessionId, userId=$userId');
    _isLoading = true;
    _error = null;
    _testMode = TestMode.srs;
    _unitId = 0; // SRS testinde unitId yok
    _userId = userId;
    _clientId = clientId;
    _sessionId = sessionId;
    notifyListeners();

    try {
      // Oturum geçerliliğini kontrol et
      final isValid = await _repository.resumeTestSession(sessionId);
      if (!isValid) {
        _setError(
          "Bu test oturumu artık geçerli değil. Yeni bir test başlatın.",
        );
        return;
      }

      await _fetchInitialQuestion();
    } catch (e, stackTrace) {
      log(
        'TestViewModel.startSrsTest ERROR: $e',
        error: e,
        stackTrace: stackTrace,
      );
      _setError("SRS testi başlatılamadı: ${_getErrorMessage(e)}");
    }
  }

  Future<void> startGuestUnitTest({required int unitId}) async {
    log('TestViewModel.startGuestUnitTest: unitId=$unitId');
    _isLoading = true;
    _error = null;
    _testMode = TestMode.normal; // Misafir ünite testi
    _unitId = unitId;
    _userId = null; // Misafir
    _sessionId = null; // Misafir testinde session ID olmaz
    notifyListeners();

    try {
      final questions = await _repository.startGuestUnitTest(unitId: unitId);

      if (questions.isEmpty) {
        throw Exception("Bu test için soru bulunamadı.");
      }

      _questionQueue = questions.map((q) => TestQuestion(question: q)).toList();
      _totalQuestions = _questionQueue.length;
      _currentTestQuestion = _questionQueue.removeAt(0); // İlk soruyu al

      _isLoading = false;
      _questionTimer.reset();
      _questionTimer.start();
      log(
        'TestViewModel.startGuestUnitTest: Misafir ünite testi başarıyla başlatıldı. Toplam $_totalQuestions soru yüklendi.',
      );
      notifyListeners();
    } catch (e, stackTrace) {
      log(
        'TestViewModel.startGuestUnitTest ERROR: $e',
        error: e,
        stackTrace: stackTrace,
      );
      _setError("Misafir ünite testi başlatılamadı: ${_getErrorMessage(e)}");
    }
  }

  Future<void> startGuestTest({
    required int unitId,
    required int curriculumWeek,
    int? topicId,
    List<int>? outcomeIds,
  }) async {
    log(
      'TestViewModel.startGuestTest: unitId=$unitId, curriculumWeek=$curriculumWeek',
    );
    _isLoading = true;
    _error = null;
    _testMode = TestMode.weekly; // Misafir testi her zaman haftalık modda
    _unitId = unitId;
    _userId = null; // Misafir
    _sessionId = null; // Misafir testinde session ID olmaz
    notifyListeners();

    try {
      final questions = await _repository.startGuestTest(
        unitId: unitId,
        curriculumWeek: curriculumWeek,
        topicId: topicId,
        outcomeIds: outcomeIds,
      );

      if (questions.isEmpty) {
        throw Exception("Bu test için soru bulunamadı.");
      }

      _questionQueue = questions.map((q) => TestQuestion(question: q)).toList();
      _totalQuestions = _questionQueue.length;
      _currentTestQuestion = _questionQueue.removeAt(0); // İlk soruyu al

      _isLoading = false;
      _questionTimer.reset();
      _questionTimer.start();
      log(
        'TestViewModel.startGuestTest: Misafir testi başarıyla başlatıldı. Toplam $_totalQuestions soru yüklendi.',
      );
      notifyListeners();
    } catch (e, stackTrace) {
      log(
        'TestViewModel.startGuestTest ERROR: $e',
        error: e,
        stackTrace: stackTrace,
      );
      _setError("Misafir testi başlatılamadı: ${_getErrorMessage(e)}");
    }
  }

  Future<void> startNewTest({
    required TestMode testMode,
    required int unitId,
    int? curriculumWeek,
    int? topicId,
    List<int>? outcomeIds,
    required String? userId,
    required String clientId,
  }) async {
    // Bu metot sadece kayıtlı kullanıcılar için. Misafirler resumeTest kullanır.
    if (userId == null || userId.isEmpty) {
      _setError("Kullanıcı kimliği bulunamadı. Lütfen tekrar giriş yapın.");
      return;
    }

    if (clientId.isEmpty) {
      _setError(
        "Cihaz kimliği bulunamadı. Lütfen uygulamayı yeniden başlatın.",
      );
      return;
    }

    log(
      'TestViewModel.startNewTest: unitId=$unitId, testMode=$testMode, userId=$userId',
    );

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
        curriculumWeek: curriculumWeek,
        topicId: topicId,
        outcomeIds: outcomeIds,
        clientId: clientId,
        userId: userId,
      );

      log('TestViewModel.startNewTest: Yeni sessionId = $_sessionId');

      await _fetchInitialQuestion();
    } catch (e, stackTrace) {
      log(
        'TestViewModel.startNewTest ERROR: $e',
        error: e,
        stackTrace: stackTrace,
      );
      _setError("Test başlatılamadı: ${_getErrorMessage(e)}");
    }
  }

  Future<void> resumeTest({
    required int sessionId,
    required String? userId, // Artık null olabilir
    required String clientId,
  }) async {
    log('TestViewModel.resumeTest: sessionId=$sessionId, userId=$userId');

    _isLoading = true;
    _error = null;
    _sessionId = sessionId;
    _userId = userId; // userId null ise bu bir misafir testidir
    _clientId = clientId;
    notifyListeners();

    try {
      // Sadece kayıtlı kullanıcılar için oturum geçerliliğini kontrol et
      if (userId != null) {
        final isValid = await _repository.resumeTestSession(sessionId);
        if (!isValid) {
          _setError(
            "Bu test oturumu artık geçerli değil. Yeni bir test başlatın.",
          );
          return;
        }
      }

      await _fetchInitialQuestion();
    } catch (e, stackTrace) {
      log(
        'TestViewModel.resumeTest ERROR: $e',
        error: e,
        stackTrace: stackTrace,
      );
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
      log(
        'TestViewModel._fetchInitialQuestion: sessionId=$_sessionId, userId=$_userId',
      );

      final response = await _repository.getNextQuestion(_sessionId!, _userId);
      final questionData = response['question'];
      final answeredCount = response['answered_count'] as int;
      final correctCount = response['correct_count'] as int;

      log(
        'TestViewModel._fetchInitialQuestion: answeredCount=$answeredCount, correctCount=$correctCount',
      );

      if (questionData == null) {
        // Eğer hiç soru cevaplanmadıysa ve ilk soru da null geldiyse, bu testte hiç soru yok demektir.
        if (answeredCount == 0) {
          log(
            'TestViewModel._fetchInitialQuestion: Test için hiç soru bulunamadı.',
          );
          throw Exception('Bu test için soru bulunamadı.');
        }
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

      log(
        'TestViewModel._fetchInitialQuestion: Soru yüklendi - id=${question.id}, type=${question.type}',
      );

      _questionTimer.reset();
      _questionTimer.start();

      notifyListeners();

      _prefetchRestOfQuestions();
    } catch (e, stackTrace) {
      log(
        'TestViewModel._fetchInitialQuestion ERROR: $e',
        error: e,
        stackTrace: stackTrace,
      );
      _setError("İlk soru yüklenemedi: ${_getErrorMessage(e)}");
    }
  }

  Future<void> _prefetchRestOfQuestions() async {
    if (_sessionId == null || _isPrefetching) return;

    _isPrefetching = true;

    try {
      log('TestViewModel._prefetchRestOfQuestions: Başlıyor...');

      final results = await Future.wait([
        _repository.getAllSessionQuestions(_sessionId!, _userId),
        if (_userId != null)
          _repository.getAnsweredQuestionIds(_sessionId!)
        else
          Future.value(<int>{}),
      ]);

      final allQuestions = results[0] as List<Question>;
      final answeredQuestionIds = results[1] as Set<int>;

      _totalQuestions = allQuestions.length;
      log(
        'TestViewModel._prefetchRestOfQuestions: Toplam $totalQuestions soru bulundu. ${answeredQuestionIds.length} tanesi cevaplanmış.',
      );

      final currentQuestionId = _currentTestQuestion?.question.id;
      _questionQueue = allQuestions
          .where(
            (q) =>
                q.id != currentQuestionId &&
                !answeredQuestionIds.contains(q.id),
          )
          .map((q) => TestQuestion(question: q))
          .toList();

      log(
        'TestViewModel._prefetchRestOfQuestions: ${allQuestions.length} sorudan, ${answeredQuestionIds.length} cevaplanmış ve 1 mevcut soru filtrelendi. Kuyrukta ${_questionQueue.length} soru kaldı.',
      );

      notifyListeners();
    } catch (e, stackTrace) {
      log(
        'TestViewModel._prefetchRestOfQuestions ERROR: $e',
        error: e,
        stackTrace: stackTrace,
      );
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

    log(
      'TestViewModel.checkAnswer: Cevap ${isCorrect ? 'DOĞRU' : 'YANLIŞ'}, duration=$duration saniye',
    );

    _currentTestQuestion = _currentTestQuestion!.copyWith(
      isChecked: true,
      isCorrect: isCorrect,
    );

    if (isCorrect) {
      _score++;
      log('TestViewModel.checkAnswer: Yeni skor=$_score');
    }

    notifyListeners();

    // Sadece kayıtlı kullanıcıların cevaplarını kaydet
    if (_userId != null) {
      await _saveAnswer(isCorrect, duration);
    }
  }

  bool _checkIfAnswerIsCorrect() {
    final testQuestion = _currentTestQuestion!;
    final question = testQuestion.question;

    try {
      switch (question.type) {
        case QuestionType.multiple_choice:
        case QuestionType.true_false:
          final correctChoice = question.choices.firstWhereOrNull(
            (c) => c.isCorrect,
          );
          if (correctChoice == null) return false;
          return (testQuestion.userAnswer == correctChoice.id);

        case QuestionType.fill_blank:
          if (testQuestion.userAnswer is! Map<int, dynamic>) return false;
          final userAnswer = testQuestion.userAnswer as Map<int, dynamic>;

          final correctOptions = question.blankOptions
              .where((opt) => opt.isCorrect)
              .toList();

          for (int i = 0; i < userAnswer.length; i++) {
            final userOption = userAnswer[i];
            if (userOption == null) return false;

            if (userOption is QuestionBlankOption) {
              final correctOption = correctOptions.firstWhereOrNull(
                (opt) => opt.id == userOption.id,
              );
              if (correctOption == null) return false;
            } else if (userOption is String) {
              final correctOption = correctOptions.firstWhereOrNull(
                (opt) => opt.id.toString() == userOption,
              );
              if (correctOption == null) return false;
            }
          }
          return true;

        case QuestionType.matching:
          if (testQuestion.userAnswer is! Map) return false;
          final userMatches = testQuestion.userAnswer as Map;

          if (question.matchingPairs == null) return false;
          if (userMatches.length != question.matchingPairs!.length)
            return false;

          for (final correctPair in question.matchingPairs!) {
            final userMatchedPair = userMatches[correctPair.leftText];

            if (userMatchedPair is! MatchingPair) {
              return false;
            }

            if (userMatchedPair.rightText != correctPair.rightText) {
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
    // userId null ise (misafir ise) cevapları kaydetme.
    if (_sessionId == null ||
        _currentTestQuestion == null ||
        _userId == null ||
        _clientId == null) {
      log(
        'TestViewModel._saveAnswer: Kaydetme işlemi iptal edildi. Eksik bilgi veya misafir kullanıcısı. SessionId: $_sessionId, UserId: $_userId, ClientId: $_clientId',
      );
      return;
    }

    try {
      _isSaving = true;
      notifyListeners();
      log(
        'TestViewModel._saveAnswer: Dahili (repository) kaydetme fonksiyonu kullanılıyor (test_session_answers).',
      );
      await _repository.saveAnswer(
        sessionId: _sessionId!,
        questionId: _currentTestQuestion!.question.id,
        userId: _userId,
        clientId: _clientId!,
        userAnswer: _currentTestQuestion!.userAnswer,
        isCorrect: isCorrect,
        durationSeconds: duration,
      );
      log(
        'TestViewModel._saveAnswer: test_session_answers tablosuna kayıt başarıyla yapıldı.',
      );
    } catch (e, stackTrace) {
      final errorMessage = "Cevap kaydedilirken bir hata oluştu.";
      log('$errorMessage\nDETAYLAR: $e', error: e, stackTrace: stackTrace);

      debugPrint("**************************************************");
      debugPrint("HATA: CEVAP KAYDEDİLEMEDİ");
      debugPrint("**************************************************");
      debugPrint("Oturum ID: $_sessionId");
      debugPrint("Soru ID: ${_currentTestQuestion?.question.id}");
      debugPrint("Hata Detayı: $e");
      if (e is PostgrestException) {
        debugPrint("Postgrest Mesajı: ${e.message}");
        debugPrint("Postgrest Detayları: ${e.details}");
        debugPrint("Postgrest İpucu: ${e.hint}");
      }
      debugPrint("**************************************************");
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ========== TEST NAVİGASYONU ==========

  Future<void> nextQuestion() async {
    if (_questionQueue.isNotEmpty) {
      log('TestViewModel.nextQuestion: Kuyruktan yeni soru yükleniyor...');

      _currentTestQuestion = _questionQueue.removeAt(0);
      _answeredCount++;

      log(
        'TestViewModel.nextQuestion: Yeni soru - id=${_currentTestQuestion!.question.id}, answeredCount=$_answeredCount',
      );

      _questionTimer.reset();
      _questionTimer.start();

      notifyListeners();
    } else {
      log('TestViewModel.nextQuestion: Kuyruk boş, test tamamlanıyor...');
      await finishTest();
    }
  }

  Future<void> finishTest() async {
    // DÜZELTME: Test bitirilirken, eğer ekranda hala bir soru varsa,
    // bu son sorunun da çözüldüğünü say.
    if (_currentTestQuestion != null) {
      _answeredCount++;
      log(
        'TestViewModel.finishTest: Son soru da sayıldı, yeni answeredCount=$_answeredCount',
      );
    }

    // Misafir testleri (sessionId == null ve userId == null) için veritabanı işlemi yapma
    if (_userId == null) {
      log(
        'TestViewModel.finishTest: Misafir testi, veritabanı işlemi atlanıyor.',
      );
      _currentTestQuestion = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    if (sessionId == null) {
      log(
        'TestViewModel.finishTest: Oturum ID yok, veritabanı işlemi atlanıyor.',
      );
      _currentTestQuestion = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    log('TestViewModel.finishTest: sessionId=$sessionId, testMode=$testMode');

    try {
      await _repository.finishTestSession(sessionId!, testMode);
      _currentTestQuestion = null;
      _isLoading = false;

      log(
        'TestViewModel.finishTest: Test başarıyla tamamlandı (UserId: $_userId)',
      );

      notifyListeners();
    } catch (e, stackTrace) {
      log(
        'TestViewModel.finishTest ERROR: $e',
        error: e,
        stackTrace: stackTrace,
      );
      debugPrint('--- HATA DETAYI --- Stack Trace: $stackTrace');
      _error = "Test bitirilirken hata: ${_getErrorMessage(e)}";
      notifyListeners();
    }
  }

  // ========== YARDIMCI METODLAR ==========

  void updateUserAnswer(dynamic answer) {
    if (_currentTestQuestion == null || _currentTestQuestion!.isChecked) return;

    _currentTestQuestion = _currentTestQuestion!.copyWith(userAnswer: answer);

    log(
      'TestViewModel.updateUserAnswer: Cevap güncellendi - type=${answer.runtimeType}',
    );

    notifyListeners();
  }

  void resetTimer() {
    _questionTimer.reset();
    _questionTimer.start();
  }

  Future<void> handleTimeExpired() async {
    if (_currentTestQuestion == null || _currentTestQuestion!.isChecked) return;

    _questionTimer.stop();
    final duration = _questionTimer.elapsed.inSeconds;

    if (_currentTestQuestion!.userAnswer != null) {
      await checkAnswer();
      return;
    }

    _currentTestQuestion = _currentTestQuestion!.copyWith(
      isChecked: true,
      isCorrect: false,
    );
    notifyListeners();

    // Süre dolan soruyu (yanlış) olarak DB'ye kaydet
    if (_userId != null) {
      await _saveAnswer(false, duration);
    }
  }

  void _setError(String message) {
    _error = message;
    _isLoading = false;
    log('TestViewModel._setError: $message');
    notifyListeners();
  }

  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString();

    if (errorStr.contains('network') ||
        errorStr.contains('internet') ||
        errorStr.contains('Connection')) {
      return 'İnternet bağlantınızı kontrol edin.';
    } else if (errorStr.contains('auth') ||
        errorStr.contains('login') ||
        errorStr.contains('unauthorized')) {
      return 'Oturumunuz sonlandırılmış. Lütfen tekrar giriş yapın.';
    } else if (errorStr.contains('no questions') ||
        errorStr.contains('soru bulunamadı')) {
      return 'Bu ünitede çözülebilecek soru bulunamadı.';
    } else if (errorStr.contains('timeout') || errorStr.contains('time out')) {
      return 'Sunucuya bağlanılamıyor. Lütfen tekrar deneyin.';
    } else {
      return errorStr.length > 100
          ? '${errorStr.substring(0, 100)}...'
          : errorStr;
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
