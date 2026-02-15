import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:egitim_uygulamasi/utils/date_utils.dart';
import 'package:egitim_uygulamasi/viewmodels/outcomes_viewmodel.dart';
import 'package:egitim_uygulamasi/viewmodels/profile_viewmodel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HeaderView extends ConsumerWidget {
  final int curriculumWeek;
  final Map<String, dynamic> data;
  final Map<String, dynamic>? pageData;
  final OutcomesViewModelArgs args;

  const HeaderView({
    super.key,
    required this.curriculumWeek,
    required this.data,
    this.pageData,
    required this.args,
  });

  (DateTime, DateTime) _getWeekDateRange(int curriculumWeek) {
    return getWeekDateRangeForAcademicWeek(curriculumWeek);
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

  Widget _buildHierarchyRow(IconData icon, String text) {
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
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.35,
                color: Colors.grey.shade800,
              ),
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
    return rawOutcomes.map((raw) {
      if (raw is Map) {
        final map = Map<String, dynamic>.from(raw);
        final description = (map['description'] as String? ?? '').trim();
        return {
          'id': map['id'] as int?,
          'description': description,
          'topic_id': map['topic_id'] as int? ?? fallbackTopicId,
          'topic_title': map['topic_title'] as String? ?? fallbackTopicTitle,
        };
      }
      final description = raw.toString().trim();
      return {
        'id': null,
        'description': description,
        'topic_id': fallbackTopicId,
        'topic_title': fallbackTopicTitle,
      };
    }).where((o) => (o['description'] as String).isNotEmpty).toList();
  }

  Future<String?> _showEditOutcomeDialog(
    BuildContext context, {
    required String initialText,
  }) async {
    final controller = TextEditingController(text: initialText);
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Kazanımı Güncelle'),
          content: TextField(
            controller: controller,
            minLines: 2,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: 'Kazanım metnini girin',
              border: OutlineInputBorder(),
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
                Navigator.of(dialogContext).pop(text);
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _updateOutcome(
    BuildContext context, {
    required int? outcomeId,
    required String description,
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
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kazanım güncellendi.')),
      );
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
      await Supabase.instance.client.from('outcomes').delete().eq('id', outcomeId);
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
            child: const Icon(Icons.flag_rounded, size: 14, color: Color(0xFF2F6FE4)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.35,
                color: Colors.grey.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (isAdmin) ...[
            IconButton(
              tooltip: 'Güncelle',
              onPressed: () async {
                final next = await _showEditOutcomeDialog(
                  context,
                  initialText: description,
                );
                if (next == null || next == description) return;
                final ok = await _updateOutcome(
                  context,
                  outcomeId: outcomeId,
                  description: next,
                );
                if (ok) {
                  onEdited(next);
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
              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
            ),
          ],
        ],
      ),
    );
  }

  void _showOutcomesSheet(
    BuildContext context,
    List<Map<String, dynamic>> sections,
    List<Map<String, dynamic>> flatOutcomes, {
    required bool isAdmin,
    required VoidCallback onRefreshWeek,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) {
        final localSections = (sections.isNotEmpty
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
                'outcomes': _normalizeOutcomeList(
                  section['outcomes'] as List?,
                  fallbackTopicId: section['topic_id'] as int?,
                  fallbackTopicTitle: section['topic_title'] as String?,
                ),
              },
            )
            .toList();

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
                          const Icon(Icons.flag_circle_rounded, color: Color(0xFF2F6FE4)),
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
                                border: Border.all(color: const Color(0xFFE3EAFF)),
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
                                          borderRadius: BorderRadius.circular(999),
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
                                    ...topicOutcomes.asMap().entries.map((entry) {
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
                                            (section['outcomes'] as List)[index] =
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
        (data['sections'] as List?)
            ?.whereType<Map>()
            .map((s) {
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
            })
            .toList() ??
        const <Map<String, dynamic>>[];
    final isMultiSectionWeek = sections.length > 1;
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
                if (!isSpecialPage && data['unit_title'] != null)
                  _buildHierarchyRow(
                    Icons.folder_open_outlined,
                    data['unit_title']!,
                  ),
                if (!isSpecialPage && data['topic_title'] != null)
                  _buildHierarchyRow(
                    Icons.article_outlined,
                    data['topic_title']!,
                  ),
                if (!isSpecialPage) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _showOutcomesSheet(
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
