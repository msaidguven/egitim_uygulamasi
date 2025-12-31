// lib/admin/pages/topics/topic_form_dialog.dart

import 'package:egitim_uygulamasi/main.dart';
import 'package:egitim_uygulamasi/models/grade_model.dart';
import 'package:egitim_uygulamasi/models/lesson_model.dart';
import 'package:egitim_uygulamasi/models/topic_model.dart';
import 'package:egitim_uygulamasi/models/unit_model.dart';
import 'package:egitim_uygulamasi/services/grade_service.dart';
import 'package:egitim_uygulamasi/services/topic_service.dart';
import 'package:flutter/material.dart';

class TopicFormPage extends StatefulWidget {
  final Topic? topic;
  final VoidCallback onSave;

  const TopicFormPage({super.key, this.topic, required this.onSave});

  @override
  State<TopicFormPage> createState() => _TopicFormPageState();
}

class _TopicFormPageState extends State<TopicFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _topicService = TopicService();
  final _gradeService = GradeService();

  late TextEditingController _titleController;
  bool _isLoading = false;

  // Seçimler için state'ler
  int? _selectedGradeId;
  int? _selectedLessonId;
  int? _selectedUnitId;

  late Future<List<Grade>> _gradesFuture;
  List<Lesson> _lessons = [];
  bool _isLessonsLoading = false;
  List<Unit> _units = [];
  bool _isUnitsLoading = false;

  bool get _isEditing => widget.topic != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.topic?.title ?? '');
    _gradesFuture = _gradeService.getGrades();

    if (_isEditing && widget.topic != null) {
      // Düzenleme modunda, mevcut konunun ilişkili ID'lerini getirmek için
      // bir sorgu yapmamız gerekiyor. `topics` tablosu `units`'e, `units` tablosu da
      // `lessons` ve `grades`'e bağlı.
      // Bu bilgiyi getirmek için bir RPC veya join'li bir sorgu idealdir.
      // Şimdilik, sadece ünite ID'sini ayarlıyoruz.
      // TODO: Düzenleme modunda sınıf ve dersin otomatik seçili gelmesi için
      // topic'in unitId'sinden yola çıkarak gradeId ve lessonId'yi getiren bir
      // fonksiyon yazılmalı.
      _selectedUnitId = widget.topic!.unitId;
      // if (_selectedGradeId != null) {
      //   _loadLessonsForGrade(_selectedGradeId!);
      // }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadLessonsForGrade(int gradeId) async {
    setState(() {
      _isLessonsLoading = true;
      _lessons = [];
      _selectedLessonId = null;
      _units = [];
      _selectedUnitId = null;
    });
    final response = await supabase.rpc(
      'get_lessons_by_grade',
      params: {'gid': gradeId},
    );
    setState(() {
      _lessons = (response as List).map((e) => Lesson.fromMap(e)).toList();
      _isLessonsLoading = false;
    });
  }

  Future<void> _loadUnitsForLesson(int lessonId, int gradeId) async {
    setState(() {
      _isUnitsLoading = true;
      _units = [];
      _selectedUnitId = null;
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      int createdCount = 0;
      if (_isEditing) {
        await _topicService.updateTopic(
          id: widget.topic!.id,
          title: _titleController.text.trim(),
        );
      } else {
        if (_selectedUnitId == null) {
          throw Exception('Lütfen bir ünite seçin.');
        }

        final lines = _titleController.text.split('\n');
        final titles = lines.where((line) => line.trim().isNotEmpty).toList();

        for (final title in titles) {
          await _topicService.createTopic(
            title: title.trim(),
            unitId: _selectedUnitId!,
          );
          createdCount++;
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSave();

        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Konu başarıyla güncellendi!'
                  : '$createdCount konu başarıyla eklendi!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Hata durumunda diyaloğu kapatmıyoruz.
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.topic == null ? 'Yeni Konu Ekle' : 'Konuyu Düzenle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Konu Başlığı (Her satır yeni bir konudur)',
                  alignLabelWithHint: true,
                ),
                maxLines: null,
                minLines: 3,
                keyboardType: TextInputType.multiline,
                validator: (value) =>
                    value!.isEmpty ? 'Başlık boş olamaz.' : null,
              ),
              const SizedBox(height: 16),
              // Sınıf Seçici
              FutureBuilder<List<Grade>>(
                future: _gradesFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());
                  return DropdownButtonFormField<int>(
                    value: _selectedGradeId,
                    decoration: const InputDecoration(labelText: 'Sınıf'),
                    items: snapshot.data!
                        .map(
                          (g) => DropdownMenuItem(
                            value: g.id,
                            child: Text(g.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedGradeId = value);
                        _loadLessonsForGrade(value);
                      }
                    },
                    validator: (v) =>
                        v == null ? 'Sınıf seçimi zorunlu.' : null,
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
                    enabled: _selectedGradeId != null && _lessons.isNotEmpty,
                  ),
                  hint: const Text('Ders seçin'),
                  items: _lessons
                      .map(
                        (l) =>
                            DropdownMenuItem(value: l.id, child: Text(l.name)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedLessonId = value);
                      _loadUnitsForLesson(value, _selectedGradeId!);
                    }
                  },
                  validator: (v) => v == null ? 'Ders seçimi zorunlu.' : null,
                ),
              const SizedBox(height: 16),
              // Ünite Seçici
              if (_isUnitsLoading)
                const Center(child: CircularProgressIndicator())
              else
                DropdownButtonFormField<int>(
                  value: _selectedUnitId,
                  decoration: InputDecoration(
                    labelText: 'Ünite',
                    enabled: _selectedLessonId != null && _units.isNotEmpty,
                  ),
                  hint: const Text('Ünite seçin'),
                  items: _units
                      .map(
                        (u) =>
                            DropdownMenuItem(value: u.id, child: Text(u.title)),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedUnitId = value);
                  },
                  validator: (v) => v == null ? 'Ünite seçimi zorunlu.' : null,
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.topic == null ? 'Kaydet' : 'Güncelle'),
        ),
      ),
    );
  }
}
