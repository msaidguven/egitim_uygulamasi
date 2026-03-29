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

class _QuizRefQuestion {
  final String quizRef;
  final Map<String, dynamic>? payload;

  const _QuizRefQuestion({required this.quizRef, required this.payload});
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
    var successMessage = 'İçerik başarıyla eklendi!';
    var successColor = Colors.green;

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
            .select('id')
            .eq('lesson_id', lessonId)
            .eq('title', newUnitTitle)
            .eq('grade_id', gradeId)
            .maybeSingle();

        if (existingUnit != null) {
          unitId = existingUnit['id'];
        } else {
          final newUnit = await supabase
              .from('units')
              .insert({
                'lesson_id': lessonId,
                'grade_id': gradeId,
                'title': newUnitTitle,
              })
              .select('id')
              .single();
          unitId = newUnit['id'];
        }
      }

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
      final isLessonV11Payload =
          decodedContent is Map<String, dynamic> &&
          decodedContent.containsKey('lessonModule');

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
        if (!isLessonV11Payload) {
          throw Exception(
            'Yeni sistemde icerik alani gecerli bir lesson_v11 JSON\'u icermelidir.',
          );
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
        final contentId = await _insertTopicContentV11(
          topicId,
          contentTitle,
          decodedContent,
          selectedOutcomeIds: _selectedOutcomeIds.toList(),
        );
        try {
          final importedCount = await _importLessonV11QuizRefsAsQuestions(
            contentId: contentId,
            payload: decodedContent,
            topicId: topicId,
            selectedOutcomeIds: _selectedOutcomeIds.toList(),
            preferredWeek: curriculumWeek,
          );
          if (importedCount > 0) {
            successMessage =
                'İçerik eklendi, $importedCount adet quiz_refs sorusu soru bankasına kaydedildi.';
          } else {
            successMessage =
                'İçerik eklendi. quiz_refs için eklenecek uygun soru bulunamadı.';
            successColor = Colors.orange;
          }
        } catch (e) {
          successMessage =
              'İçerik eklendi fakat quiz_refs soruları kaydedilemedi: $e';
          successColor = Colors.orange;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: successColor,
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

  Future<int> _insertTopicContentV11(
    int topicId,
    String title,
    Map<String, dynamic> payload, {
    required List<int> selectedOutcomeIds,
  }) async {
    final supabase = Supabase.instance.client;
    final versionRes = await supabase
        .from('topic_contents_v11')
        .select('version_no')
        .eq('topic_id', topicId)
        .order('version_no', ascending: false)
        .limit(1)
        .maybeSingle();

    final nextVersionNo = (versionRes?['version_no'] ?? 0) + 1;
    final safeTitle = title.trim().isNotEmpty ? title.trim() : 'Lesson V11';

    final newContent = await supabase
        .from('topic_contents_v11')
        .insert({
          'topic_id': topicId,
          'title': safeTitle,
          'payload': payload,
          'version_no': nextVersionNo,
          'is_published': true,
          'source': 'smart_content_addition',
          'created_by': supabase.auth.currentUser?.id,
        })
        .select('id')
        .single();
    final newContentId = newContent['id'];

    if (selectedOutcomeIds.isNotEmpty) {
      await supabase
          .from('topic_content_outcomes_v11')
          .insert(
            selectedOutcomeIds
                .map(
                  (outcomeId) => {
                    'topic_content_v11_id': newContentId,
                    'outcome_id': outcomeId,
                  },
                )
                .toList(),
          );
    }
    return newContentId as int;
  }

  Future<int> _importLessonV11QuizRefsAsQuestions({
    required int contentId,
    required Map<String, dynamic> payload,
    required int topicId,
    required List<int> selectedOutcomeIds,
    int? preferredWeek,
  }) async {
    final refs = _extractQuizRefQuestionBlocks(payload);
    if (refs.isEmpty) return 0;

    final parsed = refs
        .map(
          (block) => _QuizRefQuestion(
            quizRef: block['id']?.toString() ?? '',
            payload: _convertLessonV11QuizToQuestionPayload(block),
          ),
        )
        .where((e) => e.quizRef.isNotEmpty && e.payload != null)
        .toList();

    final questionsPayload = parsed.map((e) => e.payload!).toList();
    if (questionsPayload.isEmpty) return 0;

    final resolvedWeek = (preferredWeek != null && preferredWeek > 0)
        ? preferredWeek
        : await _resolveDefaultWeekFromSelectedOutcomes();
    final usageType = (resolvedWeek != null && resolvedWeek > 0)
        ? 'weekly'
        : 'topic_end';

    dynamic rpcResult;
    try {
      rpcResult = await Supabase.instance.client.rpc(
        'bulk_create_questions',
        params: {
          'p_topic_id': topicId,
          'p_usage_type': usageType,
          'p_curriculum_week': usageType == 'weekly' ? resolvedWeek : null,
          'p_start_week': null,
          'p_end_week': null,
          'p_questions_json': {'questions': questionsPayload},
          'p_outcome_ids': selectedOutcomeIds,
        },
      );
    } on PostgrestException catch (e) {
      final message = e.message.toLowerCase();
      final signatureMismatch =
          e.code == 'PGRST202' && message.contains('p_outcome_ids');
      if (!signatureMismatch) rethrow;

      rpcResult = await Supabase.instance.client.rpc(
        'bulk_create_questions',
        params: {
          'p_topic_id': topicId,
          'p_usage_type': usageType,
          'p_curriculum_week': usageType == 'weekly' ? resolvedWeek : null,
          'p_start_week': null,
          'p_end_week': null,
          'p_questions_json': {'questions': questionsPayload},
        },
      );
    }

    final result = rpcResult is Map<String, dynamic>
        ? rpcResult
        : (rpcResult is Map
              ? Map<String, dynamic>.from(rpcResult)
              : <String, dynamic>{});
    final insertedCount = (result['inserted_count'] as num?)?.toInt() ?? 0;
    final insertedIds = (result['inserted_question_ids'] as List? ?? const [])
        .whereType<num>()
        .map((e) => e.toInt())
        .toList();
    final errors = (result['errors'] as List?) ?? const [];
    if (errors.isNotEmpty) {
      throw Exception(errors.first.toString());
    }
    if (insertedIds.length == parsed.length) {
      final linkRows = <Map<String, dynamic>>[];
      for (var i = 0; i < parsed.length; i++) {
        linkRows.add({
          'topic_content_v11_id': contentId,
          'question_id': insertedIds[i],
          'quiz_ref': parsed[i].quizRef,
        });
      }
      if (linkRows.isNotEmpty) {
        await Supabase.instance.client
            .from('topic_content_generated_questions')
            .insert(linkRows);
      }
    }
    return insertedCount;
  }

  List<Map<String, dynamic>> _extractQuizRefQuestionBlocks(
    Map<String, dynamic> payload,
  ) {
    final module = payload['lessonModule'];
    if (module is! Map) return const [];
    final sectionsRaw = module['sections'];
    if (sectionsRaw is! List) return const [];

    final allQuizById = <String, Map<String, dynamic>>{};
    for (final sectionRaw in sectionsRaw) {
      if (sectionRaw is! Map) continue;
      final section = Map<String, dynamic>.from(sectionRaw);
      final quizRaw = section['quiz'];
      if (quizRaw is! List) continue;
      for (final blockRaw in quizRaw) {
        if (blockRaw is! Map) continue;
        final block = Map<String, dynamic>.from(blockRaw);
        final id = block['id']?.toString();
        if (id == null || id.isEmpty) continue;
        allQuizById[id] = block;
      }
    }

    final picked = <Map<String, dynamic>>[];
    final seenIds = <String>{};
    for (final sectionRaw in sectionsRaw) {
      if (sectionRaw is! Map) continue;
      final section = Map<String, dynamic>.from(sectionRaw);
      final refsRaw = section['quiz_refs'];
      if (refsRaw is! List) continue;
      for (final ref in refsRaw) {
        final refId = ref?.toString();
        if (refId == null || refId.isEmpty || seenIds.contains(refId)) {
          continue;
        }
        final quiz = allQuizById[refId];
        if (quiz != null) {
          picked.add(quiz);
          seenIds.add(refId);
        }
      }
    }
    return picked;
  }

  Map<String, dynamic>? _convertLessonV11QuizToQuestionPayload(
    Map<String, dynamic> quizBlock,
  ) {
    final contentRaw = quizBlock['content'];
    if (contentRaw is! Map) return null;
    final content = Map<String, dynamic>.from(contentRaw);

    final questionType = (content['questionType'] as String? ?? '')
        .trim()
        .toLowerCase();
    if (questionType.isEmpty) return null;

    final questionText =
        (content['question_text'] as String?)?.trim().isNotEmpty == true
        ? (content['question_text'] as String).trim()
        : (content['question'] as String?)?.trim() ?? '';
    if (questionText.isEmpty) return null;

    final solutionText = (content['explanation'] as String?)?.trim();
    final base = <String, dynamic>{
      'question_text': questionText,
      'difficulty': 1,
      'score': 1,
      if (solutionText != null && solutionText.isNotEmpty)
        'solution_text': solutionText,
    };

    switch (questionType) {
      case 'single_choice':
      case 'multiple_choice':
        final optionsRaw = content['options'] as List? ?? const [];
        final correctOne = content['correctOptionId']?.toString();
        final correctMany = (content['correctOptionIds'] as List? ?? const [])
            .map((e) => e.toString())
            .toSet();
        final choices = <Map<String, dynamic>>[];
        for (final optionRaw in optionsRaw) {
          if (optionRaw is! Map) continue;
          final option = Map<String, dynamic>.from(optionRaw);
          final optionText = (option['text'] as String?)?.trim();
          if (optionText == null || optionText.isEmpty) continue;
          final optionId = option['id']?.toString();
          final isCorrect =
              (correctOne != null && optionId == correctOne) ||
              (optionId != null && correctMany.contains(optionId));
          choices.add({'text': optionText, 'is_correct': isCorrect});
        }
        if (choices.isEmpty) return null;
        return {...base, 'question_type_id': 1, 'choices': choices};

      case 'true_false':
        final raw = content['correctAnswer'];
        bool? correct;
        if (raw is bool) {
          correct = raw;
        } else if (raw is String) {
          final lowered = raw.toLowerCase();
          if (lowered == 'true') correct = true;
          if (lowered == 'false') correct = false;
        }
        if (correct == null) return null;
        return {...base, 'question_type_id': 2, 'correct_answer': correct};

      case 'fill_blank':
        final accepted = (content['acceptedAnswers'] as List? ?? const [])
            .whereType<String>()
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        final distractors = (content['distractors'] as List? ?? const [])
            .whereType<String>()
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        final seen = <String>{};
        final options = <Map<String, dynamic>>[];
        for (final answer in accepted) {
          if (seen.add(answer.toLowerCase())) {
            options.add({'text': answer, 'is_correct': true});
          }
        }
        for (final distractor in distractors) {
          if (seen.add(distractor.toLowerCase())) {
            options.add({'text': distractor, 'is_correct': false});
          }
        }
        if (options.isEmpty) return null;
        return {
          ...base,
          'question_type_id': 3,
          'blank': {'options': options},
        };

      case 'matching':
        final pairsRaw = content['pairs'] as List? ?? const [];
        final pairs = <Map<String, dynamic>>[];
        for (final pairRaw in pairsRaw) {
          if (pairRaw is! Map) continue;
          final pair = Map<String, dynamic>.from(pairRaw);
          final left =
              (pair['left_text'] as String?)?.trim() ??
              (pair['left'] as String?)?.trim() ??
              '';
          final right =
              (pair['right_text'] as String?)?.trim() ??
              (pair['right'] as String?)?.trim() ??
              '';
          if (left.isEmpty || right.isEmpty) continue;
          pairs.add({'left_text': left, 'right_text': right});
        }
        if (pairs.isEmpty) return null;
        return {...base, 'question_type_id': 5, 'pairs': pairs};

      case 'ordering':
      case 'classical_order':
        final words = (content['answer_words'] as List? ?? const [])
            .whereType<String>()
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        String? modelAnswer = (content['model_answer'] as String?)?.trim();
        if (modelAnswer == null || modelAnswer.isEmpty) {
          if (words.isNotEmpty) {
            modelAnswer = words.join(' -> ');
          }
        }
        if (modelAnswer == null || modelAnswer.isEmpty) return null;
        return {
          ...base,
          'question_type_id': 4,
          'model_answer': modelAnswer,
          if (words.isNotEmpty) 'answer_words': words,
        };
    }

    return null;
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
              _buildSectionTitle('5. Lesson V11 İçeriği'),
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
            labelText: 'Konu İçeriği (lesson_v11 JSON veya soru JSON)',
            hintText: 'Lesson V11 JSON\'u veya soru JSON\'u buraya girin...',
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
