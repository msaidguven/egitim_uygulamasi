// lib/screens/outcomes/outcomes_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:egitim_uygulamasi/services/cache_service.dart';
import 'package:egitim_uygulamasi/utils/date_utils.dart';
import 'package:egitim_uygulamasi/models/question_model.dart'; // Question modelini import et
import 'package:egitim_uygulamasi/models/topic_content.dart'; // TopicContent modelini import et
import 'package:egitim_uygulamasi/features/test/presentation/views/questions_screen.dart';


// _SuccessLevel sınıfını buraya taşıyoruz, çünkü ViewModel'ın iş mantığına dahil.
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

// _specialWeeks sabitini de ViewModel'a taşıyoruz veya ayrı bir model/servis katmanında tutabiliriz.
// Şimdilik ViewModel'a taşıyalım.
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
  final int lessonId;
  final int gradeId;
  final int? initialCurriculumWeek;
  final CacheService _cacheService = CacheService();

  PageController? _pageController;
  PageController get pageController {
    if (_pageController == null) {
      _pageController = PageController(initialPage: _initialPageIndex);
    }
    return _pageController!;
  }

  List<Map<String, dynamic>> _allWeeksData = [];
  List<Map<String, dynamic>> get allWeeksData => _allWeeksData;

  bool _isLoadingWeeks = true;
  bool get isLoadingWeeks => _isLoadingWeeks;

  bool _hasErrorWeeks = false;
  bool get hasErrorWeeks => _hasErrorWeeks;

  String _weeksErrorMessage = '';
  String get weeksErrorMessage => _weeksErrorMessage;

  int _initialPageIndex = 0;
  int get initialPageIndex => _initialPageIndex;

  // Haftaya özel verileri tutan haritalar
  final Map<int, Map<String, dynamic>> _weekMainContents = {};
  final Map<int, List<Question>> _weekQuestions = {};
  final Map<int, Map<String, dynamic>?> _weekStats = {};
  final Map<int, int> _weekUnitIds = {};
  final Map<int, bool> _weekLoadingStatus = {};
  final Map<int, String> _weekErrorMessages = {};

  // Mevcut haftanın verilerine erişim için getter'lar
  Map<String, dynamic>? get currentWeekContent => _weekMainContents[_currentWeek];
  List<Question>? get questions => _weekQuestions[_currentWeek];
  Map<String, dynamic>? get weeklyStats => _weekStats[_currentWeek];
  int? get unitId => _weekUnitIds[_currentWeek];
  bool get isLoadingContent => _weekLoadingStatus[_currentWeek] ?? false;
  bool get hasErrorContent => _weekErrorMessages.containsKey(_currentWeek);
  String get contentErrorMessage => _weekErrorMessages[_currentWeek] ?? '';

  int? _currentWeek;
  int? get currentWeek => _currentWeek;

  bool _disposed = false;

  OutcomesViewModel({
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

      for (final breakInfo in academicBreaks.reversed) {
        int breakIndex = processedWeeks.indexWhere((week) =>
            week['type'] == 'week' && week['curriculum_week'] == breakInfo['after_week']);
        if (breakIndex != -1) {
          final breaks = (breakInfo['weeks'] as List)
              .map((b) => Map<String, dynamic>.from(b))
              .toList();
          processedWeeks.insertAll(breakIndex + 1, breaks);
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

      if (initialCurriculumWeek != null) {
        _initialPageIndex = _allWeeksData.indexWhere((w) =>
            w['type'] == 'week' && w['curriculum_week'] == initialCurriculumWeek);
        if (_initialPageIndex == -1) _initialPageIndex = 0;
      } else {
        int currentAcademicWeek = calculateCurrentAcademicWeek();
        _initialPageIndex = _allWeeksData.indexWhere((w) =>
            w['type'] == 'week' &&
            w['curriculum_week'] == currentAcademicWeek);
        if (_initialPageIndex == -1) _initialPageIndex = 0;
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

  Future<void> fetchWeekContent(int curriculumWeek) async {
    _currentWeek = curriculumWeek;
    _safeNotifyListeners();

    // Mevcut, önceki ve sonraki haftaları önceden yükle
    _prefetchWeek(curriculumWeek);
    
    final weekIndex = _allWeeksData.indexWhere((w) => w['curriculum_week'] == curriculumWeek);
    if (weekIndex != -1) {
      // Önceki haftayı yükle
      if (weekIndex > 0) {
        final prevWeek = _allWeeksData[weekIndex - 1];
        if (prevWeek['type'] == 'week') {
          _prefetchWeek(prevWeek['curriculum_week']);
        }
      }
      // Sonraki haftayı yükle
      if (weekIndex < _allWeeksData.length - 1) {
        final nextWeek = _allWeeksData[weekIndex + 1];
        if (nextWeek['type'] == 'week') {
          _prefetchWeek(nextWeek['curriculum_week']);
        }
      }
    }
  }

  Future<void> _prefetchWeek(int curriculumWeek) async {
    // Zaten yüklendiyse veya yükleniyorsa tekrar deneme
    if (_weekMainContents.containsKey(curriculumWeek) || (_weekLoadingStatus[curriculumWeek] ?? false)) {
      return;
    }

    _weekLoadingStatus[curriculumWeek] = true;
    _weekErrorMessages.remove(curriculumWeek);
    // Sadece mevcut hafta için yükleme göstergesi göster
    if (curriculumWeek == _currentWeek) {
      _safeNotifyListeners();
    }

    try {
      final cachedData = await _cacheService.getWeeklyCurriculumData(
        curriculumWeek: curriculumWeek,
        lessonId: lessonId,
        gradeId: gradeId,
      );

      if (cachedData != null) {
        _weekMainContents[curriculumWeek] = cachedData;
        _weekUnitIds[curriculumWeek] = cachedData['unit_id'];
        if (curriculumWeek == _currentWeek) {
          _weekLoadingStatus[curriculumWeek] = false;
          _safeNotifyListeners();
        }
        await _fetchDynamicData(curriculumWeek);
      } else {
        final fullData = await _fetchFullDataFromNetwork(curriculumWeek: curriculumWeek);
        
        final contentToCache = Map<String, dynamic>.from(fullData);
        contentToCache.remove('mini_quiz_questions');
        _weekMainContents[curriculumWeek] = contentToCache;
        await _cacheService.saveWeeklyCurriculumData(
          curriculumWeek: curriculumWeek,
          lessonId: lessonId,
          gradeId: gradeId,
          data: contentToCache,
        );

        _weekQuestions[curriculumWeek] = (fullData['mini_quiz_questions'] as List? ?? [])
            .map((q) => Question.fromMap(q as Map<String, dynamic>))
            .toList();
        
        _weekUnitIds[curriculumWeek] = _weekMainContents[curriculumWeek]?['unit_id'];
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
      // Sadece mevcut hafta değiştiyse UI'ı güncelle
      if (curriculumWeek == _currentWeek) {
        _safeNotifyListeners();
      }
    }
  }

  Future<void> _fetchDynamicData(int curriculumWeek) async {
    try {
      final fullData = await _fetchNetworkDataWithoutCaching(curriculumWeek: curriculumWeek);
      
      _weekQuestions[curriculumWeek] = (fullData['mini_quiz_questions'] as List? ?? [])
          .map((q) => Question.fromMap(q as Map<String, dynamic>))
          .toList();
      
      await _loadWeeklyStats(curriculumWeek);

    } catch (e) {
      debugPrint('Error fetching dynamic data for week $curriculumWeek: $e');
      _weekQuestions.remove(curriculumWeek);
      _weekStats.remove(curriculumWeek);
    } finally {
      if (curriculumWeek == _currentWeek) {
        _safeNotifyListeners();
      }
    }
  }

  Future<void> _loadWeeklyStats(int curriculumWeek) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
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
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) throw Exception('Kullanıcı girişi gerekli.');

    final response = await Supabase.instance.client.rpc(
      'get_weekly_curriculum',
      params: {
        'p_user_id': userId,
        'p_grade_id': gradeId,
        'p_lesson_id': lessonId,
        'p_curriculum_week': curriculumWeek
      },
    );

    if (response == null || (response as List).isEmpty) {
      debugPrint('No data returned from get_weekly_curriculum for week $curriculumWeek');
      return {};
    }

    final firstItem = response.first;
    return {
      'unit_title': firstItem['unit_title'],
      'topic_title': firstItem['topic_title'],
      'topic_id': firstItem['topic_id'],
      'unit_id': firstItem['unit_id'],
      'outcomes': (response as List)
          .map((item) => item['outcome_description'] as String)
          .toSet()
          .toList(),
      'contents': firstItem['contents'],
      'mini_quiz_questions': firstItem['mini_quiz_questions'],
      'is_last_week_of_unit': firstItem['is_last_week_of_unit'],
      'unit_summary': firstItem['unit_summary'],
    };
  }

  Future<Map<String, dynamic>> _fetchFullDataFromNetwork({required int curriculumWeek}) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      try {
        await Supabase.instance.client.rpc('mark_week_as_started', params: {
          'p_user_id': userId,
          'p_lesson_id': lessonId,
          'p_grade_id': gradeId,
          'p_curriculum_week': curriculumWeek
        });
      } catch (e) {
        debugPrint("Error marking week as started: $e");
      }
    }
    
    return await _fetchNetworkDataWithoutCaching(curriculumWeek: curriculumWeek);
  }

  void refreshCurrentWeekData(int curriculumWeek) async {
    await _cacheService.clearWeeklyCurriculumData(
      curriculumWeek: curriculumWeek,
      lessonId: lessonId,
      gradeId: gradeId,
    );
    _weekMainContents.remove(curriculumWeek);
    _weekQuestions.remove(curriculumWeek);
    _weekStats.remove(curriculumWeek);
    _weekUnitIds.remove(curriculumWeek);
    _weekLoadingStatus.remove(curriculumWeek);
    _weekErrorMessages.remove(curriculumWeek);

    await fetchWeekContent(curriculumWeek);
  }
}
