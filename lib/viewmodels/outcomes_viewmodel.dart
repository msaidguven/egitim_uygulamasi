import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:egitim_uygulamasi/services/cache_service.dart';
import 'package:egitim_uygulamasi/utils/date_utils.dart';
import 'package:egitim_uygulamasi/models/question_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:egitim_uygulamasi/viewmodels/profile_viewmodel.dart';

// Helper class to pass arguments to the family provider
class OutcomesViewModelArgs {
  final int lessonId;
  final int gradeId;
  final int? initialCurriculumWeek;

  OutcomesViewModelArgs({
    required this.lessonId,
    required this.gradeId,
    this.initialCurriculumWeek,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OutcomesViewModelArgs &&
          runtimeType == other.runtimeType &&
          lessonId == other.lessonId &&
          gradeId == other.gradeId &&
          initialCurriculumWeek == other.initialCurriculumWeek;

  @override
  int get hashCode => lessonId.hashCode ^ gradeId.hashCode ^ initialCurriculumWeek.hashCode;
}

final outcomesViewModelProvider = ChangeNotifierProvider.family<OutcomesViewModel, OutcomesViewModelArgs>(
  (ref, args) => OutcomesViewModel(
    ref,
    lessonId: args.lessonId,
    gradeId: args.gradeId,
    initialCurriculumWeek: args.initialCurriculumWeek,
  ),
);

class SuccessLevel {
  final int starCount;
  final String title;
  final String message;
  final MaterialColor color;
  final IconData icon;

  SuccessLevel({
    required this.starCount,
    required this.title,
    required this.message,
    required this.color,
    required this.icon,
  });

  static SuccessLevel fromRate(double successRate) {
    if (successRate >= 85) {
      return SuccessLevel(
        starCount: 5,
        title: 'Mükemmel!',
        message: 'Konuya tamamen hakimsin. Harika bir iş çıkardın!',
        color: Colors.green,
        icon: Icons.celebration,
      );
    } else if (successRate >= 70) {
      return SuccessLevel(
        starCount: 4,
        title: 'Çok İyi!',
        message: 'Zirveye çok az kaldı. Başarın göz dolduruyor.',
        color: Colors.blue,
        icon: Icons.thumb_up_alt,
      );
    } else if (successRate >= 55) {
      return SuccessLevel(
        starCount: 3,
        title: 'İyi Yoldasın',
        message: 'Sağlam bir temel attın. Ufak tekrarlarla daha da iyi olacak.',
        color: Colors.teal,
        icon: Icons.trending_up,
      );
    } else if (successRate >= 50) {
      return SuccessLevel(
        starCount: 2,
        title: 'Daha İyi Olabilir',
        message: 'Konuyu anlıyorsun ama biraz daha gayret gerek.',
        color: Colors.orange,
        icon: Icons.lightbulb_outline,
      );
    } else {
      return SuccessLevel(
        starCount: 1,
        title: 'Tekrar Gerekli',
        message: 'Endişelenme, konuyu tekrar gözden geçirerek başarabilirsin.',
        color: Colors.red,
        icon: Icons.sync_problem,
      );
    }
  }
}

final List<Map<String, dynamic>> _specialWeeks = [
  {
    'grade_id': 5,
    'lesson_id': 3,
    'curriculum_week': 1,
    'type': 'special_content',
    'title': 'FEN LABORATUVARI KURALLARI',
    'icon': Icons.science,
    'content': "<ul><li>...</li></ul>",
  },
];

class OutcomesViewModel extends ChangeNotifier {
  final Ref _ref;
  final int lessonId;
  final int gradeId;
  final int? initialCurriculumWeek;
  final CacheService _cacheService = CacheService();

  PageController? _pageController;
  PageController get pageController {
    _pageController ??= PageController(initialPage: _initialPageIndex);
    return _pageController!;
  }

  List<Map<String, dynamic>> _allWeeksData = [];
  List<Map<String, dynamic>> get allWeeksData => _allWeeksData;

  List<Map<String, dynamic>> _lessonTopics = [];
  List<Map<String, dynamic>> get lessonTopics => _lessonTopics;

  bool _isLoadingLessonTopics = false;
  bool get isLoadingLessonTopics => _isLoadingLessonTopics;

  Set<int> _solvedWeeks = {};
  Set<int> get solvedWeeks => _solvedWeeks;

  bool _isLoadingWeeks = true;
  bool get isLoadingWeeks => _isLoadingWeeks;

  bool _hasErrorWeeks = false;
  bool get hasErrorWeeks => _hasErrorWeeks;

  String _weeksErrorMessage = '';
  String get weeksErrorMessage => _weeksErrorMessage;

  int _initialPageIndex = 0;
  int get initialPageIndex => _initialPageIndex;

  final Map<int, Map<String, dynamic>> _weekMainContents = {};
  final Map<int, List<Question>> _weekQuestions = {};
  final Map<int, Map<String, dynamic>?> _weekStats = {};
  final Map<int, int> _weekUnitIds = {};
  final Map<int, bool> _weekLoadingStatus = {};
  final Map<int, String> _weekErrorMessages = {};

  Map<String, dynamic>? getWeekContent(int week) => _weekMainContents[week];
  List<Question>? getWeekQuestions(int week) => _weekQuestions[week];
  Map<String, dynamic>? getWeekStats(int week) => _weekStats[week];
  int? getWeekUnitId(int week) => _weekUnitIds[week];
  bool isWeekLoading(int week) => _weekLoadingStatus[week] ?? false;
  String? getWeekError(int week) => _weekErrorMessages[week];

  int? _currentWeek;
  int? get currentWeek => _currentWeek;

  bool _disposed = false;

  OutcomesViewModel(
    this._ref, {
    required this.lessonId,
    required this.gradeId,
    this.initialCurriculumWeek,
  }) {
    _fetchAndProcessWeeks();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _disposed = true;
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> _fetchAndProcessWeeks() async {
    _isLoadingWeeks = true;
    _hasErrorWeeks = false;
    _weeksErrorMessage = '';
    _safeNotifyListeners();

    try {
      List<dynamic>? dbResult = await _cacheService.getAvailableWeeks(
          gradeId: gradeId, lessonId: lessonId);

      if (dbResult == null) {
        dbResult = await Supabase.instance.client.rpc(
          'get_available_weeks',
          params: {'p_grade_id': gradeId, 'p_lesson_id': lessonId},
        );
        await _cacheService.saveAvailableWeeks(
          gradeId: gradeId,
          lessonId: lessonId,
          weeks: dbResult ?? [],
        );
      }

      Map<int, Map<String, dynamic>> weeksMap = {};
      for (final specialWeek in _specialWeeks) {
        if (specialWeek['grade_id'] == gradeId &&
            specialWeek['lesson_id'] == lessonId) {
          weeksMap[specialWeek['curriculum_week']] = specialWeek;
        }
      }

      if (dbResult != null) {
        for (var item in dbResult) {
          final curriculumWeekValue = item['curriculum_week'];
          if (curriculumWeekValue != null) {
            final curriculumWeek = curriculumWeekValue as int;
            if (!weeksMap.containsKey(curriculumWeek)) {
              weeksMap[curriculumWeek] = {
                'type': 'week',
                'curriculum_week': curriculumWeek
              };
            }
          } else {
            debugPrint(
                'HATA: get_available_weeks RPC\'sinden null curriculum_week değeri geldi. Gelen veri: $item');
          }
        }
      }

      List<Map<String, dynamic>> processedWeeks = weeksMap.values.toList();
      processedWeeks.sort(
          (a, b) => (a['curriculum_week'] as int).compareTo(b['curriculum_week'] as int));

      // TATİL HAFTALARINI EKLEME MANTIĞI
      // Ters sıralama ile ekliyoruz ki indexler kaymasın.
      final breakEntries = getAcademicBreakEntries();
      for (final breakEntry in breakEntries.reversed) {
        final int breakAfterWeek = breakEntry['insert_after_week'] as int;
        
        // Hangi index'ten sonraya ekleneceğini bul
        int breakIndex = processedWeeks.indexWhere((week) =>
            week['type'] == 'week' && week['curriculum_week'] == breakAfterWeek);
        
        if (breakIndex != -1) {
          final breakMap = Map<String, dynamic>.from(breakEntry['break'] as Map);
          // Bulunan index'in bir sonrasına ekle
          processedWeeks.insert(breakIndex + 1, breakMap);
        }
      }

      int week36Index =
          processedWeeks.indexWhere((w) => w['type'] == 'week' && w['curriculum_week'] == 36);
      if (week36Index != -1) {
        processedWeeks.insert(week36Index + 1, {
          'type': 'social_activity',
          'curriculum_week': 37,
          'title': 'SOSYAL ETKİNLİK HAFTASI'
        });
      }

      _allWeeksData = processedWeeks;
      await _fetchLessonTopics();

      // Başlangıç sayfasını belirle
      final currentInfo = getCurrentPeriodInfo();
      
      // ÖNCELİK 1: Eğer şu an gerçek tarihte tatildeysek, parametreyi ez ve tatil kartını aç.
      if (currentInfo.isHoliday) {
        _initialPageIndex = _allWeeksData.indexWhere((w) =>
            w['type'] == 'break' &&
            w['title'] == currentInfo.displayTitle &&
            w['duration'] == currentInfo.displaySubtitle
        );
        
        // Eğer tam eşleşme bulamazsa (isim farkı vs.), genel bir 'break' bulmaya çalış
        if (_initialPageIndex == -1) {
           _initialPageIndex = _allWeeksData.indexWhere((w) => w['type'] == 'break');
        }
      }
      
      // ÖNCELİK 2: Tatil değilse veya tatil kartı bulunamadıysa parametreyi kullan
      if (_initialPageIndex == -1 || !currentInfo.isHoliday) {
        if (initialCurriculumWeek != null) {
          _initialPageIndex = _allWeeksData.indexWhere((w) =>
              w['type'] == 'week' && w['curriculum_week'] == initialCurriculumWeek);
        }
        
        // Parametre yoksa veya bulunamadıysa bugünü hesapla
        if (_initialPageIndex == -1) {
          int currentAcademicWeek = calculateCurrentAcademicWeek();
          _initialPageIndex = _allWeeksData.indexWhere((w) =>
              w['type'] == 'week' &&
              w['curriculum_week'] == currentAcademicWeek);
        }
        
        if (_initialPageIndex == -1) _initialPageIndex = 0;
      }

      // Sayfa kontrolcüsü zaten oluştuysa, onu yeni sayfaya zıplat
      if (_pageController != null && _pageController!.hasClients) {
        _pageController!.jumpToPage(_initialPageIndex);
      }
    } catch (e) {
      _hasErrorWeeks = true;
      _weeksErrorMessage = e.toString();
      _allWeeksData = [];
    } finally {
      _isLoadingWeeks = false;
      _safeNotifyListeners();
    }
  }

  Future<void> _fetchLessonTopics() async {
    _isLoadingLessonTopics = true;
    _safeNotifyListeners();
    try {
      final unitsResponse = await Supabase.instance.client
          .from('units')
          .select('id, title, order_no, unit_grades!inner(grade_id)')
          .eq('lesson_id', lessonId)
          .eq('is_active', true)
          .eq('unit_grades.grade_id', gradeId)
          .order('order_no', ascending: true);

      final units = (unitsResponse as List)
          .map((u) => Map<String, dynamic>.from(u as Map))
          .toList();
      final unitIds = units.map((u) => u['id']).whereType<int>().toList();
      final unitTitleById = <int, String>{
        for (final unit in units)
          if (unit['id'] is int) unit['id'] as int: (unit['title'] as String? ?? ''),
      };
      final unitOrderById = <int, int>{
        for (final unit in units)
          if (unit['id'] is int)
            unit['id'] as int: (unit['order_no'] as int? ?? 0),
      };

      if (unitIds.isEmpty) {
        _lessonTopics = [];
        _solvedWeeks = {};
        return;
      }

      final topicsResponse = await Supabase.instance.client
          .from('topics')
          .select('id, unit_id, title, order_no')
          .inFilter('unit_id', unitIds)
          .eq('is_active', true)
          .order('order_no', ascending: true);

      final rawTopics = (topicsResponse as List)
          .map((t) => Map<String, dynamic>.from(t as Map))
          .toList();

      final topicIds = rawTopics.map((t) => t['id']).whereType<int>().toList();
      final weeksByTopic = <int, Set<int>>{};
      for (final topicId in topicIds) {
        weeksByTopic[topicId] = <int>{};
      }

      if (topicIds.isNotEmpty) {
        final outcomesRes = await Supabase.instance.client
            .from('outcomes')
            .select('topic_id, outcome_weeks(start_week, end_week)')
            .inFilter('topic_id', topicIds);

        for (final raw in (outcomesRes as List)) {
          final row = Map<String, dynamic>.from(raw as Map);
          final topicId = row['topic_id'] as int?;
          if (topicId == null) continue;
          final list = (row['outcome_weeks'] as List? ?? []);
          for (final rawOw in list) {
            final ow = Map<String, dynamic>.from(rawOw as Map);
            final startWeek = ow['start_week'] as int?;
            final endWeek = ow['end_week'] as int?;
            if (startWeek == null || endWeek == null) continue;
            for (var w = startWeek; w <= endWeek; w++) {
              weeksByTopic[topicId]?.add(w);
            }
          }
        }

        final topicContentsRes = await Supabase.instance.client
            .from('topic_contents')
            .select('topic_id, topic_content_weeks(curriculum_week)')
            .inFilter('topic_id', topicIds);

        for (final raw in (topicContentsRes as List)) {
          final row = Map<String, dynamic>.from(raw as Map);
          final topicId = row['topic_id'] as int?;
          if (topicId == null) continue;
          final list = (row['topic_content_weeks'] as List? ?? []);
          for (final rawTcw in list) {
            final tcw = Map<String, dynamic>.from(rawTcw as Map);
            final week = tcw['curriculum_week'] as int?;
            if (week != null) weeksByTopic[topicId]?.add(week);
          }
        }
      }

      final topics = rawTopics.map((topic) {
        final unitId = topic['unit_id'] as int?;
        final topicId = topic['id'] as int?;
        final weeks = topicId != null
            ? ((weeksByTopic[topicId] ?? <int>{}).toList()..sort())
            : <int>[];
        return {
          'topic_id': topicId,
          'topic_title': topic['title'],
          'unit_id': unitId,
          'unit_title': unitId != null ? unitTitleById[unitId] : null,
          'unit_order': unitId != null ? (unitOrderById[unitId] ?? 0) : 0,
          'topic_order': topic['order_no'] as int? ?? 0,
          'weeks': weeks,
          'first_week': weeks.isNotEmpty ? weeks.first : null,
          'last_week': weeks.isNotEmpty ? weeks.last : null,
        };
      }).toList()
        ..sort((a, b) {
          final unitCompare = (a['unit_order'] as int).compareTo(b['unit_order'] as int);
          if (unitCompare != 0) return unitCompare;
          return (a['topic_order'] as int).compareTo(b['topic_order'] as int);
        });

      _lessonTopics = topics;
      await _fetchSolvedWeeks(unitIds);
    } catch (e) {
      debugPrint('Error fetching lesson topics: $e');
      _lessonTopics = [];
      _solvedWeeks = {};
    } finally {
      _isLoadingLessonTopics = false;
      _safeNotifyListeners();
    }
  }

  Future<void> _fetchSolvedWeeks(List<int> unitIds) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null || unitIds.isEmpty) {
        _solvedWeeks = {};
        return;
      }

      final response = await Supabase.instance.client
          .from('user_curriculum_week_run_summary')
          .select('curriculum_week, correct_count, wrong_count')
          .eq('user_id', userId)
          .inFilter('unit_id', unitIds);

      final solved = <int>{};
      for (final raw in (response as List)) {
        final row = Map<String, dynamic>.from(raw as Map);
        final week = row['curriculum_week'] as int?;
        final correct = row['correct_count'] as int? ?? 0;
        final wrong = row['wrong_count'] as int? ?? 0;
        if (week != null && (correct + wrong) > 0) {
          solved.add(week);
        }
      }
      _solvedWeeks = solved;
    } catch (e) {
      debugPrint('Error fetching solved weeks: $e');
      _solvedWeeks = {};
    }
  }

