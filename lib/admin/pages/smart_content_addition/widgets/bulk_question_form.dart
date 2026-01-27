import 'package:egitim_uygulamasi/admin/pages/smart_content_addition/widgets/add_question_dialog.dart';
import 'dart:convert';
import 'package:egitim_uygulamasi/models/grade_model.dart';
import 'package:egitim_uygulamasi/models/lesson_model.dart';
import 'package:egitim_uygulamasi/models/topic_model.dart';
import 'package:egitim_uygulamasi/models/unit_model.dart';
import 'package:egitim_uygulamasi/services/grade_service.dart';
import 'package:egitim_uygulamasi/services/topic_service.dart';
import 'package:egitim_uygulamasi/services/unit_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BulkQuestionForm extends StatefulWidget {
  const BulkQuestionForm({super.key});

  @override
  State<BulkQuestionForm> createState() => _BulkQuestionFormState();
}

class _BulkQuestionFormState extends State<BulkQuestionForm> {
  final _formKey = GlobalKey<FormState>();
  final _gradeService = GradeService();
  final _unitService = UnitService();
  final _topicService = TopicService();

  // Controllers
  final _startWeekController = TextEditingController();
  final _endWeekController = TextEditingController();
  final _jsonController = TextEditingController();

  // State
  List<Grade> _availableGrades = [];
  Grade? _selectedGrade;
  List<Lesson> _availableLessons = [];
  Lesson? _selectedLesson;
  List<Unit> _availableUnits = [];
  Unit? _selectedUnit;
  List<Topic> _availableTopics = [];
  Topic? _selectedTopic;

  String? _usageType = 'weekly';
  List<Map<String, dynamic>> _previewQuestions = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _showJsonInput = true;

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  @override
  void dispose() {
    _startWeekController.dispose();
    _endWeekController.dispose();
    _jsonController.dispose();
    super.dispose();
  }

