import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:egitim_uygulamasi/models/grade_model.dart';
import 'package:egitim_uygulamasi/models/lesson_model.dart';
import 'package:egitim_uygulamasi/models/topic_model.dart';
import 'package:egitim_uygulamasi/models/unit_model.dart';
import 'package:egitim_uygulamasi/services/grade_service.dart';
import 'package:egitim_uygulamasi/services/topic_service.dart';
import 'package:egitim_uygulamasi/services/unit_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SmartContentAdditionPage extends StatefulWidget {
  final int? initialGradeId;
  final int? initialLessonId;
  final int? initialUnitId;
  final int? initialTopicId;
  final int? initialCurriculumWeek;
  final String? initialUsageType;

  const SmartContentAdditionPage({
    super.key,
    this.initialGradeId,
    this.initialLessonId,
    this.initialUnitId,
    this.initialTopicId,
    this.initialCurriculumWeek,
    this.initialUsageType,
  });

  @override
  State<SmartContentAdditionPage> createState() =>
      _SmartContentAdditionPageState();
}

class _SmartContentAdditionPageState extends State<SmartContentAdditionPage> {
  // Keys and Services
  final _formKey = GlobalKey<FormState>();
  final _gradeService = GradeService();
  final _unitService = UnitService();
  final _topicService = TopicService();

  // State Variables for Selections
  Grade? _selectedGrade;
  Lesson? _selectedLesson;
  Unit? _selectedUnit;
  Topic? _selectedTopic;

  // State Variables for Data Loading
  List<Grade> _availableGrades = [];
  List<Lesson> _availableLessons = [];
  List<Unit> _availableUnits = [];
  List<Topic> _availableTopics = [];
  List<Map<String, dynamic>> _availableOutcomes = [];

  // State Variables for UI Control
  bool _isLoadingGrades = true;
  bool _isLoadingUnits = false;
  bool _isLoadingTopics = false;
  bool _isLoadingOutcomes = false;
  String? _topicError;
  String? _outcomeError;
  bool _isSubmitting = false;
  String? _unitSelectionType = 'existing';
  String? _topicSelectionType = 'existing';
  bool _initialSelectionAttempted = false;

  // Text Editing Controllers
  final _newUnitTitleController = TextEditingController();
  final _newTopicTitleController = TextEditingController();
  final _topicContentTitleController = TextEditingController();
  final _rawTopicContentController = TextEditingController();
  final Set<int> _selectedOutcomeIds = <int>{};

