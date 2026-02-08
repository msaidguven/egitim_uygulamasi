import 'package:flutter/material.dart';

class TestProgressBar extends StatelessWidget {
  final int currentQuestion;
  final int totalQuestions;
  final int score;

  const TestProgressBar({
    super.key,
    required this.currentQuestion,
    required this.totalQuestions,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final bool isNarrow = MediaQuery.of(context).size.width < 700;

    return Padding(
      padding: EdgeInsets.all(isNarrow ? 12.0 : 16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Soru $currentQuestion/$totalQuestions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isNarrow ? 14 : 16,
                ),
              ),
              Text(
                'Puan: $score',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isNarrow ? 14 : 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (totalQuestions > 0)
            LinearProgressIndicator(
              value: currentQuestion / totalQuestions,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              borderRadius: BorderRadius.circular(8),
            ),
        ],
      ),
    );
  }
}
