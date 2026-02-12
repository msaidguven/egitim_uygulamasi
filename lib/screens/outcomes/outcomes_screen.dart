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
import 'package:egitim_uygulamasi/utils/date_utils.dart';
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
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppleStyleAppBar(
        title: widget.lessonName,
        backgroundColor: Colors.white,
        actions: _buildTextScaleActions(),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF6F9FF), Color(0xFFEEF3FF), Color(0xFFF8FAFF)],
              ),
            ),
          ),
          Positioned(
            top: -90,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFBFD6FF).withOpacity(0.28),
              ),
            ),
          ),
          Positioned(
            top: 220,
            left: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFD9B8).withOpacity(0.22),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -30,
            child: Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFCDEBD9).withOpacity(0.25),
              ),
            ),
          ),
          viewModel.isLoadingWeeks
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
        ],
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
  int? _selectedSectionIndex;

  Future<void> _handleTopicSelect({
    required int topicId,
    required List<Map<String, dynamic>> currentSections,
  }) async {
    final inCurrentWeekIndex = currentSections.indexWhere(
      (s) => s['topic_id'] == topicId,
    );
    if (inCurrentWeekIndex != -1) {
      setState(() => _selectedSectionIndex = inCurrentWeekIndex);
      return;
    }

    final viewModel = ref.read(outcomesViewModelProvider(widget.args));
    final targetWeek = await viewModel.findBestWeekForTopic(
      topicId: topicId,
      currentWeek: widget.curriculumWeek,
    );

    if (!mounted) return;
    if (targetWeek == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu konu için hafta bilgisi bulunamadı.')),
      );
      return;
    }

    final targetPageIndex = viewModel.allWeeksData.indexWhere(
      (w) => w['type'] == 'week' && w['curriculum_week'] == targetWeek,
    );
    if (targetPageIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konunun haftası takvimde bulunamadı.')),
      );
      return;
    }

    await viewModel.pageController.animateToPage(
      targetPageIndex,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _selectedSectionIndex ??= 0;
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
    final isAdmin = ref.watch(
      profileViewModelProvider.select((p) => p.profile?.role == 'admin'),
    );
    final lessonTopics = ref.watch(
      outcomesViewModelProvider(
        widget.args,
      ).select((vm) => vm.lessonTopics),
    );
    final allWeeksData = ref.watch(
      outcomesViewModelProvider(
        widget.args,
      ).select((vm) => vm.allWeeksData),
    );
    final solvedWeeks = ref.watch(
      outcomesViewModelProvider(
        widget.args,
      ).select((vm) => vm.solvedWeeks),
    );
    final weekNumbers = allWeeksData
        .where((w) => w['type'] == 'week' && w['curriculum_week'] != null)
        .map((w) => w['curriculum_week'] as int)
        .toList()
      ..sort();
    final actualCurrentWeek = calculateCurrentAcademicWeek();

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

    final rawSections = (data['sections'] as List?)
        ?.whereType<Map>()
        .map((s) => Map<String, dynamic>.from(s))
        .toList();

    final sections = (rawSections != null && rawSections.isNotEmpty)
        ? rawSections
        : [
            {
              'unit_id': data['unit_id'],
              'unit_title': data['unit_title'],
              'topic_id': data['topic_id'],
              'topic_title': data['topic_title'],
              'outcomes': data['outcomes'] ?? <dynamic>[],
              'contents': data['contents'] ?? <dynamic>[],
            }
          ];
    if (sections.isEmpty) {
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
              '${widget.curriculumWeek}. hafta için oturum bulunamadı.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }
    final rawSelectedIndex = _selectedSectionIndex ?? 0;
    final safeSelectedIndex =
        (rawSelectedIndex >= 0 && rawSelectedIndex < sections.length)
            ? rawSelectedIndex
            : 0;
    if (_selectedSectionIndex != safeSelectedIndex) {
      _selectedSectionIndex = safeSelectedIndex;
    }

    final selectedSection = sections[safeSelectedIndex];
    final selectedOutcomes = (selectedSection['outcomes'] as List? ?? [])
        .whereType<String>()
        .toList();
    final selectedContents = (selectedSection['contents'] as List? ?? [])
        .whereType<Map>()
        .map((c) => TopicContent.fromJson(Map<String, dynamic>.from(c)))
        .toList();
    final selectedUnitId = selectedSection['unit_id'] as int?;
    final selectedTopicId = selectedSection['topic_id'] as int?;
    final currentWeekTopicIds = sections
        .map((s) => s['topic_id'])
        .whereType<int>()
        .toSet();
    final topicMenu = lessonTopics.isNotEmpty
        ? lessonTopics
        : sections
            .map((s) => {
                  'topic_id': s['topic_id'],
                  'topic_title': s['topic_title'],
                  'unit_id': s['unit_id'],
                  'unit_title': s['unit_title'],
                  'unit_order': 0,
                  'topic_order': 0,
                  'weeks': <int>[widget.curriculumWeek],
                  'first_week': widget.curriculumWeek,
                  'last_week': widget.curriculumWeek,
                })
            .toList();

    final isLastWeek = data['is_last_week_of_unit'] ?? false;
    final unitSummary = data['unit_summary'];
    final unitId = selectedUnitId ?? data['unit_id'];

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
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            sliver: SliverToBoxAdapter(
              child: _WeekStripBar(
                weekNumbers: weekNumbers,
                selectedWeek: widget.curriculumWeek,
                actualCurrentWeek: actualCurrentWeek,
                solvedWeeks: solvedWeeks,
                onSelectWeek: (targetWeek) async {
                  final viewModel = ref.read(outcomesViewModelProvider(widget.args));
                  final targetPageIndex = viewModel.allWeeksData.indexWhere(
                    (w) => w['type'] == 'week' && w['curriculum_week'] == targetWeek,
                  );
                  if (targetPageIndex == -1) return;
                  await viewModel.pageController.animateToPage(
                    targetPageIndex,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                  );
                },
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _TopicSelectorCard(
                      topics: topicMenu,
                      selectedTopicId: selectedTopicId,
                      currentWeekTopicIds: currentWeekTopicIds,
                      currentWeek: widget.curriculumWeek,
                      onSelectTopic: (topicId) => _handleTopicSelect(
                        topicId: topicId,
                        currentSections: sections,
                      ),
                    ),
                  ),
                  _WeekSectionBlock(
                    unitTitle: selectedSection['unit_title'] as String?,
                    topicTitle: selectedSection['topic_title'] as String?,
                    outcomes: selectedOutcomes,
                    contents: selectedContents,
                    isAdmin: isAdmin,
                    onContentUpdated: () => ref
                        .read(outcomesViewModelProvider(widget.args))
                        .refreshCurrentWeekData(widget.curriculumWeek),
                  ),
                ],
              ),
            ),
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

