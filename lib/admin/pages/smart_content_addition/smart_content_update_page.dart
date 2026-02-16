import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SmartContentUpdatePage extends StatefulWidget {
  final int? initialGradeId;
  final int? initialLessonId;
  final int? initialUnitId;
  final int? initialTopicId;
  final int? initialCurriculumWeek;

  const SmartContentUpdatePage({
    super.key,
    this.initialGradeId,
    this.initialLessonId,
    this.initialUnitId,
    this.initialTopicId,
    this.initialCurriculumWeek,
  });

  @override
  State<SmartContentUpdatePage> createState() => _SmartContentUpdatePageState();
}

class _SmartContentUpdatePageState extends State<SmartContentUpdatePage> {
  final _client = Supabase.instance.client;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  String _topicTitle = '';
  List<Map<String, dynamic>> _contents = [];
  List<Map<String, dynamic>> _outcomes = [];
  Map<int, Set<int>> _selectedOutcomeIdsByContent = {};
  Map<int, List<Map<String, int>>> _weekRangesByOutcomeId = {};
  bool _onlySelectedWeek = false;

  @override
  void initState() {
    super.initState();
    _onlySelectedWeek = widget.initialCurriculumWeek != null;
    _load();
  }

  Future<void> _load() async {
    final topicId = widget.initialTopicId;
    if (topicId == null) {
      setState(() {
        _isLoading = false;
        _error = 'Konu seçimi bulunamadı.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final topic = await _client
          .from('topics')
          .select('title')
          .eq('id', topicId)
          .maybeSingle();
      _topicTitle = (topic?['title'] as String? ?? '').trim();

      final contentsRaw = await _client
          .from('topic_contents')
          .select('id, topic_id, title, content, order_no, is_published')
          .eq('topic_id', topicId)
          .order('order_no', ascending: true);
      _contents = (contentsRaw as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final outcomesRaw = await _client
          .from('outcomes')
          .select('id, description, order_index')
          .eq('topic_id', topicId)
          .order('order_index', ascending: true);
      _outcomes = (outcomesRaw as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final contentIds = _contents
          .map((c) => c['id'])
          .whereType<int>()
          .toList(growable: false);
      _selectedOutcomeIdsByContent = {};
      if (contentIds.isNotEmpty) {
        final linksRaw = await _client
            .from('topic_content_outcomes')
            .select('topic_content_id, outcome_id')
            .inFilter('topic_content_id', contentIds);
        for (final raw in (linksRaw as List)) {
          final row = Map<String, dynamic>.from(raw as Map);
          final contentId = row['topic_content_id'] as int?;
          final outcomeId = row['outcome_id'] as int?;
          if (contentId == null || outcomeId == null) continue;
          _selectedOutcomeIdsByContent.putIfAbsent(contentId, () => <int>{});
          _selectedOutcomeIdsByContent[contentId]!.add(outcomeId);
        }
      }

      final outcomeIds = _outcomes
          .map((o) => o['id'])
          .whereType<int>()
          .toList(growable: false);
      _weekRangesByOutcomeId = {};
      if (outcomeIds.isNotEmpty) {
        final rangesRaw = await _client
            .from('outcome_weeks')
            .select('outcome_id, start_week, end_week')
            .inFilter('outcome_id', outcomeIds);
        for (final raw in (rangesRaw as List)) {
          final row = Map<String, dynamic>.from(raw as Map);
          final outcomeId = row['outcome_id'] as int?;
          final start = row['start_week'] as int?;
          final end = row['end_week'] as int?;
          if (outcomeId == null || start == null || end == null) continue;
          _weekRangesByOutcomeId.putIfAbsent(outcomeId, () => []);
          _weekRangesByOutcomeId[outcomeId]!.add({
            'start_week': start,
            'end_week': end,
          });
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Yükleme hatası: $e';
        });
      }
    }
  }

  bool _isContentVisibleInWeek(int contentId, int week) {
    final linkedOutcomes = _selectedOutcomeIdsByContent[contentId] ?? <int>{};
    for (final outcomeId in linkedOutcomes) {
      final ranges = _weekRangesByOutcomeId[outcomeId] ?? const [];
      for (final range in ranges) {
        final start = range['start_week'] ?? 0;
        final end = range['end_week'] ?? 0;
        if (week >= start && week <= end) return true;
      }
    }
    return false;
  }

  Future<void> _updateContent({
    required int contentId,
    required String title,
    required String content,
    required bool isPublished,
    required Set<int> selectedOutcomeIds,
  }) async {
    if (selectedOutcomeIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir kazanım seçmelisiniz.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _client
          .from('topic_contents')
          .update({
            'title': title.trim().isEmpty ? 'İçerik' : title.trim(),
            'content': content,
            'is_published': isPublished,
          })
          .eq('id', contentId);

      await _client
          .from('topic_content_outcomes')
          .delete()
          .eq('topic_content_id', contentId);
      await _client
          .from('topic_content_outcomes')
          .insert(
            selectedOutcomeIds
                .map(
                  (outcomeId) => {
                    'topic_content_id': contentId,
                    'outcome_id': outcomeId,
                  },
                )
                .toList(),
          );

      await _client
          .from('topic_content_weeks')
          .delete()
          .eq('topic_content_id', contentId);
      final weekRows = await _client
          .from('outcome_weeks')
          .select('start_week, end_week')
          .inFilter('outcome_id', selectedOutcomeIds.toList());
      final weekSet = <int>{};
      for (final raw in (weekRows as List)) {
        final row = Map<String, dynamic>.from(raw as Map);
        final start = row['start_week'] as int?;
        final end = row['end_week'] as int?;
        if (start == null || end == null) continue;
        for (var week = start; week <= end; week++) {
          weekSet.add(week);
        }
      }
      if (weekSet.isNotEmpty) {
        await _client
            .from('topic_content_weeks')
            .insert(
              weekSet
                  .map(
                    (week) => {
                      'topic_content_id': contentId,
                      'curriculum_week': week,
                    },
                  )
                  .toList(),
            );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('İçerik güncellendi.')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Güncelleme hatası: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteContent(int contentId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İçeriği Sil'),
        content: const Text(
          'Bu içerik kalıcı olarak silinecek. Devam edilsin mi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _isSaving = true);
    try {
      await _client.from('topic_contents').delete().eq('id', contentId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('İçerik silindi.')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Silme hatası: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _openEditDialog(Map<String, dynamic> contentRow) async {
    final contentId = contentRow['id'] as int?;
    if (contentId == null) return;
    final titleController = TextEditingController(
      text: contentRow['title'] as String? ?? '',
    );
    final contentController = TextEditingController(
      text: contentRow['content'] as String? ?? '',
    );
    var published = contentRow['is_published'] as bool? ?? true;
    final selected = <int>{
      ...(_selectedOutcomeIdsByContent[contentId] ?? const <int>{}),
    };

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('İçeriği Güncelle'),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Başlık',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: contentController,
                        minLines: 8,
                        maxLines: 18,
                        decoration: const InputDecoration(
                          labelText: 'İçerik (HTML)',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Yayınlandı'),
                        value: published,
                        onChanged: (v) => setDialogState(() => published = v),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Kazanımlar',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ..._outcomes.map((o) {
                        final outcomeId = o['id'] as int?;
                        if (outcomeId == null) return const SizedBox.shrink();
                        final desc = (o['description'] as String? ?? '').trim();
                        return CheckboxListTile(
                          value: selected.contains(outcomeId),
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            desc.isEmpty ? 'Kazanım #$outcomeId' : desc,
                          ),
                          onChanged: (checked) {
                            setDialogState(() {
                              if (checked == true) {
                                selected.add(outcomeId);
                              } else {
                                selected.remove(outcomeId);
                              }
                            });
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('İptal'),
                ),
                FilledButton(
                  onPressed: _isSaving
                      ? null
                      : () async {
                          await _updateContent(
                            contentId: contentId,
                            title: titleController.text,
                            content: contentController.text,
                            isPublished: published,
                            selectedOutcomeIds: selected,
                          );
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
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

  @override
  Widget build(BuildContext context) {
    final weekText = widget.initialCurriculumWeek == null
        ? '-'
        : widget.initialCurriculumWeek.toString();
    final selectedWeek = widget.initialCurriculumWeek;
    final filteredContents = (selectedWeek != null && _onlySelectedWeek)
        ? _contents.where((row) {
            final contentId = row['id'] as int?;
            if (contentId == null) return false;
            return _isContentVisibleInWeek(contentId, selectedWeek);
          }).toList()
        : _contents;

    return Scaffold(
      appBar: AppBar(title: const Text('Akıllı İçerik Güncelleme')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF5FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCFE1FF)),
                  ),
                  child: Text(
                    'Konu: ${_topicTitle.isEmpty ? '-' : _topicTitle}\nHafta: $weekText\nİçerik sayısı: ${_contents.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
                if (selectedWeek != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: SwitchListTile(
                      title: const Text(
                        'Sadece seçili haftada görünen içerikler',
                      ),
                      subtitle: Text('Hafta: $selectedWeek'),
                      value: _onlySelectedWeek,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) => setState(() => _onlySelectedWeek = v),
                    ),
                  ),
                Expanded(
                  child: filteredContents.isEmpty
                      ? const Center(
                          child: Text('Filtreye uygun içerik bulunamadı.'),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          itemCount: filteredContents.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final row = filteredContents[index];
                            final contentId = row['id'] as int?;
                            final title = (row['title'] as String? ?? 'İçerik')
                                .trim();
                            final orderNo = row['order_no'] as int? ?? 0;
                            final published =
                                row['is_published'] as bool? ?? true;
                            final selectedCount = contentId == null
                                ? 0
                                : (_selectedOutcomeIdsByContent[contentId]
                                          ?.length ??
                                      0);

                            return Card(
                              child: ListTile(
                                title: Text(
                                  title.isEmpty ? 'İçerik #$contentId' : title,
                                ),
                                subtitle: Text(
                                  'Sıra: $orderNo • Yayın: ${published ? "Evet" : "Hayır"} • Kazanım: $selectedCount',
                                ),
                                trailing: Wrap(
                                  spacing: 8,
                                  children: [
                                    IconButton(
                                      tooltip: 'Güncelle',
                                      onPressed: _isSaving || contentId == null
                                          ? null
                                          : () => _openEditDialog(row),
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                    IconButton(
                                      tooltip: 'Sil',
                                      onPressed: _isSaving || contentId == null
                                          ? null
                                          : () => _deleteContent(contentId),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
