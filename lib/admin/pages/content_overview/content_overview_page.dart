import 'package:egitim_uygulamasi/screens/outcomes/outcomes_screen_v2.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ContentOverviewPage extends StatefulWidget {
  const ContentOverviewPage({super.key});

  @override
  State<ContentOverviewPage> createState() => _ContentOverviewPageState();
}

class _ContentOverviewPageState extends State<ContentOverviewPage> {
  final SupabaseClient _client = Supabase.instance.client;

  int _selectedWeek = 1;
  bool _isLoading = false;
  String? _error;
  List<_LessonWeekStatus> _statuses = const [];
  String _selectedGradeFilter = 'Tümü';

  @override
  void initState() {
    super.initState();
    _loadWeekSummary();
  }

  Future<void> _loadWeekSummary() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final lessonGradeRaw = await _client
          .from('lesson_grades')
          .select(
            'grade_id, lesson_id, is_active, '
            'grades!inner(id, name, order_no, is_active), '
            'lessons!inner(id, name, order_no, is_active)',
          )
          .eq('is_active', true)
          .eq('grades.is_active', true)
          .eq('lessons.is_active', true);

      final lessonGradePairs = (lessonGradeRaw as List)
          .whereType<Map<String, dynamic>>()
          .map(_LessonGradePair.fromRow)
          .toList();

      final unitGradeRaw = await _client
          .from('unit_grades')
          .select(
            'grade_id, unit_id, start_week, end_week, '
            'units!inner(id, title, lesson_id, order_no, is_active)',
          )
          .eq('units.is_active', true);

      final unitAssignments = (unitGradeRaw as List)
          .whereType<Map<String, dynamic>>()
          .map(_UnitAssignment.fromRow)
          .toList(growable: false);

      final unitIds = unitAssignments.map((u) => u.unitId).toSet().toList();

      List<_TopicRow> topics = const [];
      if (unitIds.isNotEmpty) {
        final topicsRaw = await _client
            .from('topics')
            .select('id, unit_id, title, order_no, is_active')
            .inFilter('unit_id', unitIds)
            .eq('is_active', true);

        topics = (topicsRaw as List)
            .whereType<Map<String, dynamic>>()
            .map(_TopicRow.fromRow)
            .toList(growable: false);
      }

      final topicIds = topics.map((t) => t.topicId).toSet().toList();
      final topicsByUnit = <int, List<_TopicRow>>{};
      for (final topic in topics) {
        topicsByUnit.putIfAbsent(topic.unitId, () => <_TopicRow>[]).add(topic);
      }

      final topicsWithPublishedContent = <int>{};
      final topicsWithDraftContent = <int>{};
      final questionsByTopic = <int, Set<int>>{};

      if (topicIds.isNotEmpty) {
        // Outcomes ekranındaki hafta çözümlemesiyle aynı mantık:
        // selectedWeek aralığına düşen outcome'lara bağlı içerikleri içerik var kabul et.
        final activeOutcomeIds = <int>{};
        final activeOutcomesRaw = await _client
            .from('outcomes')
            .select('id, topic_id, outcome_weeks!inner(start_week, end_week)')
            .inFilter('topic_id', topicIds)
            .lte('outcome_weeks.start_week', _selectedWeek)
            .gte('outcome_weeks.end_week', _selectedWeek);

        for (final row
            in (activeOutcomesRaw as List).whereType<Map<String, dynamic>>()) {
          final outcomeId = _toInt(row['id']);
          if (outcomeId != null) activeOutcomeIds.add(outcomeId);
        }

        if (activeOutcomeIds.isNotEmpty) {
          final contentOutcomeRaw = await _client
              .from('topic_content_outcomes')
              .select('outcome_id, topic_contents!inner(topic_id, is_published)')
              .inFilter('outcome_id', activeOutcomeIds.toList());

          for (final row
              in (contentOutcomeRaw as List)
                  .whereType<Map<String, dynamic>>()) {
            final topicContentRaw = row['topic_contents'];
            if (topicContentRaw is! Map<String, dynamic>) continue;
            final topicId = _toInt(topicContentRaw['topic_id']);
            if (topicId == null) continue;
            final isPublished = topicContentRaw['is_published'] == true;
            if (isPublished) {
              topicsWithPublishedContent.add(topicId);
            } else {
              topicsWithDraftContent.add(topicId);
            }
          }
        }

        final usagesRaw = await _client
            .from('question_usages')
            .select('topic_id, question_id')
            .eq('usage_type', 'weekly')
            .eq('curriculum_week', _selectedWeek)
            .inFilter('topic_id', topicIds);

        for (final row
            in (usagesRaw as List).whereType<Map<String, dynamic>>()) {
          final topicId = _toInt(row['topic_id']);
          final questionId = _toInt(row['question_id']);
          if (topicId == null || questionId == null) continue;
          questionsByTopic.putIfAbsent(topicId, () => <int>{}).add(questionId);
        }
      }

