import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:egitim_uygulamasi/viewmodels/outcomes_viewmodel.dart';
import 'package:egitim_uygulamasi/screens/outcomes/widgets/header_view.dart';
import 'package:egitim_uygulamasi/screens/outcomes/widgets/topic_content_view.dart';
import 'package:egitim_uygulamasi/screens/outcomes/widgets/mini_quiz_view.dart';
import 'package:egitim_uygulamasi/screens/outcomes/widgets/weekly_test_view.dart';
import 'package:egitim_uygulamasi/screens/outcomes/widgets/unit_test_view.dart';
import 'package:egitim_uygulamasi/screens/outcomes/widgets/special_cards_view.dart';
import 'package:egitim_uygulamasi/screens/outcomes/widgets/app_bar_view.dart';
import 'package:egitim_uygulamasi/viewmodels/profile_viewmodel.dart'; // profileViewModelProvider için
import 'package:egitim_uygulamasi/models/topic_content.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class OutcomesScreen extends ConsumerStatefulWidget {
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
  ConsumerState<OutcomesScreen> createState() => _OutcomesScreenState();
}

class _OutcomesScreenState extends ConsumerState<OutcomesScreen> {
  double _textScale = 1.0;
  double get _maxScale => kIsWeb ? 4.0 : 1.3;

  void _increaseTextScale() {
    setState(() {
      _textScale = (_textScale + 0.1).clamp(0.9, _maxScale);
    });
  }

  void _decreaseTextScale() {
    setState(() {
      _textScale = (_textScale - 0.1).clamp(0.9, _maxScale);
    });
  }

