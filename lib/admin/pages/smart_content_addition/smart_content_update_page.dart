import 'dart:convert';

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

  static const _questionTypeSingleChoice = 1;
  static const _questionTypeTrueFalse = 2;
  static const _questionTypeFillBlank = 3;
  static const _questionTypeClassical = 4;
  static const _questionTypeMatching = 5;

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
          .from('topic_contents_v11')
          .select('id, topic_id, title, payload, version_no, is_published')
          .eq('topic_id', topicId)
          .order('version_no', ascending: false);
      _contents = (contentsRaw as List).map((e) {
        final row = Map<String, dynamic>.from(e as Map);
        final payload = row['payload'];
        row['payload_text'] = const JsonEncoder.withIndent('  ').convert(
          payload is Map ? Map<String, dynamic>.from(payload) : payload,
        );
        return row;
      }).toList();

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
            .from('topic_content_outcomes_v11')
            .select('topic_content_v11_id, outcome_id')
            .inFilter('topic_content_v11_id', contentIds);
        for (final raw in (linksRaw as List)) {
          final row = Map<String, dynamic>.from(raw as Map);
          final contentId = row['topic_content_v11_id'] as int?;
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
      debugPrint(
        '[SmartContentUpdate] Update started: contentId=$contentId, selectedOutcomeCount=${selectedOutcomeIds.length}, isPublished=$isPublished',
      );
      final decodedPayload = jsonDecode(content);
      if (decodedPayload is! Map<String, dynamic>) {
        throw Exception('Lesson V11 JSON nesne formatinda olmali.');
      }

      await _client
          .from('topic_contents_v11')
          .update({
            'title': title.trim().isEmpty ? 'Lesson V11' : title.trim(),
            'payload': decodedPayload,
            'is_published': isPublished,
          })
          .eq('id', contentId);

      await _client
          .from('topic_content_outcomes_v11')
          .delete()
          .eq('topic_content_v11_id', contentId);
      await _client
          .from('topic_content_outcomes_v11')
          .insert(
            selectedOutcomeIds
                .map(
                  (outcomeId) => {
                    'topic_content_v11_id': contentId,
                    'outcome_id': outcomeId,
                  },
                )
                .toList(),
          );

      final syncResult = await _syncQuizRefsToQuestionBank(
        contentId: contentId,
        topicId: widget.initialTopicId,
        payload: decodedPayload,
        selectedOutcomeIds: selectedOutcomeIds,
      );
      debugPrint(
        '[SmartContentUpdate] Sync completed: hasRefs=${syncResult.hasRefs}, inserted=${syncResult.insertedCount}, deleted=${syncResult.deletedCount}',
      );

      if (!mounted) return;
      final snackText = syncResult.hasRefs
          ? 'İçerik güncellendi. Soru bankası: +${syncResult.insertedCount}, '
                'silinen(eski linkli): ${syncResult.deletedCount}.'
          : syncResult.deletedCount > 0
          ? 'İçerik güncellendi. quiz_refs yok, eski linkli ${syncResult.deletedCount} soru temizlendi.'
          : 'İçerik güncellendi. quiz_refs bulunmadığı için soru bankasına yeni kayıt eklenmedi.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(snackText),
          backgroundColor: syncResult.hasRefs ? Colors.green : Colors.orange,
        ),
      );
      await _load();
    } catch (e, st) {
      debugPrint('[SmartContentUpdate] Update failed: $e');
      debugPrint('[SmartContentUpdate] Stack trace:\n$st');
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

  Future<_QuizSyncResult> _syncQuizRefsToQuestionBank({
    required int contentId,
    required int? topicId,
    required Map<String, dynamic> payload,
    required Set<int> selectedOutcomeIds,
  }) async {
    debugPrint(
      '[SmartContentUpdate] Sync started: contentId=$contentId, topicId=$topicId, outcomeCount=${selectedOutcomeIds.length}',
    );
    if (topicId == null) {
      return const _QuizSyncResult(
        hasRefs: false,
        insertedCount: 0,
        deletedCount: 0,
      );
    }

    final deletedCount = await _deleteGeneratedQuestionsForContent(contentId);
    debugPrint(
      '[SmartContentUpdate] Previously generated questions deleted: $deletedCount',
    );

    final refs = _extractQuizRefQuestionBlocks(payload);
    debugPrint('[SmartContentUpdate] quiz_refs resolved: ${refs.length}');
    if (refs.isEmpty) {
      return _QuizSyncResult(
        hasRefs: false,
        insertedCount: 0,
        deletedCount: deletedCount,
      );
    }

    final parsed = refs
        .map(
          (block) => _QuizRefQuestion(
            quizRef: block['id']?.toString() ?? '',
            payload: _convertLessonV11QuizToQuestionPayload(block),
          ),
        )
        .where((e) => e.quizRef.isNotEmpty && e.payload != null)
        .toList();
    debugPrint(
      '[SmartContentUpdate] quiz_refs parsed to payloads: ${parsed.length}',
    );
    final converted = parsed.map((e) => e.payload!).toList();
    if (converted.isEmpty) {
      return _QuizSyncResult(
        hasRefs: true,
        insertedCount: 0,
        deletedCount: deletedCount,
      );
    }

    final resolvedWeek = _resolveDefaultWeekFromOutcomeSet(selectedOutcomeIds);
    final usageType = (resolvedWeek != null && resolvedWeek > 0)
        ? 'weekly'
        : 'topic_end';

    dynamic rpcResult;
    try {
      debugPrint(
        '[SmartContentUpdate] Calling bulk_create_questions: usageType=$usageType, week=$resolvedWeek, questionCount=${converted.length}',
      );
      rpcResult = await _client.rpc(
        'bulk_create_questions',
        params: {
          'p_topic_id': topicId,
          'p_usage_type': usageType,
          'p_curriculum_week': usageType == 'weekly' ? resolvedWeek : null,
          'p_start_week': null,
          'p_end_week': null,
          'p_questions_json': {'questions': converted},
          'p_outcome_ids': selectedOutcomeIds.toList(),
        },
      );
    } on PostgrestException catch (e) {
      final message = e.message.toLowerCase();
      final signatureMismatch =
          e.code == 'PGRST202' && message.contains('p_outcome_ids');
      debugPrint(
        '[SmartContentUpdate] RPC primary call failed: code=${e.code}, message=${e.message}, details=${e.details}, hint=${e.hint}',
      );
      if (!signatureMismatch) rethrow;

      debugPrint(
        '[SmartContentUpdate] Retrying bulk_create_questions without p_outcome_ids due to signature mismatch.',
      );
      rpcResult = await _client.rpc(
        'bulk_create_questions',
        params: {
          'p_topic_id': topicId,
          'p_usage_type': usageType,
          'p_curriculum_week': usageType == 'weekly' ? resolvedWeek : null,
          'p_start_week': null,
          'p_end_week': null,
          'p_questions_json': {'questions': converted},
        },
      );
    }

    final result = rpcResult is Map<String, dynamic>
        ? rpcResult
        : (rpcResult is Map
              ? Map<String, dynamic>.from(rpcResult)
              : <String, dynamic>{});
    final insertedCount = (result['inserted_count'] as num?)?.toInt() ?? 0;
    final insertedIds = (result['inserted_question_ids'] as List? ?? const [])
        .whereType<num>()
        .map((e) => e.toInt())
        .toList();
    final errors = (result['errors'] as List?) ?? const [];
    debugPrint(
      '[SmartContentUpdate] RPC result: inserted=$insertedCount, insertedIds=${insertedIds.length}, errors=${errors.length}',
    );
    if (errors.isNotEmpty) {
      debugPrint('[SmartContentUpdate] First RPC error: ${errors.first}');
      throw Exception(errors.first.toString());
    }
    if (insertedIds.length == parsed.length) {
      final linkRows = <Map<String, dynamic>>[];
      for (var i = 0; i < parsed.length; i++) {
        linkRows.add({
          'topic_content_v11_id': contentId,
          'question_id': insertedIds[i],
          'quiz_ref': parsed[i].quizRef,
        });
      }
      if (linkRows.isNotEmpty) {
        await _client
            .from('topic_content_generated_questions')
            .insert(linkRows);
        debugPrint(
          '[SmartContentUpdate] Generated question links inserted: ${linkRows.length}',
        );
      }
    } else {
      debugPrint(
        '[SmartContentUpdate] Link insert skipped due to length mismatch: insertedIds=${insertedIds.length}, parsed=${parsed.length}',
      );
    }

    return _QuizSyncResult(
      hasRefs: true,
      insertedCount: insertedCount,
      deletedCount: deletedCount,
    );
  }

  Future<int> _deleteGeneratedQuestionsForContent(int contentId) async {
    final rows = await _client
        .from('topic_content_generated_questions')
        .select('question_id')
        .eq('topic_content_v11_id', contentId);
    final questionIds = (rows as List)
        .map((e) => Map<String, dynamic>.from(e as Map)['question_id'])
        .whereType<int>()
        .toSet()
        .toList();
    if (questionIds.isEmpty) return 0;
    debugPrint(
      '[SmartContentUpdate] Deleting generated question IDs: $questionIds',
    );

    // Prefer root delete: dependent rows should be handled by ON DELETE CASCADE.
    await _deleteInChunks('questions', 'id', questionIds);

    // Defensive cleanup in case DB FK/cascade differs across environments.
    await _deleteInChunks(
      'topic_content_generated_questions',
      'question_id',
      questionIds,
      extraEq: {'topic_content_v11_id': contentId},
    );
    return questionIds.length;
  }

  Future<void> _deleteInChunks(
    String table,
    String column,
    List<int> ids, {
    Map<String, dynamic>? extraEq,
  }) async {
    const chunkSize = 500;
    for (var i = 0; i < ids.length; i += chunkSize) {
      final end = (i + chunkSize < ids.length) ? i + chunkSize : ids.length;
      final chunk = ids.sublist(i, end);
      var q = _client.from(table).delete().inFilter(column, chunk);
      if (extraEq != null) {
        for (final entry in extraEq.entries) {
          q = q.eq(entry.key, entry.value);
        }
      }
      await q;
    }
  }

  int? _resolveDefaultWeekFromOutcomeSet(Set<int> outcomeIds) {
    if (outcomeIds.isEmpty) return null;
    int? minWeek;
    for (final outcomeId in outcomeIds) {
      final ranges = _weekRangesByOutcomeId[outcomeId] ?? const [];
      for (final range in ranges) {
        final start = range['start_week'];
        if (start == null) continue;
        if (minWeek == null || start < minWeek) {
          minWeek = start;
        }
      }
    }
    return minWeek;
  }

  List<Map<String, dynamic>> _extractQuizRefQuestionBlocks(
    Map<String, dynamic> payload,
  ) {
    final module = payload['lessonModule'];
    if (module is! Map) return const [];
    final sectionsRaw = module['sections'];
    if (sectionsRaw is! List) return const [];

    final allQuizById = <String, Map<String, dynamic>>{};
    for (final sectionRaw in sectionsRaw) {
      if (sectionRaw is! Map) continue;
      final section = Map<String, dynamic>.from(sectionRaw);
      final quizRaw = section['quiz'];
      if (quizRaw is! List) continue;
      for (final blockRaw in quizRaw) {
        if (blockRaw is! Map) continue;
        final block = Map<String, dynamic>.from(blockRaw);
        final id = block['id']?.toString();
        if (id == null || id.isEmpty) continue;
        allQuizById[id] = block;
      }
    }

    final picked = <Map<String, dynamic>>[];
    final seenIds = <String>{};
    for (final sectionRaw in sectionsRaw) {
      if (sectionRaw is! Map) continue;
      final section = Map<String, dynamic>.from(sectionRaw);
      final refsRaw = section['quiz_refs'];
      if (refsRaw is! List) continue;
      for (final ref in refsRaw) {
        final refId = ref?.toString();
        if (refId == null || refId.isEmpty || seenIds.contains(refId)) {
          continue;
        }
        final quiz = allQuizById[refId];
        if (quiz != null) {
          picked.add(quiz);
          seenIds.add(refId);
        }
      }
    }
    return picked;
  }

  Map<String, dynamic>? _convertLessonV11QuizToQuestionPayload(
    Map<String, dynamic> quizBlock,
  ) {
    final contentRaw = quizBlock['content'];
    if (contentRaw is! Map) return null;
    final content = Map<String, dynamic>.from(contentRaw);

    final questionType = (content['questionType'] as String? ?? '')
        .trim()
        .toLowerCase();
    if (questionType.isEmpty) return null;

    final questionText =
        (content['question_text'] as String?)?.trim().isNotEmpty == true
        ? (content['question_text'] as String).trim()
        : (content['question'] as String?)?.trim() ?? '';
    if (questionText.isEmpty) return null;

    final solutionText = (content['explanation'] as String?)?.trim();
    final base = <String, dynamic>{
      'question_text': questionText,
      'difficulty': 1,
      'score': 1,
      if (solutionText != null && solutionText.isNotEmpty)
        'solution_text': solutionText,
    };

    switch (questionType) {
      case 'single_choice':
      case 'multiple_choice':
        final optionsRaw = content['options'] as List? ?? const [];
        final correctOne = content['correctOptionId']?.toString();
        final correctMany = (content['correctOptionIds'] as List? ?? const [])
            .map((e) => e.toString())
            .toSet();
        final choices = <Map<String, dynamic>>[];
        for (final optionRaw in optionsRaw) {
          if (optionRaw is! Map) continue;
          final option = Map<String, dynamic>.from(optionRaw);
          final optionText = (option['text'] as String?)?.trim();
          if (optionText == null || optionText.isEmpty) continue;
          final optionId = option['id']?.toString();
          final isCorrect =
              (correctOne != null && optionId == correctOne) ||
              (optionId != null && correctMany.contains(optionId));
          choices.add({'text': optionText, 'is_correct': isCorrect});
        }
        if (choices.isEmpty) return null;
        return {
          ...base,
          'question_type_id': _questionTypeSingleChoice,
          'choices': choices,
        };

      case 'true_false':
        final raw = content['correctAnswer'];
        bool? correct;
        if (raw is bool) {
          correct = raw;
        } else if (raw is String) {
          final lowered = raw.toLowerCase();
          if (lowered == 'true') correct = true;
          if (lowered == 'false') correct = false;
        }
        if (correct == null) return null;
        return {
          ...base,
          'question_type_id': _questionTypeTrueFalse,
          'correct_answer': correct,
        };

      case 'fill_blank':
        final accepted = (content['acceptedAnswers'] as List? ?? const [])
            .whereType<String>()
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        final distractors = (content['distractors'] as List? ?? const [])
            .whereType<String>()
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        final seen = <String>{};
        final options = <Map<String, dynamic>>[];
        for (final answer in accepted) {
          if (seen.add(answer.toLowerCase())) {
            options.add({'text': answer, 'is_correct': true});
          }
        }
        for (final distractor in distractors) {
          if (seen.add(distractor.toLowerCase())) {
            options.add({'text': distractor, 'is_correct': false});
          }
        }
        if (options.isEmpty) return null;
        return {
          ...base,
          'question_type_id': _questionTypeFillBlank,
          'blank': {'options': options},
        };

      case 'matching':
        final pairsRaw = content['pairs'] as List? ?? const [];
        final pairs = <Map<String, dynamic>>[];
        for (final pairRaw in pairsRaw) {
          if (pairRaw is! Map) continue;
          final pair = Map<String, dynamic>.from(pairRaw);
          final left =
              (pair['left_text'] as String?)?.trim() ??
              (pair['left'] as String?)?.trim() ??
              '';
          final right =
              (pair['right_text'] as String?)?.trim() ??
              (pair['right'] as String?)?.trim() ??
              '';
          if (left.isEmpty || right.isEmpty) continue;
          pairs.add({'left_text': left, 'right_text': right});
        }
        if (pairs.isEmpty) return null;
        return {
          ...base,
          'question_type_id': _questionTypeMatching,
          'pairs': pairs,
        };

      case 'ordering':
      case 'classical_order':
        final words = (content['answer_words'] as List? ?? const [])
            .whereType<String>()
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        String? modelAnswer = (content['model_answer'] as String?)?.trim();
        if (modelAnswer == null || modelAnswer.isEmpty) {
          if (words.isNotEmpty) {
            modelAnswer = words.join(' -> ');
          }
        }
        if (modelAnswer == null || modelAnswer.isEmpty) return null;
        return {
          ...base,
          'question_type_id': _questionTypeClassical,
          'model_answer': modelAnswer,
          if (words.isNotEmpty) 'answer_words': words,
        };
    }

    return null;
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
      await _client.from('topic_contents_v11').delete().eq('id', contentId);
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
      text: contentRow['payload_text'] as String? ?? '',
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
                          labelText: 'İçerik (Lesson V11 JSON)',
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
                            final versionNo = row['version_no'] as int? ?? 0;
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
                                  'Versiyon: $versionNo • Yayın: ${published ? "Evet" : "Hayır"} • Kazanım: $selectedCount',
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

class _QuizSyncResult {
  final bool hasRefs;
  final int insertedCount;
  final int deletedCount;

  const _QuizSyncResult({
    required this.hasRefs,
    required this.insertedCount,
    required this.deletedCount,
  });
}

class _QuizRefQuestion {
  final String quizRef;
  final Map<String, dynamic>? payload;

  const _QuizRefQuestion({required this.quizRef, required this.payload});
}
