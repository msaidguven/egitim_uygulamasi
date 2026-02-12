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
                                palette: palette,
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
  final _LessonThemePalette palette;

  const WeekContentView({
    super.key,
    required this.curriculumWeek,
    required this.args,
    required this.palette,
  });

  @override
  ConsumerState<WeekContentView> createState() => _WeekContentViewState();
}

class _WeekContentViewState extends ConsumerState<WeekContentView>
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
                              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: ListView.builder(
                                    controller: scrollController,
                                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
                                    itemCount: units.length,
                                    itemBuilder: (context, index) {
                                      final unit = units[index];
                                      final unitId = unit['unit_id'] as int?;
                                      final isSelected =
                                          unitId != null && unitId == selectedUnitId;
                                      final icon = unitIcons[index % unitIcons.length];
                                      final iconColor = unitColors[index % unitColors.length];
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 5),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(14),
                                          onTap: unitId == null
                                              ? null
                                              : () => Navigator.of(context).pop(unitId),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 180),
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
                                              color: isSelected ? null : Colors.grey.shade50,
                                              borderRadius: BorderRadius.circular(14),
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
                                                    color: iconColor.withOpacity(0.14),
                                                    borderRadius: BorderRadius.circular(10),
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
                                                    (unit['unit_title'] as String? ?? 'Ünite')
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
                                                      ? Icons.check_circle_rounded
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

    final firstTopicForUnit = allTopics.firstWhere(
      (topic) => topic['unit_id'] == picked,
      orElse: () => <String, dynamic>{},
    )['topic_id'] as int?;
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
    final breakAfterWeekCounts = <int, int>{};
    final breakPageIndexesByAfterWeek = <int, List<int>>{};
    final extraPages = <Map<String, dynamic>>[];
    for (var i = 0; i < allWeeksData.length; i++) {
      final item = allWeeksData[i];
      final type = item['type'] as String?;
      if (type == 'special_content' || type == 'social_activity') {
        extraPages.add({
          'type': type,
          'title': (item['title'] as String? ?? '').trim(),
          'page_index': i,
        });
      }
      if (item['type'] != 'break') continue;
      int? previousWeek;
      for (var j = i - 1; j >= 0; j--) {
        final prev = allWeeksData[j];
        if (prev['type'] == 'week' && prev['curriculum_week'] != null) {
          previousWeek = prev['curriculum_week'] as int;
          break;
        }
      }
      if (previousWeek != null) {
        breakAfterWeekCounts[previousWeek] =
            (breakAfterWeekCounts[previousWeek] ?? 0) + 1;
        final indexes = breakPageIndexesByAfterWeek.putIfAbsent(
          previousWeek,
          () => <int>[],
        );
        indexes.add(i);
      }
    }
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
    final effectiveSelectedTopicId = filteredTopics.any((t) => t['topic_id'] == selectedTopicId)
        ? selectedTopicId
        : (filteredTopics.isNotEmpty ? filteredTopics.first['topic_id'] as int? : null);
    final selectedUnitTitle = unitOptions
            .firstWhere(
              (u) => u['unit_id'] == effectiveUnitId,
              orElse: () => <String, dynamic>{'unit_title': 'Ünite seçiniz'},
            )['unit_title'] as String? ??
        'Ünite seçiniz';

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
                breakAfterWeekCounts: breakAfterWeekCounts,
                breakPageIndexesByAfterWeek: breakPageIndexesByAfterWeek,
                extraPages: extraPages,
                selectedWeek: widget.curriculumWeek,
                actualCurrentWeek: actualCurrentWeek,
                solvedWeeks: solvedWeeks,
                palette: widget.palette,
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
                onSelectBreakPageIndex: (breakPageIndex) async {
                  if (breakPageIndex < 0 || breakPageIndex >= allWeeksData.length) return;
                  final viewModel = ref.read(outcomesViewModelProvider(widget.args));
                  await viewModel.pageController.animateToPage(
                    breakPageIndex,
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
    final selectedTopicTitle = (widget.topics
            .firstWhere(
              (topic) => topic['topic_id'] == widget.selectedTopicId,
              orElse: () => <String, dynamic>{'topic_title': ''},
            )['topic_title'] as String? ??
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
            color: widget.palette.primary.withOpacity(0.2),
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
                color: const Color(0xFFBFD6FF).withOpacity(0.22),
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
                color: const Color(0xFFFFD9B8).withOpacity(0.18),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.72),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: widget.palette.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: widget.palette.primary.withOpacity(0.13),
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
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
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
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.palette.primary.withOpacity(0.12),
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
                    key: ValueKey('${widget.topics.first['unit_id']}_${widget.topics.length}'),
                    children: widget.topics.map((topic) {
                      final topicId = topic['topic_id'] as int?;
                      final title = (topic['topic_title'] as String? ?? 'Konu').trim();
                      final isSelected = topicId != null && topicId == widget.selectedTopicId;
                      final status = _statusLabel(topic);
                      final weekRange = _weekRangeLabel(topic);
                      final bool isCurrent = status == 'Bu Hafta';
                      return Container(
                        margin: const EdgeInsets.only(top: 7),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [widget.palette.soft, const Color(0xFFF3F8FF)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : const LinearGradient(
                                  colors: [Color(0xFFFFFFFF), Color(0xFFF8FBFF)],
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
                                color: widget.palette.primary.withOpacity(0.18),
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
                                  ? widget.palette.primary.withOpacity(0.12)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(
                              isSelected ? Icons.bookmark_rounded : Icons.book_outlined,
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
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            '$status • $weekRange',
                            style: TextStyle(
                              fontSize: 11,
                          color: isCurrent
                                  ? widget.palette.primary
                                  : Colors.grey.shade600,
                              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: isSelected
                                ? widget.palette.primary
                                : Colors.grey.shade500,
                          ),
                          onTap: topicId == null ? null : () => widget.onSelectTopic(topicId),
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
  final List<Map<String, dynamic>> extraPages;
  final int selectedWeek;
  final int actualCurrentWeek;
  final Set<int> solvedWeeks;
  final _LessonThemePalette palette;
  final ValueChanged<int> onSelectWeek;
  final ValueChanged<int> onSelectBreakPageIndex;

  const _WeekStripBar({
    required this.weekNumbers,
    required this.breakAfterWeekCounts,
    required this.breakPageIndexesByAfterWeek,
    required this.extraPages,
    required this.selectedWeek,
    required this.actualCurrentWeek,
    required this.solvedWeeks,
    required this.palette,
    required this.onSelectWeek,
    required this.onSelectBreakPageIndex,
  });

  @override
  State<_WeekStripBar> createState() => _WeekStripBarState();
}

class _WeekStripBarState extends State<_WeekStripBar> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _weekKeys = <int, GlobalKey>{};
  static bool _didGlobalInitialCentering = false;
  bool _didInitialCentering = false;

  GlobalKey _keyForWeek(int week) {
    return _weekKeys.putIfAbsent(week, () => GlobalKey());
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
            _centerWeek(
              week,
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
      final initialWeek = !_didGlobalInitialCentering
          ? (widget.weekNumbers.contains(widget.actualCurrentWeek)
              ? widget.actualCurrentWeek
              : widget.weekNumbers.contains(widget.selectedWeek)
                  ? widget.selectedWeek
                  : widget.weekNumbers.first)
          : (widget.weekNumbers.contains(widget.selectedWeek)
              ? widget.selectedWeek
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
    if (oldWidget.selectedWeek != widget.selectedWeek) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final weekToCenter = widget.weekNumbers.contains(widget.selectedWeek)
            ? widget.selectedWeek
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
            'Hafta Akışı • Şu an: ${widget.actualCurrentWeek}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
          if (widget.extraPages.isNotEmpty) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: widget.extraPages.map((entry) {
                  final type = entry['type'] as String? ?? '';
                  final title = entry['title'] as String? ?? '';
                  final pageIndex = entry['page_index'] as int?;
                  final isSpecial = type == 'special_content';
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      onPressed: pageIndex == null
                          ? null
                          : () => widget.onSelectBreakPageIndex(pageIndex),
                      backgroundColor: isSpecial
                          ? const Color(0xFFEAF2FF)
                          : const Color(0xFFEAF7F3),
                      side: BorderSide(
                        color: isSpecial
                            ? const Color(0xFFC8DBFF)
                            : const Color(0xFFBFE9DE),
                      ),
                      label: Text(
                        isSpecial ? 'Özel: $title' : 'Etkinlik: $title',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSpecial
                              ? const Color(0xFF2F6FE4)
                              : const Color(0xFF16A085),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 8),
          SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: Row(
              children: widget.weekNumbers.map((week) {
                final isSelected = week == widget.selectedWeek;
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
                        onTap: () => widget.onSelectWeek(week),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? widget.palette.primary
                                : isCurrent
                                    ? const Color(0xFFFFE7CB)
                                    : isPast
                                        ? const Color(0xFFE8F0FF)
                                        : Colors.white,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: isCurrent
                                  ? widget.palette.warm
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
                                              ? widget.palette.primary
                                              : Colors.grey.shade700,
                                ),
                              ),
                              if (isCurrent) ...[
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
                      ...List.generate(
                        widget.breakAfterWeekCounts[week] ?? 0,
                        (index) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: (widget.breakPageIndexesByAfterWeek[week] != null &&
                                    widget.breakPageIndexesByAfterWeek[week]!.length > index)
                                ? () => widget.onSelectBreakPageIndex(
                                      widget.breakPageIndexesByAfterWeek[week]![index],
                                    )
                                : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE4EC),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: const Color(0xFFFFB0C7)),
                              ),
                              child: const Text(
                                'T',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFC43D67),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
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
            title: 'Süreç Bileşenleri',
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
