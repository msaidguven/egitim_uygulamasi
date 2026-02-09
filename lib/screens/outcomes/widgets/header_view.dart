import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:egitim_uygulamasi/utils/date_utils.dart';
import 'package:egitim_uygulamasi/viewmodels/outcomes_viewmodel.dart';
import 'package:egitim_uygulamasi/viewmodels/profile_viewmodel.dart';

class HeaderView extends ConsumerWidget {
  final int curriculumWeek;
  final Map<String, dynamic> data;
  final OutcomesViewModelArgs args;

  const HeaderView({
    Key? key,
    required this.curriculumWeek,
    required this.data,
    required this.args,
  }) : super(key: key);

  (DateTime, DateTime) _getWeekDateRange(int curriculumWeek) {
    final now = DateTime.now();
    final schoolStart = getSchoolStartDate(now);
    int offsetInWeeks = 0;
    for (final breakInfo in academicBreaks) {
      if (curriculumWeek > breakInfo['after_week']) {
        offsetInWeeks += (breakInfo['weeks'] as List).length;
      }
    }
    final daysToAdd = ((curriculumWeek - 1) + offsetInWeeks) * 7;
    final weekStartDate = schoolStart.add(Duration(days: daysToAdd));
    final weekEndDate = weekStartDate.add(const Duration(days: 6));
    return (weekStartDate, weekEndDate);
  }

  Widget _buildStatusIndicator(
    BuildContext context,
    Map<String, dynamic>? stats,
    bool isGuest,
  ) {
    final solved = isGuest ? 0 : stats?['solved_unique'] ?? 0;
    final total = isGuest ? 10 : stats?['total_questions'] ?? 0;
    final correctCount = isGuest ? 0 : stats?['correct_count'] ?? 0;
    final wrongCount = isGuest ? 0 : stats?['wrong_count'] ?? 0;
    final totalAnswered = correctCount + wrongCount;
    final successRate = totalAnswered > 0
        ? (correctCount / totalAnswered) * 100
        : 0.0;

    if (total == 0 && !isGuest) return const SizedBox.shrink();

    final level = SuccessLevel.fromRate(successRate);
    final progress = total > 0 ? (solved / total).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isGuest ? 'Giriş Yapın' : level.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isGuest ? Colors.grey.shade600 : level.color,
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < (isGuest ? 0 : level.starCount)
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: Colors.amber.shade500,
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: isGuest ? 0.0 : progress,
            backgroundColor: Colors.grey.shade200,
            color: isGuest ? Colors.grey.shade400 : level.color,
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
          const SizedBox(height: 4),
          Text(
            isGuest
                ? 'İlerlemenizi görmek için giriş yapın'
                : '$solved/$total soru çözüldü',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildHierarchyRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(
      outcomesViewModelProvider(
        args,
      ).select((vm) => vm.getWeekStats(curriculumWeek)),
    );
    final isGuest = ref.watch(
      profileViewModelProvider.select((p) => p.profile == null),
    );

    final (startDate, endDate) = _getWeekDateRange(curriculumWeek);
    final formattedStartDate = '${startDate.day} ${aylar[startDate.month - 1]}';
    final formattedEndDate =
        '${endDate.day} ${aylar[endDate.month - 1]} ${endDate.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$curriculumWeek. Hafta',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$formattedStartDate - $formattedEndDate',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 20),
              if (data['unit_title'] != null)
                _buildHierarchyRow(
                  Icons.folder_open_outlined,
                  data['unit_title']!,
                ),
              if (data['topic_title'] != null)
                _buildHierarchyRow(
                  Icons.article_outlined,
                  data['topic_title']!,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildStatusIndicator(context, stats, isGuest),
      ],
    );
  }
}
