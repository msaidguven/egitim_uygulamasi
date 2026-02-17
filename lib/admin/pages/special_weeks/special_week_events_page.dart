import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SpecialWeekEventsPage extends StatefulWidget {
  const SpecialWeekEventsPage({super.key});

  @override
  State<SpecialWeekEventsPage> createState() => _SpecialWeekEventsPageState();
}

class _SpecialWeekEventsPageState extends State<SpecialWeekEventsPage> {
  final _client = Supabase.instance.client;

  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _grades = [];
  List<Map<String, dynamic>> _lessons = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _client
            .from('special_week_events')
            .select(
              'id, grade_id, lesson_id, curriculum_week, event_type, title, subtitle, content_html, is_active, priority, created_at',
            )
            .order('curriculum_week', ascending: true)
            .order('priority', ascending: true),
        _client
            .from('grades')
            .select('id, name')
            .eq('is_active', true)
            .order('order_no', ascending: true),
        _client
            .from('lessons')
            .select('id, name')
            .eq('is_active', true)
            .order('order_no', ascending: true),
      ]);

      _events = (results[0] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      _grades = (results[1] as List)
          .map((g) => Map<String, dynamic>.from(g as Map))
          .toList();
      _lessons = (results[2] as List)
          .map((l) => Map<String, dynamic>.from(l as Map))
          .toList();
    } catch (e) {
      _error = 'Özel hafta verileri yüklenemedi: $e';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'break':
        return 'Tatil';
      case 'social_activity':
        return 'Sosyal Etkinlik';
      default:
        return 'Özel İçerik';
    }
  }

  String _scopeLabel(Map<String, dynamic> item) {
    final gradeId = item['grade_id'] as int?;
    final lessonId = item['lesson_id'] as int?;
    if (gradeId == null && lessonId == null) return 'Tüm sınıf/dersler';
    final gradeName = _grades
        .firstWhere(
          (g) => g['id'] == gradeId,
          orElse: () => const {'name': '-'},
        )['name'];
    final lessonName = _lessons
        .firstWhere(
          (l) => l['id'] == lessonId,
          orElse: () => const {'name': '-'},
        )['name'];
    if (lessonId == null) return '$gradeName - Tüm dersler';
    return '$gradeName - $lessonName';
  }

  Future<void> _deleteEvent(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kaydı Sil'),
        content: const Text('Bu özel hafta kaydı silinsin mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _client.from('special_week_events').delete().eq('id', id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kayıt silindi.')),
      );
      await _loadAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Silme hatası: $e')),
      );
    }
  }

  Future<void> _openEventDialog({Map<String, dynamic>? initial}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SpecialWeekEventDialog(
        grades: _grades,
        lessons: _lessons,
        initial: initial,
      ),
    );

    if (result == true) {
      await _loadAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Özel Haftalar'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadAll,
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : () => _openEventDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Yeni Kayıt'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _events.isEmpty
          ? const Center(
              child: Text('Henüz özel hafta kaydı yok.'),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: _events.length,
              separatorBuilder: (_, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = _events[index];
                final id = item['id'] as int;
                final week = item['curriculum_week'] as int? ?? 0;
                final type = item['event_type'] as String? ?? 'special_content';
                final title = (item['title'] as String? ?? '').trim();
                final subtitle = (item['subtitle'] as String? ?? '').trim();
                final isActive = item['is_active'] == true;
                final priority = item['priority'] as int? ?? 0;

                return Card(
                  child: ListTile(
                    title: Text(
                      'Hafta $week - ${_typeLabel(type)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      [
                        if (title.isNotEmpty) title,
                        if (subtitle.isNotEmpty) subtitle,
                        _scopeLabel(item),
                        'Öncelik: $priority',
                        'Durum: ${isActive ? "Aktif" : "Pasif"}',
                      ].join('\n'),
                    ),
                    isThreeLine: true,
                    trailing: Wrap(
                      spacing: 6,
                      children: [
                        IconButton(
                          tooltip: 'Düzenle',
                          onPressed: () => _openEventDialog(initial: item),
                          icon: const Icon(Icons.edit),
                        ),
                        IconButton(
                          tooltip: 'Sil',
                          onPressed: () => _deleteEvent(id),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _SpecialWeekEventDialog extends StatefulWidget {
  final List<Map<String, dynamic>> grades;
  final List<Map<String, dynamic>> lessons;
  final Map<String, dynamic>? initial;

  const _SpecialWeekEventDialog({
    required this.grades,
    required this.lessons,
    this.initial,
  });

  @override
  State<_SpecialWeekEventDialog> createState() => _SpecialWeekEventDialogState();
}

class _SpecialWeekEventDialogState extends State<_SpecialWeekEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _client = Supabase.instance.client;

  late final TextEditingController _weekController;
  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;
  late final TextEditingController _contentController;
  late final TextEditingController _priorityController;

  String _scopeType = 'all';
  int? _selectedGradeId;
  int? _selectedLessonId;
  String _eventType = 'special_content';
  bool _isActive = true;
  bool _isSaving = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;

    _weekController = TextEditingController(
      text: (initial?['curriculum_week'] as int?)?.toString() ?? '',
    );
    _titleController = TextEditingController(
      text: (initial?['title'] as String?) ?? '',
    );
    _subtitleController = TextEditingController(
      text: (initial?['subtitle'] as String?) ?? '',
    );
    _contentController = TextEditingController(
      text: (initial?['content_html'] as String?) ?? '',
    );
    _priorityController = TextEditingController(
      text: (initial?['priority'] as int?)?.toString() ?? '0',
    );

    _selectedGradeId = initial?['grade_id'] as int?;
    _selectedLessonId = initial?['lesson_id'] as int?;
    _eventType = (initial?['event_type'] as String?) ?? 'special_content';
    _isActive = initial?['is_active'] == false ? false : true;

    if (_selectedGradeId != null && _selectedLessonId != null) {
      _scopeType = 'grade_lesson';
    } else if (_selectedGradeId != null) {
      _scopeType = 'grade';
    } else {
      _scopeType = 'all';
    }
  }

  @override
  void dispose() {
    _weekController.dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    _contentController.dispose();
    _priorityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final week = int.parse(_weekController.text.trim());
      final title = _titleController.text.trim();
      final subtitle = _subtitleController.text.trim();
      final contentHtml = _contentController.text.trim();
      final priority = int.parse(_priorityController.text.trim());
      final currentUser = _client.auth.currentUser;

      final gradeId = _scopeType == 'all' ? null : _selectedGradeId;
      final lessonId = _scopeType == 'grade_lesson' ? _selectedLessonId : null;

      if (_scopeType != 'all' && gradeId == null) {
        throw Exception('Sınıf seçmelisiniz.');
      }
      if (_scopeType == 'grade_lesson' && lessonId == null) {
        throw Exception('Ders seçmelisiniz.');
      }

      final payload = <String, dynamic>{
        'grade_id': gradeId,
        'lesson_id': lessonId,
        'curriculum_week': week,
        'event_type': _eventType,
        'title': title,
        'subtitle': subtitle.isEmpty ? null : subtitle,
        'content_html': contentHtml.isEmpty ? null : contentHtml,
        'is_active': _isActive,
        'priority': priority,
        if (!_isEdit && currentUser != null) 'created_by': currentUser.id,
      };

      if (_isEdit) {
        final id = widget.initial!['id'] as int;
        await _client.from('special_week_events').update(payload).eq('id', id);
      } else {
        await _client.from('special_week_events').insert(payload);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kayıt hatası: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Özel Hafta Düzenle' : 'Özel Hafta Ekle'),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _scopeType,
                  decoration: const InputDecoration(
                    labelText: 'Kapsam',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text('Tüm sınıf/dersler'),
                    ),
                    DropdownMenuItem(
                      value: 'grade',
                      child: Text('Sınıf bazlı (tüm dersler)'),
                    ),
                    DropdownMenuItem(
                      value: 'grade_lesson',
                      child: Text('Sınıf + ders bazlı'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _scopeType = value;
                      if (value == 'all') {
                        _selectedGradeId = null;
                        _selectedLessonId = null;
                      } else if (value == 'grade') {
                        _selectedLessonId = null;
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                if (_scopeType != 'all')
                  DropdownButtonFormField<int>(
                    initialValue: _selectedGradeId,
                    decoration: const InputDecoration(
                      labelText: 'Sınıf',
                      border: OutlineInputBorder(),
                    ),
                    items: widget.grades
                        .map(
                          (g) => DropdownMenuItem<int>(
                            value: g['id'] as int,
                            child: Text((g['name'] as String?) ?? ''),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _selectedGradeId = value),
                    validator: (value) {
                      if (_scopeType != 'all' && value == null) {
                        return 'Sınıf seçiniz';
                      }
                      return null;
                    },
                  ),
                if (_scopeType != 'all') const SizedBox(height: 12),
                if (_scopeType == 'grade_lesson')
                  DropdownButtonFormField<int>(
                    initialValue: _selectedLessonId,
                    decoration: const InputDecoration(
                      labelText: 'Ders',
                      border: OutlineInputBorder(),
                    ),
                    items: widget.lessons
                        .map(
                          (l) => DropdownMenuItem<int>(
                            value: l['id'] as int,
                            child: Text((l['name'] as String?) ?? ''),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedLessonId = value),
                    validator: (value) {
                      if (_scopeType == 'grade_lesson' && value == null) {
                        return 'Ders seçiniz';
                      }
                      return null;
                    },
                  ),
                if (_scopeType == 'grade_lesson') const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _eventType,
                  decoration: const InputDecoration(
                    labelText: 'Tip',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'special_content',
                      child: Text('Özel İçerik'),
                    ),
                    DropdownMenuItem(value: 'break', child: Text('Tatil')),
                    DropdownMenuItem(
                      value: 'social_activity',
                      child: Text('Sosyal Etkinlik'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _eventType = value);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _weekController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Hafta No',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final parsed = int.tryParse(value?.trim() ?? '');
                    if (parsed == null || parsed < 1 || parsed > 52) {
                      return '1-52 arası hafta giriniz';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Başlık',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty)
                      ? 'Başlık zorunlu'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _subtitleController,
                  decoration: const InputDecoration(
                    labelText: 'Alt Başlık / Süre',
                    hintText: 'Örn: 1. Dönem Ara Tatili',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priorityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Öncelik (küçük önce gelir)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      int.tryParse(value?.trim() ?? '') == null
                      ? 'Sayı giriniz'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contentController,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'İçerik (HTML, opsiyonel)',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Aktif'),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context, false),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: Text(_isSaving ? 'Kaydediliyor...' : 'Kaydet'),
        ),
      ],
    );
  }
}
