// lib/admin/pages/units/unit_list_page.dart
import 'package:egitim_uygulamasi/admin/pages/units/unit_form_dialog.dart';
import 'package:egitim_uygulamasi/models/grade_model.dart';
import 'package:egitim_uygulamasi/models/unit_model.dart';
import 'package:egitim_uygulamasi/models/lesson_model.dart';
import 'package:egitim_uygulamasi/services/grade_service.dart';
import 'package:egitim_uygulamasi/services/unit_service.dart';
import 'package:egitim_uygulamasi/main.dart'; // Supabase client'a erişim için
import 'package:flutter/material.dart';

class UnitListPage extends StatefulWidget {
  const UnitListPage({super.key});

  @override
  State<UnitListPage> createState() => _UnitListPageState();
}

class _UnitListPageState extends State<UnitListPage> {
  final GradeService _gradeService = GradeService();
  final UnitService _unitService = UnitService();

  // State variables
  late Future<List<Grade>> _gradesFuture;
  Grade? _selectedGrade;

  List<Lesson> _lessons = [];
  Lesson? _selectedLesson;
  bool _isLessonsLoading = false;
  String? _lessonsError;

  List<Unit> _units = [];
  bool _isUnitsLoading = false;
  String? _unitsError;

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  void _loadGrades() {
    _gradesFuture = _gradeService.getGrades();
  }

  Future<void> _loadLessonsForGrade(int gradeId) async {
    setState(() {
      _isLessonsLoading = true;
      _lessonsError = null;
      _lessons = [];
      _selectedLesson = null;
      _units = [];
    });
    try {
      final response = await supabase
          .from('lessons')
          .select('*, lesson_grades!inner(grade_id)')
          .eq('lesson_grades.grade_id', gradeId)
          .eq('is_active', true);
      final lessons = (response as List)
          .map((data) => Lesson.fromMap(data as Map<String, dynamic>))
          .toList();
      setState(() {
        _isLessonsLoading = false;
        _lessons = lessons;
      });
    } catch (e) {
      setState(() {
        _lessonsError = "Dersler yüklenemedi: $e";
        _isLessonsLoading = false;
      });
    }
  }

  Future<void> _loadUnitsForLesson(int lessonId) async {
    setState(() {
      _isUnitsLoading = true;
      _unitsError = null;
      _units = [];
    });
    try {
      final response = await supabase
          .from('units')
          .select('*, unit_grades!inner(grade_id)')
          .eq('lesson_id', lessonId)
          .eq('unit_grades.grade_id', _selectedGrade!.id)
          .eq('is_active', true)
          .order('order_no', ascending: true); // Sıralamayı order_no'ya göre yap

      final units = (response as List)
          .map((data) => Unit.fromMap(data as Map<String, dynamic>))
          .toList();

      setState(() {
        _isUnitsLoading = false;
        _units = units;
      });
    } catch (e) {
      setState(() {
        _unitsError = "Üniteler yüklenemedi: $e";
        _isUnitsLoading = false;
      });
    }
  }

  void _onGradeSelected(Grade? grade) {
    setState(() {
      _selectedGrade = grade;
      _selectedLesson = null;
      _lessons = [];
      _units = [];
    });
    if (grade != null) {
      _loadLessonsForGrade(grade.id);
    }
  }

  void _onLessonSelected(Lesson? lesson) {
    setState(() {
      _selectedLesson = lesson;
      _units = [];
    });
    if (lesson != null) {
      _loadUnitsForLesson(lesson.id);
    }
  }

  void _refreshUnitList() {
    if (_selectedLesson != null) {
      _loadUnitsForLesson(_selectedLesson!.id);
    }
  }

  void _showFormDialog({Unit? unit}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            UnitFormPage(unit: unit, onSave: _refreshUnitList),
      ),
    );
  }

  Future<void> _deleteUnit(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Üniteyi Sil'),
        content: const Text('Bu üniteyi silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _unitService.deleteUnit(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ünite başarıyla silindi.'), backgroundColor: Colors.green),
          );
        }
        _refreshUnitList();
      } catch (e, st) {
        final errorMessage = 'Ünite silinirken bir hata oluştu: $e';
        debugPrint('--- ÜNİTE SİLME HATASI ---');
        debugPrint(errorMessage);
        debugPrint('Stack Trace:\n$st');
        debugPrint('--------------------------');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final Unit item = _units.removeAt(oldIndex);
    setState(() {
      _units.insert(newIndex, item);
    });

    final List<int> unitIds = _units.map((u) => u.id).toList();

    try {
      await supabase.rpc('update_unit_order', params: {'p_unit_ids': unitIds});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sıralama güncellendi.'), backgroundColor: Colors.green),
        );
      }
    } catch (e, st) {
      setState(() {
        _units.removeAt(newIndex);
        _units.insert(oldIndex, item);
      });
      final errorMessage = 'Sıralama güncellenemedi: $e';
      debugPrint('--- SIRALAMA GÜNCELLEME HATASI ---');
      debugPrint(errorMessage);
      debugPrint('Stack Trace:\n$st');
      debugPrint('---------------------------------');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ünite Yönetimi'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: FilledButton.icon(
              onPressed: _selectedLesson == null ? null : () => _showFormDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Yeni Ünite'),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGradeSelector(),
            const SizedBox(height: 16),
            _buildLessonSelector(),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Expanded(child: _buildUnitList()),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeSelector() {
    return FutureBuilder<List<Grade>>(
      future: _gradesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Sınıflar yüklenemedi: ${snapshot.error}');
        }
        final grades = snapshot.data ?? [];
        return DropdownButtonFormField<Grade>(
          value: _selectedGrade,
          hint: const Text('Lütfen bir sınıf seçin'),
          onChanged: _onGradeSelected,
          items: grades.map((grade) {
            return DropdownMenuItem<Grade>(
              value: grade,
              child: Text(grade.name),
            );
          }).toList(),
          decoration: const InputDecoration(
            labelText: 'Sınıf',
            border: OutlineInputBorder(),
          ),
        );
      },
    );
  }

  Widget _buildLessonSelector() {
    if (_selectedGrade == null) {
      return const SizedBox.shrink();
    }
    if (_isLessonsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_lessonsError != null) {
      return Center(child: Text(_lessonsError!));
    }
    if (_lessons.isEmpty) {
      return const Center(child: Text('Bu sınıfa ait ders bulunamadı.'));
    }

    return DropdownButtonFormField<Lesson>(
      value: _selectedLesson,
      hint: const Text('Lütfen bir ders seçin'),
      onChanged: _onLessonSelected,
      items: _lessons.map((lesson) {
        return DropdownMenuItem<Lesson>(
          value: lesson,
          child: Text(lesson.name),
        );
      }).toList(),
      decoration: const InputDecoration(
        labelText: 'Ders',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildUnitList() {
    if (_selectedLesson == null) {
      return const Center(child: Text('Üniteleri görmek için bir ders seçin.'));
    }
    if (_isUnitsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_unitsError != null) {
      return Center(child: Text(_unitsError!));
    }
    if (_units.isEmpty) {
      return const Center(child: Text('Bu derse ait ünite bulunamadı.'));
    }

    return ReorderableListView.builder(
      itemCount: _units.length,
      itemBuilder: (context, index) {
        final unit = _units[index];
        return Card(
          key: ValueKey(unit.id),
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle),
            ),
            title: Text(unit.title),
            subtitle: Text(unit.description ?? 'Açıklama yok'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _showFormDialog(unit: unit),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () => _deleteUnit(unit.id),
                ),
              ],
            ),
          ),
        );
      },
      onReorder: _onReorder,
    );
  }
}
