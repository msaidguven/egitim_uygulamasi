// lib/admin/pages/outcomes/outcome_list_page.dart

import 'package:egitim_uygulamasi/models/grade_model.dart';
import 'package:egitim_uygulamasi/models/lesson_model.dart';
import 'package:egitim_uygulamasi/models/topic_model.dart';
import 'package:egitim_uygulamasi/models/unit_model.dart';
import 'package:egitim_uygulamasi/services/grade_service.dart';
import 'package:egitim_uygulamasi/services/outcome_service.dart';
import 'package:egitim_uygulamasi/services/topic_service.dart';
import 'package:egitim_uygulamasi/main.dart'; // Supabase client için
import 'package:flutter/material.dart';

class OutcomeListPage extends StatefulWidget {
  const OutcomeListPage({super.key});

  @override
  State<OutcomeListPage> createState() => _OutcomeListPageState();
}

class _OutcomeListPageState extends State<OutcomeListPage> {
  // Servisler
  final _gradeService = GradeService();
  final _topicService = TopicService();
  final _outcomeService = OutcomeService();

  // Seçim ID'leri
  int? _selectedGradeId;
  int? _selectedLessonId;
  int? _selectedUnitId;
  int? _selectedTopicId; // For the radio buttons

  // Veri listeleri
  List<Lesson> _lessons = [];
  List<Unit> _units = [];
  List<Topic> _topics = [];
  List<Map<String, dynamic>> _outcomes = [];

  // Yüklenme durumları
  bool _isLoadingLessons = false;
  bool _isLoadingUnits = false;
  bool _isLoadingTopics = false;
  bool _isLoadingOutcomes = false;

  // Form Controllerları ve State
  final _formKey = GlobalKey<FormState>();
  final _startWeekController = TextEditingController();
  final _endWeekController = TextEditingController();
  final _outcomeTextController = TextEditingController();
  bool _isFormLoading = false;

