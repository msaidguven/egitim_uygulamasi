import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:egitim_uygulamasi/features/test/data/models/test_question.dart';
import 'package:egitim_uygulamasi/features/test/presentation/views/questions_screen.dart';
import 'package:egitim_uygulamasi/models/question_model.dart';
import 'package:egitim_uygulamasi/viewmodels/outcomes_viewmodel.dart';

class WeeklyTestView extends ConsumerWidget {
  final int unitId;
  final int curriculumWeek;
  final int? topicId;
  final List<int> selectedOutcomeIds;
  final OutcomesViewModelArgs args;
  final bool isGuest;
  final Future<List<Question>> Function()? guestQuestionLoader;

  const WeeklyTestView({
    Key? key,
    required this.unitId,
    required this.curriculumWeek,
    this.topicId,
    this.selectedOutcomeIds = const [],
    required this.args,
    this.isGuest = false,
    this.guestQuestionLoader,
  }) : super(key: key);

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

    final solvedUnique = isGuest ? 0 : stats?['solved_unique'] ?? 0;
    final activeSession = isGuest ? null : stats?['active_session'];

    String buttonText;
    final IconData buttonIcon;
    final Color buttonColor;
    final VoidCallback onPressedAction;

    if (isGuest) {
      buttonText = 'Testi Başlat';
      buttonIcon = Icons.visibility_rounded;
      buttonColor = Colors.grey.shade600;
      onPressedAction = () {
        _startGuestTest(context);
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onPressedAction,
          icon: Icon(buttonIcon),
          label: Text(buttonText),
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  Future<void> _startGuestTest(BuildContext context) async {
    final loader = guestQuestionLoader;
    List<Question>? preloaded;
    if (loader != null) {
      preloaded = await loader();
      if (preloaded.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Misafir testi için soru alınamadı. Lütfen tekrar deneyin.'),
          ),
        );
        return;
      }
    }

    final Map<String, dynamic> routeArgs = {
      'curriculum_week': curriculumWeek,
    };
    if (topicId != null) routeArgs['topic_id'] = topicId;
    if (selectedOutcomeIds.isNotEmpty) {
      routeArgs['outcome_ids'] = selectedOutcomeIds;
    }
    if (preloaded != null) {
      routeArgs['preloaded_questions'] = preloaded;
    }

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
  }
}

// Stats chips removed per request.
