import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:egitim_uygulamasi/utils/date_utils.dart';
import 'package:egitim_uygulamasi/viewmodels/outcomes_viewmodel.dart';
import 'package:egitim_uygulamasi/viewmodels/profile_viewmodel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:egitim_uygulamasi/screens/outcomes/widgets/admin_copy_button.dart';

class HeaderView extends ConsumerWidget {
  final int curriculumWeek;
  final Map<String, dynamic> data;
  final Map<String, dynamic>? pageData;
  final OutcomesViewModelArgs args;
  final VoidCallback? onTapUnits;
  final int unitCount;
  final String gradeName;
  final String lessonName;

  const HeaderView({
    super.key,
    required this.curriculumWeek,
    required this.data,
    this.pageData,
    required this.args,
    this.onTapUnits,
    this.unitCount = 0,
    required this.gradeName,
    required this.lessonName,
  });

  (DateTime, DateTime) _getWeekDateRange(int curriculumWeek) {
    return getWeekDateRangeForAcademicWeek(curriculumWeek);
  }

  List<Map<String, dynamic>> _sortSectionsForDisplay(
    List<Map<String, dynamic>> sections,
  ) {
    final sorted = sections.map((s) => Map<String, dynamic>.from(s)).toList();
    sorted.sort((a, b) {
      final aOrder = a['topic_order'] as int? ?? (1 << 30);
      final bOrder = b['topic_order'] as int? ?? (1 << 30);
      final byOrder = aOrder.compareTo(bOrder);
      if (byOrder != 0) return byOrder;

      final aId = a['topic_id'] as int? ?? (1 << 30);
      final bId = b['topic_id'] as int? ?? (1 << 30);
      final byId = aId.compareTo(bId);
      if (byId != 0) return byId;

      final aTitle = (a['topic_title'] as String? ?? '').trim().toLowerCase();
      final bTitle = (b['topic_title'] as String? ?? '').trim().toLowerCase();
      return aTitle.compareTo(bTitle);
    });
    return sorted;
  }

  List<Map<String, dynamic>> _sortOutcomesForDisplay(
    List<Map<String, dynamic>> outcomes,
  ) {
    final sorted = outcomes.map((o) => Map<String, dynamic>.from(o)).toList();
    sorted.sort((a, b) {
      final aId = a['id'] as int? ?? (1 << 30);
      final bId = b['id'] as int? ?? (1 << 30);
      final byId = aId.compareTo(bId);
      if (byId != 0) return byId;

      final aDesc = (a['description'] as String? ?? '').trim().toLowerCase();
      final bDesc = (b['description'] as String? ?? '').trim().toLowerCase();
      return aDesc.compareTo(bDesc);
    });
    return sorted;
  }

