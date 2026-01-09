import 'dart:developer';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:egitim_uygulamasi/models/question_model.dart';
import 'package:egitim_uygulamasi/models/question_blank_option.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

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

  const QuestionsScreen({
    super.key,
    required this.unitId,
  });

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  TestQuestion? _currentTestQuestion;
  int? _sessionId;
  
  bool _isLoadingData = true;
  bool _isSavingAnswer = false;
  String? _error;
  int _score = 0;
  int _answeredCount = 0;
  final int _totalQuestions = 10;

  final Stopwatch _questionTimer = Stopwatch();

  @override
  void initState() {
    super.initState();
    _startOrResumeTest();
  }

  Future<String> _getOrCreateClientId() async {
    final prefs = await SharedPreferences.getInstance();
    String? clientId = prefs.getString('client_id');
    if (clientId == null) {
      clientId = const Uuid().v4();
      await prefs.setString('client_id', clientId);
      debugPrint('--- YENİ CLIENT_ID ÜRETİLDİ: $clientId ---');
    } else {
      debugPrint('--- MEVCUT CLIENT_ID KULLANILIYOR: $clientId ---');
    }
    return clientId;
  }

  Future<void> _startOrResumeTest() async {
    debugPrint('--- TEST BAŞLATMA SÜRECİ BAŞLADI (unitId: ${widget.unitId}) ---');
    setState(() { _isLoadingData = true; _error = null; });
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      final clientId = await _getOrCreateClientId();

      debugPrint('--- RPC start_test_v2 ÇAĞRILIYOR ---');
      debugPrint('Parametreler: {p_client_id: $clientId, p_unit_id: ${widget.unitId}, p_user_id: $userId}');

      final response = await client.rpc(
        'start_test_v2',
        params: {
          'p_client_id': clientId,
          'p_unit_id': widget.unitId,
          'p_user_id': userId,
        },
      );

      debugPrint('--- RPC start_test_v2 YANITI: $response ---');
      _sessionId = response as int;
      await _loadNextQuestion();

    } catch (e, st) {
      debugPrint('--- TEST BAŞLATILIRKEN KRİTİK HATA ---');
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

  Future<void> _loadNextQuestion() async {
    if (_sessionId == null) {
      debugPrint('--- HATA: _sessionId NULL, SORU YÜKLENEMEZ ---');
      return;
    }

    debugPrint('--- SONRAKİ SORU YÜKLENİYOR (sessionId: $_sessionId) ---');
    try {
      final client = Supabase.instance.client;
      
      debugPrint('--- RPC get_active_question_v2 ÇAĞRILIYOR ---');
      final response = await client.rpc(
        'get_active_question_v2',
        params: {'p_session_id': _sessionId!},
      );

      debugPrint('--- RPC get_active_question_v2 YANITI: $response ---');

      if (response == null) {
        debugPrint('--- SORU KALMADI, TEST BİTİRİLİYOR ---');
        await _finishTest();
        return;
      }

      final question = Question.fromMap(response as Map<String, dynamic>);
      
      debugPrint('--- CEVAPLANMIŞ SORU SAYISI KONTROL EDİLİYOR ---');
      final answersResponse = await client
          .from('test_session_answers')
          .select('id')
          .eq('test_session_id', _sessionId!);
      
      debugPrint('--- CEVAPLANMIŞ SORU SAYISI: ${(answersResponse as List).length} ---');

      if (mounted) {
        setState(() {
          _currentTestQuestion = TestQuestion(question: question);
          _answeredCount = (answersResponse).length;
          _isLoadingData = false;
          _error = null;
        });
        _questionTimer.reset();
        _questionTimer.start();
        debugPrint('--- SORU BAŞARIYLA EKRANA YANSITILDI (Question ID: ${question.id}) ---');
      }
    } catch (e, st) {
      debugPrint('--- SORU YÜKLENİRKEN HATA ---');
      debugPrint('Hata: $e');
      debugPrint('Stack Trace: $st');
      if (mounted) setState(() => _error = "Soru yüklenemedi: $e");
    }
  }

  Future<void> _checkAnswer() async {
    final testQuestion = _currentTestQuestion;
    if (testQuestion == null || testQuestion.isChecked || testQuestion.userAnswer == null) {
      debugPrint('--- KONTROL İPTAL: Soru null, zaten işaretli veya cevap seçilmemiş ---');
      return;
    }

    debugPrint('--- CEVAP KONTROL EDİLİYOR ---');
    setState(() {
      _isSavingAnswer = true;
      _error = null;
    });

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

    debugPrint('--- CEVAP SONUCU: ${isCorrect ? "DOĞRU" : "YANLIŞ"} (Süre: $duration sn) ---');

    try {
      await _saveAnswer(isCorrect, duration);
      debugPrint('--- CEVAP BAŞARIYLA KAYDEDİLDİ ---');
      if (mounted) {
        setState(() {
          testQuestion.isChecked = true;
          testQuestion.isCorrect = isCorrect;
          if (isCorrect) _score += question.score;
          _isSavingAnswer = false;
        });
      }
    } catch (e, st) {
      debugPrint('--- CEVAP KAYDEDİLİRKEN HATA OLUŞTU ---');
      debugPrint('Hata: $e');
      debugPrint('Stack Trace: $st');
      if (mounted) {
        setState(() {
          _error = "Cevap kaydedilemedi: $e";
          _isSavingAnswer = false;
        });
      }
    }
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

    debugPrint('--- test_session_answers TABLOSUNA KAYIT ATILIYOR ---');
    debugPrint('Veri: $dataToInsert');

    final insertResponse = await client.from('test_session_answers').insert(dataToInsert).select();
    debugPrint('--- INSERT YANITI: $insertResponse ---');
  }

  Future<void> _finishTest() async {
    if (_sessionId == null) return;
    debugPrint('--- RPC finish_test_v2 ÇAĞRILIYOR (sessionId: $_sessionId) ---');
    try {
      await Supabase.instance.client.rpc('finish_test_v2', params: {'p_session_id': _sessionId!});
      debugPrint('--- TEST BAŞARIYLA BİTİRİLDİ ---');
      if (mounted) {
        setState(() {
          _isLoadingData = false;
          _currentTestQuestion = null;
        });
      }
    } catch (e, st) {
      debugPrint('--- TEST BİTİRİLİRKEN HATA ---');
      debugPrint('Hata: $e');
      debugPrint('Stack Trace: $st');
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ünite Testi'),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: (_isSavingAnswer) ? null : (!isChecked
                  ? (canCheck ? _checkAnswer : null)
                  : () {
                      setState(() => _isLoadingData = true);
                      _loadNextQuestion();
                    }),
              style: ElevatedButton.styleFrom(
                backgroundColor: isChecked ? Colors.green : Colors.amber,
                foregroundColor: isChecked ? Colors.white : Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: _isSavingAnswer 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : Text(
                    !isChecked ? 'Kontrol Et' : 'Sonraki Soru',
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (question.type != QuestionType.fill_blank)
              Text(question.text, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            if (question.type != QuestionType.fill_blank) const Divider(height: 32),
            Expanded(child: _buildAnswerArea(context)),
            if (isChecked) ...[
              const SizedBox(height: 16),
              Text(
                isCorrect ? 'Doğru!' : 'Yanlış!',
                textAlign: TextAlign.center,
                style: TextStyle(color: isCorrect ? Colors.green : Colors.red, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
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
        Icon? trailingIcon;

        if (isChecked) {
          if (choice.isCorrect) {
            borderColor = Colors.green;
            trailingIcon = const Icon(Icons.check_circle, color: Colors.green);
          } else if (isSelected) {
            borderColor = Colors.red;
            trailingIcon = const Icon(Icons.cancel, color: Colors.red);
          }
        } else if (isSelected) {
          borderColor = Theme.of(context).primaryColor;
        }

        return GestureDetector(
          onTap: isChecked ? null : () => onAnswered(choice.id),
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

  @override
  Widget build(BuildContext context) {
    final question = widget.testQuestion.question;
    final isChecked = widget.testQuestion.isChecked;
    final isCorrect = widget.testQuestion.isCorrect;

    final questionParts = question.text.split('______');
    List<Widget> questionWidgets = [];

    for (int i = 0; i < questionParts.length; i++) {
      questionWidgets.add(Text(questionParts[i], style: const TextStyle(fontSize: 18)));
      if (i < questionParts.length - 1) {
        final blankIndex = i;
        final droppedOption = _droppedAnswers[blankIndex];
        Color borderColor = Colors.grey.shade400;
        if (isChecked) borderColor = isCorrect ? Colors.green : Colors.red;

        questionWidgets.add(
          DragTarget<QuestionBlankOption>(
            builder: (context, candidateData, rejectedData) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: borderColor, width: 2)),
                ),
                child: Text(
                  droppedOption?.optionText ?? '...',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
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
        Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: questionWidgets),
        const Spacer(),
        if (!isChecked)
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: _availableOptions.map((option) {
              return Draggable<QuestionBlankOption>(
                data: option,
                feedback: Material(child: Chip(label: Text(option.optionText))),
                child: Chip(label: Text(option.optionText), backgroundColor: Colors.amber.shade100),
              );
            }).toList(),
          ),
      ],
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

  @override
  Widget build(BuildContext context) {
    final isChecked = widget.testQuestion.isChecked;

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            itemCount: leftTexts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final leftText = leftTexts[index];
              final matchedPair = userMatches[leftText];

              return DragTarget<MatchingPair>(
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text(leftText)),
                        const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(child: Text(matchedPair?.right_text ?? '...', style: const TextStyle(fontWeight: FontWeight.bold))),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                onAccept: (data) {
                  if (isChecked) return;
                  setState(() {
                    userMatches[leftText] = data;
                    widget.onAnswered(Map<String, MatchingPair?>.from(userMatches));
                  });
                },
              );
            },
          ),
        ),
        if (!isChecked) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: shuffledRightPairs.where((p) => !userMatches.values.contains(p)).map((pair) {
              return Draggable<MatchingPair>(
                data: pair,
                feedback: Material(child: Chip(label: Text(pair.right_text))),
                child: Chip(label: Text(pair.right_text), backgroundColor: Colors.amber.shade100),
              );
            }).toList(),
          ),
        ]
      ],
    );
  }
}
