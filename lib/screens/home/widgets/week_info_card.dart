// lib/screens/home/widgets/week_info_card.dart

import 'package:egitim_uygulamasi/models/profile_model.dart';
import 'package:egitim_uygulamasi/utils/date_utils.dart';
import 'package:flutter/material.dart';

class WeekInfoCard extends StatelessWidget {
  final Profile? profile;
  final List<Map<String, dynamic>>? agendaData;
  final int completedLessons;

  const WeekInfoCard({
    super.key,
    required this.profile,
    this.agendaData,
    required this.completedLessons,
  });

  @override
  Widget build(BuildContext context) {
    // CSS variables mapping
    const Color primaryColor = Color(0xFF6366F1);
    const Color textPrimaryColor = Color(0xFF1E293B);
    const Color textSecondaryColor = Color(0xFF64748B);

    final periodInfo = getCurrentPeriodInfo();
    final currentWeek = calculateCurrentAcademicWeek();
    final (startDate, endDate) = getWeekDateRangeForAcademicWeek(currentWeek);
    final dateRangeText =
        '${startDate.day} ${aylar[startDate.month - 1]} - ${endDate.day} ${aylar[endDate.month - 1]} ${endDate.year}';

    final int totalLessons = agendaData?.length ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF3F7FF)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFD9E7FF)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor.withValues(alpha: 0.12),
                  primaryColor.withValues(alpha: 0.22),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(
                Icons.calendar_today_rounded,
                color: primaryColor,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  periodInfo.displayTitle,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateRangeText,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    color: textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusChip(
                      label: 'Tamamlanan',
                      value: '$completedLessons',
                      color: const Color(0xFF16A34A),
                    ),
                    _StatusChip(
                      label: 'Toplam Ders',
                      value: '$totalLessons',
                      color: const Color(0xFF2563EB),
                    ),
                    if (profile == null)
                      const _StatusChip(
                        label: 'Hesap',
                        value: 'Misafir',
                        color: Color(0xFFF59E0B),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatusChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
