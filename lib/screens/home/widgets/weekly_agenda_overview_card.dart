import 'package:flutter/material.dart';

class WeeklyAgendaOverviewCard extends StatelessWidget {
  final List<Map<String, dynamic>> agendaData;
  final int currentWeek;
  final VoidCallback onContinueTap;

  const WeeklyAgendaOverviewCard({
    super.key,
    required this.agendaData,
    required this.currentWeek,
    required this.onContinueTap,
  });

  @override
  Widget build(BuildContext context) {
    final totalLessons = agendaData.length;
    final completedLessons = agendaData
        .where((item) => ((item['progress_percentage'] as num? ?? 0) >= 100))
        .length;
    final remainingLessons = totalLessons - completedLessons;
    final totalUnsolved = agendaData.fold<int>(
      0,
      (sum, item) => sum + ((item['unsolved_count'] as num? ?? 0).toInt()),
    );
    final bool weekCompleted = totalLessons > 0 && remainingLessons == 0;

    final weakestLessons =
        agendaData.map((item) => Map<String, dynamic>.from(item)).toList()
          ..sort((a, b) {
            final aUnsolved = (a['unsolved_count'] as num? ?? 0).toInt();
            final bUnsolved = (b['unsolved_count'] as num? ?? 0).toInt();
            final byUnsolved = bUnsolved.compareTo(aUnsolved);
            if (byUnsolved != 0) return byUnsolved;
            final aProgress = (a['progress_percentage'] as num? ?? 0)
                .toDouble();
            final bProgress = (b['progress_percentage'] as num? ?? 0)
                .toDouble();
            return aProgress.compareTo(bProgress);
          });

    final focusLessons = weakestLessons
        .where((item) => ((item['progress_percentage'] as num? ?? 0) < 100))
        .take(3)
        .toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2F6FE4), Color(0xFF4F8BFF)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F6FE4).withValues(alpha: 0.34),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$currentWeek. Hafta Ozeti',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              if (weekCompleted)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.94, end: 1.06),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeInOut,
                  builder: (context, scale, child) {
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Text(
                      'Hafta Bitti',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _statChip('Ders', '$totalLessons'),
              _statChip('Tamamlanan', '$completedLessons'),
              _statChip('Kalan', '$remainingLessons'),
              _statChip('Eksik Soru', '$totalUnsolved'),
            ],
          ),
          if (focusLessons.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Odaklanman gereken dersler:',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 8),
            ...focusLessons.map((item) {
              final lessonName = (item['lesson_name'] as String? ?? 'Ders')
                  .trim();
              final unsolved = (item['unsolved_count'] as num? ?? 0).toInt();
              final progress =
                  ((item['progress_percentage'] as num? ?? 0).toDouble())
                      .toStringAsFixed(0);
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '• $lessonName  ($progress% • $unsolved eksik)',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: agendaData.isEmpty ? null : onContinueTap,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1D4ED8),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text(
                'Eksiklerden Devam Et',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
