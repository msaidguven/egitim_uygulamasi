import 'package:dots_indicator/dots_indicator.dart';
import 'package:egitim_uygulamasi/models/question_model.dart';
import 'package:egitim_uygulamasi/features/test/presentation/views/questions_screen.dart';
import 'package:egitim_uygulamasi/screens/unit_summary_screen.dart';
import 'package:egitim_uygulamasi/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_table/flutter_html_table.dart';
import 'package:egitim_uygulamasi/models/topic_content.dart';
import 'package:egitim_uygulamasi/utils/html_style.dart';
import 'package:provider/provider.dart';
import 'package:egitim_uygulamasi/screens/outcomes/outcomes_viewmodel.dart';
import 'package:egitim_uygulamasi/features/test/data/models/test_question.dart';

class OutcomesScreen extends StatelessWidget {
  final int lessonId;
  final int gradeId;
  final String gradeName;
  final String lessonName;
  final int? initialCurriculumWeek;

  const OutcomesScreen({
    super.key,
    required this.lessonId,
    required this.gradeId,
    required this.gradeName,
    required this.lessonName,
    this.initialCurriculumWeek,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OutcomesViewModel(
        lessonId: lessonId,
        gradeId: gradeId,
        initialCurriculumWeek: initialCurriculumWeek,
      ),
      child: Consumer<OutcomesViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            backgroundColor: Colors.grey.shade50,
            appBar: _AppleStyleAppBar(
              title: lessonName,
              backgroundColor: Colors.white,
            ),
            body: viewModel.isLoadingWeeks
                ? const Center(
              child: CircularProgressIndicator.adaptive(),
            )
                : viewModel.hasErrorWeeks
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Hata: ${viewModel.weeksErrorMessage}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
                : viewModel.allWeeksData.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bu derse ait hafta bulunamadı.',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
                : PageView.builder(
              controller: viewModel.pageController,
              itemCount: viewModel.allWeeksData.length,
              onPageChanged: viewModel.onPageChanged,
              itemBuilder: (context, index) {
                final weekData = viewModel.allWeeksData[index];
                if (weekData['type'] == 'social_activity') {
                  return _AppleStyleSocialActivityCard(
                    title: weekData['title'],
                  );
                }
                if (weekData['type'] == 'break') {
                  return _AppleStyleBreakCard(
                    title: weekData['title'],
                    duration: weekData['duration'],
                  );
                }
                if (weekData['type'] == 'special_content') {
                  return _AppleStyleSpecialContentCard(
                    title: weekData['title'],
                    content: weekData['content'],
                    icon: weekData['icon'],
                  );
                }

                final curriculumWeek = weekData['curriculum_week'];
                if (curriculumWeek == null) {
                  return _ErrorCard(
                    errorMessage: 'Hafta verisi bozuk',
                  );
                }

                return WeekContentView(
                  key: ValueKey(curriculumWeek),
                  curriculumWeek: curriculumWeek as int,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _AppleStyleAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color backgroundColor;

  const _AppleStyleAppBar({
    required this.title,
    required this.backgroundColor,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
      ),
      backgroundColor: backgroundColor,
      foregroundColor: Colors.black,
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 1,
      surfaceTintColor: Colors.transparent,
      shape: const Border(
        bottom: BorderSide(
          color: Color(0xFFE5E5EA),
          width: 0.5,
        ),
      ),
    );
  }
}

class WeekContentView extends StatefulWidget {
  final int curriculumWeek;

  const WeekContentView({
    super.key,
    required this.curriculumWeek,
  });

  @override
  State<WeekContentView> createState() => _WeekContentViewState();
}

class _WeekContentViewState extends State<WeekContentView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final viewModel = Provider.of<OutcomesViewModel>(context, listen: false);
        final index = viewModel.allWeeksData.indexWhere((w) => w['curriculum_week'] == widget.curriculumWeek);
        if (index != -1) {
          if (viewModel.pageController.page?.round() == index) {
            viewModel.onPageChanged(index);
          }
        }
      }
    });
  }

  (DateTime, DateTime) _getWeekDateRange(int curriculumWeek) {
    final schoolStart = DateTime(
      DateTime.now().month < 9 ? DateTime.now().year - 1 : DateTime.now().year,
      9,
      8,
    );
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

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Selector<OutcomesViewModel, _WeekDataSnapshot>(
      selector: (_, viewModel) => _WeekDataSnapshot(
        isLoading: viewModel.isWeekLoading(widget.curriculumWeek),
        error: viewModel.getWeekError(widget.curriculumWeek),
        data: viewModel.getWeekContent(widget.curriculumWeek),
        questions: viewModel.getWeekQuestions(widget.curriculumWeek),
        weeklyStats: viewModel.getWeekStats(widget.curriculumWeek),
        unitId: viewModel.getWeekUnitId(widget.curriculumWeek),
      ),
      builder: (context, snapshot, _) {
        final viewModel = context.read<OutcomesViewModel>();
        final user = Supabase.instance.client.auth.currentUser;
        final isGuest = user == null;

        if (snapshot.isLoading && snapshot.data == null) {
          return const Center(
            child: CircularProgressIndicator.adaptive(),
          );
        }

        if (snapshot.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Hata: ${snapshot.error}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.data == null || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  '${widget.curriculumWeek}. hafta için içerik bulunamadı.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data!;
        final (startDate, endDate) = _getWeekDateRange(widget.curriculumWeek);
        final contents = (data['contents'] as List? ?? [])
            .map((c) => TopicContent.fromJson(c as Map<String, dynamic>))
            .toList();

        final isLastWeek = data['is_last_week_of_unit'] ?? false;
        final unitSummary = data['unit_summary'];
        final unitId = snapshot.unitId ?? data['unit_id'];

        return RefreshIndicator.adaptive(
          onRefresh: () async =>
              viewModel.refreshCurrentWeekData(widget.curriculumWeek),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AppleWeekHeader(
                        curriculumWeek: widget.curriculumWeek,
                        startDate: startDate,
                        endDate: endDate,
                        unitTitle: data['unit_title'],
                        topicTitle: data['topic_title'],
                        stats: snapshot.weeklyStats,
                        isGuest: isGuest,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              if ((data['outcomes'] as List).isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: _AppleCollapsibleCard(
                      icon: Icons.flag_outlined,
                      title: 'Öğrenme Çıktıları',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: (data['outcomes'] as List)
                            .map((outcome) => _AppleOutcomeTile(
                          text: outcome as String,
                        ))
                            .toList(),
                      ),
                    ),
                  ),
                ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        index == 0 ? 12 : 0,
                        20,
                        12,
                      ),
                      child: _AppleContentCard(
                        content: contents[index],
                      ),
                    );
                  },
                  childCount: contents.length,
                ),
              ),
              if (snapshot.questions != null && snapshot.questions!.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: _AppleMiniQuiz(
                      key: ValueKey(widget.curriculumWeek),
                      questions: snapshot.questions!,
                    ),
                  ),
                ),
              if (unitId != null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: _AppleWeeklySummaryCard(
                      stats: snapshot.weeklyStats,
                      unitId: unitId,
                      curriculumWeek: widget.curriculumWeek,
                      onRefresh: () =>
                          viewModel.refreshCurrentWeekData(widget.curriculumWeek),
                      isGuest: isGuest,
                    ),
                  ),
                ),
              if (isLastWeek && unitSummary != null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  sliver: SliverToBoxAdapter(
                    child: _AppleUnitCompletionCard(
                      unitSummary: unitSummary,
                      unitId: data['unit_id'],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _WeekDataSnapshot {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? data;
  final List<Question>? questions;
  final Map<String, dynamic>? weeklyStats;
  final int? unitId;

  _WeekDataSnapshot({
    required this.isLoading,
    this.error,
    this.data,
    this.questions,
    this.weeklyStats,
    this.unitId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _WeekDataSnapshot &&
          runtimeType == other.runtimeType &&
          isLoading == other.isLoading &&
          error == other.error &&
          data == other.data &&
          questions == other.questions &&
          weeklyStats == other.weeklyStats &&
          unitId == other.unitId;

  @override
  int get hashCode =>
      isLoading.hashCode ^
      error.hashCode ^
      data.hashCode ^
      questions.hashCode ^
      weeklyStats.hashCode ^
      unitId.hashCode;
}


class _AppleWeekHeader extends StatelessWidget {
  final int curriculumWeek;
  final DateTime startDate;
  final DateTime endDate;
  final String? unitTitle;
  final String? topicTitle;
  final Map<String, dynamic>? stats;
  final bool isGuest;

  const _AppleWeekHeader({
    required this.curriculumWeek,
    required this.startDate,
    required this.endDate,
    this.unitTitle,
    this.topicTitle,
    this.stats,
    this.isGuest = false,
  });

  Widget _buildStatusIndicator(BuildContext context) {
    final solved = isGuest ? 0 : stats?['solved_unique'] ?? 0;
    final total = isGuest ? 10 : stats?['total_questions'] ?? 0;
    final correctCount = isGuest ? 0 : stats?['correct_count'] ?? 0;
    final wrongCount = isGuest ? 0 : stats?['wrong_count'] ?? 0;
    final totalAnswered = correctCount + wrongCount;
    final successRate =
    totalAnswered > 0 ? (correctCount / totalAnswered) * 100 : 0.0;

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
            isGuest ? 'İlerlemenizi görmek için giriş yapın' : '$solved/$total soru çözüldü',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              if (unitTitle != null) _buildHierarchyRow(Icons.folder_open_outlined, unitTitle!),
              if (topicTitle != null) _buildHierarchyRow(Icons.article_outlined, topicTitle!),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildStatusIndicator(context),
      ],
    );
  }

  Widget _buildHierarchyRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.blue,
            size: 20,
          ),
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
}

class _AppleCollapsibleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _AppleCollapsibleCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
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
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        leading: Icon(
          icon,
          color: Colors.blue,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _AppleOutcomeTile extends StatelessWidget {
  final String text;

  const _AppleOutcomeTile({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: Colors.green.shade500,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppleContentCard extends StatelessWidget {
  final TopicContent content;

  const _AppleContentCard({required this.content});

  @override
  Widget build(BuildContext context) {
    final newStyle = Map<String, Style>.from(getBaseHtmlStyle(context));
    newStyle['body'] = Style(
      fontSize: FontSize(15),
      lineHeight: const LineHeight(1.6),
    );

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
            Row(
              children: [
                const Icon(
                  Icons.article_rounded,
                  color: Colors.blue,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    content.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 1,
              color: Colors.grey.shade200,
            ),
            const SizedBox(height: 16),
            Html(
              data: content.content,
              extensions: const [TableHtmlExtension()],
              style: newStyle,
            ),
          ],
        ),
      ),
    );
  }
}

class _AppleMiniQuiz extends StatefulWidget {
  final List<Question> questions;

  const _AppleMiniQuiz({super.key, required this.questions});

  @override
  State<_AppleMiniQuiz> createState() => _AppleMiniQuizState();
}

class _AppleMiniQuizState extends State<_AppleMiniQuiz> {
  final PageController _pageController = PageController();
  Map<int, int?> _selectedChoiceIds = {};
  Map<int, bool?> _results = {};
  int _currentPage = 0;
  _MiniQuizState _quizState = _MiniQuizState.notStarted;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      if (_pageController.page?.round() != _currentPage) {
        setState(() {
          _currentPage = _pageController.page!.round();
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _checkAnswer(Question question, int choiceId) {
    QuestionChoice? correctChoice;
    for (final choice in question.choices) {
      if (choice.isCorrect) {
        correctChoice = choice;
        break;
      }
    }
    setState(() {
      _selectedChoiceIds[question.id] = choiceId;
      _results[question.id] = (correctChoice?.id == choiceId);
      if (_results.length == widget.questions.length) {
        _quizState = _MiniQuizState.finished;
      }
    });
  }

  void _startQuiz() {
    setState(() {
      _quizState = _MiniQuizState.inProgress;
    });
  }

  void _resetQuiz() {
    setState(() {
      _selectedChoiceIds = {};
      _results = {};
      _currentPage = 0;
      _quizState = _MiniQuizState.notStarted;
      _pageController.jumpToPage(0);
    });
  }

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_rounded,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Anladım mı? Kendini Sına!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildCurrentStateWidget(),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStateWidget() {
    switch (_quizState) {
      case _MiniQuizState.notStarted:
        return _AppleQuizStartCard(
          key: const ValueKey('start'),
          onStart: _startQuiz,
        );
      case _MiniQuizState.inProgress:
        return _AppleQuizContent(
          key: const ValueKey('content'),
          pageController: _pageController,
          questions: widget.questions,
          results: _results,
          selectedChoiceIds: _selectedChoiceIds,
          currentPage: _currentPage,
          onAnswer: _checkAnswer,
        );
      case _MiniQuizState.finished:
        return _AppleQuizResults(
          key: const ValueKey('results'),
          results: _results,
          totalQuestions: widget.questions.length,
          onRetry: _resetQuiz,
        );
    }
  }
}

class _AppleQuizStartCard extends StatelessWidget {
  final VoidCallback onStart;

  const _AppleQuizStartCard({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.quiz_rounded,
            size: 56,
            color: Colors.orange.shade700,
          ),
          const SizedBox(height: 20),
          const Text(
            'Konuyu Pekiştir',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '5 soruluk mini test ile konuyu ne kadar anladığını ölç',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Testi Başlat',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppleQuizContent extends StatelessWidget {
  final PageController pageController;
  final List<Question> questions;
  final Map<int, bool?> results;
  final Map<int, int?> selectedChoiceIds;
  final int currentPage;
  final Function(Question, int) onAnswer;

  const _AppleQuizContent({
    super.key,
    required this.pageController,
    required this.questions,
    required this.results,
    required this.selectedChoiceIds,
    required this.currentPage,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 350,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: pageController,
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final question = questions[index];
                final isChecked = results.containsKey(question.id);
                final selectedChoiceId = selectedChoiceIds[question.id];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'Soru ${index + 1}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      question.text,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView.separated(
                        itemCount: question.choices.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, choiceIndex) {
                          final choice = question.choices[choiceIndex];
                          bool isSelected = (selectedChoiceId == choice.id);

                          Widget buildChoice() {
                            if (isChecked) {
                              if (choice.isCorrect) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.green.shade200,
                                      width: 1.5,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          choice.text,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.check_circle_rounded,
                                        color: Colors.green.shade600,
                                      ),
                                    ],
                                  ),
                                );
                              } else if (isSelected) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.red.shade200,
                                      width: 1.5,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          choice.text,
                                          style: const TextStyle(
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.cancel_rounded,
                                        color: Colors.red.shade600,
                                      ),
                                    ],
                                  ),
                                );
                              }
                            }

                            return GestureDetector(
                              onTap: isChecked ? null : () => onAnswer(question, choice.id),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.blue.shade50 : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.blue.shade300
                                        : Colors.grey.shade300,
                                    width: 1.5,
                                  ),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  choice.text,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          }

                          return buildChoice();
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: DotsIndicator(
              dotsCount: questions.length,
              position: currentPage,
              decorator: DotsDecorator(
                activeColor: Colors.blue,
                color: Colors.grey.shade300,
                size: const Size.square(8.0),
                activeSize: const Size(24.0, 8.0),
                activeShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppleQuizResults extends StatelessWidget {
  final Map<int, bool?> results;
  final int totalQuestions;
  final VoidCallback onRetry;

  const _AppleQuizResults({
    super.key,
    required this.results,
    required this.totalQuestions,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final correctAnswers = results.values.where((r) => r == true).length;
    final successRate =
    totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0.0;

    Color getColor() {
      if (successRate == 100) return Colors.green;
      if (successRate >= 60) return Colors.blue;
      return Colors.orange;
    }

    String getMessage() {
      if (successRate == 100) return 'Mükemmel! Tamamı doğru.';
      if (successRate >= 60) return 'Çok iyi! Konuyu anlamışsın.';
      return 'Tekrar denemekte fayda var.';
    }

    final color = getColor();
    final message = getMessage();

    return Container(
      height: 300,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            successRate == 100
                ? Icons.celebration_rounded
                : successRate >= 60
                ? Icons.thumb_up_rounded
                : Icons.refresh_rounded,
            size: 56,
            color: color,
          ),
          const SizedBox(height: 20),
          Text(
            '$totalQuestions sorudan $correctAnswers tanesini doğru cevapladın.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '(${successRate.toStringAsFixed(0)}% başarı)',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Tekrar Dene',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppleWeeklySummaryCard extends StatelessWidget {
  final Map<String, dynamic>? stats;
  final int unitId;
  final int curriculumWeek;
  final VoidCallback onRefresh;
  final bool isGuest;

  const _AppleWeeklySummaryCard({
    required this.stats,
    required this.unitId,
    required this.curriculumWeek,
    required this.onRefresh,
    this.isGuest = false,
  });

  Widget _buildCompletionCard(BuildContext context, double successRate) {
    final level = SuccessLevel.fromRate(successRate);

    return Container(
      decoration: BoxDecoration(
        color: level.color.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: level.color.withAlpha(50),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            level.icon,
            size: 32,
            color: level.color,
          ),
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
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (stats == null && !isGuest) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator.adaptive(),
        ),
      );
    }

    final totalQuestions = isGuest ? 10 : stats?['total_questions'] ?? 0;
    final solvedUnique = isGuest ? 0 : stats?['solved_unique'] ?? 0;
    final correctCount = isGuest ? 0 : stats?['correct_count'] ?? 0;
    final wrongCount = isGuest ? 0 : stats?['wrong_count'] ?? 0;
    final activeSession = isGuest ? null : stats?['active_session'];
    final allQuestionsSolved = totalQuestions > 0 && solvedUnique >= totalQuestions;

    final double progress =
    totalQuestions > 0 ? solvedUnique / totalQuestions : 0.0;
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuestionsScreen(
              unitId: unitId,
              testMode: TestMode.weekly,
              sessionId: null, // Misafir için sessionId null olmalı
            ),
            settings: RouteSettings(
              arguments: curriculumWeek,
            ),
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
        onRefresh();
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
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuestionsScreen(
              unitId: unitId,
              testMode: TestMode.weekly,
              sessionId: null,
            ),
            settings: RouteSettings(
              arguments: curriculumWeek,
            ),
          ),
        );
        onRefresh();
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
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
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
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                    ),
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
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
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
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
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

class _AppleUnitCompletionCard extends StatelessWidget {
  final Map<String, dynamic> unitSummary;
  final int unitId;

  const _AppleUnitCompletionCard({
    required this.unitSummary,
    required this.unitId,
  });

  @override
  Widget build(BuildContext context) {
    final totalQuestions = unitSummary['total_questions'] ?? 0;
    final uniqueSolved = unitSummary['unique_solved_count'] ?? 0;
    final progress = totalQuestions > 0 ? uniqueSolved / totalQuestions : 0.0;
    final clampedProgress = progress.clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepPurple.shade50,
            Colors.blue.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.deepPurple.shade100,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.military_tech_rounded,
              size: 40,
              color: Colors.deepPurple.shade600,
            ),
            const SizedBox(height: 16),
            Text(
              'Ünite Bitiş Çizgisi',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.deepPurple.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tebrikler! Bu ünitenin sonuna geldin. Genel bir tekrar yapmaya ne dersin?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.deepPurple.shade700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ünite İlerlemen',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.deepPurple.shade600,
                  ),
                ),
                Text(
                  '$uniqueSolved / $totalQuestions Soru',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: clampedProgress,
              backgroundColor: Colors.deepPurple.shade100,
              color: Colors.deepPurple,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UnitSummaryScreen(unitId: unitId),
                    ),
                  );
                },
                icon: const Icon(Icons.quiz_rounded),
                label: const Text('Genel Ünite Testine Git'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
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

class _AppleStyleSocialActivityCard extends StatelessWidget {
  final String title;

  const _AppleStyleSocialActivityCard({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.teal.shade400,
              Colors.teal.shade600,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.celebration_rounded,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Bu hafta için etkinlikler yakında eklenecek.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppleStyleBreakCard extends StatelessWidget {
  final String title;
  final String duration;

  const _AppleStyleBreakCard({
    required this.title,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blueGrey.shade400,
              Colors.blueGrey.shade600,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blueGrey.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.beach_access_rounded,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                duration,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppleStyleSpecialContentCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;

  const _AppleStyleSpecialContentCard({
    required this.title,
    required this.content,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 56,
                color: Colors.blue,
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 1,
                color: Colors.grey.shade200,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Html(
                    data: content,
                    style: {
                      "body": Style(
                        fontSize: FontSize(16),
                        lineHeight: const LineHeight(1.6),
                      ),
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String errorMessage;

  const _ErrorCard({required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
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
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Lütfen yöneticinize bildirin',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _MiniQuizState { notStarted, inProgress, finished }