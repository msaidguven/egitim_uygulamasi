// lib/screens/questions_screen.dart

import 'dart:collection';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:egitim_uygulamasi/models/question_model.dart';
import 'package:egitim_uygulamasi/models/question_blank_option.dart';
import 'package:egitim_uygulamasi/services/question_service.dart';
import 'package:egitim_uygulamasi/viewmodels/profile_viewmodel.dart';
import 'package:flutter/material.dart';

class QuestionsScreen extends StatefulWidget {
  final int topicId;
  final int weekNo;
  final int? difficulty;

  QuestionsScreen({
    super.key,
    required this.topicId,
    required this.weekNo,
    this.difficulty,
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
  String? _error;

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
    setState(() { 
      _isLoadingData = true; 
      _error = null;
    });
    try {
      await _checkAdminStatus();
      var allQuestions = await _questionService.getQuestionsForWeek(widget.topicId, widget.weekNo);
      if (widget.difficulty != null) {
        _questions = allQuestions.where((q) => q.difficulty == widget.difficulty).toList();
      } else {
        _questions = allQuestions;
      }
    } catch (e, st) {
      debugPrint('--- SORU YÜKLENİRKEN HATA ---');
      debugPrint('Hata: $e');
      debugPrint('Stack Trace:\n$st');
      debugPrint('-----------------------------');
      if (mounted) {
        setState(() {
          _error = 'Sorular yüklenirken bir hata oluştu: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() { _isLoadingData = false; });
      }
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
      if (question.blankOptions.isNotEmpty) {
        if (userAnswer is Map<int, QuestionBlankOption?>) {
          final correctOptionIds = question.blankOptions
              .where((opt) => opt.isCorrect)
              .map((opt) => opt.id)
              .toSet();

          final userAnswerIds = userAnswer.values
              .whereNotNull()
              .map((opt) => opt.id)
              .toSet();

          isCorrect = const SetEquality().equals(userAnswerIds, correctOptionIds);

        } else { 
          final correctOptionIds = question.blankOptions.where((o) => o.isCorrect).map((o) => o.id).toList();
          if (correctOptionIds.contains(userAnswer)) {
            isCorrect = true;
          }
        }
      } else {
        // This case is for simple fill-in-the-blanks without predefined options.
        // It seems the `correctAnswer` field in the model is now bool?, so we need to handle this.
        // Assuming this type of question is not used for now, or it needs a different field.
        // For safety, we'll compare with `toString()`.
        if ((userAnswer as String).trim().toLowerCase() == question.correctAnswer.toString().toLowerCase()) {
          isCorrect = true;
        }
      }
    } else if (question.type == QuestionType.true_false) {
      // With the corrected model, this is a direct boolean comparison.
      if (userAnswer == question.correctAnswer) {
        isCorrect = true;
      }
    } else if (question.type == QuestionType.matching) {
      final userMatches = userAnswer as Map<String, MatchingPair?>?;
      if (userMatches != null &&
          question.matchingPairs != null &&
          userMatches.length == question.matchingPairs!.length &&
          userMatches.values.every((v) => v != null)) {
        final correctMatches = {
          for (var p in question.matchingPairs!) p.left_text: p.right_text
        };

        isCorrect = userMatches.entries.every((entry) {
          final leftText = entry.key;
          final selectedRightText = entry.value?.right_text;
          return correctMatches[leftText] == selectedRightText;
        });
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

  String _getAppBarTitle() {
    if (widget.difficulty == null) {
      return 'Haftalık Değerlendirme';
    }
    switch (widget.difficulty) {
      case 1:
        return 'Kolay Seviye Testi';
      case 2:
        return 'Orta Seviye Testi';
      case 3:
        return 'Zor Seviye Testi';
      default:
        return 'Haftalık Değerlendirme';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
      ),
      body: _isLoadingData 
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      ));
    }
    if (_questions.isEmpty) {
      return const Center(child: Text('Bu seviye için soru bulunamadı.'));
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
            if (question.type != QuestionType.fill_blank)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  question.text,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
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
        if (question.blankOptions.isNotEmpty) {
          return _FillBlankWithOptionsBody(
            question: question,
            onAnswered: onAnswered,
            userAnswer: userAnswer,
            isChecked: isChecked,
            isCorrect: isCorrect,
          );
        } else {
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
        }
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
          userAnswer: (userAnswer as Map?)?.cast<String, MatchingPair?>() ?? {},
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
    Color? getCardColor(bool forValue) {
      if (!isChecked) return null;

      final bool isThisTheCorrectAnswer = (question.correctAnswer == forValue);
      final bool isThisTheUserAnswer = (userAnswer == forValue);

      if (isThisTheCorrectAnswer) {
        return Colors.green.withOpacity(0.3);
      }
      if (isThisTheUserAnswer) { // and not the correct answer
        return Colors.red.withOpacity(0.3);
      }
      return null;
    }

    return Column(
      children: [
        Card(
          color: getCardColor(true),
          child: RadioListTile<bool>(
            title: const Text('Doğru'),
            value: true,
            groupValue: userAnswer as bool?,
            onChanged: isChecked ? null : (value) => onAnswered(value),
          ),
        ),
        Card(
          color: getCardColor(false),
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

class _FillBlankWithOptionsBody extends StatefulWidget {
  final Question question;
  final ValueChanged<dynamic> onAnswered;
  final dynamic userAnswer;
  final bool isChecked;
  final bool isCorrect;

  const _FillBlankWithOptionsBody({
    required this.question,
    required this.onAnswered,
    required this.userAnswer,
    required this.isChecked,
    required this.isCorrect,
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
    final int blankCount = '______'.allMatches(widget.question.text).length;
    _droppedAnswers = {for (var i = 0; i < blankCount; i++) i: null};
    _availableOptions = List.from(widget.question.blankOptions);

    if (widget.userAnswer is Map<int, QuestionBlankOption?>) {
       _droppedAnswers.addAll(widget.userAnswer as Map<int, QuestionBlankOption?>);
       for (var answer in _droppedAnswers.values) {
         if (answer != null) {
           _availableOptions.removeWhere((opt) => opt.id == answer.id);
         }
       }
    }
  }

  void _onDrop(int blankIndex, QuestionBlankOption option) {
    if (widget.isChecked) return;

    setState(() {
      final previousEntry = _droppedAnswers.entries.firstWhereOrNull((entry) => entry.value?.id == option.id);
      if (previousEntry != null) {
        _droppedAnswers[previousEntry.key] = null;
      }

      final existingOption = _droppedAnswers[blankIndex];
      if (existingOption != null) {
        _availableOptions.add(existingOption);
      }

      _droppedAnswers[blankIndex] = option;
      _availableOptions.removeWhere((opt) => opt.id == option.id);

      final answersToSubmit = Map<int, QuestionBlankOption?>.from(_droppedAnswers);
      widget.onAnswered(answersToSubmit);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Make blank width responsive, clamping it to avoid being too small or large.
    final blankWidth = (screenWidth * 0.25).clamp(100.0, 150.0);

    final questionParts = widget.question.text.split('______');
    List<Widget> questionWidgets = [];

    for (int i = 0; i < questionParts.length; i++) {
      questionWidgets.add(Text(questionParts[i], style: Theme.of(context).textTheme.headlineSmall?.copyWith(height: 1.5)));
      if (i < questionParts.length - 1) {
        final blankIndex = i;
        final droppedOption = _droppedAnswers[blankIndex];
        
        Color borderColor = Colors.grey;
        Color backgroundColor = Colors.grey.shade100;

        if (widget.isChecked) {
          borderColor = widget.isCorrect ? Colors.green : Colors.red;
          backgroundColor = widget.isCorrect ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2);
        }

        questionWidgets.add(
          DragTarget<QuestionBlankOption>(
            builder: (context, candidateData, rejectedData) {
              return Container(
                height: 50,
                width: blankWidth, // USE RESPONSIVE WIDTH
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(8),
                  color: backgroundColor,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: FittedBox( // ADD FITTEDBOX
                      fit: BoxFit.scaleDown,
                      child: Text(
                        droppedOption?.optionText ?? '______',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: droppedOption != null ? FontWeight.bold : FontWeight.normal,
                          color: droppedOption != null ? Colors.blue.shade800 : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
            onAccept: (option) => _onDrop(blankIndex, option),
          ),
        );
      }
    }

    return ListView(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: questionWidgets,
        ),
        const Divider(height: 48, thickness: 1),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          alignment: WrapAlignment.center,
          children: _availableOptions.map((option) {
            return Draggable<QuestionBlankOption>(
              data: option,
              feedback: Material(
                elevation: 4.0,
                child: Chip(label: Text(option.optionText), backgroundColor: Colors.blue.shade200),
              ),
              childWhenDragging: Chip(
                label: Text(option.optionText),
                backgroundColor: Colors.grey.shade300,
              ),
              child: Chip(label: Text(option.optionText)),
            );
          }).toList(),
        ),
      ],
    );
  }
}


class _MatchingQuestionBody extends StatefulWidget {
  final Question question;
  final ValueChanged<dynamic> onAnswered;
  final Map<String, MatchingPair?> userAnswer;
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
  late List<MatchingPair> shuffledRightPairs;
  late Map<String, MatchingPair?> userMatches;

  @override
  void initState() {
    super.initState();
    leftTexts = widget.question.matchingPairs?.map((p) => p.left_text).toList() ?? [];
    shuffledRightPairs = List.from(widget.question.matchingPairs ?? []);
    shuffledRightPairs.shuffle();
    userMatches = Map.from(widget.userAnswer);
  }

  void _handleDrop(String leftText, MatchingPair droppedPair) {
    if (widget.isChecked) return;

    setState(() {
      // We are dropping `droppedPair` onto the slot for `leftText`.

      // The most important thing is to ensure the `droppedPair` is not present in any *other* slot.
      // We create a new map for the updated matches.
      final newMatches = <String, MatchingPair?>{};
      userMatches.forEach((key, value) {
        // If the value is not the one we just dropped, keep it.
        if (value?.id != droppedPair.id) {
          newMatches[key] = value;
        }
      });

      // Now, add the new match.
      newMatches[leftText] = droppedPair;

      // Update the state with the new map.
      userMatches = newMatches;
      widget.onAnswered(userMatches);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use the ID to check for availability, allowing duplicate texts.
    final availableRightPairs = shuffledRightPairs.where((pair) {
      return !userMatches.values.any((matchedPair) => matchedPair?.id == pair.id);
    }).toList();

    final draggableOptions = availableRightPairs.map((pair) {
      return Draggable<MatchingPair>(
        data: pair,
        feedback: Material(
          elevation: 4.0,
          child: Chip(label: Text(pair.right_text)),
        ),
        childWhenDragging: Chip(label: Text(pair.right_text), backgroundColor: Colors.grey.shade300),
        child: Chip(label: Text(pair.right_text)),
      );
    }).toList();

    final dropTargets = ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: leftTexts.length,
      itemBuilder: (context, index) {
        final leftText = leftTexts[index];
        final matchedPair = userMatches[leftText];
        bool? isCorrect;

        if (widget.isChecked) {
          final correctMatch = widget.question.matchingPairs!.firstWhere((p) => p.left_text == leftText).right_text;
          isCorrect = matchedPair?.right_text == correctMatch;
        }

        return DragTarget<MatchingPair>(
          builder: (context, candidateData, rejectedData) {
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8.0),
                color: widget.isChecked ? (isCorrect! ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2)) : Colors.grey.shade100,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(leftText),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        border: Border(left: BorderSide(color: Colors.grey.shade300)),
                      ),
                      child: Center(
                        child: Text(
                          matchedPair?.right_text ?? '...',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
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

    return ListView(
      children: [
        dropTargets,
        const Divider(height: 24),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          alignment: WrapAlignment.center,
          children: draggableOptions,
        ),
      ],
    );
  }
}