class _TopicSelectorCard extends StatefulWidget {
  final List<Map<String, dynamic>> topics;
  final int? selectedTopicId;
  final Set<int> currentWeekTopicIds;
  final int currentWeek;
  final ValueChanged<int> onSelectTopic;

  const _TopicSelectorCard({
    required this.topics,
    required this.selectedTopicId,
    required this.currentWeekTopicIds,
    required this.currentWeek,
    required this.onSelectTopic,
  });

  @override
  State<_TopicSelectorCard> createState() => _TopicSelectorCardState();
}

class _TopicSelectorCardState extends State<_TopicSelectorCard> {
  int? _expandedUnitId;

  String _statusLabel(Map<String, dynamic> topic) {
    final topicId = topic['topic_id'] as int?;
    if (topicId != null && widget.currentWeekTopicIds.contains(topicId)) {
      return 'Bu Hafta';
    }
    final firstWeek = topic['first_week'] as int?;
    final lastWeek = topic['last_week'] as int?;
    if (firstWeek == null || lastWeek == null) return 'Plan Bekliyor';
    if (widget.currentWeek < firstWeek) return '${firstWeek}. Hafta';
    if (widget.currentWeek > lastWeek) return 'Tamamlandı';
    return 'Devam Ediyor';
  }

  String _weekRangeLabel(Map<String, dynamic> topic) {
    final firstWeek = topic['first_week'] as int?;
    final lastWeek = topic['last_week'] as int?;
    if (firstWeek == null || lastWeek == null) return 'Hafta bilgisi yok';
    if (firstWeek == lastWeek) return '$firstWeek. hafta';
    return '$firstWeek-$lastWeek. hafta';
  }

