import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'common/lesson_step_card.dart';

class StepText extends StatelessWidget {
  final Map<String, dynamic> step;
  final bool isActive;
  final VoidCallback onComplete;

  const StepText({
    super.key,
    required this.step,
    required this.isActive,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return LessonStepCard(
          badge: step['badge']?.toString() ?? 'Ders Adimi',
          title: step['title']?.toString(),
          subtitle: step['subtitle']?.toString(),
          helperText: step['helper']?.toString(),
          footer: isActive
              ? SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      step['buttonText']?.toString() ?? 'Devam Et',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              : null,
          child: Text(
            step['content']?.toString() ?? '',
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Color(0xFF475569),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .slide(begin: const Offset(0, 0.1), end: Offset.zero)
        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1));
  }
}
