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
    return getWeekDateRangeForAcademicWeek(curriculumWeek);
  }

  Widget _statPill({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
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

    final sections = (data['sections'] as List?)
            ?.whereType<Map>()
            .map((s) => Map<String, dynamic>.from(s))
            .toList() ??
        const <Map<String, dynamic>>[];
    final isMultiSectionWeek = sections.length > 1;
    final solved = isGuest ? 0 : stats?['solved_unique'] ?? 0;
    final total = isGuest ? 10 : stats?['total_questions'] ?? 0;
    final correctCount = isGuest ? 0 : stats?['correct_count'] ?? 0;
    final wrongCount = isGuest ? 0 : stats?['wrong_count'] ?? 0;
    final totalAnswered = correctCount + wrongCount;
    final successRate = totalAnswered > 0
        ? (correctCount / totalAnswered) * 100
        : 0.0;
    final level = SuccessLevel.fromRate(successRate);
    final progress = total > 0 ? (solved / total).clamp(0.0, 1.0) : 0.0;

    final (startDate, endDate) = _getWeekDateRange(curriculumWeek);
    final formattedStartDate = '${startDate.day} ${aylar[startDate.month - 1]}';
    final formattedEndDate =
        '${endDate.day} ${aylar[endDate.month - 1]} ${endDate.year}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF2F7FF)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD8E6FF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7CA5E8).withOpacity(0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
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
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isGuest ? 'Giriş Yapın' : level.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isGuest ? Colors.grey.shade600 : level.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
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
            ],
          ),
          const SizedBox(height: 14),
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
          if (!isGuest && totalAnswered > 0) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _statPill(
                  label: 'Doğru',
                  value: correctCount.toString(),
                  color: Colors.green.shade700,
                ),
                _statPill(
                  label: 'Yanlış',
                  value: wrongCount.toString(),
                  color: Colors.red.shade700,
                ),
                _statPill(
                  label: 'Başarı',
                  value: '${successRate.toStringAsFixed(0)}%',
                  color: level.color.shade700,
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          if (isMultiSectionWeek)
            _buildHierarchyRow(
              Icons.layers_outlined,
              'Bu hafta ${sections.length} farklı konu planlandı',
            ),
          if (!isMultiSectionWeek && data['unit_title'] != null)
            _buildHierarchyRow(
              Icons.folder_open_outlined,
              data['unit_title']!,
            ),
          if (!isMultiSectionWeek && data['topic_title'] != null)
            _buildHierarchyRow(
              Icons.article_outlined,
              data['topic_title']!,
            ),
        ],
      ),
    );
  }
}
