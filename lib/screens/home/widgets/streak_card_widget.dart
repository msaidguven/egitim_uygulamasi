import 'package:flutter/material.dart';

class StreakCardWidget extends StatelessWidget {
  final int streakCount;
  final int dailyGoal;
  final int currentProgress;

  const StreakCardWidget({
    super.key,
    required this.streakCount,
    required this.dailyGoal,
    required this.currentProgress,
  });

  @override
  Widget build(BuildContext context) {
    const Color textPrimaryColor = Color(0xFF1E293B);
    const Color textSecondaryColor = Color(0xFF64748B);
    final bool goalReached = currentProgress >= dailyGoal;
    final Color warningColor = goalReached
        ? const Color(0xFF16A34A)
        : const Color(0xFFF59E0B);
    final double progressPercentage = (currentProgress / dailyGoal).clamp(
      0.0,
      1.0,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFFFF7EC), Color(0xFFFFFAF3)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9800).withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
        border: Border.all(color: const Color(0xFFFFE2BC)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -16,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFD59B).withValues(alpha: 0.28),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -16,
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFE7C4).withValues(alpha: 0.5),
              ),
            ),
          ),
          Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Günlük Seri',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: textSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '$streakCount',
                              style: const TextStyle(
                                fontSize: 27,
                                fontWeight: FontWeight.w900,
                                color: textPrimaryColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text('🔥', style: TextStyle(fontSize: 20)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Gün üst üste çalışma',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: textSecondaryColor,
                          ),
                        ),
                        if (streakCount >= 3) ...[
                          const SizedBox(height: 6),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.95, end: 1.05),
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.easeInOut,
                            builder: (context, scale, child) {
                              return Transform.scale(
                                scale: scale,
                                child: child,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: warningColor.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: warningColor.withValues(alpha: 0.28),
                                ),
                              ),
                              child: Text(
                                streakCount >= 7
                                    ? 'Roket Seri'
                                    : 'Seri Başladı',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: warningColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          warningColor.withValues(alpha: 0.16),
                          warningColor.withValues(alpha: 0.28),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.local_fire_department_rounded,
                      color: warningColor,
                      size: 25,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Günlük hedef',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: textPrimaryColor,
                    ),
                  ),
                  Text(
                    '$currentProgress / $dailyGoal soru',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: warningColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progressPercentage,
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFFF59E0B),
                  ),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
