import 'package:collection/collection.dart';
import 'package:egitim_uygulamasi/models/question_model.dart';
import 'package:egitim_uygulamasi/models/question_blank_option.dart';
import 'package:egitim_uygulamasi/viewmodels/profile_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

class SessionAnswer {
  final int questionId;
  final int? selectedOptionId;
  final String? userAnswerText;
  final bool isCorrect;

  SessionAnswer({
    required this.questionId,
    this.selectedOptionId,
    this.userAnswerText,
    required this.isCorrect,
  });

  factory SessionAnswer.fromJson(Map<String, dynamic> json) {
    return SessionAnswer(
      questionId: json['question_id'] as int,
      selectedOptionId: json['selected_option_id'] as int?,
      userAnswerText: json['user_answer_text'] as String?,
      isCorrect: json['is_correct'] as bool,
    );
  }
}

class QuestionsScreen extends StatefulWidget {
  final int? topicId;
  final int? unitId;
  final int testNumber;
  final int questionsPerTest;
  final int? weekNo;
  final int? previousSessionId;

  const QuestionsScreen({
    super.key,
    this.topicId,
    this.unitId,
    required this.testNumber,
    required this.questionsPerTest,
    this.weekNo,
    this.previousSessionId,
  }) : assert(
            (topicId != null && weekNo != null) || unitId != null,
            'Either (topicId and weekNo) or unitId must be provided.');

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  final ProfileViewModel _profileViewModel = ProfileViewModel();
  
  List<TestQuestion> _testQuestions = [];
  
  bool _isAdmin = false;
  bool _isLoadingData = true;
  String? _error;

  final PageController _pageController = PageController();
  int _score = 0;
  bool _showResults = false;
  int _currentPage = 0;

