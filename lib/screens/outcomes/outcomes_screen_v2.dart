import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:egitim_uygulamasi/viewmodels/outcomes_viewmodel.dart';
import 'package:egitim_uygulamasi/screens/outcomes/widgets/header_view.dart';
import 'package:egitim_uygulamasi/screens/outcomes/widgets/topic_content_view.dart';
import 'package:egitim_uygulamasi/screens/outcomes/widgets/weekly_test_view.dart';
import 'package:egitim_uygulamasi/screens/outcomes/widgets/unit_test_view.dart';
import 'package:egitim_uygulamasi/screens/outcomes/widgets/special_cards_view.dart';
import 'package:egitim_uygulamasi/screens/outcomes/widgets/app_bar_view.dart';
import 'package:egitim_uygulamasi/screens/outcomes/widgets/admin_question_shortcut_card.dart';
import 'package:egitim_uygulamasi/screens/outcomes/widgets/admin_content_shortcut_card.dart';
import 'package:egitim_uygulamasi/viewmodels/profile_viewmodel.dart'; // profileViewModelProvider için
import 'package:egitim_uygulamasi/models/topic_content.dart';
import 'package:egitim_uygulamasi/utils/date_utils.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:egitim_uygulamasi/admin/pages/smart_question_addition/smart_question_addition_page.dart';
import 'package:egitim_uygulamasi/admin/pages/smart_content_addition/smart_content_addition_page.dart';
import 'package:egitim_uygulamasi/admin/pages/smart_content_addition/smart_content_update_page.dart';

const bool _enableOutcomesV2Entry = false;

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

class OutcomesScreenV2 extends ConsumerStatefulWidget {
  final int lessonId;
  final int gradeId;
  final String gradeName;
  final String lessonName;
  final int? initialCurriculumWeek;

  const OutcomesScreenV2({
    super.key,
    required this.lessonId,
    required this.gradeId,
    required this.gradeName,
    required this.lessonName,
    this.initialCurriculumWeek,
  });

  @override
  ConsumerState<OutcomesScreenV2> createState() => _OutcomesScreenV2State();
}

class _OutcomesScreenV2State extends ConsumerState<OutcomesScreenV2> {
  double _textScale = 1.0;
  final String _providerInstanceKey = UniqueKey().toString();
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