  List<Widget> _buildTextScaleActions() {
    return [
      TextButton(
        onPressed: _decreaseTextScale,
        style: TextButton.styleFrom(
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: const Text(
          'A-',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      TextButton(
        onPressed: _increaseTextScale,
        style: TextButton.styleFrom(
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: const Text(
          'A+',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final viewModelArgs = OutcomesViewModelArgs(
      lessonId: widget.lessonId,
      gradeId: widget.gradeId,
      initialCurriculumWeek: widget.initialCurriculumWeek,
    );
    final viewModel = ref.watch(outcomesViewModelProvider(viewModelArgs));
    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppleStyleAppBar(
        title: widget.lessonName,
        backgroundColor: Colors.white,
        actions: _buildTextScaleActions(),
      ),
      body: viewModel.isLoadingWeeks
          ? const Center(child: CircularProgressIndicator.adaptive())
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
                      physics: const BouncingScrollPhysics(),
                      controller: viewModel.pageController,
                      itemCount: viewModel.allWeeksData.length,
                      onPageChanged: viewModel.onPageChanged,
                      itemBuilder: (context, index) {
                        final weekData = viewModel.allWeeksData[index];
                        if (weekData['type'] == 'social_activity') {
                          return AppleStyleSocialActivityCard(
                            title: weekData['title'],
                          );
                        }
                        if (weekData['type'] == 'break') {
                          return AppleStyleBreakCard(
                            title: weekData['title'],
                            duration: weekData['duration'],
                          );
                        }
                        if (weekData['type'] == 'special_content') {
                          return AppleStyleSpecialContentCard(
                            title: weekData['title'],
                            content: weekData['content'],
                            icon: weekData['icon'],
                          );
                        }

                        final curriculumWeek = weekData['curriculum_week'];
                        if (curriculumWeek == null) {
                          return ErrorCard(errorMessage: 'Hafta verisi bozuk');
                        }

                        return MediaQuery(
                          data: mediaQuery.copyWith(
                            textScaleFactor: _textScale,
                          ),
                          child: WeekContentView(
                            key: ValueKey('week_content_$curriculumWeek'),
                            curriculumWeek: curriculumWeek as int,
                            args: viewModelArgs,
                          ),
                        );
                      },
                    ),
    );
  }
}

class WeekContentView extends ConsumerStatefulWidget {
  final int curriculumWeek;
  final OutcomesViewModelArgs args;

  const WeekContentView({
    super.key,
    required this.curriculumWeek,
    required this.args,
  });

  @override
  ConsumerState<WeekContentView> createState() => _WeekContentViewState();
}

class _WeekContentViewState extends ConsumerState<WeekContentView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final viewModel = ref.read(outcomesViewModelProvider(widget.args));
        final index = viewModel.allWeeksData.indexWhere(
          (w) => w['curriculum_week'] == widget.curriculumWeek,
        );
        if (index != -1) {
          if (viewModel.pageController.page?.round() == index) {
            viewModel.onPageChanged(index);
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final mediaQuery = MediaQuery.of(context);
    final isLoading = ref.watch(
      outcomesViewModelProvider(widget.args).select(
        (vm) =>
            vm.isWeekLoading(widget.curriculumWeek) &&
            vm.getWeekContent(widget.curriculumWeek) == null,
      ),
    );
    final error = ref.watch(
      outcomesViewModelProvider(
        widget.args,
      ).select((vm) => vm.getWeekError(widget.curriculumWeek)),
    );
    final data = ref.watch(
      outcomesViewModelProvider(
        widget.args,
      ).select((vm) => vm.getWeekContent(widget.curriculumWeek)),
    );
    final questions = ref.watch(
      outcomesViewModelProvider(
        widget.args,
      ).select((vm) => vm.getWeekQuestions(widget.curriculumWeek)),
    );
    final isGuest = ref.watch(
      profileViewModelProvider.select((p) => p.profile == null),
    );

    if (isLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (error != null) {
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
            Text('Hata: $error', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    if (data == null || data.isEmpty) {
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
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    final contents = (data['contents'] as List? ?? [])
        .map((c) => TopicContent.fromJson(c as Map<String, dynamic>))
        .toList();

    final isLastWeek = data['is_last_week_of_unit'] ?? false;
    final unitSummary = data['unit_summary'];
    final unitId = data['unit_id'];

    return RefreshIndicator.adaptive(
      onRefresh: () async => ref
          .read(outcomesViewModelProvider(widget.args))
          .refreshCurrentWeekData(widget.curriculumWeek),
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: HeaderView(
                curriculumWeek: widget.curriculumWeek,
                data: data,
                args: widget.args,
              ),
            ),
          ),
          if ((data['outcomes'] as List).isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: AppleCollapsibleCard(
                  icon: Icons.flag_outlined,
                  title: 'Öğrenme Çıktıları',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: (data['outcomes'] as List)
                        .map(
                          (outcome) =>
                              AppleOutcomeTile(text: outcome as String),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              return Padding(
                padding: EdgeInsets.fromLTRB(20, index == 0 ? 12 : 0, 20, 12),
                child: TopicContentView(content: contents[index]),
              );
            }, childCount: contents.length),
          ),
          if (questions != null && questions.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              sliver: SliverToBoxAdapter(
                child: MediaQuery(
                  data: mediaQuery.copyWith(textScaleFactor: 1.0),
                  child: MiniQuizView(
                    key: ValueKey('mini_quiz_${widget.curriculumWeek}'),
                    questions: questions,
                  ),
                ),
              ),
            ),
          if (unitId != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              sliver: SliverToBoxAdapter(
                child: MediaQuery(
                  data: mediaQuery.copyWith(textScaleFactor: 1.0),
                  child: WeeklyTestView(
                    unitId: unitId,
                    curriculumWeek: widget.curriculumWeek,
                    args: widget.args,
                    isGuest: isGuest,
                  ),
                ),
              ),
            ),
          if (isLastWeek && unitSummary != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              sliver: SliverToBoxAdapter(
                child: MediaQuery(
                  data: mediaQuery.copyWith(textScaleFactor: 1.0),
                  child: UnitTestView(
                    unitSummary: unitSummary,
                    unitId: data['unit_id']!,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
