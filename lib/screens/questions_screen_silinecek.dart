import 'package:collection/collection.dart';
import 'package:egitim_uygulamasi/models/question_model.dart';
import 'package:egitim_uygulamasi/models/question_blank_option.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

enum TestMode { normal, wrongAnswers, weekly }

class TestQuestion {
  final Question question;
  dynamic userAnswer;
  bool isChecked;
  bool isCorrect;

  TestQuestion({
    required this.question,
    this.userAnswer,
    this.isChecked = false,
    this.isCorrect = false,
  });
}

class QuestionsScreen extends StatefulWidget {
  final int unitId;
  final TestMode testMode;
  final int? sessionId;

  const QuestionsScreen({
    super.key,
    required this.unitId,
    this.testMode = TestMode.normal,
    this.sessionId,
  });

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  List<TestQuestion> _questionQueue = [];
  bool _isPrefetching = false;

  TestQuestion? _currentTestQuestion;
  int? _sessionId;

  bool _isLoadingData = true;
  String? _error;
  int _score = 0;
  int _answeredCount = 0;
  int _totalQuestions = 10;

  final Stopwatch _questionTimer = Stopwatch();

  @override
  void initState() {
    super.initState();
    if (widget.sessionId != null) {
      _resumeTest(widget.sessionId!);
    } else {
      _startNewTest();
    }
  }

  Future<void> _resumeTest(int sessionId) async {
    setState(() { _isLoadingData = true; _error = null; });
    _sessionId = sessionId;
    debugPrint('--- MEVCUT TESTE DEVAM EDİLİYOR (sessionId): $_sessionId ---');
    await _fetchInitialAndPrefetchRest();
  }

  Future<String> _getOrCreateClientId() async {
    final prefs = await SharedPreferences.getInstance();
    String? clientId = prefs.getString('client_id');
    if (clientId == null) {
      clientId = const Uuid().v4();
      await prefs.setString('client_id', clientId);
    }
    return clientId;
  }