  int? _sessionId;
  final Stopwatch _questionTimer = Stopwatch();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoadingData = true; _error = null; });
    try {
      await _checkAdminStatus();
      List<TestQuestion> loadedTestQuestions;
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser!.id;

      if (widget.previousSessionId != null) {
        final response = await client.rpc(
          'get_session_review_data',
          params: {'p_session_id': widget.previousSessionId!},
        ) as List<dynamic>?;

        if (response == null || response.isEmpty) throw Exception("Bu geçmiş teste ait veri bulunamadı.");
        
        int currentScore = 0;
        loadedTestQuestions = response.map((json) {
          final question = Question.fromMap(json);
          final isCorrect = json['is_correct'] as bool? ?? false;
          if (isCorrect) currentScore += question.score;
          return TestQuestion(
            question: question,
            userAnswer: json['user_selected_option_id'] ?? json['user_answer_text'],
            isChecked: true,
            isCorrect: isCorrect,
          );
        }).toList();
        
        _sessionId = widget.previousSessionId;
        _score = currentScore;
      } else {
        // *** BİRLEŞTİRİLMİŞ VE GÜVENİLİR MANTIK ***
        List<int> questionIds = [];

        if (widget.topicId != null && widget.weekNo != null) {
          // Haftalık test için soru ID'lerini al
          final response = await client
              .from('question_usages')
              .select('question_id')
              .eq('topic_id', widget.topicId!)
              .eq('display_week', widget.weekNo!);
          questionIds = response.map((e) => e['question_id'] as int).toList();

        } else if (widget.unitId != null) {
          // Ünite testi için soru ID'lerini al
          final topicsResponse = await client.from('topics').select('id').eq('unit_id', widget.unitId!);
          final topicIds = topicsResponse.map((e) => e['id'] as int).toList();

          if (topicIds.isNotEmpty) {
            final response = await client
                .from('question_usages')
                .select('question_id')
                .inFilter('topic_id', topicIds);
            questionIds = response.map((e) => e['question_id'] as int).toList();
          }
        }

        if (questionIds.isEmpty) {
            loadedTestQuestions = [];
        } else {
            questionIds.shuffle();
            final selectedQuestionIds = questionIds.take(widget.questionsPerTest).toList();

            if (selectedQuestionIds.isEmpty) {
                loadedTestQuestions = [];
            } else {
                final sessionResponse = await client.from('test_sessions').insert({
                    'user_id': userId,
                    'unit_id': widget.unitId, // Haftalık testte bu null olabilir, ünite testinde dolu
                    'settings': {
                        'topic_id': widget.topicId,
                        'unit_id': widget.unitId,
                        'week_no': widget.weekNo,
                        'test_number': widget.testNumber,
                        'type': widget.unitId != null ? 'unit_test' : 'weekly_test'
                    }
                }).select('id').single();
                
                _sessionId = sessionResponse['id'] as int?;

                final questionsResponse = await client
                    .from('questions')
                    .select('*, question_choices(*), question_blank_options(*), question_matching_pairs(*), question_classical(*)')
                    .inFilter('id', selectedQuestionIds);

                loadedTestQuestions = questionsResponse.map((json) => TestQuestion(question: Question.fromMap(json))).toList();
            }
        }
      }

      if (mounted) {
        setState(() {
          _testQuestions = loadedTestQuestions;
          _isLoadingData = false;
        });
      }

      if (widget.previousSessionId == null && _testQuestions.isNotEmpty) {
        _questionTimer.start();
      }

    } catch (e, st) {
      debugPrint('--- SORU YÜKLENİRKEN HATA ---\nHata: $e\nStack Trace:\n$st');
      if (mounted) setState(() {
        _error = 'Sorular yüklenirken bir hata oluştu. Lütfen tekrar deneyin.';
        _isLoadingData = false;
      });
    }
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await _profileViewModel.isAdmin();
    if (mounted) setState(() => _isAdmin = isAdmin);
  }

  void _checkAnswer(TestQuestion testQuestion) {
    if (testQuestion.isChecked) return;
    final userAnswer = testQuestion.userAnswer;
    if (userAnswer == null) return;

    _questionTimer.stop();
    final int duration = _questionTimer.elapsed.inSeconds;

    bool isCorrect = false;
    final question = testQuestion.question;

    if (question.type == QuestionType.multiple_choice || question.type == QuestionType.true_false) {
      final correctChoice = question.choices.firstWhere((c) => c.isCorrect).id;
      isCorrect = (userAnswer == correctChoice);
    } else if (question.type == QuestionType.fill_blank) {
      if (userAnswer is Map<int, QuestionBlankOption?>) {
        final correctOptionIds = question.blankOptions.where((opt) => opt.isCorrect).map((opt) => opt.id).toSet();
        final userAnswerIds = userAnswer.values.whereNotNull().map((opt) => opt.id).toSet();
        isCorrect = const SetEquality().equals(userAnswerIds, correctOptionIds);
      }
    } else if (question.type == QuestionType.matching) {
      final userMatches = userAnswer as Map<String, MatchingPair?>?;
      if (userMatches != null && question.matchingPairs != null && userMatches.length == question.matchingPairs!.length && userMatches.values.every((v) => v != null)) {
        final correctMatches = { for (var p in question.matchingPairs!) p.left_text: p.right_text };
        isCorrect = userMatches.entries.every((entry) {
          final leftText = entry.key;
          final selectedRightText = entry.value?.right_text;
          return correctMatches[leftText] == selectedRightText;
        });
      } else {
        isCorrect = false;
      }
    }

    _saveUserAnswer(question, userAnswer, isCorrect, duration);

    setState(() {
      testQuestion.isChecked = true;
      testQuestion.isCorrect = isCorrect;
      if (isCorrect) _score += question.score;
    });
  }

  Future<void> _saveUserAnswer(Question question, dynamic userAnswer, bool isCorrect, int duration) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (_sessionId == null || userId == null) return;

    String? getUserAnswerAsText() {
      if (userAnswer is String) return userAnswer;
      if (userAnswer is int) return userAnswer.toString();
      if (userAnswer is bool) return userAnswer.toString();
      return null;
    }

    try {
      await Supabase.instance.client.from('user_answers').insert({
        'session_id': _sessionId,
        'question_id': question.id,
        'user_id': userId,
        'selected_option_id': (question.type == QuestionType.multiple_choice || question.type == QuestionType.true_false) ? userAnswer : null,
        'answer_text': getUserAnswerAsText(),
        'is_correct': isCorrect,
        'duration_seconds': duration,
      });
    } catch (e) {
      debugPrint('--- CEVAP KAYDEDİLEMEDİ ---');
      debugPrint('Hata: $e');
    }
  }

  void _submitQuiz() {
    _completeTestSession();
    setState(() => _showResults = true);
  }

  Future<void> _completeTestSession() async {
    if (_sessionId == null) return;
    try {
      await Supabase.instance.client
          .from('test_sessions')
          .update({'completed_at': DateTime.now().toIso8601String()})
          .eq('id', _sessionId!);
    } catch (e) {
      debugPrint('Test oturumu tamamlanamadı: $e');
    }
  }

  String _getAppBarTitle() {
    if (widget.weekNo != null) {
      return 'Haftalık Test ${widget.testNumber}';
    }
    return 'Ünite Testi ${widget.testNumber}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }

  Widget _buildBody() {
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: Colors.white)));
    if (_testQuestions.isEmpty) return const Center(child: Text('Bu test için soru bulunamadı.', style: TextStyle(color: Colors.white)));
    if (_showResults) return _buildResultsView();

    double progress = (_currentPage + 1) / _testQuestions.length;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Soru ${_currentPage + 1}/${_testQuestions.length}', style: const TextStyle(color: Colors.white, fontSize: 16)),
                    Text('Puan: $_score', style: const TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView.builder(
              key: ValueKey(_testQuestions.hashCode),
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _testQuestions.length,
              onPageChanged: (page) {
                setState(() => _currentPage = page);
                if (widget.previousSessionId == null) {
                  _questionTimer.reset();
                  _questionTimer.start();
                }
              },
              itemBuilder: (context, index) {
                final testQuestion = _testQuestions[index];
                return _QuestionCard(
                  key: ValueKey(testQuestion.question.id),
                  testQuestion: testQuestion,
                  onAnswered: (answer) => setState(() => testQuestion.userAnswer = answer),
                  onCheck: () => _checkAnswer(testQuestion),
                  isAdmin: _isAdmin,
                  isReviewMode: widget.previousSessionId != null,
                );
              },
            ),
          ),
          _buildBottomNavBar(),
        ],
      ),
    );
  }

  Widget _buildResultsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Değerlendirme Tamamlandı!', style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Text('Puanınız: $_score', style: const TextStyle(fontSize: 48, color: Colors.amber, fontWeight: FontWeight.bold)),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Geri Dön'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12)),
          )
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    if (_testQuestions.isEmpty) return const SizedBox.shrink();
    final bool isLastQuestion = _currentPage == _testQuestions.length - 1;
    final bool isReviewMode = widget.previousSessionId != null;

    if (isReviewMode) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_currentPage > 0)
              TextButton.icon(
                onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                label: const Text('Önceki', style: TextStyle(color: Colors.white)),
              ),
            const Spacer(),
            if (!isLastQuestion)
              ElevatedButton.icon(
                onPressed: () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn),
                label: const Text('Sonraki'),
                icon: const Icon(Icons.arrow_forward),
              )
            else
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                label: const Text('Bitir'),
                icon: const Icon(Icons.check),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
          ],
        ),
      );
    }

    final testQuestion = _testQuestions[_currentPage];
    final bool canCheck = testQuestion.userAnswer != null;
    final bool isChecked = testQuestion.isChecked;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0) TextButton.icon(
            onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            label: const Text('Önceki', style: TextStyle(color: Colors.white)),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: !isChecked
                ? (canCheck ? () => _checkAnswer(testQuestion) : null)
                : (isLastQuestion ? _submitQuiz : () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn)),
            style: ElevatedButton.styleFrom(
              backgroundColor: isChecked ? (isLastQuestion ? Colors.green : Theme.of(context).primaryColor) : Colors.amber,
              foregroundColor: isChecked ? Colors.white : Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: Text(
              !isChecked ? 'Kontrol Et' : (isLastQuestion ? 'Bitir' : 'Sonraki'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
  final VoidCallback onCheck;
  final bool isAdmin;
  final bool isReviewMode;

  const _QuestionCard({
    super.key,
    required this.testQuestion,
    required this.onAnswered,
    required this.onCheck,
    required this.isAdmin,
    required this.isReviewMode,
  });

  @override
  Widget build(BuildContext context) {
    final question = testQuestion.question;
    final isChecked = testQuestion.isChecked;
    final isCorrect = testQuestion.isCorrect;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (question.type != QuestionType.fill_blank)
                  Padding(
                    padding: const EdgeInsets.only(right: 30.0),
                    child: Text(question.text, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                if (question.type != QuestionType.fill_blank) const Divider(height: 32),
                Expanded(child: _buildAnswerArea(context)),
                if (isChecked) _buildFeedback(context, isCorrect),
              ],
            ),
          ),
          if (isAdmin)
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                onPressed: () {}, // Silme fonksiyonu buraya gelecek
                tooltip: 'Soruyu Sil',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeedback(BuildContext context, bool isCorrect) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        isCorrect ? 'Doğru!' : 'Yanlış!',
        textAlign: TextAlign.center,
        style: TextStyle(color: isCorrect ? Colors.green : Colors.red, fontSize: 20, fontWeight: FontWeight.bold),
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
          isReviewMode: isReviewMode,
        );
      case QuestionType.matching:
        return _MatchingQuestionBody(
          testQuestion: testQuestion,
          onAnswered: onAnswered,
          isReviewMode: isReviewMode,
        );
      default:
        return const Center(child: Text('Bu soru tipi henüz desteklenmiyor.'));
    }
  }

  Widget _buildMultipleChoice(BuildContext context) {
    final question = testQuestion.question;
    final userAnswer = testQuestion.userAnswer;
    final isChecked = testQuestion.isChecked;

    return ListView.separated(
      itemCount: question.choices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final choice = question.choices[index];
        bool isSelected = (userAnswer == choice.id);
        Color? borderColor;
        Icon? trailingIcon;

        if (isChecked) {
          if (choice.isCorrect) {
            borderColor = Colors.green;
            trailingIcon = const Icon(Icons.check_circle, color: Colors.green);
          } else if (isSelected && !choice.isCorrect) {
            borderColor = Colors.red;
            trailingIcon = const Icon(Icons.cancel, color: Colors.red);
          }
        } else if (isSelected) {
          borderColor = Theme.of(context).primaryColor;
        }

        return GestureDetector(
          onTap: isReviewMode ? null : () => onAnswered(choice.id),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: borderColor ?? Colors.grey.shade300, width: 2),
              borderRadius: BorderRadius.circular(16),
              color: isSelected ? (borderColor ?? Theme.of(context).primaryColor).withOpacity(0.1) : Colors.transparent,
            ),
            child: Row(
              children: [
                Expanded(child: Text(choice.text, style: const TextStyle(fontSize: 16))),
                if (trailingIcon != null) ...[const SizedBox(width: 12), trailingIcon],
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
  final bool isReviewMode;

  const _FillBlankWithOptionsBody({
    required this.testQuestion,
    required this.onAnswered,
    required this.isReviewMode,
  });

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
    final userAnswer = widget.testQuestion.userAnswer;

    final int blankCount = '______'.allMatches(question.text).length;
    _droppedAnswers = {for (var i = 0; i < blankCount; i++) i: null};
    _availableOptions = List.from(question.blankOptions);

    if (userAnswer is Map<int, QuestionBlankOption?>) {
       _droppedAnswers.addAll(userAnswer);
       for (var answer in _droppedAnswers.values) {
         if (answer != null) {
           _availableOptions.removeWhere((opt) => opt.id == answer.id);
         }
       }
    }
  }

  void _onDrop(int blankIndex, QuestionBlankOption option) {
    if (widget.testQuestion.isChecked || widget.isReviewMode) return;

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

  @override
  Widget build(BuildContext context) {
    final question = widget.testQuestion.question;
    final isChecked = widget.testQuestion.isChecked;
    final isCorrect = widget.testQuestion.isCorrect;

    final questionParts = question.text.split('______');
    List<Widget> questionWidgets = [];

    for (int i = 0; i < questionParts.length; i++) {
      questionWidgets.add(Text(questionParts[i], style: Theme.of(context).textTheme.headlineSmall));
      if (i < questionParts.length - 1) {
        final blankIndex = i;
        final droppedOption = _droppedAnswers[blankIndex];
        Color borderColor = Colors.grey.shade400;
        Color backgroundColor = Colors.grey.shade100;
        if (isChecked) {
          borderColor = isCorrect ? Colors.green : Colors.red;
          backgroundColor = isCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1);
        }
        questionWidgets.add(
          DragTarget<QuestionBlankOption>(
            builder: (context, candidateData, rejectedData) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: backgroundColor,
                ),
                child: Text(
                  droppedOption?.optionText ?? '...',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: droppedOption != null ? Theme.of(context).primaryColorDark : Colors.grey),
                ),
              );
            },
            onAccept: (option) => _onDrop(blankIndex, option),
          ),
        );
      }
    }

    return Column(
      children: [
        Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, runSpacing: 8, children: questionWidgets),
        const Spacer(),
        if (!widget.isReviewMode) ...[
          const Text('Seçenekleri boşluklara sürükleyin:', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            alignment: WrapAlignment.center,
            children: _availableOptions.map((option) {
              return Draggable<QuestionBlankOption>(
                data: option,
                feedback: Material(elevation: 4.0, child: Chip(label: Text(option.optionText), backgroundColor: Colors.amber.shade200)),
                childWhenDragging: Chip(label: Text(option.optionText), backgroundColor: Colors.grey.shade300),
                child: Chip(label: Text(option.optionText), backgroundColor: Colors.amber.shade100),
              );
            }).toList(),
          ),
        ]
      ],
    );
  }
}

