import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MasteryOverviewStep extends StatelessWidget {
  final Map<String, dynamic> step;
  final int earnedPoints;
  final int maxPoints;
  final VoidCallback onComplete;

  const MasteryOverviewStep({
    super.key,
    required this.step,
    required this.earnedPoints,
    required this.maxPoints,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final percent = maxPoints == 0
        ? 0
        : ((earnedPoints / maxPoints) * 100).round();
    final badge = _badge(percent);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF4F46E5)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.military_tech_rounded,
            color: Colors.amber,
            size: 72,
          ),
          const SizedBox(height: 12),
          Text(
            step['title']?.toString() ?? 'Ustalik Sonucu',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Puan: $earnedPoints / $maxPoints',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ustalik: %$percent',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 10),
          Chip(
            label: Text(
              badge,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: onComplete,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF3730A3),
            ),
            child: Text(step['buttonText']?.toString() ?? 'Bitir'),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 320.ms).scale();
  }

  String _badge(int percent) {
    if (percent >= 90) return 'Altin Rozet';
    if (percent >= 75) return 'Gumus Rozet';
    if (percent >= 55) return 'Bronz Rozet';
    return 'Baslangic Rozeti';
  }
}