  Future<int?> findBestWeekForTopic({
    required int topicId,
    required int currentWeek,
  }) async {
    try {
      final topic = _lessonTopics.firstWhere(
        (t) => t['topic_id'] == topicId,
        orElse: () => <String, dynamic>{},
      );
      final weeks = (topic['weeks'] as List? ?? []).whereType<int>().toList();
      if (weeks.isEmpty) return null;

      weeks.sort();
      final futureOrCurrent = weeks.where((w) => w >= currentWeek).toList();
      return futureOrCurrent.isNotEmpty ? futureOrCurrent.first : weeks.first;
    } catch (e) {
      debugPrint('Error finding week for topic $topicId: $e');
      return null;
    }
  }

  void onPageChanged(int index) {
    final weekData = _allWeeksData[index];
    if (weekData['type'] == 'week') {
      final curriculumWeek = weekData['curriculum_week'] as int;
      _currentWeek = curriculumWeek;
      _safeNotifyListeners();

      _fetchWeekContent(index);
    }
  }

  Future<void> _fetchWeekContent(int index) async {
    if (index < 0 || index >= _allWeeksData.length) return;

    final weekData = _allWeeksData[index];
    if (weekData['type'] != 'week') return;

    final curriculumWeek = weekData['curriculum_week'] as int;

    final existingWeekData = _weekMainContents[curriculumWeek];
    final existingSections = existingWeekData?['sections'];
    final hasSectionedWeekData =
        existingSections is List && existingSections.isNotEmpty;

    if ((_weekMainContents.containsKey(curriculumWeek) && hasSectionedWeekData) ||
        (_weekLoadingStatus[curriculumWeek] ?? false)) {
      return;
    }

    _weekLoadingStatus[curriculumWeek] = true;
    _weekErrorMessages.remove(curriculumWeek);
    _safeNotifyListeners();

    try {
      final userProfile = _ref.read(profileViewModelProvider).profile;
      final isGuest = userProfile == null;

      if (!isGuest) {
        final cachedData = await _cacheService.getWeeklyCurriculumData(
          curriculumWeek: curriculumWeek,
          lessonId: lessonId,
          gradeId: gradeId,
        );
        if (cachedData != null) {
          final cachedSections = cachedData['sections'];
          final hasSections =
              cachedSections is List && cachedSections.isNotEmpty;

          // Backward-compatibility: eski cache kayıtlarında "sections" yoktu.
          // Bu durumda taze ağ verisi çekip cache'i yeni yapıya yükselt.
          if (hasSections) {
            _weekMainContents[curriculumWeek] = cachedData;
            _weekUnitIds[curriculumWeek] = cachedData['unit_id'];
            _safeNotifyListeners();
            await _fetchDynamicData(curriculumWeek, isGuest);
            return;
          }
        }
      }

      final fullData = await _fetchNetworkDataWithoutCaching(curriculumWeek: curriculumWeek);

      final contentToCache = Map<String, dynamic>.from(fullData);
      contentToCache.remove('mini_quiz_questions');
      _weekMainContents[curriculumWeek] = contentToCache;

      if (!isGuest) {
        await _cacheService.saveWeeklyCurriculumData(
          curriculumWeek: curriculumWeek,
          lessonId: lessonId,
          gradeId: gradeId,
          data: contentToCache,
        );
      }

      _weekQuestions[curriculumWeek] = (fullData['mini_quiz_questions'] as List? ?? [])
          .map((q) => Question.fromMap(q as Map<String, dynamic>))
          .toList();

      _weekUnitIds[curriculumWeek] = _weekMainContents[curriculumWeek]?['unit_id'];

      if (!isGuest) {
        await _loadWeeklyStats(curriculumWeek);
      }

    } catch (e) {
      _weekErrorMessages[curriculumWeek] = e.toString();
      _weekMainContents.remove(curriculumWeek);
      _weekQuestions.remove(curriculumWeek);
      _weekStats.remove(curriculumWeek);
      _weekUnitIds.remove(curriculumWeek);
    } finally {
      _weekLoadingStatus[curriculumWeek] = false;
      _safeNotifyListeners();
    }
  }