  Future<void> _startNewTest() async {
    setState(() { _isLoadingData = true; _error = null; });
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      final clientId = await _getOrCreateClientId();

      String rpcName;
      dynamic params;

      // Test moduna göre doğru RPC ve parametreleri seç
      switch (widget.testMode) {
        case TestMode.weekly:
          rpcName = 'start_weekly_test_session';
          final curriculumWeek = ModalRoute.of(context)?.settings.arguments as int? ?? 1;
          params = {
            'p_user_id': userId,
            'p_unit_id': widget.unitId,
            'p_curriculum_week': curriculumWeek,
            'p_client_id': clientId,
          };
          break;
        case TestMode.wrongAnswers:
          rpcName = 'start_wrong_answers_session';
          params = {
            'p_client_id': clientId,
            'p_unit_id': widget.unitId,
            'p_user_id': userId,
          };
          break;
        case TestMode.normal:
        default:
          rpcName = 'start_unit_test';
          params = {
            'p_client_id': clientId,
            'p_unit_id': widget.unitId,
            'p_user_id': userId,
          };
          break;
      }

      debugPrint('--- RPC $rpcName ÇAĞRILIYOR (YENİ TEST) ---');
      debugPrint('Parametreler: $params');

      final response = await client.rpc(rpcName, params: params);

      _sessionId = response as int;
      debugPrint('--- RPC $rpcName YANITI (YENİ sessionId): $_sessionId ---');

      await _fetchInitialAndPrefetchRest();

    } catch (e, st) {
      debugPrint('--- YENİ TEST BAŞLATILIRKEN KRİTİK HATA ---');
      debugPrint('Hata: $e');
      debugPrint('Stack Trace: $st');
      if (mounted) {
        setState(() {
          _error = "Test başlatılamadı: $e";
          _isLoadingData = false;
        });
      }
    }
  }

  Future<void> _fetchInitialAndPrefetchRest() async {
    if (_sessionId == null) return;

    try {
      debugPrint('--- İLK SORU YÜKLENİYOR (Oturum: $_sessionId) ---');
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;

      final initialResponse = await client.rpc(
        'get_next_question_v3',
        params: {'p_session_id': _sessionId!, 'p_user_id': userId},
      );

      final initialData = initialResponse as Map<String, dynamic>;
      final initialQuestionData = initialData['question'];
      final initialAnsweredCount = initialData['answered_count'] as int;
      final initialCorrectCount = initialData['correct_count'] as int;

      if (initialQuestionData == null) {
        await _finishTest();
        return;
      }

      final firstQuestion = Question.fromMap(initialQuestionData as Map<String, dynamic>);
      if (mounted) {
        setState(() {
          _currentTestQuestion = TestQuestion(question: firstQuestion);
          _answeredCount = initialAnsweredCount;
          _score = initialCorrectCount;
          _isLoadingData = false;
          _error = null;
        });
        _questionTimer.reset();
        _questionTimer.start();
        debugPrint('--- İLK SORU GÖSTERİLDİ (ID: ${firstQuestion.id}) ---');
        debugPrint('--- MEVCUT PUAN: $_score ---');
      }

      _prefetchRestOfQuestions();

    } catch (e) {
      debugPrint('--- İLK SORU YÜKLENİRKEN HATA ---');
      if (mounted) setState(() => _error = "İlk soru yüklenemedi: $e");
    }
  }

  Future<void> _prefetchRestOfQuestions() async {
    if (_sessionId == null || _isPrefetching) return;
    _isPrefetching = true;
    debugPrint('--- ARKA PLAN YÜKLEME BAŞLADI ---');
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;

      final allQuestionsResponse = await client.rpc(
        'get_all_session_questions',
        params: {'p_session_id': _sessionId!, 'p_user_id': userId},
      );

      if (allQuestionsResponse == null) {
        debugPrint('--- ARKA PLAN YÜKLEME: Oturum için soru bulunamadı. ---');
        return;
      }

      final questionList = (allQuestionsResponse as List).map((q) => Question.fromMap(q as Map<String, dynamic>)).toList();
      if (mounted) setState(() => _totalQuestions = questionList.length);

      final answeredResponse = await client
          .from('test_session_answers')
          .select('question_id')
          .eq('test_session_id', _sessionId!);

      final answeredQuestionIds = (answeredResponse as List)
          .map((row) => row['question_id'] as int)
          .toSet();

      final remainingQuestions = questionList.where((q) {
        final isAnswered = answeredQuestionIds.contains(q.id);
        final isCurrent = q.id == _currentTestQuestion?.question.id;
        return !isAnswered && !isCurrent;
      }).toList();

      _questionQueue = remainingQuestions.map((q) => TestQuestion(question: q)).toList();
      debugPrint('--- ARKA PLAN YÜKLEME TAMAMLANDI: ${_questionQueue.length} soru hazır. ---');

    } catch (e, st) {
      debugPrint('--- ARKA PLAN YÜKLEME HATASI: $e ---');
      debugPrint(st.toString());
    } finally {
      _isPrefetching = false;
    }
  }

  Future<void> _loadNextQuestion() async {
    if (_questionQueue.isNotEmpty) {
      debugPrint('--- SONRAKİ SORU HAFIZADAN YÜKLENDİ ---');
      setState(() {
        _currentTestQuestion = _questionQueue.removeAt(0);
        _answeredCount++;
      });
      _questionTimer.reset();
      _questionTimer.start();
    } else {
      debugPrint('--- Test bitti veya sıradaki soru bekleniyor ---');
      await _finishTest();
    }
  }

  void _checkAnswer() {
    final testQuestion = _currentTestQuestion;
    if (testQuestion == null || testQuestion.isChecked || testQuestion.userAnswer == null) return;

    _questionTimer.stop();
    final int duration = _questionTimer.elapsed.inSeconds;

    bool isCorrect = false;
    final question = testQuestion.question;

    if (question.type == QuestionType.multiple_choice || question.type == QuestionType.true_false) {
      final correctChoice = question.choices.firstWhereOrNull((c) => c.isCorrect);
      isCorrect = (testQuestion.userAnswer == correctChoice?.id);
    } else if (question.type == QuestionType.fill_blank) {
      if (testQuestion.userAnswer is Map<int, QuestionBlankOption?>) {
        final correctOptionIds = question.blankOptions.where((opt) => opt.isCorrect).map((opt) => opt.id).toSet();
        final userAnswerIds = (testQuestion.userAnswer as Map<int, QuestionBlankOption?>).values.whereNotNull().map((opt) => opt.id).toSet();
        isCorrect = const SetEquality().equals(userAnswerIds, correctOptionIds);
      }
    } else if (question.type == QuestionType.matching) {
      final userMatches = testQuestion.userAnswer as Map<String, MatchingPair?>?;
      if (userMatches != null && question.matchingPairs != null && userMatches.length == question.matchingPairs!.length) {
        final correctMatches = { for (var p in question.matchingPairs!) p.left_text: p.right_text };
        isCorrect = userMatches.entries.every((entry) => correctMatches[entry.key] == entry.value?.right_text);
      }
    }

    setState(() {
      testQuestion.isChecked = true;
      testQuestion.isCorrect = isCorrect;
      if (isCorrect) _score++;
    });

    _saveAnswer(isCorrect, duration).catchError((e, st) {
      debugPrint('--- ARKA PLAN CEVAP KAYDETME HATASI: $e ---');
    });
  }

  Future<void> _saveAnswer(bool isCorrect, int duration) async {
    if (_sessionId == null || _currentTestQuestion == null) return;

    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    final clientId = await _getOrCreateClientId();
    final question = _currentTestQuestion!.question;
    final userAnswer = _currentTestQuestion!.userAnswer;

    String? getUserAnswerAsText() {
      if (userAnswer is String) return userAnswer;
      return userAnswer?.toString();
    }

    final dataToInsert = {
      'test_session_id': _sessionId,
      'question_id': question.id,
      'user_id': userId,
      'client_id': clientId,
      'selected_option_id': (question.type == QuestionType.multiple_choice || question.type == QuestionType.true_false) ? userAnswer : null,
      'answer_text': getUserAnswerAsText(),
      'is_correct': isCorrect,
      'duration_seconds': duration,
    };

    await client.from('test_session_answers').insert(dataToInsert);
  }

  Future<void> _finishTest() async {
    if (_sessionId == null) return;
    try {
      final rpcName = widget.testMode == TestMode.weekly
          ? 'finish_weekly_test'
          : 'finish_test_v2';

      await Supabase.instance.client.rpc(rpcName, params: {'p_session_id': _sessionId!});

      if (mounted) {
        setState(() {
          _isLoadingData = false;
          _currentTestQuestion = null;
        });
      }
    } catch (e) {
      debugPrint('--- TEST BİTİRİLİRKEN HATA ($widget.testMode): $e ---');
    }
  }

  Future<bool> _onWillPop() async {
    if (_sessionId == null || _currentTestQuestion == null) return true;
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Testten Çıkış'),
        content: const Text('Testi bitirmeden çıkarsanız ilerlemeniz kaydedilecek. Daha sonra devam edebilirsiniz.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Hayır')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Evet')),
        ],
      ),
    ) ?? false;
  }

  String _getAppBarTitle() {
    switch (widget.testMode) {
      case TestMode.weekly:
        return 'Haftalık Test';
      case TestMode.wrongAnswers:
        return 'Yanlışlar Testi';
      case TestMode.normal:
      default:
        return 'Ünite Testi';
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_getAppBarTitle()),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Theme.of(context).primaryColor, Colors.blue.shade300],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: _isLoadingData
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return SafeArea(
      child: Column(
        children: [
          if (_error != null)
            Container(
              color: Colors.red.shade100,
              padding: const EdgeInsets.all(8),
              width: double.infinity,
              child: SelectableText(_error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            ),
          if (_currentTestQuestion == null)
            Expanded(child: _buildResultsView())
          else ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Soru ${_answeredCount + 1}/$_totalQuestions', style: const TextStyle(color: Colors.white, fontSize: 16)),
                      Text('Puan: $_score', style: const TextStyle(color: Colors.white, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_totalQuestions > 0)
                    LinearProgressIndicator(
                      value: (_answeredCount + 1) / _totalQuestions,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                      borderRadius: BorderRadius.circular(8),
                    ),
                ],
              ),
            ),
            Expanded(
              child: _QuestionCard(
                key: ValueKey(_currentTestQuestion!.question.id),
                testQuestion: _currentTestQuestion!,
                onAnswered: (answer) => setState(() => _currentTestQuestion!.userAnswer = answer),
              ),
            ),
            _buildBottomNavBar(),
          ],
        ],
      ),
    );
  }

  Widget _buildResultsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, size: 100, color: Colors.white),
          const SizedBox(height: 24),
          const Text('Test Tamamlandı!', style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text('Toplam Puan: $_score', style: const TextStyle(fontSize: 24, color: Colors.amber, fontWeight: FontWeight.bold)),
          const SizedBox(height: 48),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Üniteye Dön'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
          )
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    final testQuestion = _currentTestQuestion!;
    final bool isChecked = testQuestion.isChecked;
    final bool canCheck = testQuestion.userAnswer != null;

    final bool isLastQuestion = _questionQueue.isEmpty;

    final String buttonText = !isChecked
        ? 'Kontrol Et'
        : (isLastQuestion ? 'Testi Bitir' : 'Sonraki Soru');

    final VoidCallback? onPressedAction = !isChecked
        ? (canCheck ? _checkAnswer : null)
        : (isLastQuestion ? _finishTest : _loadNextQuestion);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: onPressedAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: isChecked ? Colors.green : Colors.amber,
                foregroundColor: isChecked ? Colors.white : Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 4,
              ),
              child: Text(
                buttonText,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final TestQuestion testQuestion;
  final ValueChanged<dynamic> onAnswered;

  const _QuestionCard({
    super.key,
    required this.testQuestion,
    required this.onAnswered,
  });

  @override
  Widget build(BuildContext context) {
    final question = testQuestion.question;
    final isChecked = testQuestion.isChecked;
    final isCorrect = testQuestion.isCorrect;
    final stats = question.userStats;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (question.type != QuestionType.fill_blank)
                  Text(
                    question.text,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                if (question.type != QuestionType.fill_blank) const Divider(height: 32),
                Expanded(child: _buildAnswerArea(context)),
                if (isChecked) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    decoration: BoxDecoration(
                      color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCorrect ? Colors.green.shade200 : Colors.red.shade200,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isCorrect ? Icons.check_circle : Icons.cancel,
                          color: isCorrect ? Colors.green : Colors.red,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isCorrect ? 'Doğru!' : 'Yanlış!',
                          style: TextStyle(
                            color: isCorrect ? Colors.green : Colors.red,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          if (stats != null && stats.totalAttempts > 0)
            Positioned(
              top: 12,
              right: 12,
              child: Tooltip(
                message: 'Bu soruyu daha önce ${stats.totalAttempts} kez çözdünüz.',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history, size: 14, color: Colors.grey.shade700),
                      const SizedBox(width: 4),
                      Text(
                        '${stats.correctAttempts}D/${stats.wrongAttempts}Y',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnswerArea(BuildContext context) {
    switch (testQuestion.question.type) {
      case QuestionType.multiple_choice:
      case QuestionType.true_false:
        return _buildMultipleChoice(context);
      case QuestionType.fill_blank:
        return _FillBlankWithOptionsBody(
          testQuestion: testQuestion,
          onAnswered: onAnswered,
        );
      case QuestionType.matching:
        return _MatchingQuestionBody(
          testQuestion: testQuestion,
          onAnswered: onAnswered,
        );
      default:
        return const Center(child: Text('Soru tipi desteklenmiyor.'));
    }
  }

  Widget _buildMultipleChoice(BuildContext context) {
    final question = testQuestion.question;
    final isChecked = testQuestion.isChecked;

    return ListView.separated(
      itemCount: question.choices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final choice = question.choices[index];
        bool isSelected = (testQuestion.userAnswer == choice.id);
        Color? borderColor;
        Widget? trailingIcon;

        if (isChecked) {
          if (choice.isCorrect) {
            borderColor = Colors.green.shade600;
            trailingIcon = Icon(Icons.check_circle, color: Colors.green.shade600);
          } else if (isSelected) {
            borderColor = Colors.red.shade600;
            trailingIcon = Icon(Icons.cancel, color: Colors.red.shade600);
          }
        } else if (isSelected) {
          borderColor = Theme.of(context).primaryColor;
        }

        return GestureDetector(
          onTap: isChecked ? null : () => onAnswered(choice.id),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: borderColor ?? Colors.grey.shade400,
                width: 2.5,
              ),
              borderRadius: BorderRadius.circular(16),
              color: isSelected
                  ? (borderColor ?? Theme.of(context).primaryColor).withOpacity(0.1)
                  : Colors.grey.shade50,
              boxShadow: isSelected ? [
                BoxShadow(
                  color: (borderColor ?? Theme.of(context).primaryColor).withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ] : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    choice.text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? Colors.black87 : Colors.black,
                    ),
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 12),
                  trailingIcon,
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FillBlankWithOptionsBody extends StatefulWidget {
  final TestQuestion testQuestion;
  final ValueChanged<dynamic> onAnswered;

  const _FillBlankWithOptionsBody({required this.testQuestion, required this.onAnswered});

  @override
  _FillBlankWithOptionsBodyState createState() => _FillBlankWithOptionsBodyState();
}

class _FillBlankWithOptionsBodyState extends State<_FillBlankWithOptionsBody> {
  late Map<int, QuestionBlankOption?> _droppedAnswers;
  late List<QuestionBlankOption> _availableOptions;

  @override
  void initState() {
    super.initState();
    final question = widget.testQuestion.question;
    final int blankCount = '______'.allMatches(question.text).length;
    _droppedAnswers = {for (var i = 0; i < blankCount; i++) i: null};
    _availableOptions = List.from(question.blankOptions);
  }

  void _onDrop(int blankIndex, QuestionBlankOption option) {
    if (widget.testQuestion.isChecked) return;
    setState(() {
      final previousEntry = _droppedAnswers.entries.firstWhereOrNull((entry) => entry.value?.id == option.id);
      if (previousEntry != null) _droppedAnswers[previousEntry.key] = null;
      final existingOption = _droppedAnswers[blankIndex];
      if (existingOption != null) _availableOptions.add(existingOption);
      _droppedAnswers[blankIndex] = option;
      _availableOptions.removeWhere((opt) => opt.id == option.id);
      widget.onAnswered(Map<int, QuestionBlankOption?>.from(_droppedAnswers));
    });
  }

  void _removeFromBlank(int blankIndex) {
    if (widget.testQuestion.isChecked) return;
    setState(() {
      final removedOption = _droppedAnswers[blankIndex];
      if (removedOption != null) {
        _availableOptions.add(removedOption);
        _droppedAnswers[blankIndex] = null;
        widget.onAnswered(Map<int, QuestionBlankOption?>.from(_droppedAnswers));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.testQuestion.question;
    final isChecked = widget.testQuestion.isChecked;
    final isCorrect = widget.testQuestion.isCorrect;

    final questionParts = question.text.split('______');
    List<Widget> questionWidgets = [];

    for (int i = 0; i < questionParts.length; i++) {
      questionWidgets.add(Text(
        questionParts[i],
        style: const TextStyle(fontSize: 18),
      ));

      if (i < questionParts.length - 1) {
        final blankIndex = i;
        final droppedOption = _droppedAnswers[blankIndex];
        Color borderColor = Colors.grey.shade400;
        Color bgColor = Colors.white;

        if (isChecked) {
          borderColor = isCorrect ? Colors.green.shade600 : Colors.red.shade600;
          bgColor = isCorrect ? Colors.green.shade50 : Colors.red.shade50;
        } else if (droppedOption != null) {
          borderColor = Theme.of(context).primaryColor;
          bgColor = Theme.of(context).primaryColor.withOpacity(0.1);
        }

        questionWidgets.add(
          DragTarget<QuestionBlankOption>(
            builder: (context, candidateData, rejectedData) {
              return GestureDetector(
                onTap: droppedOption != null ? () => _removeFromBlank(blankIndex) : null,
                child: Container(
                  width: 150,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  margin: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: Border.all(
                      color: borderColor,
                      width: 2.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      droppedOption?.optionText ?? '...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: droppedOption != null
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              );
            },
            onAcceptWithDetails: (option) => _onDrop(blankIndex, option),
          ),
        );
      }
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Soru metni
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Wrap(
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: questionWidgets,
              ),
            ),

            const SizedBox(height: 24),

            // Talimatlar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Seçenekleri boşluklara sürükleyin. Yerleştirilen seçeneğe tıklayarak kaldırabilirsiniz.',
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Kullanılabilir seçenekler
            if (!isChecked && _availableOptions.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kullanılabilir Seçenekler:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10.0,
                    runSpacing: 10.0,
                    children: _availableOptions.map((option) {
                      return Draggable<QuestionBlankOption>(
                        data: option,
                        feedback: Material(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.amber.shade400),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              option.optionText,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        childWhenDragging: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            option.optionText,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.amber.shade400),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 3,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            option.optionText,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

            if (!isChecked && _availableOptions.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Center(
                  child: Text(
                    'Tüm seçenekler kullanıldı!',
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
class _MatchingQuestionBody extends StatefulWidget {
  final TestQuestion testQuestion;
  final ValueChanged<dynamic> onAnswered;

  const _MatchingQuestionBody({required this.testQuestion, required this.onAnswered});

  @override
  _MatchingQuestionBodyState createState() => _MatchingQuestionBodyState();
}

class _MatchingQuestionBodyState extends State<_MatchingQuestionBody> {
  late List<String> leftTexts;
  late List<MatchingPair> shuffledRightPairs;
  late Map<String, MatchingPair?> userMatches;

  @override
  void initState() {
    super.initState();
    final question = widget.testQuestion.question;
    leftTexts = question.matchingPairs?.map((p) => p.left_text).toList() ?? [];
    shuffledRightPairs = List.from(question.matchingPairs ?? [])..shuffle();
    userMatches = {};
  }

  void _removeMatch(String leftText) {
    if (widget.testQuestion.isChecked) return;
    setState(() {
      final removedPair = userMatches[leftText];
      if (removedPair != null) {
        userMatches.remove(leftText);
        widget.onAnswered(Map<String, MatchingPair?>.from(userMatches));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isChecked = widget.testQuestion.isChecked;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Talimatlar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sağdaki seçenekleri soldaki ifadelere sürükleyerek eşleştirin. Yerleştirilen seçeneğe tıklayarak kaldırabilirsiniz.',
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Sol taraf (eşleştirilecek ifadeler)
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Eşleştirilecek İfadeler:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(leftTexts.length, (index) {
                    final leftText = leftTexts[index];
                    final matchedPair = userMatches[leftText];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: DragTarget<MatchingPair>(
                        builder: (context, candidateData, rejectedData) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Sol ifade (sabit metin)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Text(
                                  '${index + 1}. $leftText',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                              ),

                              // Seçenek kutucuğu
                              GestureDetector(
                                onTap: matchedPair != null ? () => _removeMatch(leftText) : null,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: matchedPair != null
                                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                                        : Colors.grey.shade50,
                                    border: Border.all(
                                      color: matchedPair != null
                                          ? Theme.of(context).primaryColor
                                          : Colors.grey.shade300,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: matchedPair != null ? [
                                      BoxShadow(
                                        color: Theme.of(context).primaryColor.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ] : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      matchedPair?.right_text ?? 'Boş - Seçenek sürükleyin',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: matchedPair != null
                                            ? Theme.of(context).primaryColor
                                            : Colors.grey.shade600,
                                        fontSize: 15,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                        onAcceptWithDetails: (data) {
                          if (isChecked) return;
                          setState(() {
                            // Aynı seçenek başka bir yerde varsa kaldır
                            final existingEntry = userMatches.entries
                                .firstWhereOrNull((entry) => entry.value?.right_text == data.right_text);
                            if (existingEntry != null) {
                              userMatches.remove(existingEntry.key);
                            }

                            userMatches[leftText] = data;
                            widget.onAnswered(Map<String, MatchingPair?>.from(userMatches));
                          });
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          if (!isChecked) ...[
            const SizedBox(height: 24),

            // Sağ taraf (seçenekler)
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: shuffledRightPairs
                          .where((p) => !userMatches.values.contains(p))
                          .map((pair) {
                        return Draggable<MatchingPair>(
                          data: pair,
                          feedback: Material(
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.7,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.amber.shade400, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Text(
                                pair.right_text,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          childWhenDragging: Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.7,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              pair.right_text,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.7,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.shade400),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 3,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              pair.right_text,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.amber.shade900,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],

          if (userMatches.length == leftTexts.length && !isChecked)
            Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Tüm eşleştirmeler tamamlandı!',
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
