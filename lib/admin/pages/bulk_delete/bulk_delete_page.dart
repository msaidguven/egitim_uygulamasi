import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BulkDeletePage extends StatefulWidget {
  const BulkDeletePage({super.key});

  @override
  State<BulkDeletePage> createState() => _BulkDeletePageState();
}

class _BulkDeletePageState extends State<BulkDeletePage> {
  final SupabaseClient _client = Supabase.instance.client;

  bool _isLoadingOptions = true;
  bool _isLoadingPreview = false;
  bool _isDeleting = false;
  bool _isDeletingQuestions = false;
  bool _isDeletingTopics = false;
  bool _isDeletingUnits = false;
  String? _error;

  List<_GradeLessonOption> _options = const [];
  int? _selectedGradeId;
  int? _selectedLessonId;
  _DeleteScope? _scope;
  bool _allowSharedUnits = false;
  bool _deleteContents = false;
  bool _deleteOutcomes = false;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    setState(() {
      _isLoadingOptions = true;
      _error = null;
    });

    try {
      final rows = await _client
          .from('lesson_grades')
          .select(
            'grade_id, lesson_id, is_active, '
            'grades!inner(id, name, order_no, is_active), '
            'lessons!inner(id, name, order_no, is_active)',
          )
          .eq('is_active', true)
          .eq('grades.is_active', true)
          .eq('lessons.is_active', true);

      final options =
          (rows as List)
              .whereType<Map<String, dynamic>>()
              .map(_GradeLessonOption.fromRow)
              .toList()
            ..sort((a, b) {
              final byGrade = a.gradeOrder.compareTo(b.gradeOrder);
              if (byGrade != 0) return byGrade;
              return a.lessonOrder.compareTo(b.lessonOrder);
            });

      if (!mounted) return;
      setState(() {
        _options = options;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Sınıf/ders verileri alınamadı: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingOptions = false;
        });
      }
    }
  }

  Future<void> _loadPreview() async {
    if (_selectedGradeId == null || _selectedLessonId == null) return;
    setState(() {
      _isLoadingPreview = true;
      _error = null;
      _scope = null;
      _allowSharedUnits = false;
      _deleteContents = false;
      _deleteOutcomes = false;
    });

    try {
      final scope = await _buildScope(
        gradeId: _selectedGradeId!,
        lessonId: _selectedLessonId!,
      );
      if (!mounted) return;
      setState(() {
        _scope = scope;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Önizleme oluşturulamadı: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPreview = false;
        });
      }
    }
  }

  Future<_DeleteScope> _buildScope({
    required int gradeId,
    required int lessonId,
  }) async {
    final unitRows = await _client
        .from('unit_grades')
        .select('unit_id, units!inner(id, lesson_id)')
        .eq('grade_id', gradeId)
        .eq('units.lesson_id', lessonId);

    final unitIds = (unitRows as List)
        .whereType<Map<String, dynamic>>()
        .map((r) => _toInt(r['unit_id']))
        .whereType<int>()
        .toSet()
        .toList();

    if (unitIds.isEmpty) {
      return const _DeleteScope(
        unitIds: [],
        topicIds: [],
        contentIds: [],
        outcomeIds: [],
        questionIds: [],
        sharedUnitIds: [],
        contentSamples: [],
        outcomeSamples: [],
        questionSamples: [],
      );
    }

    final topicRows = await _client
        .from('topics')
        .select('id')
        .inFilter('unit_id', unitIds);
    final topicIds = (topicRows as List)
        .whereType<Map<String, dynamic>>()
        .map((r) => _toInt(r['id']))
        .whereType<int>()
        .toSet()
        .toList();

    List<int> contentIds = const [];
    List<int> outcomeIds = const [];
    List<int> questionIds = const [];
    List<String> contentSamples = const [];
    List<String> outcomeSamples = const [];
    List<String> questionSamples = const [];
    if (topicIds.isNotEmpty) {
      final contentRows = await _client
          .from('topic_contents')
          .select('id, title')
          .inFilter('topic_id', topicIds);
      contentIds = (contentRows as List)
          .whereType<Map<String, dynamic>>()
          .map((r) => _toInt(r['id']))
          .whereType<int>()
          .toSet()
          .toList();
      contentSamples = (contentRows)
          .whereType<Map<String, dynamic>>()
          .map((r) => (r['title'] as String? ?? '').trim())
          .where((t) => t.isNotEmpty)
          .take(20)
          .toList();

      final outcomeRows = await _client
          .from('outcomes')
          .select('id, description')
          .inFilter('topic_id', topicIds);
      outcomeIds = (outcomeRows as List)
          .whereType<Map<String, dynamic>>()
          .map((r) => _toInt(r['id']))
          .whereType<int>()
          .toSet()
          .toList();
      outcomeSamples = (outcomeRows)
          .whereType<Map<String, dynamic>>()
          .map((r) => (r['description'] as String? ?? '').trim())
          .where((t) => t.isNotEmpty)
          .take(20)
          .toList();

      final usageRows = await _client
          .from('question_usages')
          .select('question_id')
          .inFilter('topic_id', topicIds);
      questionIds = (usageRows as List)
          .whereType<Map<String, dynamic>>()
          .map((r) => _toInt(r['question_id']))
          .whereType<int>()
          .toSet()
          .toList();

      if (questionIds.isNotEmpty) {
        final questionRows = await _client
            .from('questions')
            .select('question_text')
            .inFilter('id', questionIds)
            .limit(20);
        questionSamples = (questionRows as List)
            .whereType<Map<String, dynamic>>()
            .map((r) => (r['question_text'] as String? ?? '').trim())
            .where((t) => t.isNotEmpty)
            .take(20)
            .toList();
      }
    }

    final sharedRows = await _client
        .from('unit_grades')
        .select('unit_id, grade_id')
        .inFilter('unit_id', unitIds)
        .neq('grade_id', gradeId);
    final sharedUnitIds = (sharedRows as List)
        .whereType<Map<String, dynamic>>()
        .map((r) => _toInt(r['unit_id']))
        .whereType<int>()
        .toSet()
        .toList();

    return _DeleteScope(
      unitIds: unitIds,
      topicIds: topicIds,
      contentIds: contentIds,
      outcomeIds: outcomeIds,
      questionIds: questionIds,
      sharedUnitIds: sharedUnitIds,
      contentSamples: contentSamples,
      outcomeSamples: outcomeSamples,
      questionSamples: questionSamples,
    );
  }

  Future<void> _deleteAll() async {
    final scope = _scope;
    if (scope == null) return;
    if (!_deleteContents && !_deleteOutcomes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('En az bir silme türü seçin (içerik veya kazanım).'),
        ),
      );
      return;
    }
    if (scope.sharedUnitIds.isNotEmpty && !_allowSharedUnits) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Paylaşılan üniteler bulundu. Silmek için önce onay kutusunu işaretleyin.',
          ),
        ),
      );
      return;
    }

    final approved = await showDialog<bool>(
      context: context,
      builder: (context) {
        final gradeName = _selectedGradeName;
        final lessonName = _selectedLessonName;
        return AlertDialog(
          title: const Text('Toplu Silmeyi Onayla'),
          content: Text(
            '$gradeName - $lessonName için:\n'
            '${_deleteContents ? '- ${scope.contentIds.length} içerik\n' : ''}'
            '${_deleteOutcomes ? '- ${scope.outcomeIds.length} kazanım\n' : ''}'
            'kalıcı olarak silinecek.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );

    if (approved != true) return;

    setState(() {
      _isDeleting = true;
      _error = null;
    });

    try {
      if (_deleteContents) {
        await _deleteInChunks(
          'topic_content_outcomes',
          'topic_content_id',
          scope.contentIds,
        );
        await _deleteInChunks(
          'topic_content_weeks',
          'topic_content_id',
          scope.contentIds,
        );
        await _deleteInChunks('topic_contents', 'id', scope.contentIds);
      }
      if (_deleteOutcomes) {
        await _deleteInChunks(
          'topic_content_outcomes',
          'outcome_id',
          scope.outcomeIds,
        );
        await _deleteInChunks('outcome_weeks', 'outcome_id', scope.outcomeIds);
        await _deleteInChunks('outcomes', 'id', scope.outcomeIds);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Toplu silme işlemi tamamlandı.'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadPreview();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Silme işlemi başarısız: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  Future<void> _deleteQuestions() async {
    final scope = _scope;
    if (scope == null) return;
    if (scope.questionIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu seçimde silinecek soru bulunamadı.')),
      );
      return;
    }
    if (scope.sharedUnitIds.isNotEmpty && !_allowSharedUnits) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Paylaşılan üniteler bulundu. Silmek için önce onay kutusunu işaretleyin.',
          ),
        ),
      );
      return;
    }

    final approved = await showDialog<bool>(
      context: context,
      builder: (context) {
        final gradeName = _selectedGradeName;
        final lessonName = _selectedLessonName;
        return AlertDialog(
          title: const Text('Soruları Silmeyi Onayla'),
          content: Text(
            '$gradeName - $lessonName için:\n'
            '- ${scope.questionIds.length} soru\n'
            'kalıcı olarak silinecek.\n\n'
            'Bu işlem geri alınamaz.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );

    if (approved != true) return;

    setState(() {
      _isDeletingQuestions = true;
      _error = null;
    });

    try {
      await _client.rpc(
        'admin_delete_cwqc_for_units',
        params: {'p_unit_ids': scope.unitIds},
      );
      await _deleteInChunks(
        'question_blank_options',
        'question_id',
        scope.questionIds,
      );
      await _deleteInChunks(
        'question_choices',
        'question_id',
        scope.questionIds,
      );
      await _deleteInChunks(
        'question_matching_pairs',
        'question_id',
        scope.questionIds,
      );
      await _deleteInChunks(
        'question_classical',
        'question_id',
        scope.questionIds,
      );
      await _deleteInChunks(
        'question_usages',
        'question_id',
        scope.questionIds,
      );
      await _deleteInChunks(
        'user_question_stats',
        'question_id',
        scope.questionIds,
      );
      await _deleteInChunks(
        'user_weekly_question_progress',
        'question_id',
        scope.questionIds,
      );
      await _deleteInChunks(
        'user_answers',
        'question_id',
        scope.questionIds,
      );
      await _deleteInChunks(
        'test_session_answers',
        'question_id',
        scope.questionIds,
      );
      await _deleteInChunks(
        'test_session_questions',
        'question_id',
        scope.questionIds,
      );
      await _deleteInChunks('questions', 'id', scope.questionIds);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sorular başarıyla silindi.'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadPreview();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Soru silme işlemi başarısız: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isDeletingQuestions = false;
        });
      }
    }
  }

  Future<void> _deleteTopics() async {
    final scope = _scope;
    if (scope == null) return;
    if (scope.topicIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu seçimde silinecek konu yok.')),
      );
      return;
    }
    if (scope.sharedUnitIds.isNotEmpty && !_allowSharedUnits) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Paylaşılan üniteler bulundu. Silmek için önce onay kutusunu işaretleyin.',
          ),
        ),
      );
      return;
    }

    final approved = await showDialog<bool>(
      context: context,
      builder: (context) {
        final gradeName = _selectedGradeName;
        final lessonName = _selectedLessonName;
        return AlertDialog(
          title: const Text('Konuları Silmeyi Onayla'),
          content: Text(
            '$gradeName - $lessonName için:\n'
            '- ${scope.topicIds.length} konu\n'
            'kalıcı olarak silinecek.\n\n'
            'Bu işlem geri alınamaz.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );

    if (approved != true) return;

    setState(() {
      _isDeletingTopics = true;
      _error = null;
    });

    try {
      await _deleteInChunks('topics', 'id', scope.topicIds);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konular başarıyla silindi.'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadPreview();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Konu silme işlemi başarısız: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isDeletingTopics = false;
        });
      }
    }
  }

  Future<void> _deleteUnits() async {
    final scope = _scope;
    if (scope == null) return;
    if (scope.unitIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu seçimde silinecek ünite yok.')),
      );
      return;
    }
    if (scope.sharedUnitIds.isNotEmpty && !_allowSharedUnits) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Paylaşılan üniteler bulundu. Silmek için önce onay kutusunu işaretleyin.',
          ),
        ),
      );
      return;
    }

    final approved = await showDialog<bool>(
      context: context,
      builder: (context) {
        final gradeName = _selectedGradeName;
        final lessonName = _selectedLessonName;
        return AlertDialog(
          title: const Text('Üniteleri Silmeyi Onayla'),
          content: Text(
            '$gradeName - $lessonName için:\n'
            '- ${scope.unitIds.length} ünite\n'
            'kalıcı olarak silinecek.\n\n'
            'Bu işlem geri alınamaz.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );

    if (approved != true) return;

    setState(() {
      _isDeletingUnits = true;
      _error = null;
    });

    try {
      await _deleteInChunks('unit_grades', 'unit_id', scope.unitIds);
      await _deleteInChunks('units', 'id', scope.unitIds);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Üniteler başarıyla silindi.'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadPreview();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Ünite silme işlemi başarısız: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isDeletingUnits = false;
        });
      }
    }
  }

  Future<void> _deleteInChunks(
    String table,
    String column,
    List<int> ids,
  ) async {
    if (ids.isEmpty) return;
    for (final chunk in _chunk(ids, 400)) {
      await _client.from(table).delete().inFilter(column, chunk);
    }
  }

  String get _selectedGradeName {
    final id = _selectedGradeId;
    if (id == null) return 'Sınıf';
    return _options
            .firstWhere(
              (o) => o.gradeId == id,
              orElse: () => const _GradeLessonOption.empty(),
            )
            .gradeName
            .trim()
            .isEmpty
        ? 'Sınıf'
        : _options
              .firstWhere(
                (o) => o.gradeId == id,
                orElse: () => const _GradeLessonOption.empty(),
              )
              .gradeName;
  }

  String get _selectedLessonName {
    final gid = _selectedGradeId;
    final lid = _selectedLessonId;
    if (gid == null || lid == null) return 'Ders';
    final row = _options.firstWhere(
      (o) => o.gradeId == gid && o.lessonId == lid,
      orElse: () => const _GradeLessonOption.empty(),
    );
    return row.lessonName.trim().isEmpty ? 'Ders' : row.lessonName;
  }

  @override
  Widget build(BuildContext context) {
    final gradeOptions =
        _options
            .map((o) => (id: o.gradeId, name: o.gradeName, order: o.gradeOrder))
            .toSet()
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));

    final lessonOptions =
        _options
            .where((o) => o.gradeId == _selectedGradeId)
            .map(
              (o) => (id: o.lessonId, name: o.lessonName, order: o.lessonOrder),
            )
            .toSet()
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));

    return Scaffold(
      appBar: AppBar(title: const Text('Sınıf/Ders Toplu Silme')),
      body: _isLoadingOptions
          ? const Center(child: CircularProgressIndicator.adaptive())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Hedef Seçimi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<int>(
                            initialValue: _selectedGradeId,
                            decoration: const InputDecoration(
                              labelText: 'Sınıf',
                            ),
                            items: gradeOptions
                                .map(
                                  (g) => DropdownMenuItem<int>(
                                    value: g.id,
                                    child: Text(g.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedGradeId = value;
                                _selectedLessonId = null;
                                _scope = null;
                                _allowSharedUnits = false;
                                _deleteContents = false;
                                _deleteOutcomes = false;
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<int>(
                            initialValue: _selectedLessonId,
                            decoration: const InputDecoration(
                              labelText: 'Ders',
                            ),
                            items: lessonOptions
                                .map(
                                  (l) => DropdownMenuItem<int>(
                                    value: l.id,
                                    child: Text(l.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedLessonId = value;
                                _scope = null;
                                _allowSharedUnits = false;
                                _deleteContents = false;
                                _deleteOutcomes = false;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed:
                                (_selectedGradeId == null ||
                                    _selectedLessonId == null ||
                                    _isLoadingPreview ||
                                    _isDeleting)
                                ? null
                                : _loadPreview,
                            icon: const Icon(Icons.visibility_outlined),
                            label: const Text('Silme Önizlemesini Getir'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_isLoadingPreview)
                    const Center(child: CircularProgressIndicator.adaptive()),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  if (_scope != null) _PreviewCard(scope: _scope!),
                  if (_scope != null)
                    Card(
                      child: Column(
                        children: [
                          CheckboxListTile(
                            value: _deleteContents,
                            onChanged: (v) =>
                                setState(() => _deleteContents = v ?? false),
                            title: Text(
                              'İçerikleri Sil (${_scope!.contentIds.length})',
                            ),
                            subtitle: const Text(
                              'Sadece konu içerik kayıtlarını siler.',
                            ),
                          ),
                          const Divider(height: 1),
                          CheckboxListTile(
                            value: _deleteOutcomes,
                            onChanged: (v) =>
                                setState(() => _deleteOutcomes = v ?? false),
                            title: Text(
                              'Kazanımları Sil (${_scope!.outcomeIds.length})',
                            ),
                            subtitle: const Text(
                              'Sadece kazanım kayıtlarını siler.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_scope != null && _scope!.sharedUnitIds.isNotEmpty)
                    CheckboxListTile(
                      value: _allowSharedUnits,
                      onChanged: (v) =>
                          setState(() => _allowSharedUnits = v ?? false),
                      title: const Text(
                        'Paylaşılan ünitelerde de silmeye izin ver',
                      ),
                      subtitle: Text(
                        '${_scope!.sharedUnitIds.length} ünite başka sınıflarda da kullanılıyor.',
                      ),
                    ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed:
                        (_scope == null ||
                            _isDeleting ||
                            _isDeletingQuestions ||
                            _isDeletingTopics ||
                            _isDeletingUnits ||
                            _isLoadingPreview ||
                            (!_deleteContents && !_deleteOutcomes))
                        ? null
                        : _deleteAll,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFB42318),
                      foregroundColor: Colors.white,
                    ),
                    icon: _isDeleting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_forever_rounded),
                    label: Text(
                      _isDeleting
                          ? 'Siliniyor...'
                          : _deleteContents && _deleteOutcomes
                          ? 'Seçili İçerik ve Kazanımları Sil'
                          : _deleteContents
                          ? 'Seçili İçerikleri Sil'
                          : 'Seçili Kazanımları Sil',
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed:
                        (_scope == null ||
                            _isDeletingQuestions ||
                            _isDeleting ||
                            _isDeletingTopics ||
                            _isDeletingUnits ||
                            _isLoadingPreview)
                        ? null
                        : _deleteQuestions,
                    icon: _isDeletingQuestions
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_outline),
                    label: Text(
                      _isDeletingQuestions
                          ? 'Sorular Siliniyor...'
                          : 'Bu Dersin Tüm Sorularını Sil',
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed:
                        (_scope == null ||
                            _isDeletingTopics ||
                            _isDeleting ||
                            _isDeletingQuestions ||
                            _isDeletingUnits ||
                            _isLoadingPreview)
                        ? null
                        : _deleteTopics,
                    icon: _isDeletingTopics
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.topic_outlined),
                    label: Text(
                      _isDeletingTopics
                          ? 'Konular Siliniyor...'
                          : 'Bu Dersin Tüm Konularını Sil',
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed:
                        (_scope == null ||
                            _isDeletingUnits ||
                            _isDeleting ||
                            _isDeletingQuestions ||
                            _isDeletingTopics ||
                            _isLoadingPreview)
                        ? null
                        : _deleteUnits,
                    icon: _isDeletingUnits
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.folder_delete_outlined),
                    label: Text(
                      _isDeletingUnits
                          ? 'Üniteler Siliniyor...'
                          : 'Bu Dersin Tüm Ünitelerini Sil',
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final _DeleteScope scope;

  const _PreviewCard({required this.scope});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Silinecek Veriler',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text('Ünite: ${scope.unitIds.length}'),
            Text('Konu: ${scope.topicIds.length}'),
            Text('İçerik: ${scope.contentIds.length}'),
            Text('Kazanım: ${scope.outcomeIds.length}'),
            Text('Soru: ${scope.questionIds.length}'),
            if (scope.contentSamples.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                'Örnek İçerikler (ilk 20):',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              ...scope.contentSamples.map(
                (item) => Text(
                  '• $item',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            if (scope.outcomeSamples.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                'Örnek Kazanımlar (ilk 20):',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              ...scope.outcomeSamples.map(
                (item) => Text(
                  '• $item',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            if (scope.questionSamples.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                'Örnek Sorular (ilk 20):',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              ...scope.questionSamples.map(
                (item) => Text(
                  '• $item',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            if (scope.contentIds.isEmpty &&
                scope.outcomeIds.isEmpty &&
                scope.questionIds.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Bu seçimde silinecek içerik/kazanım/soru yok.'),
              ),
          ],
        ),
      ),
    );
  }
}

class _GradeLessonOption {
  final int gradeId;
  final String gradeName;
  final int gradeOrder;
  final int lessonId;
  final String lessonName;
  final int lessonOrder;

  const _GradeLessonOption({
    required this.gradeId,
    required this.gradeName,
    required this.gradeOrder,
    required this.lessonId,
    required this.lessonName,
    required this.lessonOrder,
  });

  const _GradeLessonOption.empty()
    : gradeId = -1,
      gradeName = '',
      gradeOrder = 0,
      lessonId = -1,
      lessonName = '',
      lessonOrder = 0;

  factory _GradeLessonOption.fromRow(Map<String, dynamic> row) {
    final grade = (row['grades'] as Map?)?.cast<String, dynamic>() ?? const {};
    final lesson =
        (row['lessons'] as Map?)?.cast<String, dynamic>() ?? const {};
    return _GradeLessonOption(
      gradeId: _toInt(row['grade_id']) ?? _toInt(grade['id']) ?? 0,
      gradeName: (grade['name'] as String? ?? '').trim(),
      gradeOrder: _toInt(grade['order_no']) ?? 0,
      lessonId: _toInt(row['lesson_id']) ?? _toInt(lesson['id']) ?? 0,
      lessonName: (lesson['name'] as String? ?? '').trim(),
      lessonOrder: _toInt(lesson['order_no']) ?? 0,
    );
  }
}

class _DeleteScope {
  final List<int> unitIds;
  final List<int> topicIds;
  final List<int> contentIds;
  final List<int> outcomeIds;
  final List<int> questionIds;
  final List<int> sharedUnitIds;
  final List<String> contentSamples;
  final List<String> outcomeSamples;
  final List<String> questionSamples;

  const _DeleteScope({
    required this.unitIds,
    required this.topicIds,
    required this.contentIds,
    required this.outcomeIds,
    required this.questionIds,
    required this.sharedUnitIds,
    required this.contentSamples,
    required this.outcomeSamples,
    required this.questionSamples,
  });
}

int? _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

Iterable<List<int>> _chunk(List<int> values, int size) sync* {
  if (values.isEmpty) return;
  for (var i = 0; i < values.length; i += size) {
    final end = (i + size > values.length) ? values.length : i + size;
    yield values.sublist(i, end);
  }
}
