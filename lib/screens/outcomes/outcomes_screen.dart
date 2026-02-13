import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:egitim_uygulamasi/viewmodels/outcomes_viewmodel.dart';
import 'package:egitim_uygulamasi/screens/outcomes/widgets/header_view.dart';
import 'package:egitim_uygulamasi/screens/outcomes/widgets/topic_content_view.dart';
import 'package:egitim_uygulamasi/screens/outcomes/widgets/weekly_test_view.dart';
import 'package:egitim_uygulamasi/screens/outcomes/widgets/unit_test_view.dart';
import 'package:egitim_uygulamasi/screens/outcomes/widgets/special_cards_view.dart';
import 'package:egitim_uygulamasi/screens/outcomes/widgets/app_bar_view.dart';
import 'package:egitim_uygulamasi/viewmodels/profile_viewmodel.dart'; // profileViewModelProvider için
import 'package:egitim_uygulamasi/models/topic_content.dart';
import 'package:egitim_uygulamasi/utils/date_utils.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class _LessonThemePalette {
  final Color primary;
  final Color soft;
  final Color border;
  final Color warm;

  const _LessonThemePalette({
    required this.primary,
    required this.soft,
    required this.border,
    required this.warm,
  });
}

const List<_LessonThemePalette> _lessonPalettes = [
  _LessonThemePalette(
    primary: Color(0xFF2F6FE4),
    soft: Color(0xFFEAF2FF),
    border: Color(0xFFC8DBFF),
    warm: Color(0xFFF39C12),
  ),
  _LessonThemePalette(
    primary: Color(0xFF16A085),
    soft: Color(0xFFE8F7F3),
    border: Color(0xFFBFE9DE),
    warm: Color(0xFFE67E22),
  ),
  _LessonThemePalette(
    primary: Color(0xFF8E44AD),
    soft: Color(0xFFF3EBFA),
    border: Color(0xFFDCC8EE),
    warm: Color(0xFFE67E22),
  ),
  _LessonThemePalette(
    primary: Color(0xFFC0392B),
    soft: Color(0xFFFCEEEB),
    border: Color(0xFFF2CFC9),
    warm: Color(0xFFEB9A3A),
  ),
  _LessonThemePalette(
    primary: Color(0xFF1F7A8C),
    soft: Color(0xFFE8F5F7),
    border: Color(0xFFC6E3E8),
    warm: Color(0xFFD88D1C),
  ),
];

_LessonThemePalette _paletteForLesson(int lessonId) {
  final index = (lessonId - 1).abs() % _lessonPalettes.length;
  return _lessonPalettes[index];
}

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
    final palette = _paletteForLesson(widget.lessonId);

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
                colors: [
                  Color(0xFFF6F9FF),
                  Color(0xFFEEF3FF),
                  Color(0xFFF8FAFF),
                ],
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
                color: const Color(0xFFBFD6FF).withValues(alpha: 0.28),
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
                color: const Color(0xFFFFD9B8).withValues(alpha: 0.22),
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
                color: const Color(0xFFCDEBD9).withValues(alpha: 0.25),
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
                  physics: const PageScrollPhysics(),
                  controller: viewModel.pageController,
                  itemCount: viewModel.allWeeksData.length,
                  onPageChanged: viewModel.onPageChanged,
                  itemBuilder: (context, index) {
                    final weekData = viewModel.allWeeksData[index];
                    final anchorWeek = viewModel.timelineItems[index].anchorWeek;
                    if (anchorWeek == null) {
                      return ErrorCard(errorMessage: 'Hafta verisi bozuk');
                    }

                    final page = MediaQuery(
                      data: mediaQuery.copyWith(
                        textScaler: TextScaler.linear(_textScale),
                      ),
                      child: _WeekContentView(
                        key: ValueKey('week_content_${index}_$anchorWeek'),
                        curriculumWeek: anchorWeek,
                        pageData: Map<String, dynamic>.from(weekData)
                          ..['_page_index'] = index,
                        args: viewModelArgs,
                        palette: palette,
                      ),
                    );
                    return page;
                  },
                ),
        ],
      ),
    );
  }
}

class _WeekContentView extends ConsumerStatefulWidget {
  final int curriculumWeek;
  final Map<String, dynamic> pageData;
  final OutcomesViewModelArgs args;
  final _LessonThemePalette palette;

