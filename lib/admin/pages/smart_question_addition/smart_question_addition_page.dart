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

class SmartQuestionAdditionPage extends StatefulWidget {
  final int? initialGradeId;
  final int? initialLessonId;
  final int? initialUnitId;
  final int? initialTopicId;
  final int? initialCurriculumWeek;
  final String? initialUsageType;
  final List<int> initialOutcomeIds;

  const SmartQuestionAdditionPage({
    super.key,
    this.initialGradeId,
    this.initialLessonId,
    this.initialUnitId,
    this.initialTopicId,
    this.initialCurriculumWeek,
    this.initialUsageType,
    this.initialOutcomeIds = const [],
  });

  @override
  State<SmartQuestionAdditionPage> createState() =>
      _SmartQuestionAdditionPageState();
}

class _SmartQuestionAdditionPageState extends State<SmartQuestionAdditionPage> {
  final _formKey = GlobalKey<FormState>();
  final _gradeService = GradeService();
  final _unitService = UnitService();
  final _topicService = TopicService();

  // Controllers
  final _curriculumWeekController = TextEditingController();
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
  List<Map<String, dynamic>> _availableOutcomes = [];
  Set<int> _selectedOutcomeIds = {};

  String? _usageType = 'weekly';
  List<Map<String, dynamic>> _previewQuestions = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _showJsonInput = true;
  bool _initialSelectionAttempted = false;

