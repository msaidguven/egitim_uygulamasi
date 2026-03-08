import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SummaryStep extends StatelessWidget {
  final Map<String, dynamic> step;
  final VoidCallback onComplete;

  const SummaryStep({super.key, required this.step, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    final keywords =
        (step['keywords'] as List?)?.map((e) => e.toString()).toList() ??
        const <String>[];

    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.emoji_events_rounded,
            color: Color(0xFFFBBF24),
            size: 100,
          ).animate().scale(duration: 1.seconds, curve: Curves.bounceOut),
          const SizedBox(height: 20),
          Text(
            step['title']?.toString() ?? 'Tebrikler!',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            step['content']?.toString() ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              height: 1.5,
            ),
          ),
          if (keywords.isNotEmpty) ...[
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              children: keywords
                  .map(
                    (k) => Chip(
                      label: Text(
                        k,
                        style: const TextStyle(
                          color: Color(0xFF4F46E5),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: onComplete,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF4F46E5),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              step['buttonText']?.toString() ?? 'Bitir',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms).scale();
  }
}