  Widget _statPill({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, color.withValues(alpha: 0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHierarchyRow(
    IconData icon,
    List<String> items, {
    String? activeItem,
  }) {
    final normalizedActive = (activeItem ?? '').trim().toLowerCase();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: const Color(0xFF2F6FE4).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF2F6FE4), size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((item) {
                final label = item.trim();
                final isActive =
                    label.toLowerCase() == normalizedActive &&
                    normalizedActive.isNotEmpty;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFEAF2FF)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFF2F6FE4)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                      color: isActive
                          ? const Color(0xFF2F6FE4)
                          : Colors.grey.shade800,
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

  List<Map<String, dynamic>> _normalizeOutcomeList(
    List? rawOutcomes, {
    int? fallbackTopicId,
    String? fallbackTopicTitle,
  }) {
    if (rawOutcomes == null) return const [];
    return rawOutcomes
        .map((raw) {
          if (raw is Map) {
            final map = Map<String, dynamic>.from(raw);
            final description = (map['description'] as String? ?? '').trim();
            return {
              'id': map['id'] as int?,
              'description': description,
              'topic_id': map['topic_id'] as int? ?? fallbackTopicId,
              'topic_title':
                  map['topic_title'] as String? ?? fallbackTopicTitle,
            };
          }
          final description = raw.toString().trim();
          return {
            'id': null,
            'description': description,
            'topic_id': fallbackTopicId,
            'topic_title': fallbackTopicTitle,
          };
        })
        .where((o) => (o['description'] as String).isNotEmpty)
        .toList();
  }

  Future<_OutcomeEditResult?> _showEditOutcomeDialog(
    BuildContext context, {
    required String initialText,
    required List<Map<String, dynamic>> initialWeekRanges,
  }) async {
    final controller = TextEditingController(text: initialText);
    final initialStart = initialWeekRanges.isEmpty
        ? null
        : initialWeekRanges
            .map((w) => w['start_week'] as int?)
            .whereType<int>()
            .fold<int?>(null, (min, v) => min == null ? v : (v < min ? v : min));
    final initialEnd = initialWeekRanges.isEmpty
        ? null
        : initialWeekRanges
            .map((w) => w['end_week'] as int?)
            .whereType<int>()
            .fold<int?>(null, (max, v) => max == null ? v : (v > max ? v : max));
    final startController =
        TextEditingController(text: initialStart?.toString() ?? '');
    final endController =
        TextEditingController(text: initialEnd?.toString() ?? '');
    String? weekError;

    return showDialog<_OutcomeEditResult>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Kazanımı Güncelle'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      minLines: 2,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        hintText: 'Kazanım metnini girin',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: startController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Başlangıç hafta',
                              border: const OutlineInputBorder(),
                              errorText: weekError,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: endController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Bitiş hafta',
                              border: const OutlineInputBorder(),
                              errorText: weekError,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('İptal'),
                ),
                FilledButton(
                  onPressed: () {
                    final text = controller.text.trim();
                    if (text.isEmpty) return;
                    final startRaw = startController.text.trim();
                    final endRaw = endController.text.trim();
                    final startWeek =
                        startRaw.isEmpty ? null : int.tryParse(startRaw);
                    final endWeek =
                        endRaw.isEmpty ? null : int.tryParse(endRaw);
                    if (startRaw.isNotEmpty && startWeek == null) {
                      setState(() => weekError = 'Geçersiz hafta');
                      return;
                    }
                    if (endRaw.isNotEmpty && endWeek == null) {
                      setState(() => weekError = 'Geçersiz hafta');
                      return;
                    }
                    if ((startWeek == null) != (endWeek == null)) {
                      setState(() => weekError = 'İki hafta da girilmeli');
                      return;
                    }
                    if (startWeek != null && startWeek < 1) {
                      setState(() => weekError = 'Hafta 1 veya üzeri olmalı');
                      return;
                    }
                    if (endWeek != null && endWeek < 1) {
                      setState(() => weekError = 'Hafta 1 veya üzeri olmalı');
                      return;
                    }
                    if (startWeek != null &&
                        endWeek != null &&
                        startWeek > endWeek) {
                      setState(
                        () => weekError = 'Başlangıç > bitiş olamaz',
                      );
                      return;
                    }
                    Navigator.of(dialogContext).pop(
                      _OutcomeEditResult(
                        description: text,
                        startWeek: startWeek,
                        endWeek: endWeek,
                      ),
                    );
                  },
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _updateOutcome(
    BuildContext context, {
    required int? outcomeId,
    required String description,
    required int? startWeek,
    required int? endWeek,
  }) async {
    if (outcomeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu kazanım güncellenemiyor (ID yok).')),
      );
      return false;
    }

    try {
      await Supabase.instance.client
          .from('outcomes')
          .update({'description': description})
          .eq('id', outcomeId);
      await Supabase.instance.client
          .from('outcome_weeks')
          .delete()
          .eq('outcome_id', outcomeId);
      if (startWeek != null && endWeek != null) {
        await Supabase.instance.client.from('outcome_weeks').insert({
          'outcome_id': outcomeId,
          'start_week': startWeek,
          'end_week': endWeek,
        });
      }
      if (!context.mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kazanım güncellendi.')));
      return true;
    } catch (e) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Güncelleme hatası: $e')));
      return false;
    }
  }

  Future<bool> _deleteOutcome(
    BuildContext context, {
    required int? outcomeId,
  }) async {
    if (outcomeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu kazanım silinemiyor (ID yok).')),
      );
      return false;
    }

    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Kazanımı Sil'),
          content: const Text('Bu kazanımı silmek istediğinize emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );

    if (approved != true) return false;

    try {
      await Supabase.instance.client
          .from('outcomes')
          .delete()
          .eq('id', outcomeId);
      if (!context.mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kazanım silindi.')));
      return true;
    } catch (e) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Silme hatası: $e')));
      return false;
    }
  }

  Widget _buildOutcomeTile(
    BuildContext context, {
    required Map<String, dynamic> outcome,
    required bool isAdmin,
    required VoidCallback onDeleted,
    required ValueChanged<String> onEdited,
    required VoidCallback onRefreshWeek,
  }) {
    final description = (outcome['description'] as String? ?? '').trim();
    final outcomeId = outcome['id'] as int?;
    final weekRanges = (outcome['week_ranges'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map((w) => Map<String, dynamic>.from(w))
        .toList();
    final weekText = weekRanges.isEmpty
        ? null
        : weekRanges
              .map((w) {
                final start = w['start_week'] as int?;
                final end = w['end_week'] as int?;
                if (start == null || end == null) return '';
                return start == end ? '$start' : '$start-$end';
              })
              .where((s) => s.isNotEmpty)
              .join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE7FF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFF2F6FE4).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Icon(
              Icons.flag_rounded,
              size: 14,
              color: Color(0xFF2F6FE4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.35,
                    color: Colors.grey.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (weekText != null && weekText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Hafta: $weekText',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isAdmin) ...[
            IconButton(
              tooltip: 'Güncelle',
              onPressed: () async {
                final next = await _showEditOutcomeDialog(
                  context,
                  initialText: description,
                  initialWeekRanges: weekRanges,
                );
                if (next == null) return;
                final unchangedText = next.description == description;
                final currentStart = weekRanges.isEmpty
                    ? null
                    : weekRanges.first['start_week'] as int?;
                final currentEnd = weekRanges.isEmpty
                    ? null
                    : weekRanges.first['end_week'] as int?;
                final sameWeeks =
                    currentStart == next.startWeek && currentEnd == next.endWeek;
                if (unchangedText && sameWeeks) return;
                if (!context.mounted) return;
                final ok = await _updateOutcome(
                  context,
                  outcomeId: outcomeId,
                  description: next.description,
                  startWeek: next.startWeek,
                  endWeek: next.endWeek,
                );
                if (ok) {
                  onEdited(next.description);
                  onRefreshWeek();
                }
              },
              icon: const Icon(Icons.edit_outlined, size: 18),
            ),
            IconButton(
              tooltip: 'Sil',
              onPressed: () async {
                final ok = await _deleteOutcome(context, outcomeId: outcomeId);
                if (ok) {
                  onDeleted();
                  onRefreshWeek();
                }
              },
              icon: const Icon(
                Icons.delete_outline,
                size: 18,
                color: Colors.red,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showOutcomesSheet(
    BuildContext context,
    List<Map<String, dynamic>> sections,
    List<Map<String, dynamic>> flatOutcomes, {
    required bool isAdmin,
    required VoidCallback onRefreshWeek,
  }) async {
    final outcomeIds = <int>{};
    for (final section in sections) {
      final normalized = _normalizeOutcomeList(
        section['outcomes'] as List?,
        fallbackTopicId: section['topic_id'] as int?,
        fallbackTopicTitle: section['topic_title'] as String?,
      );
      for (final o in normalized) {
        final id = o['id'] as int?;
        if (id != null) outcomeIds.add(id);
      }
    }
    for (final o in flatOutcomes) {
      final id = o['id'] as int?;
      if (id != null) outcomeIds.add(id);
    }

    final weekRangesByOutcomeId = <int, List<Map<String, dynamic>>>{};
    if (outcomeIds.isNotEmpty) {
      try {
        final rows = await Supabase.instance.client
            .from('outcome_weeks')
            .select('outcome_id, start_week, end_week')
            .inFilter('outcome_id', outcomeIds.toList());
        for (final raw in (rows as List)) {
          final row = Map<String, dynamic>.from(raw as Map);
          final id = row['outcome_id'] as int?;
          if (id == null) continue;
          weekRangesByOutcomeId.putIfAbsent(id, () => []).add({
            'start_week': row['start_week'],
            'end_week': row['end_week'],
          });
        }
        for (final entry in weekRangesByOutcomeId.entries) {
          entry.value.sort((a, b) {
            final aStart = a['start_week'] as int? ?? 0;
            final bStart = b['start_week'] as int? ?? 0;
            if (aStart != bStart) return aStart.compareTo(bStart);
            final aEnd = a['end_week'] as int? ?? 0;
            final bEnd = b['end_week'] as int? ?? 0;
            return aEnd.compareTo(bEnd);
          });
        }
      } catch (_) {
        // Sessiz fallback: hafta araligi gosterimi olmadan acilir.
      }
    }

    if (!context.mounted) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) {
        final localSections = _sortSectionsForDisplay(
          (sections.isNotEmpty
                  ? sections
                  : [
                      {
                        'topic_title': data['topic_title'] ?? 'Konu',
                        'topic_id': data['topic_id'],
                        'outcomes': flatOutcomes,
                      },
                    ])
              .map(
                (section) => {
                  ...section,
                  'outcomes': _sortOutcomesForDisplay(
                    _normalizeOutcomeList(
                      section['outcomes'] as List?,
                      fallbackTopicId: section['topic_id'] as int?,
                      fallbackTopicTitle: section['topic_title'] as String?,
                    ).map((o) {
                      final id = o['id'] as int?;
                      return {
                        ...o,
                        'week_ranges': id == null
                            ? const <Map<String, dynamic>>[]
                            : (weekRangesByOutcomeId[id] ??
                                  const <Map<String, dynamic>>[]),
                      };
                    }).toList(),
                  ),
                },
              )
              .toList(),
        );

        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.82,
            child: StatefulBuilder(
              builder: (context, setModalState) {
                final hasMulti = localSections.length > 1;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.flag_circle_rounded,
                            color: Color(0xFF2F6FE4),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Kazanımlar',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: Colors.grey.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        hasMulti
                            ? '${localSections.length} konu için kazanımlar'
                            : 'Haftanın hedef kazanımları',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView(
                          children: localSections.map((section) {
                            final topicTitle =
                                (section['topic_title'] as String? ?? 'Konu')
                                    .trim();
                            final topicOutcomes =
                                (section['outcomes'] as List? ?? [])
                                    .whereType<Map>()
                                    .map((o) => Map<String, dynamic>.from(o))
                                    .toList();
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFE3EAFF),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.menu_book_rounded,
                                        size: 16,
                                        color: Color(0xFF2F6FE4),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          topicTitle,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF2F6FE4,
                                          ).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          '${topicOutcomes.length}',
                                          style: const TextStyle(
                                            color: Color(0xFF2F6FE4),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  if (topicOutcomes.isEmpty)
                                    Text(
                                      'Bu konu için kazanım bulunamadı.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                    )
                                  else
                                    ...topicOutcomes.asMap().entries.map((
                                      entry,
                                    ) {
                                      final index = entry.key;
                                      final outcome = entry.value;
                                      return _buildOutcomeTile(
                                        context,
                                        outcome: outcome,
                                        isAdmin: isAdmin,
                                        onEdited: (nextText) {
                                          setModalState(() {
                                            topicOutcomes[index]['description'] =
                                                nextText;
                                            (section['outcomes']
                                                    as List)[index] =
                                                topicOutcomes[index];
                                          });
                                        },
                                        onDeleted: () {
                                          setModalState(() {
                                            topicOutcomes.removeAt(index);
                                            section['outcomes'] = topicOutcomes;
                                          });
                                        },
                                        onRefreshWeek: onRefreshWeek,
                                      );
                                    }),
                                ],
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(
      outcomesViewModelProvider(
        args,
      ).select((vm) => vm.getWeekStats(curriculumWeek)),
    );
    final isGuest = ref.watch(
      profileViewModelProvider.select((p) => p.profile == null),
    );
    final isAdmin = ref.watch(
      profileViewModelProvider.select((p) => p.profile?.role == 'admin'),
    );

    final sections =
        (data['sections'] as List?)?.whereType<Map>().map((s) {
          final section = Map<String, dynamic>.from(s);
          final topicId = section['topic_id'] as int?;
          final topicTitle = section['topic_title'] as String?;
          return {
            ...section,
            'outcomes': _normalizeOutcomeList(
              section['outcomes'] as List?,
              fallbackTopicId: topicId,
              fallbackTopicTitle: topicTitle,
            ),
          };
        }).toList() ??
        const <Map<String, dynamic>>[];
    final isMultiSectionWeek = sections.length > 1;
    List<String> collectDistinctTitles({
      required String titleKey,
      required String idKey,
      required String orderKey,
      String? fallback,
    }) {
      final values = <Map<String, dynamic>>[];
      final seen = <String>{};
      final source = sections.isNotEmpty
          ? sections
          : <Map<String, dynamic>>[data];

      for (final row in source) {
        final value = (row[titleKey] as String? ?? '').trim();
        if (value.isEmpty || seen.contains(value)) continue;
        seen.add(value);
        values.add({
          'title': value,
          'id': row[idKey] as int? ?? 1 << 30,
          'order': row[orderKey] as int? ?? 1 << 30,
        });
      }

      values.sort((a, b) {
        final byOrder = (a['order'] as int).compareTo(b['order'] as int);
        if (byOrder != 0) return byOrder;
        final byId = (a['id'] as int).compareTo(b['id'] as int);
        if (byId != 0) return byId;
        return (a['title'] as String).compareTo(b['title'] as String);
      });

      final safeFallback = (fallback ?? '').trim();
      if (values.isEmpty) {
        if (safeFallback.isNotEmpty) {
          return [safeFallback];
        }
        return const [];
      }
      return values.map((e) => e['title'] as String).toList();
    }

    final unitTitles = collectDistinctTitles(
      titleKey: 'unit_title',
      idKey: 'unit_id',
      orderKey: 'unit_order',
      fallback: data['unit_title'] as String?,
    );
    final topicTitles = collectDistinctTitles(
      titleKey: 'topic_title',
      idKey: 'topic_id',
      orderKey: 'topic_order',
      fallback: data['topic_title'] as String?,
    );
    final flatOutcomes = _normalizeOutcomeList(
      data['outcomes'] as List?,
      fallbackTopicId: data['topic_id'] as int?,
      fallbackTopicTitle: data['topic_title'] as String?,
    );
    final solved = isGuest ? 0 : stats?['solved_unique'] ?? 0;
    final total = isGuest ? 10 : stats?['total_questions'] ?? 0;
    final correctCount = isGuest ? 0 : stats?['correct_count'] ?? 0;
    final wrongCount = isGuest ? 0 : stats?['wrong_count'] ?? 0;
    final totalAnswered = correctCount + wrongCount;
    final successRate = totalAnswered > 0
        ? (correctCount / totalAnswered) * 100
        : 0.0;
    final level = SuccessLevel.fromRate(successRate);
    final progress = total > 0 ? (solved / total).clamp(0.0, 1.0) : 0.0;

    final (startDate, endDate) = _getWeekDateRange(curriculumWeek);
    final formattedStartDate = '${startDate.day} ${aylar[startDate.month - 1]}';
    final formattedEndDate =
        '${endDate.day} ${aylar[endDate.month - 1]} ${endDate.year}';
    final pageType = (pageData?['type'] as String?) ?? 'week';
    final isSpecialPage = pageType != 'week';
    final specialTitle = (pageData?['title'] as String? ?? '').trim();
    final specialDuration = (pageData?['duration'] as String? ?? '').trim();
    final headerTitle = isSpecialPage && specialTitle.isNotEmpty
        ? specialTitle
        : '$curriculumWeek. Hafta';
    final headerSubtitle = isSpecialPage
        ? (specialDuration.isNotEmpty
              ? specialDuration
              : pageType == 'social_activity'
              ? 'Sosyal Etkinlik Haftası'
              : pageType == 'special_content'
              ? 'Özel İçerik'
              : '$formattedStartDate - $formattedEndDate')
        : '$formattedStartDate - $formattedEndDate';

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF3F8FF), Color(0xFFEDF4FF)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD4E4FF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7CA5E8).withValues(alpha: 0.2),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -28,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF9EC3FF).withValues(alpha: 0.2),
              ),
            ),
          ),
          Positioned(
            bottom: -36,
            left: -22,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFDAB5).withValues(alpha: 0.2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            headerTitle,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -1,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            headerSubtitle,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.86),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE4ECFF)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            isGuest ? 'Giriş Yapın' : level.title,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isGuest
                                  ? Colors.grey.shade600
                                  : level.color,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(5, (index) {
                              return Icon(
                                index < (isGuest ? 0 : level.starCount)
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                color: Colors.amber.shade600,
                                size: 15,
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: isGuest ? 0.0 : progress,
                    backgroundColor: Colors.white.withValues(alpha: 0.8),
                    color: isGuest ? Colors.grey.shade400 : level.color,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isGuest
                      ? 'İlerlemenizi görmek için giriş yapın'
                      : '$solved/$total soru çözüldü',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                if (!isGuest && totalAnswered > 0) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _statPill(
                        label: 'Doğru',
                        value: correctCount.toString(),
                        color: Colors.green.shade700,
                        icon: Icons.check_circle_outline_rounded,
                      ),
                      _statPill(
                        label: 'Yanlış',
                        value: wrongCount.toString(),
                        color: Colors.red.shade700,
                        icon: Icons.cancel_outlined,
                      ),
                      _statPill(
                        label: 'Başarı',
                        value: '${successRate.toStringAsFixed(0)}%',
                        color: level.color.shade700,
                        icon: Icons.trending_up_rounded,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                if (!isSpecialPage && unitTitles.isNotEmpty)
                  _buildHierarchyRow(
                    Icons.folder_open_outlined,
                    unitTitles,
                    activeItem: data['unit_title'] as String?,
                  ),
                if (!isSpecialPage && topicTitles.isNotEmpty)
                  _buildHierarchyRow(
                    Icons.article_outlined,
                    topicTitles,
                    activeItem: data['topic_title'] as String?,
                  ),
                if (!isSpecialPage) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _showOutcomesSheet(
                            context,
                            sections,
                            flatOutcomes,
                            isAdmin: isAdmin,
                            onRefreshWeek: () => ref
                                .read(outcomesViewModelProvider(args))
                                .refreshCurrentWeekData(curriculumWeek),
                          ),
                          icon: const Icon(Icons.flag_outlined, size: 18),
                          label: Text(
                            isMultiSectionWeek
                                ? 'Kazanımlar (${sections.length} konu)'
                                : 'Kazanımlar',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2F6FE4),
                            side: const BorderSide(color: Color(0xFFC8DBFF)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        if (onTapUnits != null)
                          OutlinedButton.icon(
                            onPressed: onTapUnits,
                            icon: const Icon(
                              Icons.folder_open_rounded,
                              size: 18,
                            ),
                            label: Text(
                              unitCount > 0
                                  ? 'Üniteler ($unitCount)'
                                  : 'Üniteler',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF2F6FE4),
                              side: const BorderSide(color: Color(0xFFC8DBFF)),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        if (isAdmin) ...[
                          AdminCopyButton(
                            gradeName: gradeName,
                            lessonName: lessonName,
                            unitTitle: (data['unit_title'] as String? ?? '')
                                .trim(),
                            topicTitle: (data['topic_title'] as String? ?? '')
                                .trim(),
                            outcomes: flatOutcomes,
                            promptType: AdminPromptType.content,
                          ),
                          AdminCopyButton(
                            gradeName: gradeName,
                            lessonName: lessonName,
                            unitTitle: (data['unit_title'] as String? ?? '')
                                .trim(),
                            topicTitle: (data['topic_title'] as String? ?? '')
                                .trim(),
                            outcomes: flatOutcomes,
                            promptType: AdminPromptType.questions,
                          ),
                        ],
                      ],
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

class _OutcomeEditResult {
  final String description;
  final int? startWeek;
  final int? endWeek;

  const _OutcomeEditResult({
    required this.description,
    required this.startWeek,
    required this.endWeek,
  });
}
