// lib/screens/questions_screen.dart

import 'package:egitim_uygulamasi/models/question_model.dart';
import 'package:egitim_uygulamasi/services/question_service.dart';
import 'package:egitim_uygulamasi/viewmodels/profile_viewmodel.dart';
import 'package:flutter/material.dart';

class QuestionsScreen extends StatefulWidget {
  final int topicId;
  final int weekNo;

  const QuestionsScreen({
    super.key,
    required this.topicId,
    required this.weekNo,
  });

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  final QuestionService _questionService = QuestionService();
  final ProfileViewModel _profileViewModel = ProfileViewModel();
  
  List<Question> _questions = [];
  bool _isAdmin = false;
  bool _isLoadingData = true;

  final PageController _pageController = PageController();
  final Map<int, dynamic> _userAnswers = {}; // question.id -> answer
  final Map<int, bool> _isAnswerChecked = {}; // question.id -> bool
  final Map<int, bool> _isAnswerCorrect = {}; // question.id -> bool
  int _score = 0;
  bool _showResults = false;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoadingData = true; });
    await _checkAdminStatus();
    _questions = await _questionService.getQuestionsForWeek(widget.topicId, widget.weekNo);
    if(mounted) {
      setState(() { _isLoadingData = false; });
    }
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await _profileViewModel.isAdmin();
    if (mounted) {
      setState(() {
        _isAdmin = isAdmin;
      });
    }
  }

  void _checkAnswer(Question question) {
    if (_isAnswerChecked[question.id] == true) return;

    final userAnswer = _userAnswers[question.id];
    if (userAnswer == null) return;

    bool isCorrect = false;
    if (question.type == QuestionType.multiple_choice) {
      final correctChoice = question.choices.firstWhere((c) => c.isCorrect).id;
      if (userAnswer == correctChoice) {
        isCorrect = true;
      }
    } else if (question.type == QuestionType.fill_blank) {
      if ((userAnswer as String).trim().toLowerCase() ==
          question.correctAnswer?.toLowerCase()) {
        isCorrect = true;
      }
    } else if (question.type == QuestionType.true_false) {
      final bool correctAnswer =
          question.correctAnswer?.toLowerCase() == 'true';
      if (userAnswer == correctAnswer) {
        isCorrect = true;
      }
    } else if (question.type == QuestionType.matching) {
      final userMatches = userAnswer as Map<String, String?>?;
      if (userMatches != null &&
          question.matchingPairs != null && // Add null check here
          userMatches.length == question.matchingPairs!.length && // Use ! since it's checked
          userMatches.values.every((v) => v != null && v.isNotEmpty)) { 
        final correctMatches = {
          for (var p in question.matchingPairs!) p.left_text: p.right_text // Use ! since it's checked
        };
        isCorrect = userMatches.entries
            .every((entry) => correctMatches[entry.key] == entry.value);
      } else {
        isCorrect = false;
      }
    }

    setState(() {
      _isAnswerChecked[question.id] = true;
      _isAnswerCorrect[question.id] = isCorrect;
      if (isCorrect) {
        _score += question.score;
      }
    });
  }

  Future<void> _deleteQuestion(int questionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Soruyu Sil'),
        content: const Text(
            'Bu soruyu kalıcı olarak silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('İptal')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child:
                  const Text('Sil', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _questionService.deleteQuestion(questionId);
        setState(() {
          _questions.removeWhere((q) => q.id == questionId);
          if (_currentPage >= _questions.length && _questions.isNotEmpty) {
            _currentPage = _questions.length - 1;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Soru başarıyla silindi.'),
              backgroundColor: Colors.green),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Soru silinirken hata oluştu: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _submitQuiz() {
    setState(() {
      _showResults = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Haftalık Değerlendirme'),
      ),
      body: _isLoadingData 
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_questions.isEmpty) {
      return const Center(child: Text('Bu hafta için soru bulunamadı.'));
    }

    if (_showResults) {
      return _buildResultsView();
    }

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _questions.length,
            onPageChanged: (page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemBuilder: (context, index) {
              final question = _questions[index];
              return _QuestionCard(
                key: ValueKey(question.id),
                question: question,
                questionNumber: index + 1,
                totalQuestions: _questions.length,
                userAnswer: _userAnswers[question.id],
                isChecked: _isAnswerChecked[question.id] ?? false,
                isCorrect: _isAnswerCorrect[question.id] ?? false,
                isAdmin: _isAdmin,
                onAnswered: (answer) {
                  setState(() {
                    _userAnswers[question.id] = answer;
                  });
                },
                onCheck: () => _checkAnswer(question),
                onDelete: () => _deleteQuestion(question.id),
              );
            },
          ),
        ),
        _buildBottomNavBar(),
      ],
    );
  }

  Widget _buildResultsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Değerlendirme Tamamlandı!',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          Text('Puanınız: $_score',
              style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Geri Dön'),
          )
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    if (_questions.isEmpty) return const SizedBox.shrink();

    final bool isCurrentQuestionChecked =
        _isAnswerChecked[_questions[_currentPage].id] ?? false;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: _currentPage == 0
                ? null
                : () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeIn,
                    );
                  },
            child: const Text('Önceki'),
          ),
          if (_currentPage == _questions.length - 1)
            ElevatedButton(
              onPressed: isCurrentQuestionChecked ? () => _submitQuiz() : null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Bitir'),
            )
          else
            ElevatedButton(
              onPressed: isCurrentQuestionChecked
                  ? () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeIn,
                      );
                    }
                  : null,
              child: const Text('Sonraki'),
            ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final Question question;
  final int questionNumber;
  final int totalQuestions;
  final dynamic userAnswer;
  final bool isChecked;
  final bool isCorrect;
  final bool isAdmin;
  final ValueChanged<dynamic> onAnswered;
  final VoidCallback onCheck;
  final VoidCallback onDelete;

  const _QuestionCard({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.totalQuestions,
    required this.userAnswer,
    required this.isChecked,
    required this.isCorrect,
    required this.isAdmin,
    required this.onAnswered,
    required this.onCheck,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Soru $questionNumber / $totalQuestions',
                    style: Theme.of(context).textTheme.titleMedium),
                if (isAdmin)
                  IconButton(
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    onPressed: onDelete,
                  ),
              ],
            ),
            const Divider(height: 24),
            Text(question.text, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),
            Expanded(child: _buildAnswerArea(context)),
            if (!isChecked)
              ElevatedButton(
                onPressed: userAnswer == null ? null : onCheck,
                child: const Text('Kontrol Et'),
              )
            else
              _buildFeedback(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedback(BuildContext context) {
    if (question.type == QuestionType.classical) {
      return const Text('Cevabınız gönderildi.');
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        isCorrect ? 'Doğru!' : 'Yanlış!',
        style: TextStyle(
          color: isCorrect ? Colors.green : Colors.red,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAnswerArea(BuildContext context) {
    switch (question.type) {
      case QuestionType.multiple_choice:
        return _buildMultipleChoice(context);
      case QuestionType.true_false:
        return _buildTrueFalse(context);
      case QuestionType.fill_blank:
        return TextFormField(
          initialValue: userAnswer as String?,
          onChanged: onAnswered,
          readOnly: isChecked,
          decoration: InputDecoration(
            labelText: 'Cevabınız',
            border: const OutlineInputBorder(),
            filled: isChecked,
            fillColor: Colors.grey[200],
          ),
        );
      case QuestionType.classical:
        return TextFormField(
          initialValue: userAnswer as String?,
          onChanged: onAnswered,
          readOnly: isChecked,
          decoration: InputDecoration(
            labelText: 'Cevabınız',
            border: const OutlineInputBorder(),
            alignLabelWithHint: true,
            filled: isChecked,
            fillColor: Colors.grey[200],
          ),
          maxLines: 5,
        );
      case QuestionType.matching:
        return _MatchingQuestionBody(
          question: question,
          onAnswered: onAnswered,
          userAnswer: (userAnswer as Map?)?.cast<String, String?>() ?? {},
          isChecked: isChecked,
        );
      case QuestionType.unknown:
        return const Center(child: Text('Bilinmeyen soru tipi.'));
    }
  }

  Widget _buildMultipleChoice(BuildContext context) {
    return ListView.builder(
      itemCount: question.choices.length,
      itemBuilder: (context, index) {
        final choice = question.choices[index];
        Color? tileColor;
        Icon? trailingIcon;

        if (isChecked) {
          if (choice.isCorrect) {
            tileColor = Colors.green.withOpacity(0.3);
            trailingIcon = const Icon(Icons.check_circle, color: Colors.green);
          } else if (userAnswer == choice.id && !choice.isCorrect) {
            tileColor = Colors.red.withOpacity(0.3);
            trailingIcon = const Icon(Icons.cancel, color: Colors.red);
          }
        }

        return Card(
          color: tileColor,
          child: RadioListTile<int>(
            title: Text(choice.text),
            value: choice.id,
            groupValue: userAnswer as int?,
            onChanged: isChecked ? null : (value) => onAnswered(value),
            secondary: trailingIcon,
          ),
        );
      },
    );
  }

  Widget _buildTrueFalse(BuildContext context) {
    return Column(
      children: [
        Card(
          color: isChecked && (question.correctAnswer == 'true')
              ? Colors.green.withOpacity(0.3)
              : (isChecked && userAnswer == true &&
                      (question.correctAnswer != 'true'))
                  ? Colors.red.withOpacity(0.3)
                  : null,
          child: RadioListTile<bool>(
            title: const Text('Doğru'),
            value: true,
            groupValue: userAnswer as bool?,
            onChanged: isChecked ? null : (value) => onAnswered(value),
          ),
        ),
        Card(
          color: isChecked && (question.correctAnswer == 'false')
              ? Colors.green.withOpacity(0.3)
              : (isChecked &&
                      userAnswer == false &&
                      (question.correctAnswer != 'false'))
                  ? Colors.red.withOpacity(0.3)
                  : null,
          child: RadioListTile<bool>(
            title: const Text('Yanlış'),
            value: false,
            groupValue: userAnswer as bool?,
            onChanged: isChecked ? null : (value) => onAnswered(value),
          ),
        ),
      ],
    );
  }
}

class _MatchingQuestionBody extends StatefulWidget {
  final Question question;
  final ValueChanged<dynamic> onAnswered;
  final Map<String, String?> userAnswer;
  final bool isChecked;

  const _MatchingQuestionBody({
    required this.question,
    required this.onAnswered,
    required this.userAnswer,
    required this.isChecked,
  });

  @override
  _MatchingQuestionBodyState createState() => _MatchingQuestionBodyState();
}

class _MatchingQuestionBodyState extends State<_MatchingQuestionBody> {
  late List<String> leftTexts;
  late List<String> shuffledRightTexts;
  late Map<String, String?> userMatches; // left_text -> right_text
  late List<String> availableRightTexts;

  @override
  void initState() {
    super.initState();
    leftTexts = widget.question.matchingPairs?.map((p) => p.left_text).toList() ?? [];
    shuffledRightTexts = widget.question.matchingPairs?.map((p) => p.right_text).toList() ?? [];
    shuffledRightTexts.shuffle();
    userMatches = Map.from(widget.userAnswer);

    final matchedValues = userMatches.values.toSet();
    availableRightTexts =
        shuffledRightTexts.where((m) => !matchedValues.contains(m)).toList();
  }

  void _handleDrop(String leftText, String rightText) {
    if (widget.isChecked) return;

    setState(() {
      String? previousLeftText;
      for (final entry in userMatches.entries) {
        if (entry.value == rightText) {
          previousLeftText = entry.key;
          break;
        }
      }

      if (previousLeftText != null) {
        userMatches[previousLeftText] = null;
      }

      final previousRightText = userMatches[leftText];
      if (previousRightText != null && previousRightText != rightText) {
        if (!availableRightTexts.contains(previousRightText)) {
          availableRightTexts.add(previousRightText);
        }
      }

      userMatches[leftText] = rightText;
      availableRightTexts.remove(rightText);
      widget.onAnswered(userMatches);
    });
  }

  @override
  Widget build(BuildContext context) {
    // The available options to drag from.
    final draggableOptions = shuffledRightTexts.map((rightText) {
      bool isUsed = userMatches.containsValue(rightText);
      return Draggable<String>(
        key: ValueKey(rightText),
        data: rightText,
        feedback: Material(
          elevation: 4.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(rightText,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.white)),
          ),
        ),
        childWhenDragging: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Text(rightText,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey.shade300)),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8.0),
              color:
                  widget.isChecked || isUsed ? Colors.grey.shade300 : Colors.white,
              boxShadow: widget.isChecked || isUsed
                  ? []
                  : [
                      BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 2,
                          offset: const Offset(0, 1))
                    ]),
          child: Text(rightText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: widget.isChecked || isUsed ? Colors.grey.shade600 : null,
                  )),
        ),
      );
    }).toList();

    // The drop targets.
    final dropTargets = ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: leftTexts.length,
      itemBuilder: (context, index) {
        final leftText = leftTexts[index];
        final matchedValue = userMatches[leftText];
        bool? isCorrect;
        if (widget.isChecked) {
          if (matchedValue != null && widget.question.matchingPairs != null) {
            final correctMatch = widget.question.matchingPairs!
                .firstWhere((p) => p.left_text == leftText)
                .right_text;
            isCorrect = matchedValue == correctMatch;
          } else {
            isCorrect = false;
          }
        }

        return DragTarget<String>(
          key: ValueKey(leftText),
          builder: (context, candidateData, rejectedData) {
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8.0),
                color: isCorrect == null
                    ? (candidateData.isNotEmpty
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.grey.shade50)
                    : (isCorrect
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(leftText,
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Colors.grey.shade600,
                          width: 1.5,
                          style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.white,
                    ),
                    child: Center(
                        child: Text(matchedValue ?? '...',
                            textAlign: TextAlign.center,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold))),
                  ),
                ],
              ),
            );
          },
          onWillAccept: (data) => true,
          onAccept: (data) => _handleDrop(leftText, data),
        );
      },
    );

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: dropTargets,
        ),
        const Divider(height: 24, thickness: 1,),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            spacing: 12.0,
            runSpacing: 12.0,
            alignment: WrapAlignment.center,
            children: draggableOptions,
          ),
        ),
      ],
    );
  }
}