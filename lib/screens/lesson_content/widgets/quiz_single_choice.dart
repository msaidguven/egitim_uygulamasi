import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'common/lesson_step_card.dart';

class QuizSingleChoiceStep extends StatefulWidget {
  final Map<String, dynamic> step;
  final bool isActive;
  final VoidCallback onComplete;

  const QuizSingleChoiceStep({
    super.key,
    required this.step,
    required this.isActive,
    required this.onComplete,
  });

  @override
  State<QuizSingleChoiceStep> createState() => _QuizSingleChoiceStepState();
}

class _QuizSingleChoiceStepState extends State<QuizSingleChoiceStep> {
  String? selected;
  bool submitted = false;

  @override
  Widget build(BuildContext context) {
    final options =
        (widget.step['options'] as List?)?.map((e) => e.toString()).toList() ??
        const <String>[];
    final correct = widget.step['correct']?.toString();
    final explanation = widget.step['explanation']?.toString();
    final isCorrect = submitted && selected != null && selected == correct;

    return LessonStepCard(
      badge: widget.step['badge']?.toString() ?? 'Kontrol Sorusu',
      title: widget.step['title']?.toString(),
      subtitle: widget.step['question']?.toString(),
      footer: widget.isActive
          ? SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selected == null
                    ? null
                    : () {
                        if (selected == correct) {
                          setState(() => submitted = true);
                          Future.delayed(
                            const Duration(milliseconds: 500),
                            widget.onComplete,
                          );
                          return;
                        }
                        setState(() => submitted = true);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  widget.step['buttonText']?.toString() ?? 'Cevabi Kontrol Et',
                ),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final option in options)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: widget.isActive
                    ? () {
                        setState(() {
                          selected = option;
                          submitted = false;
                        });
                      }
                    : null,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected == option
                          ? const Color(0xFF6366F1)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selected == option
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: selected == option
                            ? const Color(0xFF6366F1)
                            : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          option,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (submitted)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCorrect
                    ? const Color(0xFFECFDF3)
                    : const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCorrect
                      ? const Color(0xFFBBF7D0)
                      : const Color(0xFFFFCDD2),
                ),
              ),
              child: Text(
                isCorrect
                    ? (explanation ?? 'Dogru cevap.')
                    : (widget.step['incorrectHint']?.toString() ??
                          'Tekrar dene.'),
                style: TextStyle(
                  color: isCorrect
                      ? const Color(0xFF166534)
                      : const Color(0xFF991B1B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0);
  }
}
