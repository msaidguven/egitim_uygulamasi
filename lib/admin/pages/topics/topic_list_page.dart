// lib/admin/pages/topics/topic_list_page.dart

import 'package:egitim_uygulamasi/admin/pages/topics/topic_form_dialog.dart';
import 'package:egitim_uygulamasi/models/grade_model.dart';
import 'package:egitim_uygulamasi/models/lesson_model.dart';
import 'package:egitim_uygulamasi/models/topic_model.dart';
import 'package:egitim_uygulamasi/models/unit_model.dart';
import 'package:egitim_uygulamasi/services/grade_service.dart';
import 'package:egitim_uygulamasi/services/topic_service.dart';
import 'package:egitim_uygulamasi/main.dart';
import 'package:flutter/material.dart';

class TopicListPage extends StatefulWidget {
  const TopicListPage({super.key});

  @override
  State<TopicListPage> createState() => _TopicListPageState();
}

class _TopicListPageState extends State<TopicListPage> {
  final _gradeService = GradeService();
  final _topicService = TopicService();

  // Seçimler
  Grade? _selectedGrade;
  Lesson? _selectedLesson;
  Unit? _selectedUnit;

  // Veri Listeleri ve Durumları
  late Future<List<Grade>> _gradesFuture;
  List<Lesson> _lessons = [];
  bool _isLessonsLoading = false;
  List<Unit> _units = [];
  bool _isUnitsLoading = false;
  List<Topic> _topics = [];
  bool _isTopicsLoading = false;
  String? _topicsError;

  @override
  void initState() {
    super.initState();
    _gradesFuture = _gradeService.getGrades();
  }

  // Veri Yükleme Metotları
  Future<void> _loadLessons(int gradeId) async {
    setState(() {
      _isLessonsLoading = true;
      _lessons = [];
      _selectedLesson = null;
      _units = [];
      _selectedUnit = null;
      _topics = [];
    });
    final response = await supabase
        .from('lessons')
        .select('id, name, lesson_grades!inner(grade_id)')
        .eq('lesson_grades.grade_id', gradeId)
        .eq('is_active', true);
    setState(() {
      _lessons = (response as List).map((e) => Lesson.fromMap(e)).toList();
      _isLessonsLoading = false;
    });
  }

  Future<void> _loadUnits(int lessonId, int gradeId) async {
    setState(() {
      _isUnitsLoading = true;
      _units = [];
      _selectedUnit = null;
      _topics = [];
    });
    final response = await supabase.rpc(
      'get_units_by_lesson_and_grade',
      params: {'lid': lessonId, 'gid': gradeId},
    );
    setState(() {
      _units = (response as List).map((e) => Unit.fromMap(e)).toList();
      _isUnitsLoading = false;
    });
  }

  Future<void> _loadTopics(int unitId) async {
    setState(() {
      _isTopicsLoading = true;
      _topicsError = null;
    });
    try {
      _topics = await _topicService.getTopicsForUnit(unitId);
    } catch (e, st) {
      final errorMessage = 'Error loading topics: $e\n$st';
      debugPrint(errorMessage);
      setState(() {
        _topicsError = errorMessage;
      });
    } finally {
      if (mounted) setState(() => _isTopicsLoading = false);
    }
  }

  // Seçim Değişikliklerini Yöneten Metotlar
  void _onGradeChanged(Grade? grade) {
    if (grade == null) return;
    setState(() => _selectedGrade = grade);
    _loadLessons(grade.id!);
  }

  void _onLessonChanged(Lesson? lesson) {
    if (lesson == null) return;
    setState(() => _selectedLesson = lesson);
    _loadUnits(lesson.id, _selectedGrade!.id!);
  }

  void _onUnitChanged(Unit? unit) {
    if (unit == null) return;
    setState(() => _selectedUnit = unit);
    _loadTopics(unit.id);
  }

  void _refreshTopics() {
    if (_selectedUnit != null) {
      _loadTopics(_selectedUnit!.id);
    }
  }

