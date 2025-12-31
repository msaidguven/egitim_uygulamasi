// lib/admin/pages/units/unit_form_dialog.dart

import 'package:egitim_uygulamasi/models/grade_model.dart';
import 'package:egitim_uygulamasi/services/grade_service.dart';
import 'package:egitim_uygulamasi/services/unit_service.dart';
import 'package:flutter/material.dart';
import 'package:egitim_uygulamasi/models/unit_model.dart';
import 'package:egitim_uygulamasi/models/lesson_model.dart';
import 'package:egitim_uygulamasi/main.dart';

class UnitFormPage extends StatefulWidget {
  final Unit? unit;
  final VoidCallback onSave;

  const UnitFormPage({super.key, this.unit, required this.onSave});

  @override
  State<UnitFormPage> createState() => _UnitFormPageState();
}

class _UnitFormPageState extends State<UnitFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _unitService = UnitService();
  final _gradeService = GradeService();

  final _titleController = TextEditingController();

  // Seçimler için state'ler
  int? _selectedGradeId;
  Lesson? _selectedLesson;

  // Veri listeleri ve durumları
  late Future<List<Grade>> _gradesFuture;
  List<Lesson> _lessons = [];
  bool _isLessonsLoading = false;
  bool _isLoading = false;

  bool get _isEditing => widget.unit != null;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.unit?.title ?? '';
    _gradesFuture = _gradeService.getGrades();

    if (_isEditing && widget.unit != null) {
      _titleController.text = widget.unit!.title;
      // Düzenleme modunda, mevcut ünitenin sınıfını ve dersini yükle
      _loadInitialDataForEdit();
    }
  }

  Future<void> _loadInitialDataForEdit() async {
    // Düzenleme modunda, ünitenin sınıfını ve dersini getirmek için bir RPC çağrısı yapıyoruz.
    // Bu, dropdown'ların doğru değerlerle başlamasını sağlar.
    try {
      final response = await supabase
          .rpc('get_unit_details', params: {'uid': widget.unit!.id})
          .single();

      final gradeId = response['grade_id'] as int?;
      final lessonId = response['lesson_id'] as int?;

      if (gradeId != null && lessonId != null) {
        await _loadLessonsForGrade(gradeId); // Önce dersleri yükle
        if (mounted) {
          setState(() {
            _selectedGradeId = gradeId;
            // Yüklenen dersler arasından doğru olanı bul ve seç.
            // .firstWhere, eleman bulamazsa hata fırlatır. Bunu önlemek için try-catch kullanalım.
            try {
              _selectedLesson = _lessons.firstWhere((l) => l.id == lessonId);
            } catch (e) {
              _selectedLesson = null; // Eleman bulunamazsa null ata.
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Ünite detayları yüklenirken hata: $e');
    }
  }

  Future<void> _loadLessonsForGrade(int gradeId) async {
    setState(() {
      _isLessonsLoading = true;
      _lessons = [];
      _selectedLesson = null;
    });

    try {
      final response = await supabase.rpc(
        'get_lessons_by_grade',
        params: {'gid': gradeId},
      );
      if (mounted) {
        setState(() {
          _lessons = (response as List).map((e) => Lesson.fromMap(e)).toList();
        });
      }
    } catch (e) {
      debugPrint('Dersler yüklenirken hata: $e');
    } finally {
      if (mounted) setState(() => _isLessonsLoading = false);
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      try {
        // Form gönderilmeden önce seçimlerin yapıldığından emin ol.
        if (_selectedGradeId == null || _selectedLesson == null) {
          throw Exception('Sınıf ve Ders seçimi zorunludur.');
        }

        int createdCount = 0;

        if (_isEditing) {
          // Güncelleme
          await _unitService.updateUnit(
            widget.unit!.id,
            _titleController.text.trim(),
            _selectedLesson!.id,
            _selectedGradeId!,
          );
        } else {
          // Toplu Oluşturma (Batch Insert)
          // Metni satırlara böl, boş satırları temizle
          final lines = _titleController.text.split('\n');
          final titles = lines.where((line) => line.trim().isNotEmpty).toList();

          for (final title in titles) {
            await _unitService.createUnit(
              title.trim(),
              _selectedLesson!.id,
              _selectedGradeId!,
            );
            createdCount++;
          }
        }

        if (mounted) {
          final successMessage = _isEditing
              ? 'Ünite başarıyla güncellendi!'
              : '$createdCount ünite başarıyla oluşturuldu!';

          Navigator.of(context).pop();
          widget.onSave();

          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(successMessage),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
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
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // AlertDialog'dan Scaffold'a dönüştürüldü.
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.unit == null ? 'Yeni Ünite Ekle' : 'Üniteyi Düzenle',
        ),
        // Eğer bu sayfa Navigator.push ile açılıyorsa, geri butonu otomatik eklenir.
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              if (_isLessonsLoading)
                const Center(child: CircularProgressIndicator())
              else
                DropdownButtonFormField<Lesson>(
                  value: _selectedLesson,
                  decoration: InputDecoration(
                    labelText: 'Ders',
                    enabled: _selectedGradeId != null && _lessons.isNotEmpty,
                    hintText: _selectedGradeId == null
                        ? 'Önce sınıf seçin'
                        : null,
                  ),
                  items: _lessons
                      .map(
                        (lesson) => DropdownMenuItem(
                          value: lesson,
                          child: Text(lesson.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _selectedLesson = value),
                  validator: (value) =>
                      value == null ? 'Lütfen bir ders seçin.' : null,
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Ünite Başlığı (Her satır yeni bir ünitedir)',
                  alignLabelWithHint: true,
                ),
                maxLines: null,
                minLines: 5, // Daha fazla alan için
                keyboardType: TextInputType.multiline,
                validator: (value) => value == null || value.isEmpty
                    ? 'Başlık boş olamaz.'
                    : null,
              ),
            ],
          ),
        ),
      ),
      // Butonlar artık body'nin altına veya FloatingActionButton olarak eklenebilir.
      // Burada sayfanın altında sabit bir buton alanı oluşturalım.
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
              : Text(_isEditing ? 'Güncelle' : 'Kaydet'),
        ),
      ),
    );
  }
}