  void _openOutcomesV2() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OutcomesScreenV2(
          lessonId: widget.lessonId,
          gradeId: widget.gradeId,
          gradeName: widget.gradeName,
          lessonName: widget.lessonName,
          initialCurriculumWeek: widget.initialCurriculumWeek,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModelArgs = OutcomesViewModelArgs(
      lessonId: widget.lessonId,
      gradeId: widget.gradeId,
      initialCurriculumWeek: widget.initialCurriculumWeek,
      instanceKey: _providerInstanceKey,
    );
    final viewModel = ref.watch(outcomesViewModelProvider(viewModelArgs));
    final mediaQuery = MediaQuery.of(context);
    final palette = _paletteForLesson(widget.lessonId);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppleStyleAppBar(
        title: widget.lessonName,
        backgroundColor: Colors.white,
        actions: [
          ..._buildTextScaleActions(),
          if (_enableOutcomesV2Entry)
            IconButton(
              tooltip: 'Outcomes V2',
              onPressed: _openOutcomesV2,
              icon: const Icon(Icons.auto_awesome_rounded),
            ),
        ],
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
                    final anchorWeek =
                        viewModel.timelineItems[index].anchorWeek;
                    if (anchorWeek == null) {
                      return ErrorCard(errorMessage: 'Hafta verisi bozuk');
                    }

                    final page = RepaintBoundary(
                      child: MediaQuery(
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
                          gradeName: widget.gradeName,
                          lessonName: widget.lessonName,
                        ),
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
  final String gradeName;
  final String lessonName;

  const _WeekContentView({
    super.key,
    required this.curriculumWeek,
    required this.pageData,
    required this.args,
    required this.palette,
    required this.gradeName,
    required this.lessonName,
  });

  @override
  ConsumerState<_WeekContentView> createState() => _WeekContentViewState();
}

class _WeekContentViewState extends ConsumerState<_WeekContentView>
    with AutomaticKeepAliveClientMixin {
  int? _selectedSectionIndex;
  int? _selectedUnitId;

  int _pickDefaultSectionIndex(
    List<Map<String, dynamic>> sections, {
    int? preferredUnitId,
  }) {
    if (sections.isEmpty) return 0;

    bool hasContentOrOutcome(Map<String, dynamic> section) {
      final hasContents = (section['contents'] as List?)?.isNotEmpty ?? false;
      final hasOutcomes = (section['outcomes'] as List?)?.isNotEmpty ?? false;
      return hasContents || hasOutcomes;
    }

    if (preferredUnitId != null) {
      final preferredRichIndex = sections.indexWhere(
        (s) => s['unit_id'] == preferredUnitId && hasContentOrOutcome(s),
      );
      if (preferredRichIndex != -1) return preferredRichIndex;
    }

    final withContentsIndex = sections.indexWhere(
      (s) => (s['contents'] as List?)?.isNotEmpty ?? false,
    );
    if (withContentsIndex != -1) return withContentsIndex;

    final withOutcomesIndex = sections.indexWhere(
      (s) => (s['outcomes'] as List?)?.isNotEmpty ?? false,
    );
    if (withOutcomesIndex != -1) return withOutcomesIndex;

    if (preferredUnitId != null) {
      final preferredAnyIndex = sections.indexWhere(
        (s) => s['unit_id'] == preferredUnitId,
      );
      if (preferredAnyIndex != -1) return preferredAnyIndex;
    }

    return 0;
  }

  Future<void> _showUnitPicker(
    BuildContext context,
    List<Map<String, dynamic>> units,
    int? selectedUnitId,
    List<Map<String, dynamic>> allTopics,
    List<Map<String, dynamic>> currentSections,
  ) async {
    final selectedTopicIdInWeek =
        (_selectedSectionIndex != null &&
            _selectedSectionIndex! >= 0 &&
            _selectedSectionIndex! < currentSections.length)
        ? currentSections[_selectedSectionIndex!]['topic_id'] as int?
        : null;

    final picked = await showModalBottomSheet<Map<String, int>>(
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
                                      final unitTopics = allTopics
                                          .where((t) => t['unit_id'] == unitId)
                                          .toList();
                                      final icon =
                                          unitIcons[index % unitIcons.length];
                                      final iconColor =
                                          unitColors[index % unitColors.length];
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 5,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              onTap: unitId == null
                                                  ? null
                                                  : () => Navigator.of(
                                                      context,
                                                    ).pop({'unit_id': unitId}),
                                              child: AnimatedContainer(
                                                duration: const Duration(
                                                  milliseconds: 180,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
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
                                                        ? const Color(
                                                            0xFF2F6FE4,
                                                          )
                                                        : Colors.grey.shade300,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 34,
                                                      height: 34,
                                                      decoration: BoxDecoration(
                                                        color: iconColor
                                                            .withValues(
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
                                                          ? const Color(
                                                              0xFF2F6FE4,
                                                            )
                                                          : Colors
                                                                .grey
                                                                .shade600,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            if (unitTopics.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  left: 16,
                                                  right: 6,
                                                  top: 6,
                                                ),
                                                child: Column(
                                                  children: unitTopics.map((
                                                    topic,
                                                  ) {
                                                    final topicId =
                                                        topic['topic_id']
                                                            as int?;
                                                    final topicTitle =
                                                        (topic['topic_title']
                                                                    as String? ??
                                                                'Konu')
                                                            .trim();
                                                    final topicWeeksRaw =
                                                        (topic['weeks']
                                                                as List?)
                                                            ?.whereType<num>()
                                                            .map(
                                                              (w) => w.toInt(),
                                                            )
                                                            .toSet()
                                                            .toList() ??
                                                        <int>[];
                                                    topicWeeksRaw.sort();
                                                    final topicWeeksText =
                                                        topicWeeksRaw.isEmpty
                                                        ? ''
                                                        : topicWeeksRaw.join(
                                                            ', ',
                                                          );
                                                    final isTopicSelected =
                                                        topicId != null &&
                                                        topicId ==
                                                            selectedTopicIdInWeek;
                                                    return Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            bottom: 4,
                                                          ),
                                                      child: InkWell(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                        onTap:
                                                            (unitId == null ||
                                                                topicId == null)
                                                            ? null
                                                            : () =>
                                                                  Navigator.of(
                                                                    context,
                                                                  ).pop({
                                                                    'unit_id':
                                                                        unitId,
                                                                    'topic_id':
                                                                        topicId,
                                                                  }),
                                                        child: Container(
                                                          width:
                                                              double.infinity,
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 10,
                                                                vertical: 8,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color:
                                                                isTopicSelected
                                                                ? const Color(
                                                                    0xFFEAF2FF,
                                                                  )
                                                                : Colors.white,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  10,
                                                                ),
                                                            border: Border.all(
                                                              color:
                                                                  isTopicSelected
                                                                  ? const Color(
                                                                      0xFF2F6FE4,
                                                                    )
                                                                  : const Color(
                                                                      0xFFDDE8FB,
                                                                    ),
                                                            ),
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .article_outlined,
                                                                size: 16,
                                                                color:
                                                                    isTopicSelected
                                                                    ? const Color(
                                                                        0xFF2F6FE4,
                                                                      )
                                                                    : Colors
                                                                          .grey
                                                                          .shade700,
                                                              ),
                                                              const SizedBox(
                                                                width: 8,
                                                              ),
                                                              Expanded(
                                                                child: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Text(
                                                                      topicTitle,
                                                                      style: TextStyle(
                                                                        fontSize:
                                                                            12.5,
                                                                        fontWeight:
                                                                            isTopicSelected
                                                                            ? FontWeight.w700
                                                                            : FontWeight.w500,
                                                                        color: Colors
                                                                            .grey
                                                                            .shade900,
                                                                      ),
                                                                    ),
                                                                    if (topicWeeksText
                                                                        .isNotEmpty) ...[
                                                                      const SizedBox(
                                                                        height:
                                                                            2,
                                                                      ),
                                                                      Text(
                                                                        'Hafta: $topicWeeksText',
                                                                        style: TextStyle(
                                                                          fontSize:
                                                                              11.5,
                                                                          fontWeight:
                                                                              FontWeight.w600,
                                                                          color:
                                                                              isTopicSelected
                                                                              ? const Color(
                                                                                  0xFF2F6FE4,
                                                                                )
                                                                              : Colors.grey.shade600,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ],
                                                                ),
                                                              ),
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
    final pickedUnitId = picked['unit_id'];
    final pickedTopicId = picked['topic_id'];
    if (pickedUnitId == null) return;
    setState(() => _selectedUnitId = pickedUnitId);

    if (pickedTopicId != null) {
      await _handleTopicSelect(
        topicId: pickedTopicId,
        currentSections: currentSections,
      );
      return;
    }

    int? firstTopicForUnit =
        currentSections.firstWhere(
              (section) =>
                  section['unit_id'] == pickedUnitId &&
                  section['topic_id'] != null,
              orElse: () => <String, dynamic>{},
            )['topic_id']
            as int?;
    firstTopicForUnit ??=
        allTopics.firstWhere(
              (topic) => topic['unit_id'] == pickedUnitId,
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

  Future<void> _openSmartQuestionAddition({
    required int selectedUnitId,
    required int selectedTopicId,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SmartQuestionAdditionPage(
          initialGradeId: widget.args.gradeId,
          initialLessonId: widget.args.lessonId,
          initialUnitId: selectedUnitId,
          initialTopicId: selectedTopicId,
          initialCurriculumWeek: widget.curriculumWeek,
          initialUsageType: 'weekly',
        ),
      ),
    );
  }

  Future<void> _openSmartContentAddition({
    required int selectedUnitId,
    required int selectedTopicId,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SmartContentAdditionPage(
          initialGradeId: widget.args.gradeId,
          initialLessonId: widget.args.lessonId,
          initialUnitId: selectedUnitId,
          initialTopicId: selectedTopicId,
          initialCurriculumWeek: widget.curriculumWeek,
          initialUsageType: 'weekly',
        ),
      ),
    );
  }

  Future<void> _openSmartContentUpdate({
    required int selectedUnitId,
    required int selectedTopicId,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SmartContentUpdatePage(
          initialGradeId: widget.args.gradeId,
          initialLessonId: widget.args.lessonId,
          initialUnitId: selectedUnitId,
          initialTopicId: selectedTopicId,
          initialCurriculumWeek: widget.curriculumWeek,
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final viewModel = ref.read(outcomesViewModelProvider(widget.args));
        viewModel.ensureWeekDataByCurriculumWeek(widget.curriculumWeek);
        final exactPageIndex = widget.pageData['_page_index'] as int?;
        final index =
            exactPageIndex ??
            viewModel.allWeeksData.indexWhere(
              (w) => w['curriculum_week'] == widget.curriculumWeek,
            );
        if (index != -1) {
          final attachedCount = viewModel.pageController.positions.length;
          final hasSingleAttachment = attachedCount == 1;
          if (!viewModel.pageController.hasClients || !hasSingleAttachment) {
            viewModel.onPageChanged(index);
          } else if (viewModel.pageController.page?.round() == index) {
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
    final rawSelectedIndex = _selectedSectionIndex ?? -1;
    final baseSelectedIndex =
        (rawSelectedIndex >= 0 && rawSelectedIndex < sections.length)
        ? rawSelectedIndex
        : _pickDefaultSectionIndex(sections, preferredUnitId: _selectedUnitId);
    final baseSelectedSection = sections[baseSelectedIndex];
    final baseSelectedUnitId = baseSelectedSection['unit_id'] as int?;
    final baseSelectedTopicId = baseSelectedSection['topic_id'] as int?;
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

    final selectedUnitFromSection = baseSelectedUnitId;
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
    final starterTopicInWeek =
        filteredTopics.where((t) {
          final topicId = t['topic_id'] as int?;
          if (topicId == null) return false;
          final isInCurrentSections = sections.any(
            (s) => s['topic_id'] == topicId,
          );
          if (!isInCurrentSections) return false;
          return (t['first_week'] as int?) == widget.curriculumWeek;
        }).toList()..sort((a, b) {
          final aOrder = a['topic_order'] as int? ?? 0;
          final bOrder = b['topic_order'] as int? ?? 0;
          return aOrder.compareTo(bOrder);
        });
    final defaultFocusedTopicId = starterTopicInWeek.isNotEmpty
        ? starterTopicInWeek.first['topic_id'] as int?
        : null;
    final effectiveSelectedTopicId =
        _selectedSectionIndex == null && defaultFocusedTopicId != null
        ? defaultFocusedTopicId
        : filteredTopics.any((t) => t['topic_id'] == baseSelectedTopicId)
        ? baseSelectedTopicId
        : (filteredTopics.isNotEmpty
              ? filteredTopics.first['topic_id'] as int?
              : null);
    final resolvedSectionIndex = effectiveSelectedTopicId == null
        ? -1
        : sections.indexWhere((s) => s['topic_id'] == effectiveSelectedTopicId);
    final safeSelectedIndex = resolvedSectionIndex != -1
        ? resolvedSectionIndex
        : baseSelectedIndex;
    if (_selectedSectionIndex != safeSelectedIndex) {
      _selectedSectionIndex = safeSelectedIndex;
    }

    final selectedSection = sections[safeSelectedIndex];
    final firstSection = sections.isNotEmpty ? sections.first : null;
    final selectedUnitId = selectedSection['unit_id'] as int?;
    final selectedTopicId = selectedSection['topic_id'] as int?;
    final shortcutUnitId = (firstSection?['unit_id'] as int?) ?? selectedUnitId;
    final shortcutTopicId =
        (firstSection?['topic_id'] as int?) ?? selectedTopicId;
    final selectedUnitTitle =
        unitOptions.firstWhere(
              (u) => u['unit_id'] == effectiveUnitId,
              orElse: () => <String, dynamic>{'unit_title': 'Ünite seçiniz'},
            )['unit_title']
            as String? ??
        'Ünite seçiniz';
    final selectedTopicTitleFromMenu =
        topicMenu.firstWhere(
              (t) => t['topic_id'] == selectedTopicId,
              orElse: () => <String, dynamic>{'topic_title': ''},
            )['topic_title']
            as String? ??
        '';
    final selectedTopicMeta = topicMenu.firstWhere(
      (t) => t['topic_id'] == selectedTopicId,
      orElse: () => <String, dynamic>{},
    );
    final selectedTopicWeeks =
        (selectedTopicMeta['weeks'] as List? ?? const <dynamic>[])
            .whereType<num>()
            .map((w) => w.toInt())
            .toSet()
            .toList()
          ..sort();
    final topicStartWeek = selectedTopicWeeks.isEmpty
        ? widget.curriculumWeek
        : selectedTopicWeeks.first;
    final topicEndWeek = selectedTopicWeeks.isEmpty
        ? widget.curriculumWeek
        : selectedTopicWeeks.last;
    final topicWeekCount = selectedTopicWeeks.isEmpty
        ? 1
        : selectedTopicWeeks.length;
    int topicWeekPosition =
        selectedTopicWeeks.indexOf(widget.curriculumWeek) + 1;
    if (topicWeekPosition <= 0) {
      final passedWeekCount = selectedTopicWeeks
          .where((w) => w <= widget.curriculumWeek)
          .length;
      topicWeekPosition = passedWeekCount.clamp(1, topicWeekCount);
    }
    final selectedSectionUnitTitle =
        (selectedSection['unit_title'] as String? ?? '').trim();
    final selectedSectionTopicTitle =
        (selectedSection['topic_title'] as String? ?? '').trim();
    final headerData = Map<String, dynamic>.from(safeData)
      ..['unit_id'] = selectedUnitId ?? safeData['unit_id']
      ..['topic_id'] = selectedTopicId ?? safeData['topic_id']
      ..['unit_title'] = selectedSectionUnitTitle.isNotEmpty
          ? selectedSectionUnitTitle
          : (selectedUnitTitle.trim().isNotEmpty
                ? selectedUnitTitle.trim()
                : safeData['unit_title'])
      ..['topic_title'] = selectedSectionTopicTitle.isNotEmpty
          ? selectedSectionTopicTitle
          : (selectedTopicTitleFromMenu.trim().isNotEmpty
                ? selectedTopicTitleFromMenu.trim()
                : safeData['topic_title']);

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
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
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
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            sliver: SliverToBoxAdapter(
              child: HeaderView(
                curriculumWeek: widget.curriculumWeek,
                data: headerData,
                pageData: widget.pageData,
                args: widget.args,
                gradeName: widget.gradeName,
                lessonName: widget.lessonName,
                onTapUnits: unitOptions.isEmpty
                    ? null
                    : () => _showUnitPicker(
                        context,
                        unitOptions,
                        effectiveUnitId,
                        topicMenu,
                        sections,
                      ),
                unitCount: unitOptions.length,
              ),
            ),
          ),
          if (!isSpecialPage)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              sliver: SliverToBoxAdapter(
                child: _TopicProgressHintCard(
                  startWeek: topicStartWeek,
                  endWeek: topicEndWeek,
                  totalWeeks: topicWeekCount,
                  currentWeekPosition: topicWeekPosition,
                ),
              ),
            ),
          if (!isSpecialPage && isAdmin)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              sliver: SliverToBoxAdapter(
                child: AdminQuestionShortcutCard(
                  curriculumWeek: widget.curriculumWeek,
                  onTap: (selectedUnitId == null || selectedTopicId == null)
                      ? null
                      : () => _openSmartQuestionAddition(
                          selectedUnitId: selectedUnitId,
                          selectedTopicId: selectedTopicId,
                        ),
                ),
              ),
            ),
          if (!isSpecialPage && isAdmin)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              sliver: SliverToBoxAdapter(
                child: AdminContentShortcutCard(
                  curriculumWeek: widget.curriculumWeek,
                  onTapAdd: (shortcutUnitId == null || shortcutTopicId == null)
                      ? null
                      : () => _openSmartContentAddition(
                          selectedUnitId: shortcutUnitId,
                          selectedTopicId: shortcutTopicId,
                        ),
                  onTapUpdate:
                      (shortcutUnitId == null || shortcutTopicId == null)
                      ? null
                      : () => _openSmartContentUpdate(
                          selectedUnitId: shortcutUnitId,
                          selectedTopicId: shortcutTopicId,
                        ),
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
          if (isSpecialPage)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              sliver: SliverToBoxAdapter(
                child: _SpecialInfoContentCard(pageData: widget.pageData),
              ),
            ),
          if (!isSpecialPage)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: _WeekSectionsBlock(
                  sections: sections,
                  focusedTopicId: selectedTopicId,
                  onFocusTopic: (topicId) {
                    final index = sections.indexWhere(
                      (s) => s['topic_id'] == topicId,
                    );
                    if (index == -1) return;
                    if (mounted) {
                      setState(() => _selectedSectionIndex = index);
                    }
                  },
                  isAdmin: isAdmin,
                  onContentUpdated: () => ref
                      .read(outcomesViewModelProvider(widget.args))
                      .refreshCurrentWeekData(widget.curriculumWeek),
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

class _SpecialInfoContentCard extends StatelessWidget {
  final Map<String, dynamic> pageData;

  const _SpecialInfoContentCard({required this.pageData});

  String _defaultHtmlForType(String type, String title, String duration) {
    if (type == 'break') {
      final safeTitle = title.isNotEmpty ? title : 'Tatil Haftasi';
      final safeDuration = duration.isNotEmpty ? duration : 'Planli ara donem';
      return '''
<p><strong>$safeTitle</strong></p>
<p>Bu hafta ders icerigi yerine planli tatil uygulanir.</p>
<ul>
  <li>Sure: $safeDuration</li>
  <li>Oneri: Kisa tekrar ve dinlenme dengesi kurun.</li>
</ul>
''';
    }
    if (type == 'social_activity') {
      return '''
<p><strong>Sosyal Etkinlik Haftasi</strong></p>
<p>Bu hafta sosyal-duygusal gelisim ve isbirligi odaklidir.</p>
<ul>
  <li>Kisa grup etkinligi planlayin.</li>
  <li>Hafta sonu kisa yansitma yaptirin.</li>
</ul>
''';
    }
    return '''
<p><strong>Bilgilendirme</strong></p>
<p>Bu hafta icin ozel bir icerik planlanmistir.</p>
''';
  }

  @override
  Widget build(BuildContext context) {
    final type = pageData['type'] as String? ?? 'special_content';
    final title = (pageData['title'] as String? ?? '').trim();
    final duration = (pageData['duration'] as String? ?? '').trim();
    final rawContent = (pageData['content'] as String? ?? '').trim();
    final htmlContent = rawContent.isNotEmpty
        ? rawContent
        : _defaultHtmlForType(type, title, duration);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF4F8FF)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD8E6FF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9EBBEE).withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.menu_book_rounded, size: 18, color: Color(0xFF2F6FE4)),
              SizedBox(width: 8),
              Text(
                'Bilgilendirme Icerigi',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2F4FA8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Html(
            data: htmlContent,
            style: {
              'body': Style(
                margin: Margins.zero,
                padding: HtmlPaddings.zero,
                fontSize: FontSize(13),
                lineHeight: const LineHeight(1.45),
                color: const Color(0xFF334155),
              ),
              'p': Style(margin: Margins.only(bottom: 8)),
              'ul': Style(margin: Margins.only(left: 14, bottom: 8)),
              'li': Style(margin: Margins.only(bottom: 4)),
              'strong': Style(fontWeight: FontWeight.w700),
            },
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

class _TopicProgressHintCard extends StatelessWidget {
  final int startWeek;
  final int endWeek;
  final int totalWeeks;
  final int currentWeekPosition;

  const _TopicProgressHintCard({
    required this.startWeek,
    required this.endWeek,
    required this.totalWeeks,
    required this.currentWeekPosition,
  });

  @override
  Widget build(BuildContext context) {
    final safeTotal = totalWeeks < 1 ? 1 : totalWeeks;
    final safePosition = currentWeekPosition.clamp(1, safeTotal);

    // Cok uzun surelerde ekrani sade tutmak icin nokta sayisini sinirliyoruz.
    final nodeCount = safeTotal <= 5 ? safeTotal : 5;
    final activeNodeIndex = safeTotal == 1
        ? 0
        : (((safePosition - 1) / (safeTotal - 1)) * (nodeCount - 1)).round();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE6F4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$safeTotal haftalik konu - $safePosition. hafta',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF23344E),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '$startWeek',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: List.generate(nodeCount * 2 - 1, (index) {
                    if (index.isEven) {
                      final nodeIndex = index ~/ 2;
                      final isActive = nodeIndex <= activeNodeIndex;
                      return Container(
                        width: isActive ? 8 : 7,
                        height: isActive ? 8 : 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? const Color(0xFF2F6FE4)
                              : const Color(0xFFBECDE7),
                        ),
                      );
                    }
                    final leftNodeIndex = (index - 1) ~/ 2;
                    final isActive = leftNodeIndex < activeNodeIndex;
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 2,
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF2F6FE4)
                              : const Color(0xFFD6E0F0),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$endWeek',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekSectionsBlock extends StatelessWidget {
  final List<Map<String, dynamic>> sections;
  final int? focusedTopicId;
  final ValueChanged<int> onFocusTopic;
  final bool isAdmin;
  final VoidCallback onContentUpdated;

  const _WeekSectionsBlock({
    required this.sections,
    required this.focusedTopicId,
    required this.onFocusTopic,
    required this.isAdmin,
    required this.onContentUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final visibleSections = sections
        .map((section) {
          final contents = (section['contents'] as List? ?? [])
              .whereType<Map>()
              .map((c) => TopicContent.fromJson(Map<String, dynamic>.from(c)))
              .toList();
          return {
            'section': section,
            'contents': contents,
            'topic_id': section['topic_id'] as int?,
          };
        })
        .where((entry) => (entry['contents'] as List).isNotEmpty)
        .toList();

    if (visibleSections.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDDE8FB)),
        ),
        child: Text(
          'Bu konu için haftaya bağlı içerik bulunamadı. Kazanımları kontrol ederek devam edebilirsin.',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    final resolvedFocusedTopicId =
        (focusedTopicId != null &&
            visibleSections.any((e) => e['topic_id'] == focusedTopicId))
        ? focusedTopicId
        : visibleSections.first['topic_id'] as int?;
    final focusedEntry = visibleSections.firstWhere(
      (e) => e['topic_id'] == resolvedFocusedTopicId,
      orElse: () => visibleSections.first,
    );
    final secondaryEntries = visibleSections
        .where((e) => e['topic_id'] != focusedEntry['topic_id'])
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SingleSectionContentCard(
          section: Map<String, dynamic>.from(focusedEntry['section'] as Map),
          contents: (focusedEntry['contents'] as List)
              .whereType<TopicContent>()
              .toList(),
          isAdmin: isAdmin,
          onContentUpdated: onContentUpdated,
        ),
        for (var i = 0; i < secondaryEntries.length; i++)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: _SectionSummaryCard(
              section: Map<String, dynamic>.from(
                secondaryEntries[i]['section'] as Map,
              ),
              onTap: () {
                final topicId = secondaryEntries[i]['topic_id'] as int?;
                if (topicId != null) onFocusTopic(topicId);
              },
            ),
          ),
      ],
    );
  }
}

class _SectionSummaryCard extends StatelessWidget {
  final Map<String, dynamic> section;
  final VoidCallback onTap;

  const _SectionSummaryCard({required this.section, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final unitTitle = (section['unit_title'] as String? ?? '').trim();
    final topicTitle = (section['topic_title'] as String? ?? 'Konu').trim();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDCE5F3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (unitTitle.isNotEmpty)
                    Text(
                      unitTitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  Text(
                    topicTitle,
                    style: const TextStyle(
                      fontSize: 14.5,
                      color: Color(0xFF13243D),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF2F6FE4),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _SingleSectionContentCard extends StatefulWidget {
  final Map<String, dynamic> section;
  final List<TopicContent> contents;
  final bool isAdmin;
  final VoidCallback onContentUpdated;

  const _SingleSectionContentCard({
    required this.section,
    required this.contents,
    required this.isAdmin,
    required this.onContentUpdated,
  });

  @override
  State<_SingleSectionContentCard> createState() =>
      _SingleSectionContentCardState();
}

class _SingleSectionContentCardState extends State<_SingleSectionContentCard> {
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant _SingleSectionContentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.contents.isEmpty) {
      _currentPageIndex = 0;
      return;
    }
    if (_currentPageIndex >= widget.contents.length) {
      _currentPageIndex = widget.contents.length - 1;
    }
  }

  Future<void> _goToPage(int index) async {
    if (index < 0 || index >= widget.contents.length) return;
    if (!mounted) return;
    setState(() => _currentPageIndex = index);
  }

  Widget _buildMiniPager() {
    if (widget.contents.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            onTap: _currentPageIndex > 0
                ? () => _goToPage(_currentPageIndex - 1)
                : null,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.chevron_left_rounded,
                size: 20,
                color: _currentPageIndex > 0
                    ? const Color(0xFF2F6FE4)
                    : const Color(0xFFB8C6DF),
              ),
            ),
          ),
          const SizedBox(width: 4),
          ...List.generate(widget.contents.length, (index) {
            final isActive = index == _currentPageIndex;
            return Container(
              width: isActive ? 8 : 7,
              height: isActive ? 8 : 7,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? const Color(0xFF2F6FE4)
                    : const Color(0xFFCAD7ED),
              ),
            );
          }),
          const SizedBox(width: 4),
          InkWell(
            onTap: _currentPageIndex < widget.contents.length - 1
                ? () => _goToPage(_currentPageIndex + 1)
                : null,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: _currentPageIndex < widget.contents.length - 1
                    ? const Color(0xFF2F6FE4)
                    : const Color(0xFFB8C6DF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unitTitle = (widget.section['unit_title'] as String? ?? '').trim();
    final topicTitle = (widget.section['topic_title'] as String? ?? '').trim();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE8FB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (unitTitle.isNotEmpty || topicTitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (unitTitle.isNotEmpty)
                    Text(
                      unitTitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (topicTitle.isNotEmpty)
                    Text(
                      topicTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF13243D),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
            ),
          _buildMiniPager(),
          if (widget.contents.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 6),
              child: Text(
                '${_currentPageIndex + 1} / ${widget.contents.length}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (widget.contents.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F8FC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFDCE5F3)),
                ),
                child: Text(
                  'Bu konu için içerik bulunamadı.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: TopicContentView(
                  key: ValueKey(
                    widget.contents[_currentPageIndex].id ?? _currentPageIndex,
                  ),
                  content: widget.contents[_currentPageIndex],
                  isAdmin: widget.isAdmin,
                  onContentUpdated: widget.onContentUpdated,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
