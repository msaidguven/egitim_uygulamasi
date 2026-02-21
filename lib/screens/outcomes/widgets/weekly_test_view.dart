import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:egitim_uygulamasi/features/test/presentation/views/questions_screen.dart';
import 'package:egitim_uygulamasi/features/test/data/models/test_question.dart';
import 'package:egitim_uygulamasi/viewmodels/outcomes_viewmodel.dart';

class WeeklyTestView extends ConsumerWidget {
  final int unitId;
  final int curriculumWeek;
  final int? topicId;
  final List<int> selectedOutcomeIds;
  final OutcomesViewModelArgs args;
  final bool isGuest;

  const WeeklyTestView({
    Key? key,
    required this.unitId,
    required this.curriculumWeek,
    this.topicId,
    this.selectedOutcomeIds = const [],
    required this.args,
    this.isGuest = false,
  }) : super(key: key);

  Widget _buildCompletionCard(BuildContext context, double successRate) {
    final level = SuccessLevel.fromRate(successRate);

    return Container(
      decoration: BoxDecoration(
        color: level.color.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: level.color.withAlpha(50), width: 1),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(level.icon, size: 32, color: level.color),
          const SizedBox(height: 12),
          Text(
            level.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: level.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            level.message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
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
    final onRefresh = ref
        .read(outcomesViewModelProvider(args))
        .refreshCurrentWeekData;

    if (stats == null && !isGuest) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    final totalQuestions = isGuest ? 10 : stats?['total_questions'] ?? 0;
    final solvedUnique = isGuest ? 0 : stats?['solved_unique'] ?? 0;
    final correctCount = isGuest ? 0 : stats?['correct_count'] ?? 0;
    final wrongCount = isGuest ? 0 : stats?['wrong_count'] ?? 0;
    final activeSession = isGuest ? null : stats?['active_session'];
    final allQuestionsSolved =
        totalQuestions > 0 && solvedUnique >= totalQuestions;

    final double progress = totalQuestions > 0
        ? solvedUnique / totalQuestions
        : 0.0;
    final double successRate = (correctCount + wrongCount) > 0
        ? correctCount / (correctCount + wrongCount)
        : 0.0;

    String buttonText;
    final IconData buttonIcon;
    final Color buttonColor;
    final VoidCallback onPressedAction;

    if (isGuest) {
      buttonText = 'Teste Göz At';
      buttonIcon = Icons.visibility_rounded;
      buttonColor = Colors.grey.shade600;
      onPressedAction = () {
        final routeArgs = topicId != null && selectedOutcomeIds.isNotEmpty
            ? {
                'curriculum_week': curriculumWeek,
                'topic_id': topicId,
                'outcome_ids': selectedOutcomeIds,
              }
            : curriculumWeek;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuestionsScreen(
              unitId: unitId,
              testMode: TestMode.weekly,
              sessionId: null,
            ),
            settings: RouteSettings(arguments: routeArgs),
          ),
        );
      };
    } else if (activeSession != null) {
      final answered = activeSession['answered_questions'] ?? 0;
      final total = activeSession['total_questions'] ?? 0;
      buttonText = 'Teste Devam Et ($answered/$total)';
      buttonIcon = Icons.play_arrow_rounded;
      buttonColor = Colors.green.shade600;
      onPressedAction = () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuestionsScreen(
              unitId: unitId,
              testMode: TestMode.weekly,
              sessionId: activeSession['id'],
            ),
          ),
        );
        onRefresh(curriculumWeek);
      };
    } else {
      buttonIcon = Icons.checklist_rtl_rounded;
      buttonColor = Colors.blue;
      if (solvedUnique == 0) {
        buttonText = 'Haftalık Teste Başla';
      } else {
        buttonText = 'Kalan Soruları Çöz';
      }
      onPressedAction = () async {
        final routeArgs = topicId != null && selectedOutcomeIds.isNotEmpty
            ? {
                'curriculum_week': curriculumWeek,
                'topic_id': topicId,
                'outcome_ids': selectedOutcomeIds,
              }
            : curriculumWeek;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuestionsScreen(
              unitId: unitId,
              testMode: TestMode.weekly,
              sessionId: null,
            ),
            settings: RouteSettings(arguments: routeArgs),
          ),
        );
        onRefresh(curriculumWeek);
      };
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Haftalık Pekiştirme Testi',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            if (isGuest)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'İlerlemenizin kaydedilmesi için giriş yapmalısınız.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ),
            const SizedBox(height: 16),
            if (totalQuestions > 0 || isGuest) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'İlerleme',
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                  ),
                  Text(
                    '$solvedUnique / $totalQuestions Soru',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.grey.shade200,
                color: Colors.blue,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _AppleStatChip(
                    label: 'Başarı',
                    value: '${(successRate * 100).toStringAsFixed(0)}%',
                    color: Colors.green,
                  ),
                  _AppleStatChip(
                    label: 'Doğru',
                    value: correctCount.toString(),
                    color: Colors.green,
                  ),
                  _AppleStatChip(
                    label: 'Yanlış',
                    value: wrongCount.toString(),
                    color: Colors.red,
                  ),
                ],
              ),
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Bu hafta için henüz pekiştirme sorusu eklenmemiş.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            const SizedBox(height: 20),
            if (totalQuestions > 0 || isGuest)
              if (allQuestionsSolved)
                _buildCompletionCard(context, successRate * 100)
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onPressedAction,
                    icon: Icon(buttonIcon),
                    label: Text(buttonText),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _AppleStatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AppleStatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 18,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
