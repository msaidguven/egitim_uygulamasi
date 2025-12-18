// lib/admin/pages/units/unit_form_dialog.dart

import 'package:egitim_uygulamasi/main.dart';
import 'package:egitim_uygulamasi/models/grade_model.dart';
import 'package:egitim_uygulamasi/models/unit_model.dart';
import 'package:egitim_uygulamasi/models/lesson_model.dart';
import 'package:egitim_uygulamasi/services/grade_service.dart';
import 'package:egitim_uygulamasi/services/unit_service.dart';
import 'package:flutter/material.dart';

class UnitFormDialog extends StatefulWidget {
  final Unit? unit; // Düzenleme modu için mevcut ünite
  final int? lessonId; // Oluşturma modu için seçili ders ID'si
  final int? gradeId; // Oluşturma ve düzenleme için seçili sınıf ID'si
  final String? lessonName; // Görüntüleme için ders adı
  final VoidCallback onSave; // Kaydetme sonrası listeyi yenilemek için

  const UnitFormDialog({
    super.key,
    this.unit,
    this.gradeId,
    this.lessonId,
    this.lessonName,
    required this.onSave,
  });

  @override
  State<UnitFormDialog> createState() => _UnitFormDialogState();
}

class _UnitFormDialogState extends State<UnitFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _unitService = UnitService();
  final _gradeService = GradeService();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  bool _isLoading = false;

  // Sınıf ve ders seçimi için state'ler
  int? _selectedGradeId;
  int? _selectedLessonId;

  late Future<List<Grade>> _gradesFuture;
  List<Lesson> _lessons = [];
  bool _isLessonsLoading = false;

  // Düzenleme modunda ders ve sınıfın değiştirilip değiştirilmediğini takip etmek için
  bool get _isEditing => widget.unit != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.unit?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.unit?.description ?? '',
    );
    _gradesFuture = _gradeService.getGrades();

    // Düzenleme modundaysa, mevcut ünitenin bilgilerini yükle
    if (_isEditing && widget.unit != null) {
      _selectedGradeId = widget.unit!.gradeId;
      _selectedLessonId = widget.unit!.lessonId;
      if (_selectedGradeId != null) {
        _loadLessonsForGrade(_selectedGradeId!);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadLessonsForGrade(int gradeId) async {
    setState(() {
      _isLessonsLoading = true;
      _lessons = [];
      _selectedLessonId = null; // Sınıf değiştiğinde ders seçimini sıfırla
    });
    try {
      final response = await supabase.rpc(
        'get_lessons_by_grade',
        params: {'gid': gradeId},
      );
      final lessons = (response as List)
          .map((data) => Lesson.fromMap(data as Map<String, dynamic>))
          .toList();
      setState(() {
        _lessons = lessons;
      });
    } catch (e) {
      debugPrint('Dersler yüklenirken hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Dersler yüklenemedi: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLessonsLoading = false);
      }
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final isCreating = widget.unit == null;

      try {
        if (isCreating) {
          // Oluşturma
          if (_selectedLessonId == null || _selectedGradeId == null) {
            throw Exception('Sınıf ve Ders seçimi zorunludur.');
          }
          await _unitService.createUnit(
            _titleController.text,
            _selectedLessonId!,
            _selectedGradeId!,
          );
        } else {
          // Güncelleme
          await _unitService.updateUnit(
            widget.unit!.id,
            _titleController.text,
            _selectedLessonId!,
            _selectedGradeId!,
          );
        }

        // İşlem başarılı olduğunda yapılacaklar
        if (mounted) {
          final successMessage = isCreating
              ? 'Ünite başarıyla eklendi!'
              : 'Ünite başarıyla güncellendi!';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successMessage),
              backgroundColor: Colors.green,
            ),
          );
          widget.onSave(); // Listeyi yenile
          Navigator.of(context).pop(); // Diyaloğu kapat
        }
      } catch (e) {
        if (mounted) {
          debugPrint('Ünite işlemi sırasında hata: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bir hata oluştu: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.unit == null ? 'Yeni Ünite Ekle' : 'Üniteyi Düzenle'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Ünite Başlığı'),
              validator: (value) =>
                  value!.isEmpty ? 'Ünite başlığı boş olamaz.' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Açıklama (Opsiyonel)',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            // Sınıf Seçici
            FutureBuilder<List<Grade>>(
              future: _gradesFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return DropdownButtonFormField<int>(
                  value: _selectedGradeId,
                  decoration: const InputDecoration(labelText: 'Sınıf'),
                  items: snapshot.data!
                      .map(
                        (grade) => DropdownMenuItem(
                          value: grade.id,
                          child: Text(grade.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedGradeId = value);
                      _loadLessonsForGrade(value);
                    }
                  },
                  validator: (value) =>
                      value == null ? 'Lütfen bir sınıf seçin.' : null,
                );
              },
            ),
            const SizedBox(height: 16),
            // Ders Seçici
            if (_isLessonsLoading)
              const Center(child: CircularProgressIndicator())
            else
              DropdownButtonFormField<int>(
                value: _selectedLessonId,
                decoration: InputDecoration(
                  labelText: 'Ders',
                  // Sınıf seçilmeden ders seçiciyi pasif yap
                  enabled: _selectedGradeId != null && _lessons.isNotEmpty,
                ),
                hint: _selectedGradeId == null
                    ? const Text('Önce sınıf seçin')
                    : const Text('Ders seçin'),
                items: _lessons
                    .map(
                      (lesson) => DropdownMenuItem(
                        value: lesson.id,
                        child: Text(lesson.name),
                      ),
                    )
                    .toList(),
                onChanged: _selectedGradeId == null
                    ? null
                    : (value) {
                        setState(() => _selectedLessonId = value);
                      },
                validator: (value) =>
                    value == null ? 'Lütfen bir ders seçin.' : null,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Kaydet'),
        ),
      ],
    );
  }
}