  @override
  Widget build(BuildContext context) {
    final unitGroups = <int, List<Map<String, dynamic>>>{};
    final unitTitleById = <int, String>{};
    final unitOrderById = <int, int>{};

    for (final topic in widget.topics) {
      final unitId = topic['unit_id'] as int?;
      if (unitId == null) continue;
      unitGroups.putIfAbsent(unitId, () => <Map<String, dynamic>>[]).add(topic);
      unitTitleById[unitId] = topic['unit_title'] as String? ?? 'Ünite';
      unitOrderById[unitId] = topic['unit_order'] as int? ?? 0;
    }

    final sortedUnitIds = unitGroups.keys.toList()
      ..sort((a, b) => (unitOrderById[a] ?? 0).compareTo(unitOrderById[b] ?? 0));
    const unitBadgePalette = <Color>[
      Color(0xFF2F6FE4),
      Color(0xFF16A085),
      Color(0xFFE67E22),
      Color(0xFF8E44AD),
      Color(0xFFC0392B),
      Color(0xFF1F7A8C),
    ];

    if (_expandedUnitId == null && sortedUnitIds.isNotEmpty) {
      final selectedUnitId = widget.topics
          .firstWhere(
            (t) => t['topic_id'] == widget.selectedTopicId,
            orElse: () => <String, dynamic>{},
          )['unit_id'] as int?;
      _expandedUnitId = selectedUnitId ?? sortedUnitIds.first;
    }

    final selectedTopicTitle = (widget.topics
            .firstWhere(
              (topic) => topic['topic_id'] == widget.selectedTopicId,
              orElse: () => <String, dynamic>{'topic_title': ''},
            )['topic_title'] as String? ??
        '')
        .trim();
    final currentWeekCount = widget.currentWeekTopicIds.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF5F8FF)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE7FF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF87A8E5).withOpacity(0.16),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dersin Konuları',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.topics.length} konu • Bu hafta $currentWeekCount konu aktif',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          ...sortedUnitIds.asMap().entries.map((entry) {
            final index = entry.key;
            final unitId = entry.value;
            final unitTopics = unitGroups[unitId] ?? const <Map<String, dynamic>>[];
            final expanded = _expandedUnitId == unitId;
            final badgeColor = unitBadgePalette[index % unitBadgePalette.length];
            return Container(
              margin: const EdgeInsets.only(top: 8),
              child: _UnitAccordionPanel(
                title: unitTitleById[unitId] ?? 'Ünite',
                subtitle: '${unitTopics.length} konu',
                badgeColor: badgeColor,
                expanded: expanded,
                onHeaderTap: () {
                  setState(() {
                    _expandedUnitId = expanded ? null : unitId;
                  });
                },
                child: Column(
                  children: unitTopics.map((topic) {
                    final topicId = topic['topic_id'] as int?;
                    final title = (topic['topic_title'] as String? ?? 'Konu').trim();
                    final isSelected = topicId != null && topicId == widget.selectedTopicId;
                    final status = _statusLabel(topic);
                    final weekRange = _weekRangeLabel(topic);
                    return ListTile(
                      dense: true,
                      selected: isSelected,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      selectedTileColor: const Color(0xFFE9F1FF),
                      leading: Icon(
                        isSelected ? Icons.bookmark_rounded : Icons.book_outlined,
                        color: isSelected ? const Color(0xFF2F6FE4) : Colors.grey.shade700,
                        size: 20,
                      ),
                      title: Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        '$status • $weekRange',
                        style: TextStyle(
                          fontSize: 11,
                          color: status == 'Bu Hafta'
                              ? const Color(0xFF2F6FE4)
                              : Colors.grey.shade600,
                          fontWeight: status == 'Bu Hafta' ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      onTap: topicId == null ? null : () => widget.onSelectTopic(topicId),
                    );
                  }).toList(),
                ),
              ),
            );
          }),
          if (selectedTopicTitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Seçili konu: $selectedTopicTitle',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UnitAccordionPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color badgeColor;
  final bool expanded;
  final VoidCallback onHeaderTap;
  final Widget child;

  const _UnitAccordionPanel({
    required this.title,
    required this.subtitle,
    required this.badgeColor,
    required this.expanded,
    required this.onHeaderTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: expanded
              ? const [Color(0xFFFFFFFF), Color(0xFFF1F7FF)]
              : const [Color(0xFFFFFFFF), Color(0xFFF7FAFF)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: expanded ? const Color(0xFFCFE0FF) : const Color(0xFFE1E9FF),
        ),
        boxShadow: [
          if (expanded)
            BoxShadow(
              color: const Color(0xFF8CACEE).withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onHeaderTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 34,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: expanded ? const Color(0xFF2F6FE4) : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              child: expanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      child: child,
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekStripBar extends StatelessWidget {
  final List<int> weekNumbers;
  final int selectedWeek;
  final int actualCurrentWeek;
  final Set<int> solvedWeeks;
  final ValueChanged<int> onSelectWeek;

  const _WeekStripBar({
    required this.weekNumbers,
    required this.selectedWeek,
    required this.actualCurrentWeek,
    required this.solvedWeeks,
    required this.onSelectWeek,
  });

  @override
  Widget build(BuildContext context) {
    if (weekNumbers.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF2F7FF)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD9E7FF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF87A8E5).withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hafta Akışı • Şu an: $actualCurrentWeek',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: weekNumbers.map((week) {
                final isSelected = week == selectedWeek;
                final isCurrent = week == actualCurrentWeek;
                final isPast = week < actualCurrentWeek;
                final isSolved = solvedWeeks.contains(week);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => onSelectWeek(week),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF2F6FE4)
                            : isCurrent
                                ? const Color(0xFFFFE7CB)
                            : isPast
                                ? const Color(0xFFE8F0FF)
                                : Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isCurrent
                              ? const Color(0xFFF39C12)
                              : const Color(0xFFD5E2FF),
                          width: isCurrent ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$week',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : isCurrent
                                      ? const Color(0xFFB76A00)
                                      : isPast
                                          ? const Color(0xFF356FD9)
                                          : Colors.grey.shade700,
                            ),
                          ),
                          if (isCurrent) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF39C12),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                          if (isSolved) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF2F6FE4),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekSectionBlock extends StatelessWidget {
  final String? unitTitle;
  final String? topicTitle;
  final List<String> outcomes;
  final List<TopicContent> contents;
  final bool isAdmin;
  final VoidCallback onContentUpdated;

  const _WeekSectionBlock({
    required this.unitTitle,
    required this.topicTitle,
    required this.outcomes,
    required this.contents,
    required this.isAdmin,
    required this.onContentUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFFFF), Color(0xFFF3F8FF)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDCE8FF)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7CA3E8).withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (unitTitle != null)
                Row(
                  children: [
                    const Icon(Icons.folder_open_outlined, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        unitTitle!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              if (topicTitle != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.article_outlined, color: Colors.indigo),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        topicTitle!,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (outcomes.isNotEmpty) ...[
          const SizedBox(height: 12),
          AppleCollapsibleCard(
            icon: Icons.flag_outlined,
            title: 'Öğrenme Çıktıları',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: outcomes
                  .map((outcome) => AppleOutcomeTile(text: outcome))
                  .toList(),
            ),
          ),
        ],
        for (var i = 0; i < contents.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 12 : 8),
            child: TopicContentView(
              content: contents[i],
              isAdmin: isAdmin,
              onContentUpdated: onContentUpdated,
            ),
          ),
      ],
    );
  }
}
