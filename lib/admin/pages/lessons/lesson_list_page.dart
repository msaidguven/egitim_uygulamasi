// lib/admin/pages/lessons/lesson_list_page.dart
import 'package:egitim_uygulamasi/admin/pages/lessons/lesson_form_dialog.dart';
import 'package:egitim_uygulamasi/models/grade_model.dart';
import 'package:egitim_uygulamasi/models/lesson_model.dart';
import 'package:egitim_uygulamasi/services/lesson_service.dart';
import 'package:egitim_uygulamasi/services/grade_service.dart';
import 'package:egitim_uygulamasi/main.dart'; // Supabase client'a erişim için
import 'package:flutter/material.dart';

class LessonListPage extends StatefulWidget {
  const LessonListPage({super.key});

  @override
  State<LessonListPage> createState() => _LessonListPageState();
}

class _LessonListPageState extends State<LessonListPage> {
  final LessonService _lessonService = LessonService();
  final GradeService _gradeService = GradeService();

  // State variables
  late Future<List<Grade>> _gradesFuture;
  Grade? _selectedGrade;
  List<Lesson> _lessons = [];
  bool _isLessonsLoading = false;
  String? _lessonsError;

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
    });
    try {
      // RPC yerine direkt sorgu kullanarak 'is_active' filtresi ekliyoruz.
      final response = await supabase
          .from('lessons')
          .select('*, lesson_grades!inner(grade_id)')
          .eq('lesson_grades.grade_id', gradeId)
          .eq('is_active', true);

      // Gelen veri List<Map<String, dynamic>> formatındadır.
      // Bunu Lesson model listesine dönüştürüyoruz.
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

  void _onGradeSelected(Grade? grade) {
    setState(() {
      _selectedGrade = grade;
      _lessons = []; // Yeni sınıf seçildiğinde eski listeyi temizle
    });
    if (grade != null) {
      _loadLessonsForGrade(grade.id!);
    }
  }

  // Liste yenileme metodu
  void _refreshLessonList() {
    if (_selectedGrade != null) {
      _loadLessonsForGrade(_selectedGrade!.id!);
    }
  }

  void _showFormDialog({Lesson? lesson}) {
    showDialog(
      context: context,
      builder: (context) {
        return LessonFormDialog(
          lesson: lesson, // Düzenleme için dersi gönder
          // Yeni ders oluşturulacaksa, hangi sınıfa ait olacağını belirtiyoruz.
          gradeId: _selectedGrade?.id,
          // onSave parametresi VoidCallback (void Function()) tipindedir.
          onSave: _refreshLessonList, // Kaydetme sonrası listeyi yenile
        );
      },
    );
  }

  Future<void> _deleteLesson(int id) async {
    // Silme onayı
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dersi Sil'),
        content: const Text('Bu dersi silmek istediğinizden emin misiniz?'),
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
        await _lessonService.deleteLesson(id);
        _refreshLessonList(); // Silme sonrası listeyi yenile
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Hata: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // AppBar'ı AdminLayout yönettiği için kaldırabiliriz.
        title: const Text('Ders Yönetimi'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: FilledButton.icon(
              onPressed: () => _showFormDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Yeni Ders'),
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
            const Divider(),
            const SizedBox(height: 16),
            Expanded(child: _buildLessonList()),
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

  Widget _buildLessonList() {
    if (_selectedGrade == null) {
      return const Center(child: Text('Dersleri görmek için bir sınıf seçin.'));
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

    // Mevcut DataTable yapısını kullanmaya devam edelim
    return SingleChildScrollView(
      child: DataTable(
        columns: const [
          DataColumn(label: Text('ID')),
          DataColumn(label: Text('Ders Adı')),
          DataColumn(label: Text('İşlemler')),
        ],
        rows: _lessons.map((lesson) {
          return DataRow(
            cells: [
              DataCell(Text(lesson.id.toString())),
              DataCell(Text(lesson.name)),
              DataCell(
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showFormDialog(lesson: lesson),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteLesson(lesson.id),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