      final statuses = <_LessonWeekStatus>[];
      final pairByGradeLessonKey = <String, _LessonGradePair>{
        for (final pair in lessonGradePairs)
          '${pair.gradeId}-${pair.lessonId}': pair,
      };

      for (final unit in unitAssignments) {
        final pair = pairByGradeLessonKey['${unit.gradeId}-${unit.lessonId}'];
        if (pair == null) continue;
        final unitTopics = topicsByUnit[unit.unitId] ?? const <_TopicRow>[];
        // içerik güncelle akışı kaldırıldı, topic seçenek listesine gerek yok
      }

      for (final pair in lessonGradePairs) {
        final allRelatedUnits = unitAssignments.where(
          (u) => u.gradeId == pair.gradeId && u.lessonId == pair.lessonId,
        );
        final weekRelatedUnits = allRelatedUnits.where(
          (u) =>
              (u.startWeek == null || u.startWeek! <= _selectedWeek) &&
              (u.endWeek == null || u.endWeek! >= _selectedWeek),
        );

        final topicSetInWeek = <int>{};
        for (final unit in weekRelatedUnits) {
          final unitTopics = topicsByUnit[unit.unitId] ?? const <_TopicRow>[];
          for (final topic in unitTopics) {
            topicSetInWeek.add(topic.topicId);
          }
        }

        final hasPublishedContent =
            topicSetInWeek.any(topicsWithPublishedContent.contains);
        final hasDraftContent =
            topicSetInWeek.any(topicsWithDraftContent.contains);
        final hasContent = hasPublishedContent || hasDraftContent;
        final questionIds = <int>{};
        for (final topicId in topicSetInWeek) {
          questionIds.addAll(questionsByTopic[topicId] ?? const <int>{});
        }

        statuses.add(
          _LessonWeekStatus(
            gradeName: pair.gradeName,
            gradeOrder: pair.gradeOrder,
            lessonName: pair.lessonName,
            lessonOrder: pair.lessonOrder,
            hasContent: hasContent,
            hasDraftContent: hasDraftContent && !hasPublishedContent,
            questionCount: questionIds.length,
            gradeId: pair.gradeId,
            gradeNameForNav: pair.gradeName,
            lessonId: pair.lessonId,
            lessonNameForNav: pair.lessonName,
            preferredUnitId: null,
            preferredTopicId: null,
          ),
        );
      }

      statuses.sort((a, b) {
        final gradeCompare = a.gradeOrder.compareTo(b.gradeOrder);
        if (gradeCompare != 0) return gradeCompare;
        return a.lessonOrder.compareTo(b.lessonOrder);
      });

