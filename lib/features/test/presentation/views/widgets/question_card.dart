import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:egitim_uygulamasi/features/test/data/models/test_question.dart';
import 'package:egitim_uygulamasi/features/test/presentation/views/widgets/multiple_choice_widget.dart';
import 'package:egitim_uygulamasi/features/test/presentation/views/widgets/fill_blank_widget.dart';
import 'package:egitim_uygulamasi/features/test/presentation/views/widgets/matching_question_widget.dart';
import 'package:egitim_uygulamasi/models/question_model.dart';
import 'package:egitim_uygulamasi/widgets/question_text.dart';

class QuestionCard extends StatelessWidget {
  final TestQuestion testQuestion;
  final ValueChanged<dynamic> onAnswered;

  const QuestionCard({
    super.key,
    required this.testQuestion,
    required this.onAnswered,
  });

  @override
  Widget build(BuildContext context) {
    final question = testQuestion.question;
    final isChecked = testQuestion.isChecked;
    final isCorrect = testQuestion.isCorrect;
    final isTimeUp = isChecked && testQuestion.userAnswer == null;
    final stats = question.userStats;
    final isNarrow = MediaQuery.of(context).size.width < 700;
    final contentPadding = EdgeInsets.fromLTRB(
      isNarrow ? 16 : 20,
      isNarrow ? 32 : 40,
      isNarrow ? 16 : 20,
      isNarrow ? 16 : 20,
    );

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: isNarrow ? 12 : 16,
        vertical: isNarrow ? 6 : 8,
      ),
      elevation: 4,
      shadowColor: Colors.black26, // Daha yumuşak gölge
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), // Daha yuvarlak köşeler
      child: Stack(
        children: [
          Padding(
            padding: contentPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (question.type != QuestionType.fill_blank)
                  QuestionText(
                    text: question.text,
                    fontSize: isNarrow ? 17 : 18,
                    textColor: Theme.of(context).textTheme.titleLarge?.color ?? Colors.black,
                    fractionColor: Theme.of(context).colorScheme.primary,
                    //enableFractions: question.unit.isMath, // veya question.questionTypeId == 1
                  ),
                if (question.type != QuestionType.fill_blank)
                  Divider(height: isNarrow ? 24 : 32),
                Expanded(child: _buildAnswerArea(context)),
                if (isChecked) ...[
                  SizedBox(height: isNarrow ? 16 : 24),
                  // Oyunsu Sonuç Rozeti (Badge)
                  Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: isNarrow ? 12 : 16,
                        horizontal: isNarrow ? 24 : 32,
                      ),
                      decoration: BoxDecoration(
                        color: isTimeUp ? const Color(0xFFFFF7ED) : (isCorrect ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2)),
                        borderRadius: BorderRadius.circular(30), // Tam yuvarlak hap(pill) şekli
                        border: Border.all(
                          color: isTimeUp ? const Color(0xFFF97316) : (isCorrect ? const Color(0xFF22C55E) : const Color(0xFFEF4444)),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isTimeUp ? const Color(0xFFF97316) : (isCorrect ? const Color(0xFF22C55E) : const Color(0xFFEF4444))).withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ]
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min, // Ortalamak için
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isTimeUp
                                ? '⏰'
                                : (isCorrect ? '✅' : '❌'),
                            style: TextStyle(
                              fontSize: isNarrow ? 24 : 28,
                            ),
                          ),
                          SizedBox(width: isNarrow ? 8 : 12),
                          Text(
                            isTimeUp ? 'Süre doldu!' : (isCorrect ? 'Harika!' : 'Şansını zorla!'),
                            style: TextStyle(
                              color: isTimeUp ? const Color(0xFFC2410C) : (isCorrect ? const Color(0xFF15803D) : const Color(0xFFB91C1C)),
                              fontSize: isNarrow ? 18 : 22,
                              fontWeight: FontWeight.w900, // Çok kalın eğlenceli font
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ).animate()
                      .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), curve: Curves.elasticOut, duration: 600.ms)
                      .fadeIn(duration: 300.ms),
                  ),
                  SizedBox(height: isNarrow ? 6 : 8),
                ],
              ],
            ),
          ),
          if (stats != null && stats.totalAttempts > 0)
            Positioned(
              top: 12,
              right: 12,
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
        ],
      ),
    ).animate().slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuart, duration: 500.ms).fadeIn(duration: 500.ms);
  }

  Widget _buildAnswerArea(BuildContext context) {
    switch (testQuestion.question.type) {
      case QuestionType.multiple_choice:
      case QuestionType.true_false:
        return MultipleChoiceWidget(
          testQuestion: testQuestion,
          onAnswered: onAnswered,
        );
      case QuestionType.fill_blank:
        return FillBlankWidget(
          testQuestion: testQuestion,
          onAnswered: onAnswered,
        );
      case QuestionType.matching:
        return MatchingQuestionWidget(
          testQuestion: testQuestion,
          onAnswered: onAnswered,
        );
      default:
        return const Center(child: Text('Soru tipi desteklenmiyor.'));
    }
  }
}