  Future<void> _loadGrades() async {
    setState(() => _isLoading = true);
    try {
      _availableGrades = await _gradeService.getGradesWithLessons();
    } catch (e) {
      _showError('Sınıflar yüklenemedi: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUnits(int gradeId, int lessonId) async {
    setState(() => _isLoading = true);
    try {
      _availableUnits =
          await _unitService.getUnitsForGradeAndLesson(gradeId, lessonId);
    } catch (e) {
      _showError('Üniteler yüklenemedi: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTopics(int unitId) async {
    setState(() => _isLoading = true);
    try {
      _availableTopics = await _topicService.getTopicsForUnit(unitId);
    } catch (e) {
      _showError('Konular yüklenemedi: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addQuestion() {
    showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const AddQuestionDialog(),
    ).then((newQuestion) {
      if (newQuestion != null) {
        setState(() {
          _previewQuestions.add(newQuestion);
        });
      }
    });
  }
  
  void _previewQuestionsFromJson() {
    if (_jsonController.text.isEmpty) {
      _showError('JSON alanı boş olamaz.');
      return;
    }
    try {
      final data = jsonDecode(_jsonController.text);
      final questions = data['questions'] as List?;
      if (questions == null) {
        _showError('JSON formatı hatalı. "questions" anahtarı bulunamadı.');
        return;
      }
      setState(() {
        _previewQuestions = List<Map<String, dynamic>>.from(questions.map((q) {
          if (q['question_type'] == 'matching') {
            final pairs = (q['pairs'] as List?)?.map((p) {
              return {'left_text': p['left_text'], 'right_text': p['right_text']};
            }).toList();
            return {...q, 'pairs': pairs};
          }
          return q;
        }));
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Önizleme oluşturuldu.'),
        backgroundColor: Colors.blue,
      ));
    } catch (e) {
      _showError('JSON parse hatası: $e');
      setState(() {
        _previewQuestions = [];
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTopic == null) {
      _showError('Lütfen bir konu seçin.');
      return;
    }

    List<Map<String, dynamic>> questionsToSubmit;

    if (_showJsonInput) {
      if (_jsonController.text.isEmpty) {
        _showError('JSON alanı boş olamaz.');
        return;
      }
      try {
        final data = jsonDecode(_jsonController.text);
        final questions = data['questions'] as List?;
        if (questions == null) {
          _showError('JSON formatı hatalı. "questions" anahtarı bulunamadı.');
          return;
        }
        questionsToSubmit = List<Map<String, dynamic>>.from(questions.map((q) {
            if (q['question_type'] == 'matching') {
              final pairs = (q['pairs'] as List?)?.map((p) {
                return {'left_text': p['left_text'], 'right_text': p['right_text']};
              }).toList();
              return {...q, 'pairs': pairs};
            }
            return q;
          }));
        if (questionsToSubmit.isEmpty) {
          _showError('JSON içeriğinde soru bulunamadı.');
          return;
        }
      } catch (e) {
        _showError('JSON parse hatası: $e');
        return;
      }
    } else {
      if (_previewQuestions.isEmpty) {
        _showError('Lütfen soru ekleyin.');
        return;
      }
      questionsToSubmit = _previewQuestions;
    }

    setState(() => _isSubmitting = true);

    try {
      final response =
          await Supabase.instance.client.rpc('bulk_create_questions', params: {
        'p_topic_id': _selectedTopic!.id,
        'p_usage_type': _usageType,
        'p_start_week': int.tryParse(_startWeekController.text),
        'p_end_week': int.tryParse(_endWeekController.text),
        'p_questions_json': {'questions': questionsToSubmit},
      });

      final errors = response['errors'] as List;
      if (errors.isNotEmpty) {
        _showError('Bazı sorular eklenirken hata oluştu: ${errors.length} hata.');
        debugPrint('Bulk question errors: $errors');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sorular başarıyla eklendi!'),
          backgroundColor: Colors.green,
        ));
        _resetForm();
      }
    } on PostgrestException catch (e) {
      _showError('Supabase Hatası: ${e.message}');
    } catch (e) {
      _showError('Beklenmedik bir hata: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
  
  void _resetForm() {
    _formKey.currentState?.reset();
    _startWeekController.clear();
    _endWeekController.clear();
    _jsonController.clear();
    setState(() {
      _selectedGrade = null;
      _availableLessons = [];
      _selectedLesson = null;
      _availableUnits = [];
      _selectedUnit = null;
      _availableTopics = [];
      _selectedTopic = null;
      _usageType = 'weekly';
      _previewQuestions = [];
      _showJsonInput = false;
    });
  }


  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle('1. Hedef Belirle'),
            _buildDropdowns(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle('2. Soruları Ekle'),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showJsonInput = !_showJsonInput;
                    });
                  },
                  child: Text(_showJsonInput ? 'Manuel Ekleme Yap' : 'JSON ile Ekle'),
                ),
              ],
            ),
            
            if (_showJsonInput)
              _buildJsonInputSection()
            else
              _buildInteractiveQuestionSection(),

            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitForm,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSubmitting ? 'Kaydediliyor...' : 'Soruları Kaydet'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
  }

  Widget _buildDropdowns() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Grade
        DropdownButtonFormField<Grade>(
          initialValue: _selectedGrade,
          hint: const Text('Sınıf Seçin'),
          onChanged: (grade) {
            setState(() {
              _selectedGrade = grade;
              _availableLessons = grade?.lessons ?? [];
              _selectedLesson = null;
              _availableUnits.clear();
              _selectedUnit = null;
              _availableTopics.clear();
              _selectedTopic = null;
            });
          },
          items: _availableGrades.map((grade) {
            return DropdownMenuItem<Grade>(value: grade, child: Text(grade.name));
          }).toList(),
          validator: (val) => val == null ? 'Lütfen bir sınıf seçin.' : null,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        // Lesson
        DropdownButtonFormField<Lesson>(
          initialValue: _selectedLesson,
          hint: const Text('Ders Seçin'),
          onChanged: _selectedGrade == null ? null : (lesson) {
            setState(() {
              _selectedLesson = lesson;
              _availableUnits.clear();
              _selectedUnit = null;
              _availableTopics.clear();
              _selectedTopic = null;
              if (lesson != null) _loadUnits(_selectedGrade!.id, lesson.id);
            });
          },
          items: _availableLessons.map((lesson) {
            return DropdownMenuItem<Lesson>(value: lesson, child: Text(lesson.name));
          }).toList(),
          validator: (val) => val == null ? 'Lütfen bir ders seçin.' : null,
          decoration: InputDecoration(
            enabled: _selectedGrade != null,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        // Unit
        DropdownButtonFormField<Unit>(
          initialValue: _selectedUnit,
          hint: const Text('Ünite Seçin'),
          onChanged: _selectedLesson == null ? null : (unit) {
            setState(() {
              _selectedUnit = unit;
              _availableTopics.clear();
              _selectedTopic = null;
              if (unit != null) _loadTopics(unit.id);
            });
          },
          items: _availableUnits.map((unit) {
            return DropdownMenuItem<Unit>(value: unit, child: Text(unit.title));
          }).toList(),
          validator: (val) => val == null ? 'Lütfen bir ünite seçin.' : null,
          decoration: InputDecoration(
            enabled: _selectedLesson != null,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        // Topic
        DropdownButtonFormField<Topic>(
          initialValue: _selectedTopic,
          hint: const Text('Konu Seçin'),
          onChanged: _selectedUnit == null ? null : (topic) {
            setState(() => _selectedTopic = topic);
          },
          items: _availableTopics.map((topic) {
            return DropdownMenuItem<Topic>(value: topic, child: Text(topic.title));
          }).toList(),
          validator: (val) => val == null ? 'Lütfen bir konu seçin.' : null,
          decoration: InputDecoration(
            enabled: _selectedUnit != null,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        // Usage Type
        DropdownButtonFormField<String>(
          initialValue: _usageType,
          onChanged: (value) {
            setState(() => _usageType = value);
          },
          items: const [
            DropdownMenuItem(value: 'weekly', child: Text('Haftalık')),
            DropdownMenuItem(value: 'topic_end', child: Text('Konu Sonu')),
          ],
          validator: (val) => val == null ? 'Lütfen kullanım tipi seçin.' : null,
          decoration: const InputDecoration(
            labelText: 'Kullanım Tipi',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        // Week Range
        if (_usageType == 'weekly')
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _startWeekController,
                  decoration: const InputDecoration(
                    labelText: 'Başlangıç Haftası',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (val) {
                    if (_usageType == 'weekly' && (val == null || val.trim().isEmpty)) {
                      return 'Zorunlu';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _endWeekController,
                  decoration: const InputDecoration(
                    labelText: 'Bitiş Haftası',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (val) {
                    if (_usageType == 'weekly' && (val == null || val.trim().isEmpty)) {
                      return 'Zorunlu';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
      ],
    );
  }
  
  Widget _buildJsonInput() {
    return TextFormField(
      controller: _jsonController,
      decoration: const InputDecoration(
        labelText: 'Toplu Soru JSON',
        alignLabelWithHint: true,
        border: OutlineInputBorder(),
        hintText: 'Soruları JSON formatında buraya yapıştırın...',
      ),
      maxLines: 15,
      validator: (val) =>
          val == null || val.trim().isEmpty ? 'JSON boş olamaz.' : null,
    );
  }

  Widget _buildJsonInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildJsonInput(),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _previewQuestionsFromJson,
          icon: const Icon(Icons.visibility),
          label: const Text('Ön İzleme'),
        ),
        const SizedBox(height: 16),
        if (_previewQuestions.isNotEmpty) _buildPreview(),
      ],
    );
  }

  Widget _buildInteractiveQuestionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPreview(),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _addQuestion,
          icon: const Icon(Icons.add),
          label: const Text('Soru Ekle'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            textStyle: Theme.of(context).textTheme.labelLarge,
          ),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    if (_previewQuestions.isEmpty) {
      return const Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.grey),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        child: Center(
          heightFactor: 3,
          child: Text('Henüz soru eklenmedi.'),
        ),
      );
    }
    return Container(
      height: 300,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        itemCount: _previewQuestions.length,
        itemBuilder: (context, index) {
          final q = _previewQuestions[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            elevation: 2,
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(child: Text((index + 1).toString())),
                  title: Text(q['question_text'] ?? 'Metin yok'),
                  subtitle: Text(q['question_type'] ?? 'Tip yok'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _previewQuestions.removeAt(index);
                      });
                    },
                  ),
                ),
                if (q['question_type'] == 'matching' && q['pairs'] != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Column(
                      children: (q['pairs'] as List).map<Widget>((pair) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("• ${pair['left_text']}"),
                            Text(pair['right_text']),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                if (q['question_type'] == 'multiple_choice' && q['choices'] != null)
                   Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: (q['choices'] as List).map<Widget>((choice) {
                        return Row(
                          children: [
                            Icon(
                              choice['is_correct'] ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: choice['is_correct'] ? Colors.green : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(choice['text']),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}