      if (!mounted) return;
      setState(() {
        _statuses = statuses;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Özet verisi alınamadı: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openOutcomesForLesson(_LessonWeekStatus status) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OutcomesScreenV2(
          lessonId: status.lessonId,
          gradeId: status.gradeId,
          gradeName: status.gradeNameForNav,
          lessonName: status.lessonNameForNav,
          initialCurriculumWeek: _selectedWeek,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Haftalık İçerik Özeti'),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: _isLoading ? null : _loadWeekSummary,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          _WeekPicker(
            selectedWeek: _selectedWeek,
            onWeekSelected: (week) {
              if (week == _selectedWeek) return;
              setState(() => _selectedWeek = week);
              _loadWeekSummary();
            },
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(_error!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    if (_statuses.isEmpty) {
      return const Center(
        child: Text('Bu hafta için gösterilecek ders planı bulunamadı.'),
      );
    }

    final gradeNames = _statuses
        .map((s) => (order: s.gradeOrder, name: s.gradeName))
        .toSet()
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    final filteredStatuses = _selectedGradeFilter == 'Tümü'
        ? _statuses
        : _statuses.where((s) => s.gradeName == _selectedGradeFilter).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      children: [
        _GradeFilterBar(
          selectedGrade: _selectedGradeFilter,
          grades: ['Tümü', ...gradeNames.map((g) => g.name)],
          onSelected: (value) {
            if (value == _selectedGradeFilter) return;
            setState(() => _selectedGradeFilter = value);
          },
        ),
        const SizedBox(height: 10),
        _WeeklyContentStatusCard(
          week: _selectedWeek,
          statuses: filteredStatuses,
          onTapLesson: _openOutcomesForLesson,
        ),
      ],
    );
  }
}

class _GradeFilterBar extends StatelessWidget {
  final String selectedGrade;
  final List<String> grades;
  final ValueChanged<String> onSelected;

  const _GradeFilterBar({
    required this.selectedGrade,
    required this.grades,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sınıf Akışı',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: grades.length,
              separatorBuilder: (_, index) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final grade = grades[index];
                return ChoiceChip(
                  label: Text(grade),
                  selected: grade == selectedGrade,
                  onSelected: (_) => onSelected(grade),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekPicker extends StatelessWidget {
  final int selectedWeek;
  final ValueChanged<int> onWeekSelected;

  const _WeekPicker({required this.selectedWeek, required this.onWeekSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hafta Akışı (1-40)',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 40,
              separatorBuilder: (context, index) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final week = index + 1;
                return ChoiceChip(
                  label: Text('$week'),
                  selected: week == selectedWeek,
                  onSelected: (_) => onWeekSelected(week),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyContentStatusCard extends StatelessWidget {
  final int week;
  final List<_LessonWeekStatus> statuses;
  final ValueChanged<_LessonWeekStatus> onTapLesson;

  const _WeeklyContentStatusCard({
    required this.week,
    required this.statuses,
    required this.onTapLesson,
  });

  Color _questionColor(int count) {
    if (count >= 30) return Colors.green;
    if (count >= 20) return Colors.amber.shade700;
    if (count >= 10) return Colors.orange;
    return Colors.red;
  }

  Color _questionBackground(Color base) => base.withAlpha(26);

  Color _questionBorder(Color base) => base.withAlpha(90);

  Color _contentColor(_LessonWeekStatus lesson) {
    if (!lesson.hasContent) return Colors.red;
    if (lesson.hasDraftContent) return Colors.amber.shade700;
    return Colors.green;
  }

  Color _contentBackground(Color base) => base.withAlpha(26);

  Color _contentBorder(Color base) => base.withAlpha(90);

  String _contentLabel(_LessonWeekStatus lesson) {
    if (!lesson.hasContent) return 'İçerik yok';
    if (lesson.hasDraftContent) return 'Taslak';
    return 'İçerik var';
  }

  IconData _contentIcon(_LessonWeekStatus lesson) {
    if (!lesson.hasContent) return Icons.cancel;
    if (lesson.hasDraftContent) return Icons.timelapse_rounded;
    return Icons.check_circle;
  }

  @override
  Widget build(BuildContext context) {
    final byGrade = <String, List<_LessonWeekStatus>>{};
    for (final item in statuses) {
      byGrade
          .putIfAbsent(item.gradeName, () => <_LessonWeekStatus>[])
          .add(item);
    }
    final isMobile = MediaQuery.of(context).size.width < 760;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '$week. Hafta İçerik Özeti',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        ...byGrade.entries.map((entry) {
          final gradeName = entry.key;
          final gradeLessons = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    gradeName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!isMobile) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F6F8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Expanded(flex: 3, child: Text('Ders')),
                          Expanded(flex: 2, child: Text('İçerik')),
                          Expanded(flex: 1, child: Text('Soru')),
                          Expanded(flex: 2, child: Text('İşlemler')),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  ...gradeLessons.map((lesson) {
                    if (isMobile) {
                      final questionColor = _questionColor(
                        lesson.questionCount,
                      );
                      final contentColor = _contentColor(lesson);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => onTapLesson(lesson),
                                    child: Text(
                                      lesson.lessonName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _contentBackground(contentColor),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: _contentBorder(contentColor),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _contentIcon(lesson),
                                        size: 16,
                                        color: contentColor,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _contentLabel(lesson),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: contentColor,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _questionBackground(questionColor),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: _questionBorder(questionColor),
                                    ),
                                  ),
                                  child: Text(
                                    'Soru: ${lesson.questionCount}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: questionColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final questionColor = _questionColor(
                            lesson.questionCount,
                          );
                          final contentColor = _contentColor(lesson);

                          return Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: InkWell(
                                  onTap: () => onTapLesson(lesson),
                                  child: Text(
                                    lesson.lessonName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Row(
                                  children: [
                                    Icon(
                                      _contentIcon(lesson),
                                      size: 16,
                                      color: contentColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      lesson.hasContent
                                          ? (lesson.hasDraftContent
                                              ? 'Taslak'
                                              : 'Var')
                                          : 'Yok',
                                      style: TextStyle(
                                        color: contentColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  '${lesson.questionCount}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: questionColor,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _LessonGradePair {
  final int gradeId;
  final String gradeName;
  final int gradeOrder;
  final int lessonId;
  final String lessonName;
  final int lessonOrder;

  const _LessonGradePair({
    required this.gradeId,
    required this.gradeName,
    required this.gradeOrder,
    required this.lessonId,
    required this.lessonName,
    required this.lessonOrder,
  });

  factory _LessonGradePair.fromRow(Map<String, dynamic> row) {
    final gradeMap =
        (row['grades'] as Map?)?.cast<String, dynamic>() ?? const {};
    final lessonMap =
        (row['lessons'] as Map?)?.cast<String, dynamic>() ?? const {};
    return _LessonGradePair(
      gradeId: _toInt(row['grade_id']) ?? _toInt(gradeMap['id']) ?? 0,
      gradeName: (gradeMap['name'] as String? ?? '').trim(),
      gradeOrder: _toInt(gradeMap['order_no']) ?? 0,
      lessonId: _toInt(row['lesson_id']) ?? _toInt(lessonMap['id']) ?? 0,
      lessonName: (lessonMap['name'] as String? ?? '').trim(),
      lessonOrder: _toInt(lessonMap['order_no']) ?? 0,
    );
  }
}

class _UnitAssignment {
  final int gradeId;
  final int unitId;
  final int lessonId;
  final String unitTitle;
  final int unitOrder;
  final int? startWeek;
  final int? endWeek;

  const _UnitAssignment({
    required this.gradeId,
    required this.unitId,
    required this.lessonId,
    required this.unitTitle,
    required this.unitOrder,
    required this.startWeek,
    required this.endWeek,
  });

  factory _UnitAssignment.fromRow(Map<String, dynamic> row) {
    final unitMap = (row['units'] as Map?)?.cast<String, dynamic>() ?? const {};
    return _UnitAssignment(
      gradeId: _toInt(row['grade_id']) ?? 0,
      unitId: _toInt(row['unit_id']) ?? _toInt(unitMap['id']) ?? 0,
      lessonId: _toInt(unitMap['lesson_id']) ?? 0,
      unitTitle: (unitMap['title'] as String? ?? '').trim(),
      unitOrder: _toInt(unitMap['order_no']) ?? 0,
      startWeek: _toInt(row['start_week']),
      endWeek: _toInt(row['end_week']),
    );
  }
}

class _TopicRow {
  final int topicId;
  final int unitId;
  final String title;
  final int orderNo;

  const _TopicRow({
    required this.topicId,
    required this.unitId,
    required this.title,
    required this.orderNo,
  });

  factory _TopicRow.fromRow(Map<String, dynamic> row) {
    return _TopicRow(
      topicId: _toInt(row['id']) ?? 0,
      unitId: _toInt(row['unit_id']) ?? 0,
      title: (row['title'] as String? ?? '').trim(),
      orderNo: _toInt(row['order_no']) ?? 0,
    );
  }
}

class _LessonWeekStatus {
  final String gradeName;
  final int gradeOrder;
  final String lessonName;
  final int lessonOrder;
  final bool hasContent;
  final bool hasDraftContent;
  final int questionCount;
  final int gradeId;
  final String gradeNameForNav;
  final int lessonId;
  final String lessonNameForNav;
  final int? preferredUnitId;
  final int? preferredTopicId;

  const _LessonWeekStatus({
    required this.gradeName,
    required this.gradeOrder,
    required this.lessonName,
    required this.lessonOrder,
    required this.hasContent,
    required this.hasDraftContent,
    required this.questionCount,
    required this.gradeId,
    required this.gradeNameForNav,
    required this.lessonId,
    required this.lessonNameForNav,
    required this.preferredUnitId,
    required this.preferredTopicId,
  });
}

int? _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
