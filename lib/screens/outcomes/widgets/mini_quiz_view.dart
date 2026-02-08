import 'package:flutter/material.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:egitim_uygulamasi/models/question_model.dart';

class MiniQuizView extends StatelessWidget {
  final List<Question> questions;

  const MiniQuizView({super.key, required this.questions});

  void _openQuizDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Quiz',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) => _QuizDialog(questions: questions),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Canlı renkler için gradient ve renk paleti
    const Color primaryColor = Color(0xFF6366F1); // Indigo
    const Color accentColor = Color(0xFF8B5CF6); // Violet

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, accentColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.lightbulb_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Anladım mı? Kendini Sına!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Start Card Content
          _AppleQuizStartCard(
            onStart: () => _openQuizDialog(context),
          ),
        ],
      ),
    );
  }
}

class _QuizDialog extends StatefulWidget {
  final List<Question> questions;

  const _QuizDialog({required this.questions});

  @override
  State<_QuizDialog> createState() => _QuizDialogState();
}

class _QuizDialogState extends State<_QuizDialog> {
  Map<int, int?> _selectedChoiceIds = {};
  Map<int, bool?> _results = {};
  int _currentPage = 0;
  bool _isFinished = false;

  void _checkAnswer(Question question, int choiceId) {
    QuestionChoice? correctChoice;
    for (final choice in question.choices) {
      if (choice.isCorrect) {
        correctChoice = choice;
        break;
      }
    }
    setState(() {
      _selectedChoiceIds[question.id] = choiceId;
      _results[question.id] = (correctChoice?.id == choiceId);
      if (_results.length == widget.questions.length) {
        _isFinished = true;
      }
    });
  }

  void _resetQuiz() {
    setState(() {
      _selectedChoiceIds = {};
      _results = {};
      _currentPage = 0;
      _isFinished = false;
    });
  }

