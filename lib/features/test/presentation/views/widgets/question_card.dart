import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:egitim_uygulamasi/features/test/data/models/test_question.dart';
import 'package:egitim_uygulamasi/features/test/presentation/views/widgets/multiple_choice_widget.dart';
import 'package:egitim_uygulamasi/features/test/presentation/views/widgets/fill_blank_widget.dart';
import 'package:egitim_uygulamasi/features/test/presentation/views/widgets/matching_question_widget.dart';
import 'package:egitim_uygulamasi/features/test/presentation/views/widgets/classical_question_widget.dart';
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
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            children: [
              Padding(
                padding: contentPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (question.type != QuestionType.fill_blank &&
                        question.type != QuestionType.classical)
                      QuestionText(
                        text: question.text,
                        fontSize: isNarrow ? 17 : 18,
                        textColor:
                            Theme.of(context).textTheme.titleLarge?.color ??
                            Colors.black,
                        fractionColor: Theme.of(context).colorScheme.primary,
                      ),
                    if (question.type != QuestionType.fill_blank &&
                        question.type != QuestionType.classical)
                      Divider(height: isNarrow ? 24 : 32),
                    _buildAnswerArea(context),
                    if (isChecked) ...[
                      SizedBox(height: isNarrow ? 16 : 24),
                      Center(
                        child:
                            Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: isNarrow ? 12 : 16,
                                    horizontal: isNarrow ? 24 : 32,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isTimeUp
                                        ? const Color(0xFFFFF7ED)
                                        : (isCorrect
                                              ? const Color(0xFFF0FDF4)
                                              : const Color(0xFFFEF2F2)),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: isTimeUp
                                          ? const Color(0xFFF97316)
                                          : (isCorrect
                                                ? const Color(0xFF22C55E)
                                                : const Color(0xFFEF4444)),
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            (isTimeUp
                                                    ? const Color(0xFFF97316)
                                                    : (isCorrect
                                                          ? const Color(
                                                              0xFF22C55E,
                                                            )
                                                          : const Color(
                                                              0xFFEF4444,
                                                            )))
                                                .withOpacity(0.2),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
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
                                        isTimeUp
                                            ? 'Süre doldu!'
                                            : (isCorrect
                                                  ? 'Harika!'
                                                  : 'Şansını zorla!'),
                                        style: TextStyle(
                                          color: isTimeUp
                                              ? const Color(0xFFC2410C)
                                              : (isCorrect
                                                    ? const Color(0xFF15803D)
                                                    : const Color(0xFFB91C1C)),
                                          fontSize: isNarrow ? 18 : 22,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                .animate()
                                .scale(
                                  begin: const Offset(0.8, 0.8),
                                  end: const Offset(1, 1),
                                  curve: Curves.elasticOut,
                                  duration: 600.ms,
                                )
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.history,
                          size: 14,
                          color: Colors.grey.shade700,
                        ),
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
        )
        .animate()
        .slideY(
          begin: 0.1,
          end: 0,
          curve: Curves.easeOutQuart,
          duration: 500.ms,
        )
        .fadeIn(duration: 500.ms);
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
      case QuestionType.classical:
        return _ClassicalAnswerSection(
          testQuestion: testQuestion,
          onAnswered: onAnswered,
        );
      default:
        return const Center(child: Text('Soru tipi desteklenmiyor.'));
    }
  }
}

/// Klasik soru tipi i\u00e7in: soru metnini + word-order alan\u0131n\u0131 birlikte g\u00f6sterir.
class _ClassicalAnswerSection extends StatelessWidget {
  final TestQuestion testQuestion;
  final ValueChanged<dynamic> onAnswered;

  const _ClassicalAnswerSection({
    required this.testQuestion,
    required this.onAnswered,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final question = testQuestion.question;
    final isNarrow = MediaQuery.of(context).size.width < 700;
    final isChecked = testQuestion.isChecked;
    final isCorrect = testQuestion.isCorrect;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Soru metni ──────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(isNarrow ? 16 : 20),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.18),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.12),
              width: 1.5,
            ),
          ),
          child: QuestionText(
            text: question.text,
            fontSize: isNarrow ? 17 : 18,
            textColor:
                theme.textTheme.titleLarge?.color ?? Colors.black,
            fractionColor: theme.colorScheme.primary,
          ),
        ),
        SizedBox(height: isNarrow ? 16 : 20),

        // ── Cevabını olu\u015ftur etiketi ────────────────────────────────────
        Row(
          children: [
            Icon(
              Icons.edit_note_rounded,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              'Cevab\u0131n\u0131 olu\u015ftur:',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Word-order widget ────────────────────────────────────────────
        ClassicalQuestionWidget(
          key: ValueKey('classical-${question.id}'),
          testQuestion: testQuestion,
          onAnswered: onAnswered,
        ),

        // ── Do\u011fru cevap g\u00f6sterimi (yanl\u0131\u015f ise) ─────────────────────────────
        if (isChecked && !isCorrect && (question.modelAnswer ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.shade200, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DO\u011eRU CEVAP',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: question.answerWords.map((w) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.red.shade300,
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          w,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.red.shade900,
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
    );
  }
}