class _MatchingQuestionBody extends StatefulWidget {
  final TestQuestion testQuestion;
  final ValueChanged<dynamic> onAnswered;
  final bool isReviewMode;

  const _MatchingQuestionBody({required this.testQuestion, required this.onAnswered, required this.isReviewMode});

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
    final userAnswer = widget.testQuestion.userAnswer;

    leftTexts = question.matchingPairs?.map((p) => p.left_text).toList() ?? [];
    shuffledRightPairs = List.from(question.matchingPairs ?? [])..shuffle();
    userMatches = Map.from((userAnswer as Map?)?.cast<String, MatchingPair?>() ?? {});
  }

  void _handleDrop(String leftText, MatchingPair droppedPair) {
    if (widget.testQuestion.isChecked || widget.isReviewMode) return;
    setState(() {
      final previousKey = userMatches.entries.firstWhereOrNull((entry) => entry.value?.id == droppedPair.id)?.key;
      if (previousKey != null) {
        userMatches[previousKey] = null;
      }
      userMatches[leftText] = droppedPair;
      widget.onAnswered(userMatches);
    });
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.testQuestion.question;
    final isChecked = widget.testQuestion.isChecked;

    final availableRightPairs = shuffledRightPairs.where((pair) => !userMatches.values.any((matchedPair) => matchedPair?.id == pair.id)).toList();
    final draggableOptions = availableRightPairs.map((pair) {
      return Draggable<MatchingPair>(
        data: pair,
        feedback: Material(elevation: 4.0, child: Chip(label: Text(pair.right_text), backgroundColor: Colors.amber.shade200)),
        childWhenDragging: Chip(label: Text(pair.right_text), backgroundColor: Colors.grey.shade300),
        child: Chip(label: Text(pair.right_text), backgroundColor: Colors.amber.shade100),
      );
    }).toList();

    final dropTargets = ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: leftTexts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final leftText = leftTexts[index];
        final matchedPair = userMatches[leftText];
        bool? isCorrect;
        if (isChecked) {
          final correctMatch = question.matchingPairs!.firstWhere((p) => p.left_text == leftText).right_text;
          isCorrect = matchedPair?.right_text == correctMatch;
        }

        return DragTarget<MatchingPair>(
          builder: (context, candidateData, rejectedData) {
            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12.0),
                color: isChecked ? (isCorrect == true ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1)) : Colors.transparent,
              ),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Padding(padding: const EdgeInsets.all(12.0), child: Text(leftText))),
                  Expanded(
                    flex: 3,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        border: Border(left: BorderSide(color: Colors.grey.shade300)),
                        color: Colors.grey.shade100,
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(11.0)),
                      ),
                      child: Center(child: Text(matchedPair?.right_text ?? '...', style: const TextStyle(fontWeight: FontWeight.bold))),
                    ),
                  ),
                ],
              ),
            );
          },
          onAccept: (data) => _handleDrop(leftText, data),
        );
      },
    );

    return Column(
      children: [
        Expanded(child: dropTargets),
        if (!widget.isReviewMode) ...[
          const SizedBox(height: 16),
          const Text('Seçenekleri kutulara sürükleyin:', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          Wrap(spacing: 8.0, runSpacing: 4.0, alignment: WrapAlignment.center, children: draggableOptions),
        ]
      ],
    );
  }
}