  T? _firstOrNull<T>(Iterable<T> list, bool Function(T item) predicate) {
    for (final item in list) {
      if (predicate(item)) return item;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  @override
  void dispose() {
    _newUnitTitleController.dispose();
    _newTopicTitleController.dispose();
    _topicContentTitleController.dispose();
    _rawTopicContentController.dispose();
    super.dispose();
  }

  // --- DATA LOADING METHODS ---

  Future<void> _loadGrades() async {
    setState(() => _isLoadingGrades = true);
    try {
      _availableGrades = await _gradeService.getGradesWithLessons();
      await _applyInitialSelectionIfNeeded();
    } catch (e) {
      _showError('Sınıflar ve dersler yüklenemedi: $e');
    } finally {
      if (mounted) setState(() => _isLoadingGrades = false);
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
    _unitSelectionType = 'existing';
    _topicSelectionType = 'existing';
    _availableUnits = [];
    _selectedUnit = null;
    _availableTopics = [];
    _selectedTopic = null;
    _availableOutcomes = [];
    _selectedOutcomeIds.clear();
    if (mounted) setState(() {});

    await _loadAvailableUnits(grade.id, lesson.id);
    if (!mounted) return;

    final unit =
        (presetUnitId == null
            ? null
            : _firstOrNull(_availableUnits, (u) => u.id == presetUnitId)) ??
        (_availableUnits.isNotEmpty ? _availableUnits.first : null);
    if (unit == null) {
      setState(() {});
      return;
    }

    _selectedUnit = unit;
    _availableTopics = [];
    _selectedTopic = null;
    setState(() {});

    await _loadAvailableTopics(unit.id);
    if (!mounted) return;

    final topic =
        (presetTopicId == null
            ? null
            : _firstOrNull(_availableTopics, (t) => t.id == presetTopicId)) ??
        (_availableTopics.isNotEmpty ? _availableTopics.first : null);
    if (topic != null) {
      _selectedTopic = topic;
      await _loadOutcomesForTopic(
        topic.id,
        preselectWeek: widget.initialCurriculumWeek,
        autoSelectIfEmpty: true,
      );
    }
    setState(() {});
  }

  Future<void> _loadAvailableUnits(int gradeId, int lessonId) async {
    setState(() {
      _isLoadingUnits = true;
      _availableUnits = [];
      _selectedUnit = null;
    });
    try {
      _availableUnits = await _unitService.getUnitsForGradeAndLesson(
        gradeId,
        lessonId,
      );
    } catch (e) {
      _showError('Üniteler yüklenemedi: $e');
    } finally {
      if (mounted) setState(() => _isLoadingUnits = false);
    }
  }

  Future<void> _loadAvailableTopics(int unitId) async {
    setState(() {
      _isLoadingTopics = true;
      _topicError = null;
      _availableTopics = [];
      _selectedTopic = null;
      _availableOutcomes = [];
      _selectedOutcomeIds.clear();
    });
    try {
      _availableTopics = await _topicService.getTopicsForUnit(unitId);
    } catch (e, st) {
      final errorMessage = 'Konular yüklenemedi: $e\n$st';
      debugPrint('HATA: Konular yüklenemedi: $errorMessage');
      setState(() => _topicError = errorMessage);
    } finally {
      if (mounted) setState(() => _isLoadingTopics = false);
    }
  }

  Future<void> _loadOutcomesForTopic(
    int topicId, {
    int? preselectWeek,
    bool autoSelectIfEmpty = false,
  }) async {
    setState(() {
      _isLoadingOutcomes = true;
      _outcomeError = null;
      _availableOutcomes = [];
      _selectedOutcomeIds.clear();
    });
    try {
      final rows = await Supabase.instance.client
          .from('outcomes')
          .select('id, description, order_index')
          .eq('topic_id', topicId)
          .order('order_index', ascending: true);
      _availableOutcomes = (rows as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();

      if (preselectWeek != null && _availableOutcomes.isNotEmpty) {
        final outcomeIds = _availableOutcomes
            .map((o) => o['id'])
            .whereType<int>()
            .toList();
        if (outcomeIds.isNotEmpty) {
          final weekRows = await Supabase.instance.client
              .from('outcome_weeks')
              .select('outcome_id, start_week, end_week')
              .inFilter('outcome_id', outcomeIds);
          final matching = <int>{};
          for (final raw in (weekRows as List)) {
            final row = Map<String, dynamic>.from(raw as Map);
            final id = row['outcome_id'] as int?;
            final start = row['start_week'] as int?;
            final end = row['end_week'] as int?;
            if (id == null || start == null || end == null) continue;
            if (preselectWeek >= start && preselectWeek <= end) {
              matching.add(id);
            }
          }
          if (matching.isNotEmpty) {
            _selectedOutcomeIds
              ..clear()
              ..addAll(matching);
          } else if (autoSelectIfEmpty && _availableOutcomes.isNotEmpty) {
            final firstId = _availableOutcomes.first['id'] as int?;
            if (firstId != null) {
              _selectedOutcomeIds
                ..clear()
                ..add(firstId);
            }
          }
        }
      } else if (autoSelectIfEmpty && _availableOutcomes.isNotEmpty) {
        final firstId = _availableOutcomes.first['id'] as int?;
        if (firstId != null) {
          _selectedOutcomeIds
            ..clear()
            ..add(firstId);
        }
      }
    } catch (e, st) {
      debugPrint('Kazanımlar yüklenemedi: $e\n$st');
      _outcomeError = 'Kazanımlar yüklenemedi: $e';
    } finally {
      if (mounted) {
        setState(() => _isLoadingOutcomes = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  // --- FORM SUBMISSION ---

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final supabase = Supabase.instance.client;

    try {
      // --- Get data from form ---
      if (_selectedLesson == null || _selectedGrade == null) {
        throw Exception('Lütfen bir sınıf ve ders seçin.');
      }
      final gradeId = _selectedGrade!.id;
      final lessonId = _selectedLesson!.id;
      final newUnitTitle = _newUnitTitleController.text.trim();
      final newTopicTitle = _newTopicTitleController.text.trim();
      int? curriculumWeek = widget.initialCurriculumWeek;
      final contentText = _rawTopicContentController.text.trim();
      final contentTitle = _topicContentTitleController.text.trim();

      if (contentText.isEmpty) {
        throw Exception('İçerik metni boş olamaz.');
      }

      // --- Step 1: Resolve Unit ID ---
      int unitId;
      if (_unitSelectionType == 'existing') {
        if (_selectedUnit == null) {
          throw Exception('Lütfen mevcut bir ünite seçin.');
        }
        unitId = _selectedUnit!.id;
      } else {
        if (newUnitTitle.isEmpty) {
          throw Exception('Lütfen yeni ünite başlığı girin.');
        }

        final existingUnit = await supabase
            .from('units')
            .select('id, unit_grades!inner(grade_id)')
            .eq('lesson_id', lessonId)
            .eq('title', newUnitTitle)
            .eq('unit_grades.grade_id', gradeId)
            .maybeSingle();

        if (existingUnit != null) {
          unitId = existingUnit['id'];
        } else {
          final newUnit = await supabase
              .from('units')
              .insert({'lesson_id': lessonId, 'title': newUnitTitle})
              .select('id')
              .single();
          unitId = newUnit['id'];
        }
      }
      await supabase.from('unit_grades').upsert({
        'unit_id': unitId,
        'grade_id': gradeId,
      });

      // --- Step 2: Resolve Topic ID ---
      int topicId;
      if (_topicSelectionType == 'existing') {
        if (_selectedTopic == null) {
          throw Exception('Lütfen mevcut bir konu seçin.');
        }
        topicId = _selectedTopic!.id;
      } else {
        if (newTopicTitle.isEmpty) {
          throw Exception('Lütfen yeni konu başlığı girin.');
        }
        final existingTopic = await supabase
            .from('topics')
            .select('id')
            .eq('unit_id', unitId)
            .eq('title', newTopicTitle)
            .maybeSingle();

        if (existingTopic != null) {
          topicId = existingTopic['id'];
        } else {
          final newTopic = await supabase
              .from('topics')
              .insert({
                'unit_id': unitId,
                'title': newTopicTitle,
                'slug': newTopicTitle.toLowerCase().replaceAll(' ', '-'),
              })
              .select('id')
              .single();
          topicId = newTopic['id'];
        }
      }

      // --- Step 3: Process Content (HTML or JSON) ---
      dynamic decodedContent;
      try {
        decodedContent = jsonDecode(contentText);
      } catch (e) {
        decodedContent = null;
      }

      final isQuestionPayload =
          decodedContent is Map<String, dynamic> &&
          decodedContent.containsKey('questions');

      if (isQuestionPayload) {
        if (curriculumWeek == null || curriculumWeek < 1) {
          curriculumWeek = await _resolveDefaultWeekFromSelectedOutcomes();
        }
        if (curriculumWeek == null || curriculumWeek < 1) {
          throw Exception('Soru JSON\'u için hafta çözümlenemedi.');
        }
      } else {
        if (_selectedOutcomeIds.isEmpty) {
          throw Exception('İçerik için en az bir kazanım seçin.');
        }
      }

      if (isQuestionPayload) {
        // It's a JSON for questions, process it
        await _processAndInsertQuestions(
          decodedContent,
          topicId,
          curriculumWeek!,
        );
      } else {
        // It's regular HTML content
        await _insertTopicContent(
          topicId,
          contentTitle,
          contentText,
          curriculumWeek: curriculumWeek,
          selectedOutcomeIds: _selectedOutcomeIds.toList(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İçerik başarıyla eklendi!'),
            backgroundColor: Colors.green,
          ),
        );
        _resetForm();
      }
    } catch (e) {
      debugPrint('Form gönderme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İşlem sırasında hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _insertTopicContent(
    int topicId,
    String title,
    String content, {
    int? curriculumWeek,
    required List<int> selectedOutcomeIds,
  }) async {
    final supabase = Supabase.instance.client;
    final orderNoRes = await supabase
        .from('topic_contents')
        .select('order_no')
        .eq('topic_id', topicId)
        .order('order_no', ascending: false)
        .limit(1)
        .maybeSingle();

    final nextOrderNo = (orderNoRes?['order_no'] ?? -1) + 1;

    final newContent = await supabase
        .from('topic_contents')
        .insert({
          'topic_id': topicId,
          'title': title,
          'content': content,
          'order_no': nextOrderNo,
        })
        .select('id')
        .single();
    final newContentId = newContent['id'];

    if (selectedOutcomeIds.isNotEmpty) {
      await supabase
          .from('topic_content_outcomes')
          .insert(
            selectedOutcomeIds
                .map(
                  (outcomeId) => {
                    'topic_content_id': newContentId,
                    'outcome_id': outcomeId,
                  },
                )
                .toList(),
          );

      final weekRows = await supabase
          .from('outcome_weeks')
          .select('start_week, end_week')
          .inFilter('outcome_id', selectedOutcomeIds);
      final weekSet = <int>{};
      for (final raw in (weekRows as List)) {
        final row = Map<String, dynamic>.from(raw as Map);
        final start = row['start_week'] as int?;
        final end = row['end_week'] as int?;
        if (start == null || end == null) continue;
        for (var week = start; week <= end; week++) {
          weekSet.add(week);
        }
      }
      if (weekSet.isNotEmpty) {
        await supabase
            .from('topic_content_weeks')
            .insert(
              weekSet
                  .map(
                    (week) => {
                      'topic_content_id': newContentId,
                      'curriculum_week': week,
                    },
                  )
                  .toList(),
            );
      }
      return;
    }

    if (curriculumWeek != null && curriculumWeek >= 1) {
      await supabase.from('topic_content_weeks').insert({
        'topic_content_id': newContentId,
        'curriculum_week': curriculumWeek,
      });
    }
  }

  Future<void> _processAndInsertQuestions(
    Map<String, dynamic> data,
    int topicId,
    int curriculumWeek,
  ) async {
    final supabase = Supabase.instance.client;
    final questions = data['questions'] as List<dynamic>;

    for (final q in questions) {
      final questionData = q as Map<String, dynamic>;

      // 1. Insert the base question
      final Map<String, dynamic> questionToInsert = {
        'question_type_id': questionData['question_type_id'],
        'question_text': questionData['question_text'],
        'difficulty': questionData['difficulty'],
        'score': questionData['score'],
      };

      if (questionData.containsKey('correct_answer')) {
        questionToInsert['correct_answer'] = questionData['correct_answer'];
      }

      final newQuestion = await supabase
          .from('questions')
          .insert(questionToInsert)
          .select('id')
          .single();
      final questionId = newQuestion['id'];

      // 2. Insert question details based on type
      final typeId = questionData['question_type_id'];

      if (typeId == 1 && questionData.containsKey('choices')) {
        // Multiple Choice
        final choices = (questionData['choices'] as List)
            .map(
              (c) => {
                'question_id': questionId,
                'choice_text': c['text'],
                'is_correct': c['is_correct'],
              },
            )
            .toList();
        await supabase.from('question_choices').insert(choices);
      } else if (typeId == 3 && questionData.containsKey('blank')) {
        // Fill in the Blank
        final blankData = questionData['blank'] as Map<String, dynamic>;
        final options = (blankData['options'] as List)
            .map(
              (opt) => {
                'question_id': questionId, // Use question_id directly
                'option_text': opt['text'],
                'is_correct': opt['is_correct'],
              },
            )
            .toList();
        await supabase.from('question_blank_options').insert(options);
      }
      // ... handle other question types like matching, classical etc.

      // 3. Create usage record
      await supabase.from('question_usages').insert({
        'question_id': questionId,
        'topic_id': topicId,
        'usage_type': 'weekly',
        'curriculum_week': curriculumWeek,
      });
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _newUnitTitleController.clear();
    _newTopicTitleController.clear();
    _topicContentTitleController.clear();
    _rawTopicContentController.clear();
    _selectedOutcomeIds.clear();

    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        setState(() {
          _selectedGrade = null;
          _availableLessons.clear();
          _selectedLesson = null;
          _availableUnits.clear();
          _unitSelectionType = 'existing';
          _selectedUnit = null;
          _topicSelectionType = 'existing';
          _selectedTopic = null;
          _availableTopics.clear();
          _availableOutcomes.clear();
        });
      }
    });
  }

  // --- WIDGET BUILD METHODS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Akıllı İçerik Ekleme')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('1. Sınıf ve Ders Seçimi'),
              _buildGradeSelector(),
              const SizedBox(height: 12),
              _buildLessonSelector(),
              const SizedBox(height: 24),
              _buildSectionTitle('2. Ünite'),
              _buildUnitBlock(),
              const SizedBox(height: 24),
              _buildSectionTitle('3. Konu'),
              _buildTopicBlock(),
              const SizedBox(height: 24),
              _buildSectionTitle('4. Kazanım Eşlemesi'),
              _buildOutcomeSelector(),
              const SizedBox(height: 24),
              _buildSectionTitle('5. Konu İçeriği'),
              _buildContentInput(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildGradeSelector() {
    return _isLoadingGrades
        ? const Center(child: CircularProgressIndicator())
        : DropdownButtonFormField<Grade>(
            initialValue: _selectedGrade,
            hint: const Text('Sınıf Seçin'),
            onChanged: (grade) {
              if (grade == null) return;
              setState(() {
                _selectedGrade = grade;
                _availableLessons = grade.lessons;
                _selectedLesson = null;
                _availableUnits.clear();
                _selectedUnit = null;
                _availableTopics.clear();
                _selectedTopic = null;
                _availableOutcomes.clear();
                _selectedOutcomeIds.clear();
              });
            },
            items: _availableGrades.map((grade) {
              return DropdownMenuItem<Grade>(
                value: grade,
                child: Text(grade.name),
              );
            }).toList(),
            validator: (val) => val == null ? 'Lütfen bir sınıf seçin.' : null,
          );
  }

  Widget _buildLessonSelector() {
    return DropdownButtonFormField<Lesson>(
      initialValue: _selectedLesson,
      hint: const Text('Ders Seçin'),
      onChanged: _selectedGrade == null
          ? null
          : (lesson) {
              if (lesson == null) return;
              setState(() {
                _selectedLesson = lesson;
                _availableUnits.clear();
                _selectedUnit = null;
                _availableTopics.clear();
                _selectedTopic = null;
                _availableOutcomes.clear();
                _selectedOutcomeIds.clear();
                _loadAvailableUnits(_selectedGrade!.id, lesson.id);
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
    );
  }

  Widget _buildUnitBlock() {
    bool isEnabled = _selectedLesson != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Mevcut Ünite'),
                value: 'existing',
                groupValue: _unitSelectionType,
                onChanged: !isEnabled
                    ? null
                    : (val) => setState(() => _unitSelectionType = val),
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Yeni Ünite'),
                value: 'new',
                groupValue: _unitSelectionType,
                onChanged: !isEnabled
                    ? null
                    : (val) => setState(() {
                        _unitSelectionType = val;
                        if (val == 'new') {
                          _availableTopics.clear();
                          _selectedTopic = null;
                          _availableOutcomes.clear();
                          _selectedOutcomeIds.clear();
                        }
                      }),
              ),
            ),
          ],
        ),
        if (_unitSelectionType == 'existing')
          _isLoadingUnits
              ? const Center(child: CircularProgressIndicator())
              : DropdownButtonFormField<Unit>(
                  initialValue: _selectedUnit,
                  hint: const Text('Mevcut Üniteyi Seçin'),
                  onChanged: !isEnabled
                      ? null
                      : (unit) {
                          if (unit == null) return;
                          setState(() {
                            _selectedUnit = unit;
                            _loadAvailableTopics(unit.id);
                          });
                        },
                  items: _availableUnits
                      .map(
                        (unit) => DropdownMenuItem<Unit>(
                          value: unit,
                          child: Text(unit.title),
                        ),
                      )
                      .toList(),
                  validator: (val) =>
                      _unitSelectionType == 'existing' && val == null
                      ? 'Lütfen bir ünite seçin.'
                      : null,
                  decoration: InputDecoration(
                    enabled: isEnabled,
                    border: const OutlineInputBorder(),
                  ),
                )
        else
          TextFormField(
            controller: _newUnitTitleController,
            enabled: isEnabled,
            decoration: const InputDecoration(
              labelText: 'Yeni Ünite Adı',
              border: OutlineInputBorder(),
            ),
            validator: (val) =>
                _unitSelectionType == 'new' &&
                    (val == null || val.trim().isEmpty)
                ? 'Yeni ünite adı boş olamaz.'
                : null,
          ),
      ],
    );
  }

  Widget _buildTopicBlock() {
    bool isEnabled =
        (_unitSelectionType == 'existing' && _selectedUnit != null) ||
        (_unitSelectionType == 'new' &&
            _newUnitTitleController.text.isNotEmpty);
    Widget topicSelector;
    if (_isLoadingTopics) {
      topicSelector = const Center(child: CircularProgressIndicator());
    } else if (_topicError != null) {
      topicSelector = Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Text(
            'HATA: $_topicError',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    } else if (_availableTopics.isEmpty) {
      topicSelector = const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Text('Bu ünite için konu bulunamadı.'),
      );
    } else {
      topicSelector = Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
          ),
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        child: Column(
          children: _availableTopics.map((topic) {
            return RadioListTile<Topic>(
              title: Text(topic.title),
              value: topic,
              groupValue: _selectedTopic,
              onChanged: !isEnabled
                  ? null
                  : (newlySelectedTopic) async {
                      if (newlySelectedTopic == null) return;
                      setState(() => _selectedTopic = newlySelectedTopic);
                      final preselectWeek = widget.initialCurriculumWeek;
                      await _loadOutcomesForTopic(
                        newlySelectedTopic.id,
                        preselectWeek: preselectWeek,
                        autoSelectIfEmpty: true,
                      );
                    },
            );
          }).toList(),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Mevcut Konu'),
                value: 'existing',
                groupValue: _topicSelectionType,
                onChanged: !isEnabled
                    ? null
                    : (val) => setState(() => _topicSelectionType = val),
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Yeni Konu'),
                value: 'new',
                groupValue: _topicSelectionType,
                onChanged: !isEnabled
                    ? null
                    : (val) => setState(() {
                        _topicSelectionType = val;
                        if (val == 'new') {
                          _availableOutcomes = [];
                          _selectedOutcomeIds.clear();
                        }
                      }),
              ),
            ),
          ],
        ),
        if (_topicSelectionType == 'existing')
          topicSelector
        else
          TextFormField(
            controller: _newTopicTitleController,
            enabled: isEnabled,
            decoration: const InputDecoration(
              labelText: 'Yeni Konu Adı',
              border: OutlineInputBorder(),
            ),
            validator: (val) =>
                _topicSelectionType == 'new' &&
                    (val == null || val.trim().isEmpty)
                ? 'Yeni konu adı boş olamaz.'
                : null,
          ),
      ],
    );
  }

