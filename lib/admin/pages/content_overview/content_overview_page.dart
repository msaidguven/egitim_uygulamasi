import 'package:egitim_uygulamasi/admin/pages/smart_content_addition/smart_content_addition_page.dart';
import 'package:egitim_uygulamasi/admin/pages/smart_content_addition/smart_content_update_page.dart';
import 'package:egitim_uygulamasi/admin/pages/smart_question_addition/smart_question_addition_page.dart';
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
  List<_TopicSelectionOption> _topicOptions = const [];

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

      final topicsWithContent = <int>{};
      final questionsByTopic = <int, Set<int>>{};

      if (topicIds.isNotEmpty) {
        final contentsRaw = await _client
            .from('topic_contents')
            .select('topic_id, topic_content_weeks!inner(curriculum_week)')
            .inFilter('topic_id', topicIds)
            .eq('topic_content_weeks.curriculum_week', _selectedWeek);

        for (final row
            in (contentsRaw as List).whereType<Map<String, dynamic>>()) {
          final topicId = _toInt(row['topic_id']);
          if (topicId != null) topicsWithContent.add(topicId);
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
      final topicOptions = <_TopicSelectionOption>[];
      final pairByGradeLessonKey = <String, _LessonGradePair>{
        for (final pair in lessonGradePairs)
          '${pair.gradeId}-${pair.lessonId}': pair,
      };

      for (final unit in unitAssignments) {
        final pair = pairByGradeLessonKey['${unit.gradeId}-${unit.lessonId}'];
        if (pair == null) continue;
        final unitTopics = topicsByUnit[unit.unitId] ?? const <_TopicRow>[];
        for (final topic in unitTopics) {
          topicOptions.add(
            _TopicSelectionOption(
              gradeId: pair.gradeId,
              gradeName: pair.gradeName,
              gradeOrder: pair.gradeOrder,
              lessonId: pair.lessonId,
              lessonName: pair.lessonName,
              lessonOrder: pair.lessonOrder,
              unitId: unit.unitId,
              unitTitle: unit.unitTitle,
              unitOrder: unit.unitOrder,
              topicId: topic.topicId,
              topicTitle: topic.title,
              topicOrder: topic.orderNo,
            ),
          );
        }
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
        final topicCandidates = <_TopicSelectionOption>[];

        for (final unit in weekRelatedUnits) {
          final unitTopics = topicsByUnit[unit.unitId] ?? const <_TopicRow>[];
          for (final topic in unitTopics) {
            topicSetInWeek.add(topic.topicId);
          }
        }

        for (final unit in allRelatedUnits) {
          final unitTopics = topicsByUnit[unit.unitId] ?? const <_TopicRow>[];
          for (final topic in unitTopics) {
            topicCandidates.add(
              _TopicSelectionOption(
                gradeId: pair.gradeId,
                gradeName: pair.gradeName,
                gradeOrder: pair.gradeOrder,
                lessonId: pair.lessonId,
                lessonName: pair.lessonName,
                lessonOrder: pair.lessonOrder,
                unitId: unit.unitId,
                unitTitle: unit.unitTitle,
                unitOrder: unit.unitOrder,
                topicId: topic.topicId,
                topicTitle: topic.title,
                topicOrder: topic.orderNo,
              ),
            );
          }
        }

        topicCandidates.sort((a, b) {
          final byUnit = a.unitOrder.compareTo(b.unitOrder);
          if (byUnit != 0) return byUnit;
          return a.topicOrder.compareTo(b.topicOrder);
        });

        _TopicSelectionOption? preferredTopic;
        if (topicCandidates.isNotEmpty) {
          preferredTopic = topicCandidates.firstWhere(
            (c) => topicsWithContent.contains(c.topicId),
            orElse: () => topicCandidates.first,
          );
        }

        final hasContent = topicSetInWeek.any(topicsWithContent.contains);
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
            questionCount: questionIds.length,
            gradeId: pair.gradeId,
            gradeNameForNav: pair.gradeName,
            lessonId: pair.lessonId,
            lessonNameForNav: pair.lessonName,
            preferredUnitId: preferredTopic?.unitId,
            preferredTopicId: preferredTopic?.topicId,
          ),
        );
      }

      statuses.sort((a, b) {
        final gradeCompare = a.gradeOrder.compareTo(b.gradeOrder);
        if (gradeCompare != 0) return gradeCompare;
        return a.lessonOrder.compareTo(b.lessonOrder);
      });

      topicOptions.sort((a, b) {
        final byGrade = a.gradeOrder.compareTo(b.gradeOrder);
        if (byGrade != 0) return byGrade;
        final byLesson = a.lessonOrder.compareTo(b.lessonOrder);
        if (byLesson != 0) return byLesson;
        final byUnit = a.unitOrder.compareTo(b.unitOrder);
        if (byUnit != 0) return byUnit;
        return a.topicOrder.compareTo(b.topicOrder);
      });

      if (!mounted) return;
      setState(() {
        _statuses = statuses;
        _topicOptions = topicOptions;
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

  Future<void> _openSmartQuestionAdditionForLesson(
    _LessonWeekStatus status,
  ) async {
    final topicId = status.preferredTopicId;
    final unitId = status.preferredUnitId;
    if (topicId == null || unitId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu ders için uygun konu bulunamadı.')),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SmartQuestionAdditionPage(
          initialGradeId: status.gradeId,
          initialLessonId: status.lessonId,
          initialUnitId: unitId,
          initialTopicId: topicId,
          initialCurriculumWeek: _selectedWeek,
          initialUsageType: 'weekly',
        ),
      ),
    );
    if (!mounted) return;
    await _loadWeekSummary();
  }

  Future<void> _openSmartContentAdditionForLesson(
    _LessonWeekStatus status,
  ) async {
    final topicId = status.preferredTopicId;
    final unitId = status.preferredUnitId;
    if (topicId == null || unitId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu ders için uygun konu bulunamadı.')),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SmartContentAdditionPage(
          initialGradeId: status.gradeId,
          initialLessonId: status.lessonId,
          initialUnitId: unitId,
          initialTopicId: topicId,
          initialCurriculumWeek: _selectedWeek,
          initialUsageType: 'weekly',
        ),
      ),
    );
    if (!mounted) return;
    await _loadWeekSummary();
  }

  Future<void> _openSmartContentUpdate(_TopicSelectionOption option) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SmartContentUpdatePage(
          initialGradeId: option.gradeId,
          initialLessonId: option.lessonId,
          initialUnitId: option.unitId,
          initialTopicId: option.topicId,
          initialCurriculumWeek: _selectedWeek,
        ),
      ),
    );
    if (!mounted) return;
    await _loadWeekSummary();
  }

  Future<void> _showUpdateSelectionDialog() async {
    if (_topicOptions.isEmpty) return;

    final selected = await showDialog<_TopicSelectionOption>(
      context: context,
      builder: (dialogContext) {
        int? selectedGradeId;
        int? selectedLessonId;
        int? selectedUnitId;
        int? selectedTopicId;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final gradeOptions =
                _topicOptions
                    .map(
                      (o) => (
                        id: o.gradeId,
                        order: o.gradeOrder,
                        name: o.gradeName,
                      ),
                    )
                    .toSet()
                    .toList()
                  ..sort((a, b) => a.order.compareTo(b.order));
            selectedGradeId ??= gradeOptions.isNotEmpty
                ? gradeOptions.first.id
                : null;

            final lessonOptions =
                _topicOptions
                    .where((o) => o.gradeId == selectedGradeId)
                    .map(
                      (o) => (
                        id: o.lessonId,
                        order: o.lessonOrder,
                        name: o.lessonName,
                      ),
                    )
                    .toSet()
                    .toList()
                  ..sort((a, b) => a.order.compareTo(b.order));
            if (!lessonOptions.any((l) => l.id == selectedLessonId)) {
              selectedLessonId = lessonOptions.isNotEmpty
                  ? lessonOptions.first.id
                  : null;
            }

            final unitOptions =
                _topicOptions
                    .where(
                      (o) =>
                          o.gradeId == selectedGradeId &&
                          o.lessonId == selectedLessonId,
                    )
                    .map(
                      (o) =>
                          (id: o.unitId, order: o.unitOrder, name: o.unitTitle),
                    )
                    .toSet()
                    .toList()
                  ..sort((a, b) => a.order.compareTo(b.order));
            if (!unitOptions.any((u) => u.id == selectedUnitId)) {
              selectedUnitId = unitOptions.isNotEmpty
                  ? unitOptions.first.id
                  : null;
            }

            final topicOptions =
                _topicOptions
                    .where(
                      (o) =>
                          o.gradeId == selectedGradeId &&
                          o.lessonId == selectedLessonId &&
                          o.unitId == selectedUnitId,
                    )
                    .toList()
                  ..sort((a, b) => a.topicOrder.compareTo(b.topicOrder));

            if (!topicOptions.any((t) => t.topicId == selectedTopicId)) {
              selectedTopicId = topicOptions.isNotEmpty
                  ? topicOptions.first.topicId
                  : null;
            }

            final selectedOption = topicOptions.firstWhere(
              (o) => o.topicId == selectedTopicId,
              orElse: () => topicOptions.isNotEmpty
                  ? topicOptions.first
                  : _topicOptions.first,
            );

            return AlertDialog(
              title: const Text('Güncellenecek Konuyu Seç'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: selectedGradeId,
                      decoration: const InputDecoration(labelText: 'Sınıf'),
                      items: gradeOptions
                          .map(
                            (g) => DropdownMenuItem<int>(
                              value: g.id,
                              child: Text(g.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedGradeId = value;
                          selectedLessonId = null;
                          selectedUnitId = null;
                          selectedTopicId = null;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      initialValue: selectedLessonId,
                      decoration: const InputDecoration(labelText: 'Ders'),
                      items: lessonOptions
                          .map(
                            (l) => DropdownMenuItem<int>(
                              value: l.id,
                              child: Text(l.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedLessonId = value;
                          selectedUnitId = null;
                          selectedTopicId = null;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      initialValue: selectedUnitId,
                      decoration: const InputDecoration(labelText: 'Ünite'),
                      items: unitOptions
                          .map(
                            (u) => DropdownMenuItem<int>(
                              value: u.id,
                              child: Text(u.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedUnitId = value;
                          selectedTopicId = null;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      initialValue: selectedTopicId,
                      decoration: const InputDecoration(labelText: 'Konu'),
                      items: topicOptions
                          .map(
                            (t) => DropdownMenuItem<int>(
                              value: t.topicId,
                              child: Text(t.topicTitle),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() => selectedTopicId = value);
                      },
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '$_selectedWeek. hafta için içerikler açılacak.',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Vazgeç'),
                ),
                FilledButton(
                  onPressed: topicOptions.isEmpty
                      ? null
                      : () => Navigator.of(dialogContext).pop(selectedOption),
                  child: const Text('Aç'),
                ),
              ],
            );
          },
        );
      },
    );

    if (selected == null) return;
    await _openSmartContentUpdate(selected);
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      children: [
        _WeeklyContentStatusCard(
          week: _selectedWeek,
          statuses: _statuses,
          onTapLesson: _openOutcomesForLesson,
          onTapLessonQuestion: _openSmartQuestionAdditionForLesson,
          onTapLessonContent: _openSmartContentAdditionForLesson,
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: _topicOptions.isEmpty
                ? null
                : _showUpdateSelectionDialog,
            icon: const Icon(Icons.edit_note_rounded),
            label: const Text('İçerik Güncelle'),
          ),
        ),
      ],
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
  final ValueChanged<_LessonWeekStatus> onTapLessonQuestion;
  final ValueChanged<_LessonWeekStatus> onTapLessonContent;

  const _WeeklyContentStatusCard({
    required this.week,
    required this.statuses,
    required this.onTapLesson,
    required this.onTapLessonQuestion,
    required this.onTapLessonContent,
  });

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
                            InkWell(
                              onTap: () => onTapLesson(lesson),
                              child: Text(
                                lesson.lessonName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: lesson.hasContent
                                        ? const Color(0xFFE8F7ED)
                                        : const Color(0xFFFDECEC),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: lesson.hasContent
                                          ? const Color(0xFFBEE5C9)
                                          : const Color(0xFFF4C7C7),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        lesson.hasContent
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        size: 16,
                                        color: lesson.hasContent
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        lesson.hasContent
                                            ? 'İçerik var'
                                            : 'İçerik yok',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: lesson.hasContent
                                              ? Colors.green.shade800
                                              : Colors.red.shade800,
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
                                    color: const Color(0xFFF4F6F8),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'Soru: ${lesson.questionCount}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade800,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _QuickActionButton(
                                    label: 'Soru Ekle',
                                    enabled: lesson.preferredTopicId != null,
                                    onTap: () => onTapLessonQuestion(lesson),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _QuickActionButton(
                                    label: 'İçerik Ekle',
                                    enabled: lesson.preferredTopicId != null,
                                    onTap: () => onTapLessonContent(lesson),
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
                          final isNarrow = constraints.maxWidth < 720;

                          if (isNarrow) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                InkWell(
                                  onTap: () => onTapLesson(lesson),
                                  child: Text(
                                    lesson.lessonName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Icon(
                                            lesson.hasContent
                                                ? Icons.check_circle
                                                : Icons.cancel,
                                            size: 16,
                                            color: lesson.hasContent
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            lesson.hasContent ? 'Var' : 'Yok',
                                            style: TextStyle(
                                              color: lesson.hasContent
                                                  ? Colors.green.shade700
                                                  : Colors.red.shade700,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text('${lesson.questionCount}'),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    _QuickActionButton(
                                      label: 'Soru',
                                      enabled: lesson.preferredTopicId != null,
                                      onTap: () => onTapLessonQuestion(lesson),
                                    ),
                                    const SizedBox(width: 6),
                                    _QuickActionButton(
                                      label: 'İçerik',
                                      enabled: lesson.preferredTopicId != null,
                                      onTap: () => onTapLessonContent(lesson),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          }

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
                                      lesson.hasContent
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      size: 16,
                                      color: lesson.hasContent
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      lesson.hasContent ? 'Var' : 'Yok',
                                      style: TextStyle(
                                        color: lesson.hasContent
                                            ? Colors.green.shade700
                                            : Colors.red.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text('${lesson.questionCount}'),
                              ),
                              Expanded(
                                flex: 2,
                                child: Row(
                                  children: [
                                    _QuickActionButton(
                                      label: 'Soru',
                                      enabled: lesson.preferredTopicId != null,
                                      onTap: () => onTapLessonQuestion(lesson),
                                    ),
                                    const SizedBox(width: 4),
                                    _QuickActionButton(
                                      label: 'İçerik',
                                      enabled: lesson.preferredTopicId != null,
                                      onTap: () => onTapLessonContent(lesson),
                                    ),
                                  ],
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

class _QuickActionButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: enabled ? onTap : null,
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF1D4ED8),
        backgroundColor: const Color(0xFFEAF2FF),
        disabledForegroundColor: Colors.grey.shade500,
        disabledBackgroundColor: Colors.grey.shade200,
        visualDensity: VisualDensity.compact,
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      child: Text(label),
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
    required this.questionCount,
    required this.gradeId,
    required this.gradeNameForNav,
    required this.lessonId,
    required this.lessonNameForNav,
    required this.preferredUnitId,
    required this.preferredTopicId,
  });
}

class _TopicSelectionOption {
  final int gradeId;
  final String gradeName;
  final int gradeOrder;
  final int lessonId;
  final String lessonName;
  final int lessonOrder;
  final int unitId;
  final String unitTitle;
  final int unitOrder;
  final int topicId;
  final String topicTitle;
  final int topicOrder;

  const _TopicSelectionOption({
    required this.gradeId,
    required this.gradeName,
    required this.gradeOrder,
    required this.lessonId,
    required this.lessonName,
    required this.lessonOrder,
    required this.unitId,
    required this.unitTitle,
    required this.unitOrder,
    required this.topicId,
    required this.topicTitle,
    required this.topicOrder,
  });
}

int? _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
