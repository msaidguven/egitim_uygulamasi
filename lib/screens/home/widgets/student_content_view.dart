// lib/screens/home/widgets/student_content_view.dart

import 'package:egitim_uygulamasi/screens/home/models/home_models.dart';
import 'package:egitim_uygulamasi/screens/home/widgets/common_widgets.dart';
import 'package:egitim_uygulamasi/screens/outcomes/outcomes_screen_v2.dart';
import 'lesson_card.dart';
import 'package:flutter/material.dart';

class StudentContentView extends StatelessWidget {
  final List<Map<String, dynamic>>? agendaData;
  final List<Map<String, dynamic>>? nextStepsData;
  final int currentCurriculumWeek;
  final NextStepsDisplayState nextStepsState;
  final VoidCallback onToggleNextSteps;
  final VoidCallback onExpandNextSteps;
  final VoidCallback onRefresh;
  final ValueChanged<Map<String, dynamic>>? onLessonCardTap;

  const StudentContentView({
    super.key,
    this.agendaData,
    this.nextStepsData,
    required this.currentCurriculumWeek,
    required this.nextStepsState,
    required this.onToggleNextSteps,
    required this.onExpandNextSteps,
    required this.onRefresh,
    this.onLessonCardTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasNextSteps = nextStepsData != null && nextStepsData!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Bu Hafta', icon: Icons.today_outlined),
        const SizedBox(height: 16),
        _buildAgendaSection(context),
        if (hasNextSteps) ...[
          const SizedBox(height: 40),
          SectionHeader(
            title: 'Geçmiş Haftalar',
            icon: Icons.history_outlined,
            trailing: IconButton(
              onPressed: onToggleNextSteps,
              icon: Icon(
                nextStepsState == NextStepsDisplayState.expanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                color: Colors.grey.shade900,
                size: 24,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (nextStepsState != NextStepsDisplayState.hidden)
            _buildNextStepsSection(context),
        ],
        if (agendaData?.isEmpty ?? false) ...[
          const SizedBox(height: 40),
          const MotivationCard(),
        ],
      ],
    );
  }

  Widget _buildAgendaSection(BuildContext context) {
    if (agendaData == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (agendaData!.isEmpty) {
      return const EmptyState();
    }
    return _buildAgendaList(context, agendaData!);
  }

  Widget _buildAgendaList(
    BuildContext context,
    List<Map<String, dynamic>> data,
  ) {
    return Column(
      children: data.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: LessonCard(
            lessonId: item['lesson_id'] as int? ?? 0,
            lessonName: item['lesson_name'],
            topicTitle: item['topic_title'] ?? 'Konu Belirtilmemiş',
            gradeName: item['grade_name'], // Sınıf adı
            lessonIcon: item['lesson_icon'] as String?,
            progress: (item['progress_percentage'] ?? 0.0).toDouble(),
            successRate: (item['success_rate'] ?? 0.0).toDouble(),
            // İstatistikler
            totalQuestions: item['total_questions'] as int?,
            correctCount: item['correct_count'] as int?,
            wrongCount: item['wrong_count'] as int?,
            unsolvedCount: item['unsolved_count'] as int?,
            onTap: () {
              onLessonCardTap?.call(item);
              _navigateToOutcomes(context, item);
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNextStepsSection(BuildContext context) {
    if (nextStepsData == null) return const SizedBox.shrink();

    final displayData = nextStepsState == NextStepsDisplayState.expanded
        ? nextStepsData!
        : nextStepsData!.take(3).toList();

    final bool showMoreButton =
        nextStepsState == NextStepsDisplayState.collapsed &&
        nextStepsData!.length > 3;

    return Column(
      children: [
        ...displayData.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: LessonCard(
              lessonId: item['lesson_id'] as int? ?? 0,
              lessonName: item['lesson_name'],
              topicTitle: item['topic_title'] ?? 'Genel Tekrar',
              gradeName: item['grade_name'], // Sınıf adı
              curriculumWeek: item['curriculum_week'],
              lessonIcon: item['lesson_icon'] as String?,
              progress: (item['progress_percentage'] ?? 0.0).toDouble(),
              successRate: (item['success_rate'] ?? 0.0).toDouble(),
              // İstatistikler (Next steps için de varsa gösterilebilir)
              totalQuestions: item['total_questions'] as int?,
              correctCount: item['correct_count'] as int?,
              wrongCount: item['wrong_count'] as int?,
              unsolvedCount: item['unsolved_count'] as int?,
              onTap: () {
                onLessonCardTap?.call(item);
                _navigateToOutcomes(context, item);
              },
              isNextStep: true,
            ),
          );
        }),
        if (showMoreButton)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onExpandNextSteps,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Diğer ${nextStepsData!.length - 3} haftayı göster',
                        style: TextStyle(
                          color: Colors.grey.shade900,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.expand_more_rounded,
                        color: Colors.grey.shade900,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _navigateToOutcomes(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            OutcomesScreenV2(
              lessonId: data['lesson_id'],
              gradeId: data['grade_id'],
              lessonName: data['lesson_name'],
              gradeName: data['grade_name'],
              initialCurriculumWeek:
                  data['curriculum_week'] ?? currentCurriculumWeek,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          final tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          final offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );
    onRefresh();
  }
}