  @override
  void dispose() {
    _startWeekController.dispose();
    _endWeekController.dispose();
    _outcomeTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kazanım Yönetimi')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGradeSelector(),
              const SizedBox(height: 16),
              _buildLessonSelector(),
              const SizedBox(height: 16),
              _buildUnitSelector(),
              const SizedBox(height: 20),
              const Divider(),
              // Form Alanı (Ünite seçiliyse göster)
              if (_selectedUnitId != null) ...[
                _buildInlineAddForm(),
                const Divider(),
              ],
              _buildOutcomeList(),
            ],
          ),
        ),
      ),
    );
  }

  // Seçim Dropdown'ları
  Widget _buildGradeSelector() {
    return FutureBuilder<List<Grade>>(
      future: _gradeService.getGrades(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        return DropdownButtonFormField<int>(
          initialValue: _selectedGradeId,
          hint: const Text('1. Sınıf Seçin'),
          onChanged: (value) {
            if (value != null) _onGradeSelected(value);
          },
          items: snapshot.data!
              .map(
                (grade) =>
                    DropdownMenuItem(value: grade.id, child: Text(grade.name)),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildLessonSelector() {
    return DropdownButtonFormField<int>(
      initialValue: _selectedLessonId,
      hint: const Text('2. Ders Seçin'),
      onChanged: _selectedGradeId == null
          ? null
          : (value) {
              if (value != null) _onLessonSelected(value);
            },
      items: _lessons
          .map(
            (lesson) =>
                DropdownMenuItem(value: lesson.id, child: Text(lesson.name)),
          )
          .toList(),
    );
  }

  Widget _buildUnitSelector() {
    return DropdownButtonFormField<int>(
      initialValue: _selectedUnitId,
      hint: const Text('3. Ünite Seçin'),
      onChanged: _selectedLessonId == null
          ? null
          : (value) {
              if (value != null) _onUnitSelected(value);
            },
      items: _units
          .map(
            (unit) => DropdownMenuItem(value: unit.id, child: Text(unit.title)),
          )
          .toList(),
    );
  }

  // Veri Yükleme ve Durum Yönetimi
  void _onGradeSelected(int gradeId) async {
    setState(() {
      _selectedGradeId = gradeId;
      _selectedLessonId = null;
      _selectedUnitId = null;
      _selectedTopicId = null;
      _lessons = [];
      _units = [];
      _topics = [];
      _outcomes = [];
      _isLoadingLessons = true;
    });
    try {
      final response = await supabase
          .from('lessons')
          .select('*, lesson_grades!inner(grade_id)')
          .eq('lesson_grades.grade_id', gradeId)
          .eq('is_active', true);
      _lessons = (response as List)
          .map((data) => Lesson.fromMap(data as Map<String, dynamic>))
          .toList();
    } finally {
      if (mounted) setState(() => _isLoadingLessons = false);
    }
  }

  void _onLessonSelected(int lessonId) async {
    setState(() {
      _selectedLessonId = lessonId;
      _selectedUnitId = null;
      _selectedTopicId = null;
      _units = [];
      _topics = [];
      _outcomes = [];
      _isLoadingUnits = true;
    });
    try {
      final response = await supabase.rpc(
        'get_units_by_lesson_and_grade',
        params: {'lid': lessonId, 'gid': _selectedGradeId},
      );
      _units = (response as List)
          .map((data) => Unit.fromMap(data as Map<String, dynamic>))
          .toList();
    } finally {
      if (mounted) setState(() => _isLoadingUnits = false);
    }
  }

  void _onUnitSelected(int unitId) async {
    setState(() {
      _selectedUnitId = unitId;
      _selectedTopicId = null;
      _topics = [];
      _outcomes = [];
      _isLoadingTopics = true;
      _isLoadingOutcomes = true;
    });

    _topics = await _topicService.getTopicsForUnit(unitId);
    setState(() => _isLoadingTopics = false);

    final response = await supabase
        .from('outcomes')
        .select(
          'id, description, order_index, topic_id, '
          'topics!inner(id, title, unit_id, is_active), '
          'outcome_weeks(start_week, end_week)',
        )
        .eq('topics.unit_id', unitId)
        .eq('topics.is_active', true)
        .order('order_index', ascending: true);

    _outcomes = List<Map<String, dynamic>>.from(response);
    if (mounted) {
      setState(() => _isLoadingOutcomes = false);
    }
  }

  // Kazanım Listesi ve İşlemleri
  Widget _buildOutcomeList() {
    if (_selectedUnitId == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32.0),
        child: Center(
          child: Text('Kazanımları listelemek için bir ünite seçin.'),
        ),
      );
    }
    if (_isLoadingOutcomes) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _outcomes.length,
      itemBuilder: (context, index) {
        final outcome = _outcomes[index];
        final topicTitle = outcome['topics']['title'] ?? '-';
        final outcomeWeeks = (outcome['outcome_weeks'] as List? ?? [])
            .whereType<Map>()
            .map((w) => Map<String, dynamic>.from(w))
            .toList();
        final weekText = outcomeWeeks.isEmpty
            ? 'Hafta aralığı yok'
            : outcomeWeeks
                  .map((w) {
                    final start = w['start_week'];
                    final end = w['end_week'];
                    return start == end ? '$start' : '$start-$end';
                  })
                  .join(', ');
        final subtitle = 'Konu: $topicTitle • Hafta: $weekText';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text(outcome['description'] ?? ''),
            subtitle: Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () {}, // TODO: Düzenleme eklenebilir
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () => _deleteOutcome(outcome['id']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteOutcome(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kazanımı Sil'),
        content: const Text('Bu kazanımı silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _outcomeService.deleteOutcome(id);
      _onUnitSelected(_selectedUnitId!);
    }
  }

  // --- YENİ: Inline Ekleme Formu ---

  Widget _buildInlineAddForm() {
    return Card(
      elevation: 2,
      color: Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hızlı Kazanım Ekle',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              // 1. Hafta Seçimi
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startWeekController,
                      decoration: const InputDecoration(
                        labelText: 'Başlangıç Haftası',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (val) =>
                          (val == null || int.tryParse(val.trim()) == null)
                          ? 'Sayı girin'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _endWeekController,
                      decoration: const InputDecoration(
                        labelText: 'Bitiş Haftası',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || int.tryParse(val.trim()) == null)
                          return 'Sayı girin';
                        final start = int.tryParse(
                          _startWeekController.text.trim(),
                        );
                        final end = int.tryParse(val.trim());
                        if (start != null && end != null && end < start)
                          return 'Bitiş < Başlangıç olamaz';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 2. Konu Seçimi (Radio Buttons)
              _buildTopicRadioList(),
              const SizedBox(height: 12),
              // 3. Kazanım Metni
              TextFormField(
                controller: _outcomeTextController,
                decoration: const InputDecoration(
                  labelText: 'Kazanım Metni',
                  hintText: 'Kazanımları girin (Her satır yeni bir kazanım)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                maxLines: 13,
                minLines: 9,
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Kazanım metni boş olamaz'
                    : null,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _isFormLoading ? null : _submitForm,
                  icon: _isFormLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Kaydet'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopicRadioList() {
    if (_isLoadingTopics)
      return const Center(child: CircularProgressIndicator());
    if (_topics.isEmpty) return const Text('Bu üniteye ait konu bulunamadı.');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Konu Seçin:', style: Theme.of(context).textTheme.titleSmall),
        ..._topics.map((topic) {
          return RadioListTile<int>(
            title: Text(topic.title),
            value: topic.id,
            groupValue: _selectedTopicId,
            onChanged: (value) {
              setState(() {
                _selectedTopicId = value;
              });
            },
          );
        }),
      ],
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTopicId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lütfen bir konu seçin.')));
      return;
    }

    setState(() => _isFormLoading = true);

    List<String> finalOutcomeTexts = _outcomeTextController.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (finalOutcomeTexts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen en az bir kazanım metni girin.')),
      );
      setState(() => _isFormLoading = false);
      return;
    }

    try {
      final startWeek = int.parse(_startWeekController.text.trim());
      final endWeek = int.parse(_endWeekController.text.trim());

      await _insertOutcomes(
        topicId: _selectedTopicId!,
        texts: finalOutcomeTexts,
        startWeek: startWeek,
        endWeek: endWeek,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kazanımlar başarıyla kaydedildi.'),
            backgroundColor: Colors.green,
          ),
        );
        _outcomeTextController.clear();
        _startWeekController.clear();
        _endWeekController.clear();
        _onUnitSelected(_selectedUnitId!);
      }
    } catch (e) {
      debugPrint('Hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isFormLoading = false);
    }
  }

  Future<List<int>> _insertOutcomes({
    required int topicId,
    required List<String> texts,
    required int startWeek,
    required int endWeek,
  }) async {
    if (texts.isEmpty) return [];

    final maxOrderResponse = await supabase
        .from('outcomes')
        .select('order_index')
        .eq('topic_id', topicId)
        .order('order_index', ascending: false)
        .limit(1)
        .maybeSingle();

    int currentMaxOrder = 0;
    if (maxOrderResponse != null && maxOrderResponse['order_index'] != null) {
      currentMaxOrder = (maxOrderResponse['order_index'] as num).toInt();
    }

    final records = texts.asMap().entries.map((entry) {
      final index = entry.key;
      final text = entry.value;
      return {
        'topic_id': topicId,
        'description': text,
        'order_index': currentMaxOrder + 1 + index,
      };
    }).toList();

    final response = await supabase
        .from('outcomes')
        .insert(records)
        .select('id');

    final insertedIds = (response as List).map((e) => e['id'] as int).toList();

    if (insertedIds.isNotEmpty) {
      final weekRows = insertedIds
          .map(
            (id) => {
              'outcome_id': id,
              'start_week': startWeek,
              'end_week': endWeek,
            },
          )
          .toList();
      await supabase.from('outcome_weeks').insert(weekRows);
    }

    return insertedIds;
  }
}
