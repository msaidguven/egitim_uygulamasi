import 'dart:ui';
import 'package:flutter/material.dart';

final _lessonDetails = {
  1: {'icon': Icons.calculate_rounded, 'gradient': [Color(0xFFFF8A65), Color(0xFFFF5252)]},
  2: {'icon': Icons.translate_rounded, 'gradient': [Color(0xFF64B5F6), Color(0xFF42A5F5)]},
  3: {'icon': Icons.science_rounded, 'gradient': [Color(0xFF81C784), Color(0xFF66BB6A)]},
  4: {'icon': Icons.public_rounded, 'gradient': [Color(0xFFE57373), Color(0xFFEF5350)]},
  5: {'icon': Icons.gavel_rounded, 'gradient': [Color(0xFFBA68C8), Color(0xFFAB47BC)]},
  6: {'icon': Icons.language_rounded, 'gradient': [Color(0xFF4DB6AC), Color(0xFF26A69A)]},
};

class LessonCard extends StatelessWidget {
  final int lessonId;
  final String lessonName;
  final String? topicTitle;
  final int? curriculumWeek;
  final double progress;
  final double successRate;
  final VoidCallback onTap;
  final bool isNextStep;

  const LessonCard({
    super.key,
    required this.lessonId,
    required this.lessonName,
    this.topicTitle,
    this.curriculumWeek,
    required this.progress,
    required this.successRate,
    required this.onTap,
    this.isNextStep = false,
  });

  @override
  Widget build(BuildContext context) {
    final details = _lessonDetails[lessonId] ??
        {
          'icon': Icons.book_rounded,
          'gradient': [Colors.grey, Colors.blueGrey],
        };
    final gradient = details['gradient'] as List<Color>;
    final icon = details['icon'] as IconData;
    final score = ((progress * successRate) / 100).toInt();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 190,
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: gradient.last.withOpacity(0.4),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ÜST
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white.withOpacity(0.25),
                        child: Icon(icon, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isNextStep && curriculumWeek != null)
                              Text(
                                'Bu Hafta ($curriculumWeek. Hafta)',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            const SizedBox(height: 2),
                            Text(
                              isNextStep ? (topicTitle ?? lessonName) : lessonName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      _ScoreBadge(score: score),
                    ],
                  ),

                  const Spacer(),

                  // ORTA - Dairesel Progress
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatColumn(title: "İlerleme", value: "${progress.toInt()}%"),
                      _StatColumn(title: "Başarı", value: "${successRate.toInt()}%"),
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: progress / 100,
                              strokeWidth: 5,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              valueColor: const AlwaysStoppedAnimation(Colors.white),
                            ),
                            Center(
                              child: Text(
                                "${progress.toInt()}%",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final int score;
  const _ScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 16),
          const SizedBox(width: 4),
          Text(
            score.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String title;
  final String value;

  const _StatColumn({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