  void _nextPage() {
    if (_currentPage < widget.questions.length - 1) {
      setState(() {
        _currentPage++;
      });
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.8, // Ekranın %80'i kadar yükseklik
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          children: [
            // Dialog Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.quiz_rounded, color: Color(0xFF6366F1), size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Mini Quiz',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, size: 18, color: Colors.black54),
                    ),
                    splashRadius: 24,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),
            
            // Content
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isFinished
                    ? _AppleQuizResults(
                        key: const ValueKey('results'),
                        results: _results,
                        totalQuestions: widget.questions.length,
                        onRetry: _resetQuiz,
                        onClose: () => Navigator.of(context).pop(),
                      )
                    : _AppleQuizContent(
                        key: ValueKey('content_$_currentPage'),
                        question: widget.questions[_currentPage],
                        totalQuestions: widget.questions.length,
                        questionIndex: _currentPage,
                        results: _results,
                        selectedChoiceIds: _selectedChoiceIds,
                        onAnswer: _checkAnswer,
                        onNext: _nextPage,
                        onPrevious: _previousPage,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppleQuizStartCard extends StatelessWidget {
  final VoidCallback onStart;

  const _AppleQuizStartCard({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.quiz_rounded, size: 64, color: Color(0xFF6366F1)),
          ),
          const SizedBox(height: 24),
          const Text(
            'Konuyu Pekiştir',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 12),
          Text(
            '5 soruluk mini test ile konuyu ne kadar anladığını ölç',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                shadowColor: const Color(0xFF6366F1).withOpacity(0.4),
              ),
              child: const Text(
                'Mini Quize Başla',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppleQuizContent extends StatelessWidget {
  final Question question;
  final int totalQuestions;
  final int questionIndex;
  final Map<int, bool?> results;
  final Map<int, int?> selectedChoiceIds;
  final Function(Question, int) onAnswer;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const _AppleQuizContent({
    super.key,
    required this.question,
    required this.totalQuestions,
    required this.questionIndex,
    required this.results,
    required this.selectedChoiceIds,
    required this.onAnswer,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  Widget build(BuildContext context) {
    final isChecked = results.containsKey(question.id);
    final selectedChoiceId = selectedChoiceIds[question.id];

    // İstatistikleri hesapla
    int correctCount = 0;
    int wrongCount = 0;
    results.forEach((_, isCorrect) {
      if (isCorrect == true) correctCount++;
      if (isCorrect == false) wrongCount++;
    });
    int currentScore = correctCount * 20;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Soru ${questionIndex + 1}/$totalQuestions',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${correctCount}d',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF10B981), // Emerald Green
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${wrongCount}y',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFEF4444), // Red
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 1,
                      height: 12,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${currentScore}p',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6366F1), // Indigo
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            question.text,
            style: const TextStyle(
              fontSize: 17,
              height: 1.4,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: question.choices.map((choice) {
              bool isSelected = (selectedChoiceId == choice.id);
              
              Widget choiceWidget;
              if (isChecked) {
                if (choice.isCorrect) {
                  choiceWidget = _buildResultChoice(
                    text: choice.text,
                    icon: Icons.check_circle_rounded,
                    color: Colors.green,
                    bgColor: Colors.green.shade50,
                    borderColor: Colors.green.shade200,
                  );
                } else if (isSelected) {
                  choiceWidget = _buildResultChoice(
                    text: choice.text,
                    icon: Icons.cancel_rounded,
                    color: Colors.red,
                    bgColor: Colors.red.shade50,
                    borderColor: Colors.red.shade200,
                  );
                } else {
                   choiceWidget = _buildNormalChoice(choice, false, true);
                }
              } else {
                choiceWidget = _buildNormalChoice(choice, isSelected, false);
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: GestureDetector(
                  onTap: isChecked ? null : () => onAnswer(question, choice.id),
                  child: choiceWidget,
                ),
              );
            }).toList(),
          ),
          
          // Navigation Controls
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: questionIndex > 0 ? onPrevious : null,
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: questionIndex > 0 ? Colors.grey.shade800 : Colors.grey.shade300,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
                
                DotsIndicator(
                  dotsCount: totalQuestions,
                  position: questionIndex,
                  decorator: DotsDecorator(
                    activeColor: const Color(0xFF6366F1),
                    color: Colors.grey.shade300,
                    size: const Size.square(8.0),
                    activeSize: const Size(24.0, 8.0),
                    activeShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                ),
                
                IconButton(
                  onPressed: questionIndex < totalQuestions - 1 ? onNext : null,
                  icon: Icon(
                    Icons.arrow_forward_rounded,
                    color: questionIndex < totalQuestions - 1 ? Colors.white : Colors.grey.shade300,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: questionIndex < totalQuestions - 1 
                        ? const Color(0xFF6366F1) 
                        : Colors.grey.shade100,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNormalChoice(QuestionChoice choice, bool isSelected, bool isDisabled) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF6366F1).withOpacity(0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF6366F1)
              : Colors.grey.shade200,
          width: isSelected ? 2 : 1.5,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF6366F1)
                    : Colors.grey.shade300,
                width: 2,
              ),
              color: isSelected
                  ? const Color(0xFF6366F1)
                  : Colors.transparent,
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              choice.text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected
                    ? FontWeight.w600
                    : FontWeight.normal,
                color: isSelected
                    ? const Color(0xFF6366F1)
                    : (isDisabled ? Colors.grey.shade400 : Colors.grey.shade800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultChoice({
    required String text,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade900,
              ),
            ),
          ),
          Icon(icon, color: color),
        ],
      ),
    );
  }
}

class _AppleQuizResults extends StatelessWidget {
  final Map<int, bool?> results;
  final int totalQuestions;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  const _AppleQuizResults({
    super.key,
    required this.results,
    required this.totalQuestions,
    required this.onRetry,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final correctAnswers = results.values.where((r) => r == true).length;
    final successRate = totalQuestions > 0
        ? (correctAnswers / totalQuestions) * 100
        : 0.0;

    Color getColor() {
      if (successRate == 100) return const Color(0xFF10B981); // Emerald
      if (successRate >= 60) return const Color(0xFF3B82F6); // Blue
      return const Color(0xFFF59E0B); // Amber
    }

    String getMessage() {
      if (successRate == 100) return 'Mükemmel! Tamamı doğru.';
      if (successRate >= 60) return 'Çok iyi! Konuyu anlamışsın.';
      return 'Tekrar denemekte fayda var.';
    }

    final color = getColor();
    final message = getMessage();

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              successRate == 100
                  ? Icons.celebration_rounded
                  : successRate >= 60
                  ? Icons.thumb_up_rounded
                  : Icons.refresh_rounded,
              size: 64,
              color: color,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '$totalQuestions sorudan $correctAnswers tanesini doğru cevapladın.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.4,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '(${successRate.toStringAsFixed(0)}% başarı)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onClose,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Kapat',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Tekrar Dene',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
