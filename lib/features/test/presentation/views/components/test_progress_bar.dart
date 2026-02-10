import 'package:flutter/material.dart';

class TestProgressBar extends StatelessWidget {
  final int currentQuestion;
  final int totalQuestions;
  final int score;
  final int remainingSeconds;
  final int totalSeconds;

  const TestProgressBar({
    super.key,
    required this.currentQuestion,
    required this.totalQuestions,
    required this.score,
    required this.remainingSeconds,
    required this.totalSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final bool isNarrow = MediaQuery.of(context).size.width < 700;
    final bool isCritical = remainingSeconds <= 5;
    final timerColor = isCritical ? Colors.redAccent : Colors.white;
    final timerBg = isCritical ? Colors.redAccent.withOpacity(0.2) : Colors.white.withOpacity(0.18);
    final progressValue = totalSeconds > 0 ? remainingSeconds / totalSeconds : 0.0;

    return Padding(
      padding: EdgeInsets.all(isNarrow ? 12.0 : 16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Soru $currentQuestion/$totalQuestions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isNarrow ? 14 : 16,
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: isNarrow ? 10 : 14,
                  vertical: isNarrow ? 6 : 8,
                ),
                decoration: BoxDecoration(
                  color: timerBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isCritical ? Colors.redAccent : Colors.white.withOpacity(0.3),
                  ),
                  boxShadow: isCritical
                      ? [
                          BoxShadow(
                            color: Colors.redAccent.withOpacity(0.6),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer, size: isNarrow ? 16 : 18, color: timerColor),
                    const SizedBox(width: 6),
                    Text(
                      '00:${remainingSeconds.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: timerColor,
                        fontSize: isNarrow ? 14 : 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
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
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progressValue.clamp(0.0, 1.0),
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              isCritical ? Colors.redAccent : Colors.lightBlueAccent,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      ),
    );
  }
}
