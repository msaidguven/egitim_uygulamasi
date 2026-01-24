import 'package:flutter/material.dart';
import 'package:egitim_uygulamasi/features/test/data/models/test_question.dart';
import 'package:egitim_uygulamasi/widgets/question_text.dart';

class MultipleChoiceWidget extends StatelessWidget {
  final TestQuestion testQuestion;
  final ValueChanged<dynamic> onAnswered;

  const MultipleChoiceWidget({
    super.key,
    required this.testQuestion,
    required this.onAnswered,
  });

  @override
  Widget build(BuildContext context) {
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

                  child: QuestionText(
                    text: choice.text,
                    fontSize: 16,
                    textColor: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                    fractionColor: Theme.of(context).colorScheme.primary,
                    //enableFractions: question.unit.isMath,
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