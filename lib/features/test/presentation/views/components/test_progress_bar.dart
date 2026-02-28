import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TestProgressBar extends StatelessWidget {
  final int currentQuestion;
  final int totalQuestions;
  final int score;
  final int incorrectCount;
  final int remainingSeconds;
  final int totalSeconds;
  final int currentStreak; // Yeni eklenen özellik

  const TestProgressBar({
    super.key,
    required this.currentQuestion,
    required this.totalQuestions,
    required this.score,
    required this.incorrectCount,
    required this.remainingSeconds,
    required this.totalSeconds,
    this.currentStreak = 0,
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
              
              // Araya Streak (Seri) Göstergesi Giriyor
              if (currentStreak > 1)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange.shade400, Colors.deepOrange],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        Text(
                          '$currentStreak Combo!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ).animate(key: ValueKey(currentStreak)) // Değer değiştikçe animasyon yenilenir
                    .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.1, 1.1), curve: Curves.elasticOut, duration: 600.ms)
                    .then()
                    .scale(begin: const Offset(1.1, 1.1), end: const Offset(1, 1), curve: Curves.easeOut, duration: 200.ms),
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
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isNarrow ? 8 : 12,
                  vertical: isNarrow ? 4 : 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 14, color: Colors.green.shade400),
                    const SizedBox(width: 4),
                    Text(
                      '$score',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isNarrow ? 14 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.cancel, size: 14, color: Colors.red.shade400),
                    const SizedBox(width: 4),
                    Text(
                      '$incorrectCount',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isNarrow ? 14 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (totalQuestions > 0)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: currentQuestion / totalQuestions,
                minHeight: 8,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
              ),
            ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progressValue.clamp(0.0, 1.0),
              minHeight: 4, // Zaman bari daha ince
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                isCritical ? Colors.redAccent : Colors.lightBlueAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
