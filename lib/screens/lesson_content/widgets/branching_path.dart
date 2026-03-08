import 'package:flutter/material.dart';

import 'common/lesson_step_card.dart';

class BranchingPathStep extends StatelessWidget {
  final Map<String, dynamic> step;
  final bool isActive;
  final double masteryPercent;
  final ValueChanged<String?> onBranch;

  const BranchingPathStep({
    super.key,
    required this.step,
    required this.isActive,
    required this.masteryPercent,
    required this.onBranch,
  });

  @override
  Widget build(BuildContext context) {
    final thresholds = Map<String, dynamic>.from(
      (step['thresholds'] as Map?) ?? <String, dynamic>{},
    );
    final targets = Map<String, dynamic>.from(
      (step['targets'] as Map?) ?? <String, dynamic>{},
    );

    final hard = (thresholds['hard'] as num?)?.toDouble() ?? 85;
    final medium = (thresholds['medium'] as num?)?.toDouble() ?? 60;

    String level;
    if (masteryPercent >= hard) {
      level = 'hard';
    } else if (masteryPercent >= medium) {
      level = 'medium';
    } else {
      level = 'easy';
    }
    final nextTarget = targets[level]?.toString();

    return LessonStepCard(
      badge: step['badge']?.toString() ?? 'Uyarlanabilir Yol',
      title: step['title']?.toString(),
      subtitle: step['instruction']?.toString(),
      footer: isActive
          ? SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => onBranch(nextTarget),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                ),
                child: Text(step['buttonText']?.toString() ?? 'Yola Devam Et'),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mevcut ustalik: %${masteryPercent.toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          Text('Secilen yol: ${_label(level)}'),
        ],
      ),
    );
  }

  String _label(String level) {
    switch (level) {
      case 'hard':
        return 'Zor Pekistirme';
      case 'medium':
        return 'Orta Pekistirme';
      default:
        return 'Temel Pekistirme';
    }
  }
}
