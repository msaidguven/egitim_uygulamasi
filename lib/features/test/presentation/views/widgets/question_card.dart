import 'package:flutter/material.dart';
import 'package:egitim_uygulamasi/features/test/data/models/test_question.dart';
import 'package:egitim_uygulamasi/features/test/presentation/views/widgets/multiple_choice_widget.dart';
import 'package:egitim_uygulamasi/features/test/presentation/views/widgets/fill_blank_widget.dart';
import 'package:egitim_uygulamasi/features/test/presentation/views/widgets/matching_question_widget.dart';
import 'package:egitim_uygulamasi/models/question_model.dart';

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
    final stats = question.userStats;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                if (question.type != QuestionType.fill_blank)
                  const Divider(height: 32),
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
    );
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