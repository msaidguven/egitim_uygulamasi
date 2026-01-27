// lib/admin/pages/lessons/lesson_form_dialog.dart

import 'package:egitim_uygulamasi/models/grade_model.dart';
import 'package:egitim_uygulamasi/models/lesson_model.dart';
import 'package:egitim_uygulamasi/services/grade_service.dart';
import 'package:egitim_uygulamasi/services/lesson_service.dart';
import 'package:flutter/material.dart';

class LessonFormDialog extends StatefulWidget {
  final Lesson? lesson; // Düzenleme modu için mevcut ders
  final int? gradeId; // Oluşturma modu için seçili sınıf ID'si
  final VoidCallback onSave; // Kaydetme sonrası listeyi yenilemek için

  const LessonFormDialog({
    super.key,
    this.lesson,
    this.gradeId,
    required this.onSave,
  });

  @override
  State<LessonFormDialog> createState() => _LessonFormDialogState();
}

class _LessonFormDialogState extends State<LessonFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _lessonService = LessonService();
  final _gradeService = GradeService();

  late TextEditingController _nameController;
  int? _selectedGradeId;
  late Future<List<Grade>> _gradesFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.lesson?.name ?? '');
    _selectedGradeId = widget.gradeId; // Düzenleme modunda dersin kendi sınıf ID'sini kullan
    _gradesFuture = _gradeService.getGrades();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final isCreating = widget.lesson == null;

      try {
        if (isCreating) {
          // Oluşturma
          if (_selectedGradeId == null) {
            // Bu durum validator tarafından engellenmeli ama yine de kontrol edelim.
            throw Exception('Sınıf seçimi zorunludur.');
          }
          await _lessonService.createLesson(
            _nameController.text,
            _selectedGradeId!,
          );
        } else {
          // Güncelleme
          await _lessonService.updateLesson(
            widget.lesson!.id,
            _nameController.text,
            _selectedGradeId!,
          );
        }

        // İşlem başarılı olduğunda yapılacaklar
        if (mounted) {
          final successMessage = isCreating
              ? 'Ders başarıyla eklendi!'
              : 'Ders başarıyla güncellendi!';
          // SnackBar hatasını önlemek için ScaffoldMessenger'ı yakala
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          Navigator.of(context).pop(); // Diyaloğu kapat
          widget.onSave(); // Listeyi yenile

          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(successMessage),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          debugPrint('Ders işlemi sırasında hata: $e');
          // SnackBar hatasını önlemek için ScaffoldMessenger'ı yakala
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          scaffoldMessenger.showSnackBar(
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
      title: Text(widget.lesson == null ? 'Yeni Ders Ekle' : 'Dersi Düzenle'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Ders Adı'),
              validator: (value) =>
                  value!.isEmpty ? 'Ders adı boş olamaz.' : null,
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Grade>>(
              future: _gradesFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return DropdownButtonFormField<int>(
                  initialValue: _selectedGradeId,
                  decoration: const InputDecoration(labelText: 'Sınıf'),
                  items: snapshot.data!
                      .map(
                        (grade) => DropdownMenuItem(
                          value: grade.id,
                          child: Text(grade.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedGradeId = value),
                  validator: (value) =>
                      value == null ? 'Lütfen bir sınıf seçin.' : null,
                );
              },
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
              : Text(widget.lesson == null ? 'Kaydet' : 'Güncelle'),
        ),
      ],
    );
  }
}
