import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'common/lesson_step_card.dart';

class InfoHighlightsStep extends StatelessWidget {
  final Map<String, dynamic> step;
  final bool isActive;
  final VoidCallback onComplete;

  const InfoHighlightsStep({
    super.key,
    required this.step,
    required this.isActive,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final points =
        (step['points'] as List?)?.map((e) => e.toString()).toList() ??
        const <String>[];
    final note = step['note']?.toString();

    return LessonStepCard(
      badge: step['badge']?.toString() ?? 'Konu Ozeti',
      title: step['title']?.toString(),
      subtitle: step['subtitle']?.toString() ?? step['content']?.toString(),
      helperText: step['helper']?.toString(),
      footer: isActive
          ? SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onComplete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(step['buttonText']?.toString() ?? 'Devam Et'),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final point in points)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      point,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF1E293B),
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (note != null && note.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Text(
                note,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF854D0E),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0);
  }
}