  Future<int?> _resolveDefaultWeekFromSelectedOutcomes() async {
    if (_selectedOutcomeIds.isEmpty) return null;
    final rows = await Supabase.instance.client
        .from('outcome_weeks')
        .select('start_week')
        .inFilter('outcome_id', _selectedOutcomeIds.toList())
        .order('start_week', ascending: true)
        .limit(1);
    final rowList = rows as List;
    if (rowList.isEmpty) return null;
    final firstRow = Map<String, dynamic>.from(rowList.first as Map);
    return firstRow['start_week'] as int?;
  }

  Widget _buildOutcomeSelector() {
    if (_topicSelectionType != 'existing' || _selectedTopic == null) {
      return const Text(
        'Kazanım seçmek için mevcut bir konu seçin. (Yeni konu için önce kazanımları oluşturun.)',
      );
    }

    if (_isLoadingOutcomes) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_outcomeError != null) {
      return Text(_outcomeError!, style: const TextStyle(color: Colors.red));
    }

    if (_availableOutcomes.isEmpty) {
      return const Text(
        'Bu konu için kazanım bulunamadı. İçerik hafta bazlı eklenecek.',
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bu içerik hangi kazanımları kapsıyor?',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ..._availableOutcomes.map((outcome) {
            final outcomeId = outcome['id'] as int;
            final desc = (outcome['description'] as String? ?? '').trim();
            return CheckboxListTile(
              value: _selectedOutcomeIds.contains(outcomeId),
              contentPadding: EdgeInsets.zero,
              title: Text(desc.isEmpty ? 'Kazanım #$outcomeId' : desc),
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    _selectedOutcomeIds.add(outcomeId);
                  } else {
                    _selectedOutcomeIds.remove(outcomeId);
                  }
                });
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildContentInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _topicContentTitleController,
          decoration: const InputDecoration(
            labelText: 'İçerik Başlığı',
            hintText: 'İsteğe bağlı içerik başlığı',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _rawTopicContentController,
          decoration: const InputDecoration(
            labelText: 'Konu İçeriği (HTML veya JSON)',
            hintText: 'HTML içeriği veya soru JSON\'u buraya girin...',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 20,
          minLines: 10,
          textAlignVertical: TextAlignVertical.top,
          validator: (val) => (val == null || val.trim().isEmpty)
              ? 'İçerik metni boş olamaz.'
              : null,
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _submitForm,
        icon: _isSubmitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_box),
        label: Text(_isSubmitting ? 'Kaydediliyor...' : 'İçerik Oluştur'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