  Future<void> _fetchDynamicData(int curriculumWeek, bool isGuest) async {
    try {
      final userProfile = _ref.read(profileViewModelProvider).profile;
      final response = await Supabase.instance.client.rpc(
        'get_weekly_curriculum',
        params: {
          'p_user_id': isGuest ? null : userProfile?.id,
          'p_grade_id': gradeId,
          'p_lesson_id': lessonId,
          'p_curriculum_week': curriculumWeek,
          'p_is_admin': userProfile?.role == 'admin',
        },
      );

      if (response != null && (response as List).isNotEmpty) {
        final allQuestions = <int, Question>{};
        for (final item in (response as List)) {
          final quizQuestions = (item['mini_quiz_questions'] as List? ?? []);
          for (final q in quizQuestions) {
            final question = Question.fromMap(q as Map<String, dynamic>);
            allQuestions[question.id] = question;
          }
        }
        _weekQuestions[curriculumWeek] = allQuestions.values.toList();
      } else {
        _weekQuestions[curriculumWeek] = [];
      }

      if (!isGuest) {
        await _loadWeeklyStats(curriculumWeek);
      }

    } catch (e) {
      debugPrint('Error fetching dynamic data for week $curriculumWeek: $e');
      _weekQuestions.remove(curriculumWeek);
      _weekStats.remove(curriculumWeek);
    } finally {
      _safeNotifyListeners();
    }
  }