  // Form ve Silme İşlemleri
  void _showFormDialog({Topic? topic}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TopicFormPage(topic: topic, onSave: _refreshTopics),
      ),
    );
  }

  Future<void> _deleteTopic(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konuyu Sil'),
        content: const Text(
          'Bu konuyu ve ilişkili tüm içerikleri silmek istediğinizden emin misiniz?',
        ),
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
      try {
        await _topicService.deleteTopic(id);
        _refreshTopics();
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konu Yönetimi'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: FilledButton.icon(
              onPressed: _showFormDialog,
              icon: const Icon(Icons.add),
              label: const Text('Yeni Konu'),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDropdown<Grade>(
              _gradesFuture,
              _selectedGrade,
              _onGradeChanged,
              '1. Sınıf Seçin',
            ),
            const SizedBox(height: 16),
            _buildDropdown<Lesson>(
              _lessons,
              _selectedLesson,
              _onLessonChanged,
              '2. Ders Seçin',
              isLoading: _isLessonsLoading,
              enabled: _selectedGrade != null,
            ),
            const SizedBox(height: 16),
            _buildDropdown<Unit>(
              _units,
              _selectedUnit,
              _onUnitChanged,
              '3. Ünite Seçin',
              isLoading: _isUnitsLoading,
              enabled: _selectedLesson != null,
            ),
            const Divider(height: 32),
            Expanded(child: _buildTopicList()),
          ],
        ),
      ),
    );
  }

  // Generic Dropdown Builder
  Widget _buildDropdown<T>(
    dynamic itemsFutureOrList,
    T? selectedValue,
    void Function(T?)? onChanged,
    String hint, {
    bool isLoading = false,
    bool enabled = true,
  }) {
    if (itemsFutureOrList is Future) {
      return FutureBuilder<List<T>>(
        future: itemsFutureOrList as Future<List<T>>,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Text('Veri yüklenemedi: ${snapshot.error}');
          return _buildActualDropdown<T>(
            snapshot.data ?? [],
            selectedValue,
            onChanged,
            hint,
            isLoading,
            enabled,
          );
        },
      );
    } else {
      return _buildActualDropdown(
        itemsFutureOrList as List<T>,
        selectedValue,
        onChanged,
        hint,
        isLoading,
        enabled,
      );
    }
  }

  Widget _buildActualDropdown<T>(
    List<T> items,
    T? selectedValue,
    void Function(T?)? onChanged,
    String hint,
    bool isLoading,
    bool enabled,
  ) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return DropdownButtonFormField<T>(
      value: selectedValue,
      hint: Text(hint),
      isExpanded: true,
      onChanged: enabled ? onChanged : null,
      items: items.map((item) {
        String text;
        if (item is Grade)
          text = item.name;
        else if (item is Lesson)
          text = item.name;
        else if (item is Unit)
          text = item.title;
        else if (item is Topic)
          text = item.title;
        else
          text = item.toString();
        return DropdownMenuItem<T>(value: item, child: Text(text));
      }).toList(),
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        enabled: enabled,
      ),
    );
  }

  Widget _buildTopicList() {
    if (_selectedUnit == null) {
      return const Center(
        child: Text('Konuları listelemek için bir ünite seçin.'),
      );
    }
    if (_isTopicsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_topicsError != null) {
      return SingleChildScrollView(
        child: Text(
          'HATA: Konular yüklenemedi.\n\nDetaylar:\n$_topicsError',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
    if (_topics.isEmpty) {
      return const Center(child: Text('Bu üniteye ait konu bulunamadı.'));
    }

    return ListView.builder(
      itemCount: _topics.length,
      itemBuilder: (context, index) {
        final topic = _topics[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            leading: CircleAvatar(child: Text(topic.orderNo.toString())),
            title: Text(topic.title),
            subtitle: Text('Slug: ${topic.slug ?? ''}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showFormDialog(topic: topic),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteTopic(topic.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