  const _WeekContentView({
    super.key,
    required this.curriculumWeek,
    required this.pageData,
    required this.args,
    required this.palette,
  });

  @override
  ConsumerState<_WeekContentView> createState() => _WeekContentViewState();
}

class _WeekContentViewState extends ConsumerState<_WeekContentView>
    with AutomaticKeepAliveClientMixin {
  int? _selectedSectionIndex;
  int? _selectedUnitId;

  Future<void> _showUnitPicker(
    BuildContext context,
    List<Map<String, dynamic>> units,
    int? selectedUnitId,
    List<Map<String, dynamic>> allTopics,
    List<Map<String, dynamic>> currentSections,
  ) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) {
        const unitIcons = <IconData>[
          Icons.auto_stories_rounded,
          Icons.public_rounded,
          Icons.menu_book_rounded,
          Icons.hub_rounded,
          Icons.account_balance_rounded,
          Icons.emoji_objects_rounded,
        ];
        const unitColors = <Color>[
          Color(0xFF2F6FE4),
          Color(0xFF16A085),
          Color(0xFFE67E22),
          Color(0xFF8E44AD),
          Color(0xFFC0392B),
          Color(0xFF1F7A8C),
        ];

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(),
                child: const SizedBox.expand(),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Material(
                  color: Colors.transparent,
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.86,
                    child: DraggableScrollableSheet(
                      initialChildSize: 0.64,
                      minChildSize: 0.42,
                      maxChildSize: 0.95,
                      expand: false,
                      builder: (context, scrollController) {
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(24),
                              ),
                            ),
                            child: Column(
                              children: [
                                const SizedBox(height: 10),
                                Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'Ünite Seç',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: ListView.builder(
                                    controller: scrollController,
                                    padding: const EdgeInsets.fromLTRB(
                                      14,
                                      4,
                                      14,
                                      16,
                                    ),
                                    itemCount: units.length,
                                    itemBuilder: (context, index) {
                                      final unit = units[index];
                                      final unitId = unit['unit_id'] as int?;
                                      final isSelected =
                                          unitId != null &&
                                          unitId == selectedUnitId;
                                      final icon =
                                          unitIcons[index % unitIcons.length];
                                      final iconColor =
                                          unitColors[index % unitColors.length];
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 5,
                                        ),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          onTap: unitId == null
                                              ? null
                                              : () => Navigator.of(
                                                  context,
                                                ).pop(unitId),
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 180,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: isSelected
                                                  ? const LinearGradient(
                                                      colors: [
                                                        Color(0xFFEAF2FF),
                                                        Color(0xFFF2F7FF),
                                                      ],
                                                    )
                                                  : null,
                                              color: isSelected
                                                  ? null
                                                  : Colors.grey.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                color: isSelected
                                                    ? const Color(0xFF2F6FE4)
                                                    : Colors.grey.shade300,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 34,
                                                  height: 34,
                                                  decoration: BoxDecoration(
                                                    color: iconColor.withValues(
                                                      alpha: 0.14,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                  child: Icon(
                                                    icon,
                                                    color: iconColor,
                                                    size: 18,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    (unit['unit_title']
                                                                as String? ??
                                                            'Ünite')
                                                        .trim(),
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: isSelected
                                                          ? FontWeight.w700
                                                          : FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                                Icon(
                                                  isSelected
                                                      ? Icons
                                                            .check_circle_rounded
                                                      : Icons
                                                            .radio_button_unchecked_rounded,
                                                  color: isSelected
                                                      ? const Color(0xFF2F6FE4)
                                                      : Colors.grey.shade600,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted || picked == null) return;
    setState(() => _selectedUnitId = picked);

    final firstTopicForUnit =
        allTopics.firstWhere(
              (topic) => topic['unit_id'] == picked,
              orElse: () => <String, dynamic>{},
            )['topic_id']
            as int?;
    if (firstTopicForUnit != null) {
      await _handleTopicSelect(
        topicId: firstTopicForUnit,
        currentSections: currentSections,
      );
    }
  }

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

    final targetPageIndex = viewModel.weekPageIndexByWeek[targetWeek] ?? -1;
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
        viewModel.ensureWeekDataByCurriculumWeek(widget.curriculumWeek);
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
    final isGuest = ref.watch(
      profileViewModelProvider.select((p) => p.profile == null),
    );
    final isAdmin = ref.watch(
      profileViewModelProvider.select((p) => p.profile?.role == 'admin'),
    );
    final lessonTopics = ref.watch(
      outcomesViewModelProvider(widget.args).select((vm) => vm.lessonTopics),
    );
    final weekNumbers = ref.watch(
      outcomesViewModelProvider(widget.args).select((vm) => vm.weekNumbers),
    );
    final weekPageIndexByWeek = ref.watch(
      outcomesViewModelProvider(
        widget.args,
      ).select((vm) => vm.weekPageIndexByWeek),
    );
    final breakAfterWeekCounts = ref.watch(
      outcomesViewModelProvider(
        widget.args,
      ).select((vm) => vm.breakAfterWeekCounts),
    );
    final breakPageIndexesByAfterWeek = ref.watch(
      outcomesViewModelProvider(
        widget.args,
      ).select((vm) => vm.breakPageIndexesByAfterWeek),
    );
    final extraBadgesByWeek = ref.watch(
      outcomesViewModelProvider(
        widget.args,
      ).select((vm) => vm.extraBadgesByWeek),
    );
    final solvedWeeks = ref.watch(
      outcomesViewModelProvider(widget.args).select((vm) => vm.solvedWeeks),
    );
    final actualCurrentWeek = calculateCurrentAcademicWeek();
    final pageType = (widget.pageData['type'] as String?) ?? 'week';
    final isSpecialPage = pageType != 'week';
    final selectedSpecialPageIndex =
        (pageType == 'break' || pageType == 'social_activity')
        ? widget.pageData['_page_index'] as int?
        : null;
    final selectedWeekForStrip = (pageType == 'special_content')
        ? widget.curriculumWeek
        : (isSpecialPage ? null : widget.curriculumWeek);
    final safeData = data ?? <String, dynamic>{};

    if (!isSpecialPage && isLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (!isSpecialPage && error != null) {
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

    if (!isSpecialPage && (data == null || data.isEmpty)) {
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

    final rawSections = (safeData['sections'] as List?)
        ?.whereType<Map>()
        .map((s) => Map<String, dynamic>.from(s))
        .toList();

    final sections = (rawSections != null && rawSections.isNotEmpty)
        ? rawSections
        : [
            {
              'unit_id': safeData['unit_id'],
              'unit_title': safeData['unit_title'],
              'topic_id': safeData['topic_id'],
              'topic_title': safeData['topic_title'],
              'outcomes': safeData['outcomes'] ?? <dynamic>[],
              'contents': safeData['contents'] ?? <dynamic>[],
            },
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
              .map(
                (s) => {
                  'topic_id': s['topic_id'],
                  'topic_title': s['topic_title'],
                  'unit_id': s['unit_id'],
                  'unit_title': s['unit_title'],
                  'unit_order': 0,
                  'topic_order': 0,
                  'weeks': <int>[widget.curriculumWeek],
                  'first_week': widget.curriculumWeek,
                  'last_week': widget.curriculumWeek,
                },
              )
              .toList();
    final unitOptions = <Map<String, dynamic>>[];
    for (final topic in topicMenu) {
      final unitId = topic['unit_id'] as int?;
      if (unitId == null) continue;
      if (unitOptions.any((u) => u['unit_id'] == unitId)) continue;
      unitOptions.add({
        'unit_id': unitId,
        'unit_title': topic['unit_title'],
        'unit_order': topic['unit_order'] as int? ?? 0,
      });
    }
    unitOptions.sort(
      (a, b) => (a['unit_order'] as int).compareTo(b['unit_order'] as int),
    );

    final selectedUnitFromSection = selectedUnitId;
    final defaultUnitId = (selectedUnitFromSection is int)
        ? selectedUnitFromSection
        : (unitOptions.isNotEmpty ? unitOptions.first['unit_id'] as int : null);
    if (_selectedUnitId == null ||
        !unitOptions.any((u) => u['unit_id'] == _selectedUnitId)) {
      _selectedUnitId = defaultUnitId;
    }

    final effectiveUnitId = _selectedUnitId;
    final filteredTopics = effectiveUnitId == null
        ? topicMenu
        : topicMenu.where((t) => t['unit_id'] == effectiveUnitId).toList();
    final effectiveSelectedTopicId =
        filteredTopics.any((t) => t['topic_id'] == selectedTopicId)
        ? selectedTopicId
        : (filteredTopics.isNotEmpty
              ? filteredTopics.first['topic_id'] as int?
              : null);
    final selectedUnitTitle =
        unitOptions.firstWhere(
              (u) => u['unit_id'] == effectiveUnitId,
              orElse: () => <String, dynamic>{'unit_title': 'Ünite seçiniz'},
            )['unit_title']
            as String? ??
        'Ünite seçiniz';

    final isLastWeek = safeData['is_last_week_of_unit'] ?? false;
    final unitSummary = safeData['unit_summary'];
    final unitId = selectedUnitId ?? safeData['unit_id'];

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
                data: safeData,
                pageData: widget.pageData,
                args: widget.args,
              ),
            ),
          ),
          if (isSpecialPage)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              sliver: SliverToBoxAdapter(
                child: _PageTypeInfoCard(pageData: widget.pageData),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            sliver: SliverToBoxAdapter(
              child: _WeekStripBar(
                weekNumbers: weekNumbers,
                breakAfterWeekCounts: breakAfterWeekCounts,
                breakPageIndexesByAfterWeek: breakPageIndexesByAfterWeek,
                extraBadgesByWeek: extraBadgesByWeek,
                weekPageIndexByWeek: weekPageIndexByWeek,
                selectedWeek: selectedWeekForStrip,
                selectedSpecialPageIndex: selectedSpecialPageIndex,
                actualCurrentWeek: actualCurrentWeek,
                solvedWeeks: solvedWeeks,
                palette: widget.palette,
                onSelectWeek: (targetWeek, directPageIndex) async {
                  final viewModel = ref.read(
                    outcomesViewModelProvider(widget.args),
                  );
                  int targetPageIndex = directPageIndex;

                  final exactFromTimeline = viewModel.timelineItems.indexWhere(
                    (item) =>
                        item.type == 'week' &&
                        item.curriculumWeek == targetWeek,
                  );
                  if (exactFromTimeline != -1) {
                    targetPageIndex = exactFromTimeline;
                  }

                  viewModel.pageController.jumpToPage(targetPageIndex);

                  final settledIndex =
                      (viewModel.pageController.page?.round() ??
                      targetPageIndex);
                  final settledItem =
                      (settledIndex >= 0 &&
                          settledIndex < viewModel.timelineItems.length)
                      ? viewModel.timelineItems[settledIndex]
                      : null;
                  final isCorrect =
                      settledItem != null &&
                      settledItem.type == 'week' &&
                      settledItem.curriculumWeek == targetWeek;
                  if (!isCorrect) {
                    final hardIndex = viewModel.timelineItems.indexWhere(
                      (item) =>
                          item.type == 'week' &&
                          item.curriculumWeek == targetWeek,
                    );
                    if (hardIndex != -1) {
                      viewModel.pageController.jumpToPage(hardIndex);
                    }
                  }
                },
                onSelectSpecialPage: (breakPageIndex, expectedType) async {
                  final viewModel = ref.read(
                    outcomesViewModelProvider(widget.args),
                  );
                  final resolved = viewModel.findNearestPageIndexByType(
                    aroundIndex: breakPageIndex,
                    expectedType: expectedType,
                  );
                  if (resolved == null) return;
                  viewModel.pageController.jumpToPage(resolved);
                },
              ),
            ),
          ),
          if (!isSpecialPage)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TopicSelectorCard(
                        topics: filteredTopics,
                        selectedTopicId: effectiveSelectedTopicId,
                        currentWeekTopicIds: currentWeekTopicIds,
                        currentWeek: widget.curriculumWeek,
                        palette: widget.palette,
                        selectedUnitTitle: selectedUnitTitle,
                        unitCount: unitOptions.length,
                        onTapUnit: () => _showUnitPicker(
                          context,
                          unitOptions,
                          effectiveUnitId,
                          topicMenu,
                          sections,
                        ),
                        onSelectTopic: (topicId) => _handleTopicSelect(
                          topicId: topicId,
                          currentSections: sections,
                        ),
                      ),
                    ),
                    _WeekSectionBlock(
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
          if (!isSpecialPage && unitId != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              sliver: SliverToBoxAdapter(
                child: MediaQuery(
                  data: mediaQuery.copyWith(textScaler: TextScaler.noScaling),
                  child: WeeklyTestView(
                    unitId: unitId,
                    curriculumWeek: widget.curriculumWeek,
                    args: widget.args,
                    isGuest: isGuest,
                  ),
                ),
              ),
            ),
          if (!isSpecialPage &&
              isLastWeek &&
              unitSummary != null &&
              unitId != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              sliver: SliverToBoxAdapter(
                child: MediaQuery(
                  data: mediaQuery.copyWith(textScaler: TextScaler.noScaling),
                  child: UnitTestView(unitSummary: unitSummary, unitId: unitId),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PageTypeInfoCard extends StatelessWidget {
  final Map<String, dynamic> pageData;

  const _PageTypeInfoCard({required this.pageData});

  String _stripHtml(String value) {
    return value
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final type = pageData['type'] as String? ?? 'week';
    String title;
    String subtitle;
    IconData icon;
    Color bg;
    Color border;
    Color text;

    if (type == 'break') {
      title = (pageData['title'] as String? ?? 'Tatil').trim();
      subtitle = (pageData['duration'] as String? ?? '').trim();
      icon = Icons.beach_access_rounded;
      bg = const Color(0xFFEAF2FB);
      border = const Color(0xFFC5D7EC);
      text = const Color(0xFF24527A);
    } else if (type == 'social_activity') {
      title = (pageData['title'] as String? ?? 'Sosyal Etkinlik').trim();
      subtitle = 'Bu hafta için sosyal etkinlik odaklı içerik.';
      icon = Icons.celebration_rounded;
      bg = const Color(0xFFE9F8F4);
      border = const Color(0xFFBFE8DA);
      text = const Color(0xFF0D7D66);
    } else {
      title = (pageData['title'] as String? ?? 'Özel İçerik').trim();
      subtitle = _stripHtml((pageData['content'] as String? ?? '')).trim();
      if (subtitle.length > 140) {
        subtitle = '${subtitle.substring(0, 140)}...';
      }
      icon = (pageData['icon'] as IconData?) ?? Icons.info_outline_rounded;
      bg = const Color(0xFFEFF3FF);
      border = const Color(0xFFC8D6FF);
      text = const Color(0xFF2F4FA8);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: text, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: text,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: text.withValues(alpha: 0.92),
                    ),
                  ),
                ],
              ],
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
  final _LessonThemePalette palette;
  final String selectedUnitTitle;
  final int unitCount;
  final VoidCallback onTapUnit;
  final ValueChanged<int> onSelectTopic;

  const _TopicSelectorCard({
    required this.topics,
    required this.selectedTopicId,
    required this.currentWeekTopicIds,
    required this.currentWeek,
    required this.palette,
    required this.selectedUnitTitle,
    required this.unitCount,
    required this.onTapUnit,
    required this.onSelectTopic,
  });

  @override
  State<_TopicSelectorCard> createState() => _TopicSelectorCardState();
}

class _TopicSelectorCardState extends State<_TopicSelectorCard> {
  String _statusLabel(Map<String, dynamic> topic) {
    final topicId = topic['topic_id'] as int?;
    if (topicId != null && widget.currentWeekTopicIds.contains(topicId)) {
      return 'Bu Hafta';
    }
    final firstWeek = topic['first_week'] as int?;
    final lastWeek = topic['last_week'] as int?;
    if (firstWeek == null || lastWeek == null) return 'Plan Bekliyor';
    if (widget.currentWeek < firstWeek) return '$firstWeek. Hafta';
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
    final selectedTopicTitle =
        (widget.topics.firstWhere(
                      (topic) => topic['topic_id'] == widget.selectedTopicId,
                      orElse: () => <String, dynamic>{'topic_title': ''},
                    )['topic_title']
                    as String? ??
                '')
            .trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, widget.palette.soft, const Color(0xFFEEF5FF)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.palette.border),
        boxShadow: [
          BoxShadow(
            color: widget.palette.primary.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -18,
            right: -10,
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFBFD6FF).withValues(alpha: 0.22),
              ),
            ),
          ),
          Positioned(
            bottom: -26,
            left: -12,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFD9B8).withValues(alpha: 0.18),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: widget.onTapUnit,
                child: Ink(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: widget.palette.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: widget.palette.primary.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          Icons.folder_open_rounded,
                          color: widget.palette.primary,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Seçili Ünite',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              widget.selectedUnitTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${widget.unitCount} ünite',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: widget.palette.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Menü',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: widget.palette.primary,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 14,
                              color: widget.palette.primary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (widget.topics.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'Bu ünite için konu bulunamadı.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
              else
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: Column(
                    key: ValueKey(
                      '${widget.topics.first['unit_id']}_${widget.topics.length}',
                    ),
                    children: widget.topics.map((topic) {
                      final topicId = topic['topic_id'] as int?;
                      final title = (topic['topic_title'] as String? ?? 'Konu')
                          .trim();
                      final isSelected =
                          topicId != null && topicId == widget.selectedTopicId;
                      final status = _statusLabel(topic);
                      final weekRange = _weekRangeLabel(topic);
                      final bool isCurrent = status == 'Bu Hafta';
                      return Container(
                        margin: const EdgeInsets.only(top: 7),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [
                                    widget.palette.soft,
                                    const Color(0xFFF3F8FF),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFFFFFFFF),
                                    Color(0xFFF8FBFF),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? widget.palette.border
                                : const Color(0xFFDDE8FB),
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: widget.palette.primary.withValues(
                                  alpha: 0.18,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: ListTile(
                          dense: true,
                          leading: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? widget.palette.primary.withValues(
                                      alpha: 0.12,
                                    )
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(
                              isSelected
                                  ? Icons.bookmark_rounded
                                  : Icons.book_outlined,
                              color: isSelected
                                  ? widget.palette.primary
                                  : Colors.grey.shade700,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            '$status • $weekRange',
                            style: TextStyle(
                              fontSize: 11,
                              color: isCurrent
                                  ? widget.palette.primary
                                  : Colors.grey.shade600,
                              fontWeight: isCurrent
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: isSelected
                                ? widget.palette.primary
                                : Colors.grey.shade500,
                          ),
                          onTap: topicId == null
                              ? null
                              : () => widget.onSelectTopic(topicId),
                        ),
                      );
                    }).toList(),
                  ),
                ),
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
        ],
      ),
    );
  }
}

class _WeekStripBar extends StatefulWidget {
  final List<int> weekNumbers;
  final Map<int, int> breakAfterWeekCounts;
  final Map<int, List<int>> breakPageIndexesByAfterWeek;
  final Map<int, List<Map<String, dynamic>>> extraBadgesByWeek;
  final Map<int, int> weekPageIndexByWeek;
  final int? selectedWeek;
  final int? selectedSpecialPageIndex;
  final int actualCurrentWeek;
  final Set<int> solvedWeeks;
  final _LessonThemePalette palette;
  final void Function(int week, int pageIndex) onSelectWeek;
  final void Function(int pageIndex, String expectedType) onSelectSpecialPage;

  const _WeekStripBar({
    required this.weekNumbers,
    required this.breakAfterWeekCounts,
    required this.breakPageIndexesByAfterWeek,
    required this.extraBadgesByWeek,
    required this.weekPageIndexByWeek,
    required this.selectedWeek,
    required this.selectedSpecialPageIndex,
    required this.actualCurrentWeek,
    required this.solvedWeeks,
    required this.palette,
    required this.onSelectWeek,
    required this.onSelectSpecialPage,
  });

  @override
  State<_WeekStripBar> createState() => _WeekStripBarState();
}

class _WeekStripBarState extends State<_WeekStripBar> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _weekKeys = <int, GlobalKey>{};
  final Map<int, GlobalKey> _specialKeys = <int, GlobalKey>{};
  static bool _didGlobalInitialCentering = false;
  bool _didInitialCentering = false;

  GlobalKey _keyForWeek(int week) {
    return _weekKeys.putIfAbsent(week, () => GlobalKey());
  }

  GlobalKey _keyForSpecial(int pageIndex) {
    return _specialKeys.putIfAbsent(pageIndex, () => GlobalKey());
  }

  void _centerWeek(
    int week, {
    Duration duration = const Duration(milliseconds: 280),
    int retryCount = 0,
  }) {
    if (!widget.weekNumbers.contains(week)) return;
    final key = _weekKeys[week];
    final targetContext = key?.currentContext;
    if (targetContext == null) {
      if (retryCount < 2) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _centerWeek(week, duration: duration, retryCount: retryCount + 1);
          }
        });
      }
      return;
    }
    Scrollable.ensureVisible(
      targetContext,
      alignment: 0.5,
      duration: duration,
      curve: Curves.easeOutCubic,
    );
  }

  void _centerSpecial(
    int pageIndex, {
    Duration duration = const Duration(milliseconds: 280),
    int retryCount = 0,
  }) {
    final key = _specialKeys[pageIndex];
    final targetContext = key?.currentContext;
    if (targetContext == null) {
      if (retryCount < 2) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _centerSpecial(
              pageIndex,
              duration: duration,
              retryCount: retryCount + 1,
            );
          }
        });
      }
      return;
    }
    Scrollable.ensureVisible(
      targetContext,
      alignment: 0.5,
      duration: duration,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.selectedSpecialPageIndex != null) {
        _didGlobalInitialCentering = true;
        _didInitialCentering = true;
        _centerSpecial(
          widget.selectedSpecialPageIndex!,
          duration: const Duration(milliseconds: 0),
        );
        return;
      }
      final initialWeek = !_didGlobalInitialCentering
          ? (widget.weekNumbers.contains(widget.actualCurrentWeek)
                ? widget.actualCurrentWeek
                : (widget.selectedWeek != null &&
                      widget.weekNumbers.contains(widget.selectedWeek))
                ? widget.selectedWeek!
                : widget.weekNumbers.first)
          : ((widget.selectedWeek != null &&
                    widget.weekNumbers.contains(widget.selectedWeek))
                ? widget.selectedWeek!
                : widget.weekNumbers.contains(widget.actualCurrentWeek)
                ? widget.actualCurrentWeek
                : widget.weekNumbers.first);
      _didGlobalInitialCentering = true;
      _didInitialCentering = true;
      _centerWeek(initialWeek, duration: const Duration(milliseconds: 0));
    });
  }

  @override
  void didUpdateWidget(covariant _WeekStripBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_didInitialCentering) return;
    if (oldWidget.selectedSpecialPageIndex != widget.selectedSpecialPageIndex &&
        widget.selectedSpecialPageIndex != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _centerSpecial(widget.selectedSpecialPageIndex!);
      });
      return;
    }
    if (oldWidget.selectedWeek != widget.selectedWeek &&
        widget.selectedSpecialPageIndex == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final weekToCenter =
            (widget.selectedWeek != null &&
                widget.weekNumbers.contains(widget.selectedWeek))
            ? widget.selectedWeek!
            : widget.weekNumbers.contains(widget.actualCurrentWeek)
            ? widget.actualCurrentWeek
            : widget.weekNumbers.first;
        _centerWeek(weekToCenter);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.weekNumbers.isEmpty) return const SizedBox.shrink();

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
            color: const Color(0xFF87A8E5).withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hafta Akışı • Şu an: ${widget.actualCurrentWeek}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: Row(
              children: widget.weekNumbers.map((week) {
                final isSelected =
                    widget.selectedWeek != null && week == widget.selectedWeek;
                final hasExplicitWeekSelection = widget.selectedWeek != null;
                final isCurrent = week == widget.actualCurrentWeek;
                final isPast = week < widget.actualCurrentWeek;
                final isSolved = widget.solvedWeeks.contains(week);
                return Row(
                  children: [
                    Padding(
                      key: _keyForWeek(week),
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () {
                          final pageIndex = widget.weekPageIndexByWeek[week];
                          if (pageIndex == null) return;
                          widget.onSelectWeek(week, pageIndex);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 190),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? widget.palette.primary
                                : isCurrent
                                ? (hasExplicitWeekSelection
                                      ? const Color(0xFFFFE7CB)
                                      : const Color(0xFFF7F9FD))
                                : isPast
                                ? const Color(0xFFE8F0FF)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: isCurrent
                                  ? (hasExplicitWeekSelection
                                        ? widget.palette.warm
                                        : const Color(0xFFD5E2FF))
                                  : const Color(0xFFD5E2FF),
                              width: isCurrent && hasExplicitWeekSelection
                                  ? 1.5
                                  : 1.0,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: widget.palette.primary.withValues(
                                        alpha: 0.28,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : (isCurrent && hasExplicitWeekSelection)
                                ? [
                                    BoxShadow(
                                      color: widget.palette.warm.withValues(
                                        alpha: 0.22,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
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
                                      ? (hasExplicitWeekSelection
                                            ? const Color(0xFFB76A00)
                                            : Colors.grey.shade700)
                                      : isPast
                                      ? widget.palette.primary
                                      : Colors.grey.shade700,
                                ),
                              ),
                              if (isCurrent && hasExplicitWeekSelection) ...[
                                const SizedBox(width: 6),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: widget.palette.warm,
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
                                        : widget.palette.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    if ((widget.breakAfterWeekCounts[week] ?? 0) > 0)
                      ...List.generate(widget.breakAfterWeekCounts[week] ?? 0, (
                        index,
                      ) {
                        final breakPageIndex =
                            (widget.breakPageIndexesByAfterWeek[week] != null &&
                                widget
                                        .breakPageIndexesByAfterWeek[week]!
                                        .length >
                                    index)
                            ? widget.breakPageIndexesByAfterWeek[week]![index]
                            : null;
                        final isSelected =
                            breakPageIndex != null &&
                            widget.selectedSpecialPageIndex == breakPageIndex;
                        return Padding(
                          key: breakPageIndex != null
                              ? _keyForSpecial(breakPageIndex)
                              : null,
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap:
                                (widget.breakPageIndexesByAfterWeek[week] !=
                                        null &&
                                    widget
                                            .breakPageIndexesByAfterWeek[week]!
                                            .length >
                                        index)
                                ? () => widget.onSelectSpecialPage(
                                    widget
                                        .breakPageIndexesByAfterWeek[week]![index],
                                    'break',
                                  )
                                : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFC43D67)
                                    : const Color(0xFFFFE4EC),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFC43D67)
                                      : const Color(0xFFFFB0C7),
                                ),
                                boxShadow: isSelected
                                    ? [
                                        const BoxShadow(
                                          color: Color(0x3DC43D67),
                                          blurRadius: 8,
                                          offset: Offset(0, 3),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                'T',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFFC43D67),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    if ((widget.extraBadgesByWeek[week]?.isNotEmpty ?? false))
                      ...widget.extraBadgesByWeek[week]!.map((badge) {
                        final pageIndex = badge['page_index'] as int?;
                        final shortLabel =
                            badge['short_label'] as String? ?? 'EK';
                        final title = badge['title'] as String? ?? '';
                        final isSpecial = badge['is_special'] == true;
                        final isSelected =
                            pageIndex != null &&
                            widget.selectedSpecialPageIndex == pageIndex;
                        return Padding(
                          key: pageIndex != null
                              ? _keyForSpecial(pageIndex)
                              : null,
                          padding: const EdgeInsets.only(right: 8),
                          child: Tooltip(
                            message: title,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(999),
                              onTap: pageIndex == null
                                  ? null
                                  : () => widget.onSelectSpecialPage(
                                      pageIndex,
                                      shortLabel == 'SE'
                                          ? 'social_activity'
                                          : 'special_content',
                                    ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (isSpecial
                                            ? const Color(0xFF2F6FE4)
                                            : const Color(0xFF16A085))
                                      : isSpecial
                                      ? const Color(0xFFEAF2FF)
                                      : const Color(0xFFEAF7F3),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: isSelected
                                        ? (isSpecial
                                              ? const Color(0xFF2F6FE4)
                                              : const Color(0xFF16A085))
                                        : isSpecial
                                        ? const Color(0xFFC8DBFF)
                                        : const Color(0xFFBFE9DE),
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color:
                                                (isSpecial
                                                        ? const Color(
                                                            0xFF2F6FE4,
                                                          )
                                                        : const Color(
                                                            0xFF16A085,
                                                          ))
                                                    .withValues(alpha: 0.24),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  shortLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected
                                        ? Colors.white
                                        : isSpecial
                                        ? const Color(0xFF2F6FE4)
                                        : const Color(0xFF16A085),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
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
  final List<TopicContent> contents;
  final bool isAdmin;
  final VoidCallback onContentUpdated;

  const _WeekSectionBlock({
    required this.contents,
    required this.isAdmin,
    required this.onContentUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < contents.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
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