  Future<void> _loadWeeklyStats(int curriculumWeek) async {
    final userProfile = _ref.read(profileViewModelProvider).profile;
    final userId = userProfile?.id;
    final currentUnitId = _weekUnitIds[curriculumWeek];

    if (userId == null || currentUnitId == null) {
      _weekStats.remove(curriculumWeek);
      return;
    }

    final params = {
      'p_user_id': userId,
      'p_unit_id': currentUnitId,
      'p_curriculum_week': curriculumWeek,
    };

    try {
      final response = await Supabase.instance.client
          .rpc('get_weekly_summary_stats', params: params);
      _weekStats[curriculumWeek] = response as Map<String, dynamic>?;
    } catch (error) {
      debugPrint('[Stats] Error fetching weekly stats for week $curriculumWeek: $error');
      _weekStats.remove(curriculumWeek);
    }
  }

  Future<Map<String, dynamic>> _fetchNetworkDataWithoutCaching({required int curriculumWeek}) async {
    final userProfile = _ref.read(profileViewModelProvider).profile;
    final userId = userProfile?.id;

    final response = await Supabase.instance.client.rpc(
      'get_weekly_curriculum',
      params: {
        'p_user_id': userId,
        'p_grade_id': gradeId,
        'p_lesson_id': lessonId,
        'p_curriculum_week': curriculumWeek,
        'p_is_admin': userProfile?.role == 'admin',
      },
    );

    if (response == null || (response as List).isEmpty) {
      debugPrint('No data returned from get_weekly_curriculum for week $curriculumWeek');
      return {};
    }

    final firstItem = response.first as Map<String, dynamic>;
    final sectionMap = <String, Map<String, dynamic>>{};
    final allOutcomes = <String>{};
    final allContents = <int, Map<String, dynamic>>{};
    final allMiniQuizQuestions = <int, Map<String, dynamic>>{};
    final allUnitIds = <int>{};

    for (final rawItem in response) {
      final item = rawItem as Map<String, dynamic>;
      final unitId = item['unit_id'] as int?;
      final topicId = item['topic_id'] as int?;
      if (unitId == null || topicId == null) continue;

      allUnitIds.add(unitId);
      final sectionKey = '$unitId-$topicId';
      final section = sectionMap.putIfAbsent(sectionKey, () {
        return {
          'unit_id': unitId,
          'unit_title': item['unit_title'],
          'topic_id': topicId,
          'topic_title': item['topic_title'],
          'outcomes': <String>{},
          'contents': <Map<String, dynamic>>[],
        };
      });

      final outcome = item['outcome_description'] as String?;
      if (outcome != null && outcome.trim().isNotEmpty) {
        (section['outcomes'] as Set<String>).add(outcome);
        allOutcomes.add(outcome);
      }

      final sectionContents = (section['contents'] as List<Map<String, dynamic>>);
      final seenContentIds = sectionContents
          .map((c) => c['id'])
          .whereType<int>()
          .toSet();
      for (final rawContent in (item['contents'] as List? ?? [])) {
        final content = Map<String, dynamic>.from(rawContent as Map);
        final contentId = content['id'] as int?;
        if (contentId != null && seenContentIds.contains(contentId)) continue;
        if (contentId != null) {
          seenContentIds.add(contentId);
          allContents[contentId] = content;
        }
        sectionContents.add(content);
      }

      for (final rawQuestion in (item['mini_quiz_questions'] as List? ?? [])) {
        final question = Map<String, dynamic>.from(rawQuestion as Map);
        final questionId = question['id'] as int?;
        if (questionId != null) {
          allMiniQuizQuestions[questionId] = question;
        }
      }
    }

    final sections = sectionMap.values.map((section) {
      return {
        'unit_id': section['unit_id'],
        'unit_title': section['unit_title'],
        'topic_id': section['topic_id'],
        'topic_title': section['topic_title'],
        'outcomes': (section['outcomes'] as Set<String>).toList(),
        'contents': section['contents'],
      };
    }).toList();

    return {
      'unit_title': firstItem['unit_title'],
      'topic_title': firstItem['topic_title'],
      'topic_id': firstItem['topic_id'],
      'unit_id': firstItem['unit_id'],
      'unit_ids': allUnitIds.toList(),
      'is_multi_topic_week': sections.length > 1,
      'sections': sections,
      'outcomes': allOutcomes.toList(),
      'contents': allContents.values.toList(),
      'mini_quiz_questions': allMiniQuizQuestions.values.toList(),
      'is_last_week_of_unit': firstItem['is_last_week_of_unit'],
      'unit_summary': firstItem['unit_summary'],
    };
  }

  void refreshCurrentWeekData(int curriculumWeek) async {
    final userProfile = _ref.read(profileViewModelProvider).profile;
    final user = userProfile;

    if (user != null) {
      await _cacheService.clearWeeklyCurriculumData(
        curriculumWeek: curriculumWeek,
        lessonId: lessonId,
        gradeId: gradeId,
      );
    }
    _weekMainContents.remove(curriculumWeek);
    _weekQuestions.remove(curriculumWeek);
    _weekStats.remove(curriculumWeek);
    _weekUnitIds.remove(curriculumWeek);
    _weekLoadingStatus.remove(curriculumWeek);
    _weekErrorMessages.remove(curriculumWeek);

    final index = _allWeeksData.indexWhere((w) => w['curriculum_week'] == curriculumWeek);
    if (index != -1) {
      await _fetchWeekContent(index);
    }
  }
}