  T? _firstOrNull<T>(Iterable<T> list, bool Function(T item) predicate) {
    for (final item in list) {
      if (predicate(item)) return item;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _selectedOutcomeIds = widget.initialOutcomeIds.toSet();
    _loadGrades();
  }

  @override
  void dispose() {
    _curriculumWeekController.dispose();
    _jsonController.dispose();
    super.dispose();
  }

  Future<void> _loadGrades() async {
    setState(() => _isLoading = true);
    try {
      _availableGrades = await _gradeService.getGradesWithLessons();
      await _applyInitialSelectionIfNeeded();
    } catch (e) {
      _showError('Sınıflar yüklenemedi: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _applyInitialSelectionIfNeeded() async {
    if (_initialSelectionAttempted) return;
    _initialSelectionAttempted = true;

    final hasPreset =
        widget.initialGradeId != null ||
        widget.initialLessonId != null ||
        widget.initialUnitId != null ||
        widget.initialTopicId != null ||
        widget.initialCurriculumWeek != null;
    if (!hasPreset) return;

    final presetGradeId = widget.initialGradeId;
    final presetLessonId = widget.initialLessonId;
    final presetUnitId = widget.initialUnitId;
    final presetTopicId = widget.initialTopicId;

    final grade = presetGradeId == null
        ? null
        : _firstOrNull(_availableGrades, (g) => g.id == presetGradeId);
    if (grade == null) return;

    _selectedGrade = grade;
    _availableLessons = grade.lessons;

    final lesson = presetLessonId == null
        ? null
        : _firstOrNull(_availableLessons, (l) => l.id == presetLessonId);
    if (lesson == null) {
      if (mounted) setState(() {});
      return;
    }

    _selectedLesson = lesson;
    _availableUnits = [];
    _selectedUnit = null;
    _availableTopics = [];
    _selectedTopic = null;
    _usageType = widget.initialUsageType ?? 'weekly';
    if (_usageType == 'weekly' && widget.initialCurriculumWeek != null) {
      _curriculumWeekController.text = widget.initialCurriculumWeek.toString();
    }

    if (mounted) setState(() {});

    await _loadUnits(grade.id, lesson.id);
    if (!mounted) return;

    final unit = presetUnitId == null
        ? null
        : _firstOrNull(_availableUnits, (u) => u.id == presetUnitId);
    if (unit == null) {
      setState(() {});
      return;
    }

    _selectedUnit = unit;
    _availableTopics = [];
    _selectedTopic = null;
    setState(() {});

    await _loadTopics(unit.id);
    if (!mounted) return;

    final topic = presetTopicId == null
        ? null
        : _firstOrNull(_availableTopics, (t) => t.id == presetTopicId);
    if (topic != null) {
      _selectedTopic = topic;
      await _loadOutcomesForSelection();
    }
    setState(() {});
  }

  Future<void> _loadOutcomesForSelection() async {
    final topic = _selectedTopic;
    if (topic == null) {
      if (!mounted) return;
      setState(() {
        _availableOutcomes = [];
        _selectedOutcomeIds = {};
      });
      return;
    }

    final week = int.tryParse(_curriculumWeekController.text.trim());
    final isWeekly = _usageType == 'weekly';

    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('outcomes')
          .select('id, description, outcome_weeks(start_week, end_week)')
          .eq('topic_id', topic.id)
          .order('id', ascending: true);

      final loaded = <Map<String, dynamic>>[];
      for (final raw in (response as List)) {
        final row = Map<String, dynamic>.from(raw as Map);
        final id = row['id'] as int?;
        final description = (row['description'] as String? ?? '').trim();
        if (id == null || description.isEmpty) continue;
        if (isWeekly && week != null) {
          final ranges = (row['outcome_weeks'] as List? ?? const <dynamic>[])
              .whereType<Map>()
              .map((r) => Map<String, dynamic>.from(r))
              .toList();
          final matchesWeek = ranges.any((r) {
            final start = r['start_week'] as int?;
            final end = r['end_week'] as int?;
            if (start == null || end == null) return false;
            return week >= start && week <= end;
          });
          if (!matchesWeek) continue;
        }
        loaded.add({'id': id, 'description': description});
      }

      final validIds = loaded.map((o) => o['id'] as int).toSet();
      final presetIds = widget.initialOutcomeIds.toSet().intersection(validIds);
      final nextSelected = _selectedOutcomeIds.intersection(validIds);
      if (nextSelected.isEmpty && presetIds.isNotEmpty) {
        nextSelected.addAll(presetIds);
      } else if (nextSelected.isEmpty) {
        nextSelected.addAll(validIds);
      }

      if (!mounted) return;
      setState(() {
        _availableOutcomes = loaded;
        _selectedOutcomeIds = nextSelected;
      });
    } catch (e) {
      _showError('Kazanımlar yüklenemedi: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUnits(int gradeId, int lessonId) async {
    setState(() => _isLoading = true);
    try {
      final units = await _unitService.getUnitsForGradeAndLesson(
        gradeId,
        lessonId,
      );
      _availableUnits = units.toSet().toList();
    } catch (e) {
      _showError('Üniteler yüklenemedi: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTopics(int unitId) async {
    setState(() => _isLoading = true);
    try {
      final topics = await _topicService.getTopicsForUnit(unitId);
      _availableTopics = topics.toSet().toList();
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
        _previewQuestions = List<Map<String, dynamic>>.from(questions);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Önizleme oluşturuldu.'),
          backgroundColor: Colors.blue,
        ),
      );
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
    if (_availableOutcomes.isNotEmpty && _selectedOutcomeIds.isEmpty) {
      _showError('Lütfen en az bir kazanım seçin.');
      return;
    }

    Map<String, dynamic> payloadForSupabase;

    if (_showJsonInput) {
      if (_jsonController.text.isEmpty) {
        _showError('JSON alanı boş olamaz.');
        return;
      }
      try {
        payloadForSupabase = jsonDecode(_jsonController.text);
        if (payloadForSupabase['questions'] == null ||
            (payloadForSupabase['questions'] as List).isEmpty) {
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
      payloadForSupabase = {'questions': _previewQuestions};
    }

    setState(() => _isSubmitting = true);

    try {
      var usedLegacySignature = false;
      try {
        await Supabase.instance.client.rpc(
          'bulk_create_questions',
          params: {
            'p_topic_id': _selectedTopic!.id,
            'p_usage_type': _usageType,
            'p_curriculum_week': _usageType == 'weekly'
                ? int.tryParse(_curriculumWeekController.text)
                : null,
            'p_start_week': null,
            'p_end_week': null,
            'p_questions_json': payloadForSupabase,
            'p_outcome_ids': _selectedOutcomeIds.toList(),
          },
        );
      } on PostgrestException catch (e) {
        final message = (e.message).toLowerCase();
        final isSignatureMismatch =
            e.code == 'PGRST202' && message.contains('p_outcome_ids');
        if (!isSignatureMismatch) rethrow;

        // DB eski fonksiyon imzasındaysa, outcomes parametresi olmadan tekrar dene.
        await Supabase.instance.client.rpc(
          'bulk_create_questions',
          params: {
            'p_topic_id': _selectedTopic!.id,
            'p_usage_type': _usageType,
            'p_curriculum_week': _usageType == 'weekly'
                ? int.tryParse(_curriculumWeekController.text)
                : null,
            'p_questions_json': payloadForSupabase,
          },
        );
        usedLegacySignature = true;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            usedLegacySignature
                ? 'Sorular eklendi. Not: DB migration eksik olduğu için kazanım eşlemesi yapılmadı.'
                : 'Sorular başarıyla eklendi!',
          ),
          backgroundColor: usedLegacySignature ? Colors.orange : Colors.green,
        ),
      );
      _resetForm();
    } on PostgrestException catch (e, st) {
      final errorMessage =
          "Veritabanı Hatası: ${e.message}\nKod: ${e.code}\nDetaylar: ${e.details}";
      debugPrint('--- SORU EKLEME HATASI (POSTGREST) ---');
      debugPrint(errorMessage);
      debugPrint('Stack Trace:\n$st');
      debugPrint('------------------------------------');
      _showError(errorMessage);
    } catch (e, st) {
      final errorMessage = 'Beklenmedik bir hata veya dönüşüm hatası: $e';
      debugPrint('--- SORU EKLEME HATASI (GENEL) ---');
      debugPrint(errorMessage);
      debugPrint('Stack Trace:\n$st');
      debugPrint('----------------------------------');
      _showError(errorMessage);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _resetForm() {
    _curriculumWeekController.clear();
    _jsonController.clear();

    setState(() {
      _selectedGrade = null;
      _availableLessons = [];
      _selectedLesson = null;
      _availableUnits = [];
      _selectedUnit = null;
      _availableTopics = [];
      _selectedTopic = null;
      _availableOutcomes = [];
      _selectedOutcomeIds = {};
      _usageType = 'weekly';
      _previewQuestions = [];
      _showJsonInput = true;
    });

    _formKey.currentState?.reset();
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 10),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Akıllı Soru Ekleme')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isLoading) ...[
                const LinearProgressIndicator(minHeight: 3),
                const SizedBox(height: 12),
              ],
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
                    child: Text(
                      _showJsonInput ? 'Manuel Ekleme Yap' : 'JSON ile Ekle',
                    ),
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
                label: Text(
                  _isSubmitting ? 'Kaydediliyor...' : 'Soruları Kaydet',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
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
            return DropdownMenuItem<Grade>(
              value: grade,
              child: Text(grade.name),
            );
          }).toList(),
          validator: (val) => val == null ? 'Lütfen bir sınıf seçin.' : null,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        // Lesson
        DropdownButtonFormField<Lesson>(
          initialValue: _selectedLesson,
          hint: const Text('Ders Seçin'),
          onChanged: _selectedGrade == null
              ? null
              : (lesson) {
                  setState(() {
                    _selectedLesson = lesson;
                    _availableUnits.clear();
                    _selectedUnit = null;
                    _availableTopics.clear();
                    _selectedTopic = null;
                    if (lesson != null) {
                      _loadUnits(_selectedGrade!.id, lesson.id);
                    }
                  });
                },
          items: _availableLessons.map((lesson) {
            return DropdownMenuItem<Lesson>(
              value: lesson,
              child: Text(lesson.name),
            );
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
          onChanged: _selectedLesson == null
              ? null
              : (unit) {
                  setState(() {
                    _selectedUnit = unit;
                    _availableTopics.clear();
                    _selectedTopic = null;
                    _availableOutcomes = [];
                    _selectedOutcomeIds = {};
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
          onChanged: _selectedUnit == null
              ? null
              : (topic) {
                  setState(() {
                    _selectedTopic = topic;
                    _availableOutcomes = [];
                    _selectedOutcomeIds = {};
                  });
                  if (topic != null) {
                    _loadOutcomesForSelection();
                  }
                },
          items: _availableTopics.map((topic) {
            return DropdownMenuItem<Topic>(
              value: topic,
              child: Text(topic.title),
            );
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
            if (_selectedTopic != null) {
              _loadOutcomesForSelection();
            }
          },
          items: const [
            DropdownMenuItem(value: 'weekly', child: Text('Haftalık')),
            DropdownMenuItem(value: 'topic_end', child: Text('Konu Sonu')),
          ],
          validator: (val) =>
              val == null ? 'Lütfen kullanım tipi seçin.' : null,
          decoration: const InputDecoration(
            labelText: 'Kullanım Tipi',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        // Week
        if (_usageType == 'weekly')
          TextFormField(
            controller: _curriculumWeekController,
            decoration: const InputDecoration(
              labelText: 'Hafta Numarası',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) {
              if (_selectedTopic != null) {
                _loadOutcomesForSelection();
              }
            },
            validator: (val) {
              if (_usageType == 'weekly' &&
                  (val == null || val.trim().isEmpty)) {
                return 'Zorunlu';
              }
              return null;
            },
          ),
        const SizedBox(height: 12),
        _buildOutcomeSelector(),
      ],
    );
  }

  Widget _buildOutcomeSelector() {
    if (_selectedTopic == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_outlined, size: 18),
              const SizedBox(width: 6),
              Text(
                'Kazanımlar',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade900,
                ),
              ),
              const Spacer(),
              if (_availableOutcomes.isNotEmpty)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedOutcomeIds = _availableOutcomes
                          .map((o) => o['id'] as int)
                          .toSet();
                    });
                  },
                  child: const Text('Tümünü Seç'),
                ),
            ],
          ),
          if (_availableOutcomes.isEmpty)
            Text(
              'Bu seçim için kazanım bulunamadı.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableOutcomes.map((outcome) {
                final id = outcome['id'] as int;
                final description = outcome['description'] as String;
                final selected = _selectedOutcomeIds.contains(id);
                return FilterChip(
                  label: SizedBox(
                    width: 240,
                    child: Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  selected: selected,
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        _selectedOutcomeIds.add(id);
                      } else {
                        _selectedOutcomeIds.remove(id);
                      }
                    });
                  },
                  selectedColor: Colors.blue.shade50,
                  checkmarkColor: Colors.blue.shade700,
                );
              }).toList(),
            ),
        ],
      ),
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

  String _getQuestionTypeName(int? typeId) {
    switch (typeId) {
      case 1:
        return 'Çoktan Seçmeli';
      case 2:
        return 'Doğru / Yanlış';
      case 3:
        return 'Boşluk Doldurma';
      case 5:
        return 'Eşleştirme';
      default:
        return 'Bilinmeyen Tip';
    }
  }

  Widget _buildPreview() {
    if (_previewQuestions.isEmpty) {
      return const Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.grey),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        child: Center(heightFactor: 3, child: Text('Henüz soru eklenmedi.')),
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
          final typeId = q['question_type_id'];

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            elevation: 2,
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(child: Text((index + 1).toString())),
                  title: Text(q['question_text'] ?? 'Metin yok'),
                  subtitle: Text(_getQuestionTypeName(typeId)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _previewQuestions.removeAt(index);
                      });
                    },
                  ),
                ),
                // Eşleştirme (ID: 5)
                if (typeId == 5 && q['pairs'] != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Column(
                      children: (q['pairs'] as List).map<Widget>((pair) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("• ${pair['left_text'] ?? ''}"),
                            Text(pair['right_text'] ?? ''),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                // Çoktan Seçmeli veya D/Y (ID: 1 veya 2)
                if ((typeId == 1 || typeId == 2) && q['choices'] != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: (q['choices'] as List).map<Widget>((choice) {
                        final isCorrect = choice['is_correct'] ?? false;
                        return Row(
                          children: [
                            Icon(
                              isCorrect
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: isCorrect ? Colors.green : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                choice['text'] ?? 'Seçenek metni yok',
                              ),
                            ),
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
