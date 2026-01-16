import 'package:collection/collection.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:egitim_uygulamasi/models/question_model.dart';
import 'package:egitim_uygulamasi/screens/questions_screen.dart';
import 'package:egitim_uygulamasi/screens/unit_summary_screen.dart';
import 'package:egitim_uygulamasi/services/cache_service.dart';
import 'package:egitim_uygulamasi/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_table/flutter_html_table.dart';
import 'package:egitim_uygulamasi/models/topic_content.dart';
import 'package:egitim_uygulamasi/utils/html_style.dart';

// YENİ: Merkezi Başarı Seviyesi Sistemi
class _SuccessLevel {
  final int starCount;
  final String title;
  final String message;
  final MaterialColor color; // DÜZELTME: Color -> MaterialColor
  final IconData icon;

  _SuccessLevel({
    required this.starCount,
    required this.title,
    required this.message,
    required this.color,
    required this.icon,
  });

  static _SuccessLevel fromRate(double successRate) {
    if (successRate >= 85) {
      return _SuccessLevel(
        starCount: 5,
        title: 'Mükemmel!',
        message: 'Konuya tamamen hakimsin. Harika bir iş çıkardın!',
        color: Colors.green,
        icon: Icons.celebration,
      );
    } else if (successRate >= 70) {
      return _SuccessLevel(
        starCount: 4,
        title: 'Çok İyi!',
        message: 'Zirveye çok az kaldı. Başarın göz dolduruyor.',
        color: Colors.blue,
        icon: Icons.thumb_up_alt,
      );
    } else if (successRate >= 55) {
      return _SuccessLevel(
        starCount: 3,
        title: 'İyi Yoldasın',
        message: 'Sağlam bir temel attın. Ufak tekrarlarla daha da iyi olacak.',
        color: Colors.teal,
        icon: Icons.trending_up,
      );
    } else if (successRate >= 50) {
      return _SuccessLevel(
        starCount: 2,
        title: 'Daha İyi Olabilir',
        message: 'Konuyu anlıyorsun ama biraz daha gayret gerek.',
        color: Colors.orange,
        icon: Icons.lightbulb_outline,
      );
    } else {
      return _SuccessLevel(
        starCount: 1,
        title: 'Tekrar Gerekli',
        message: 'Endişelenme, konuyu tekrar gözden geçirerek başarabilirsin.',
        color: Colors.red,
        icon: Icons.sync_problem,
      );
    }
  }
}


// ... (sabit listeler ve ekranın üst kısmı aynı) ...
final List<Map<String, dynamic>> _specialWeeks = [
  {
    'grade_id': 5,
    'lesson_id': 3,
    'week_no': 1,
    'type': 'special_content',
    'title': 'FEN LABORATUVARI KURALLARI',
    'icon': Icons.science,
    'content': "<ul><li>...</li></ul>",
  },
];

class OutcomesScreen extends StatefulWidget {
  final int lessonId;
  final int gradeId;
  final String gradeName;
  final String lessonName;
  final int? initialWeek;

  const OutcomesScreen({
    super.key,
    required this.lessonId,
    required this.gradeId,
    required this.gradeName,
    required this.lessonName,
    this.initialWeek,
  });

  @override
  State<OutcomesScreen> createState() => _OutcomesScreenState();
}

class _OutcomesScreenState extends State<OutcomesScreen> {
  PageController? _pageController;
  Future<List<Map<String, dynamic>>>? _weeksFuture;
  final CacheService _cacheService = CacheService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final dataFuture = _fetchAndProcessWeeks();
        final delayFuture = Future.delayed(const Duration(milliseconds: 200));
        final combinedFuture = Future.wait([dataFuture, delayFuture])
            .then((results) => results[0] as List<Map<String, dynamic>>);
        setState(() {
          _weeksFuture = combinedFuture;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchAndProcessWeeks() async {
    List<dynamic>? dbResult;
    dbResult = await _cacheService.getAvailableWeeks(
        gradeId: widget.gradeId, lessonId: widget.lessonId);
    if (dbResult == null) {
      try {
        dbResult = await Supabase.instance.client.rpc(
          'get_available_weeks',
          params: {'p_grade_id': widget.gradeId, 'p_lesson_id': widget.lessonId},
        );
        await _cacheService.saveAvailableWeeks(
          gradeId: widget.gradeId,
          lessonId: widget.lessonId,
          weeks: dbResult ?? [],
        );
      } catch (e) {
        dbResult = [];
      }
    }
    Map<int, Map<String, dynamic>> weeksMap = {};
    for (final specialWeek in _specialWeeks) {
      if (specialWeek['grade_id'] == widget.gradeId &&
          specialWeek['lesson_id'] == widget.lessonId) {
        weeksMap[specialWeek['week_no']] = specialWeek;
      }
    }
    if (dbResult != null) {
      for (var item in dbResult) {
        final weekNo = item['week_no'] as int;
        if (!weeksMap.containsKey(weekNo)) {
          weeksMap[weekNo] = {'type': 'week', 'week_no': weekNo};
        }
      }
    }
    List<Map<String, dynamic>> processedWeeks = weeksMap.values.toList();
    processedWeeks
        .sort((a, b) => (a['week_no'] as int).compareTo(b['week_no'] as int));
    for (final breakInfo in academicBreaks.reversed) {
      int breakIndex = processedWeeks.indexWhere((week) =>
          week['type'] == 'week' && week['week_no'] == breakInfo['after_week']);
      if (breakIndex != -1) {
        final breaks = (breakInfo['weeks'] as List)
            .map((b) => Map<String, dynamic>.from(b))
            .toList();
        processedWeeks.insertAll(breakIndex + 1, breaks);
      }
    }
    int week36Index =
        processedWeeks.indexWhere((w) => w['type'] == 'week' && w['week_no'] == 36);
    if (week36Index != -1) {
      processedWeeks.insert(week36Index + 1, {
        'type': 'social_activity',
        'week_no': 37,
        'title': 'SOSYAL ETKİNLİK HAFTASI'
      });
    }
    return processedWeeks;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lessonName),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _weeksFuture == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: _weeksFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!.isEmpty) {
                  return Center(
                      child: Text(snapshot.hasError
                          ? 'Hata: ${snapshot.error}'
                          : 'Bu derse ait hafta bulunamadı.'));
                }
                final allWeeksData = snapshot.data!;
                int initialPageIndex = 0;
                if (widget.initialWeek != null) {
                  initialPageIndex = allWeeksData.indexWhere((w) =>
                      w['type'] == 'week' && w['week_no'] == widget.initialWeek);
                  if (initialPageIndex == -1) initialPageIndex = 0;
                } else {
                  int currentAcademicWeek = calculateCurrentAcademicWeek();
                  initialPageIndex = allWeeksData.indexWhere((w) =>
                      w['type'] == 'week' &&
                      w['week_no'] == currentAcademicWeek);
                  if (initialPageIndex == -1) initialPageIndex = 0;
                }
                if (_pageController == null) {
                  _pageController = PageController(initialPage: initialPageIndex);
                }
                return PageView.builder(
                  controller: _pageController,
                  itemCount: allWeeksData.length,
                  itemBuilder: (context, index) {
                    final weekData = allWeeksData[index];
                    if (weekData['type'] == 'social_activity') {
                      return _SocialActivityCard(title: weekData['title']);
                    }
                    if (weekData['type'] == 'break') {
                      return _BreakCard(
                          title: weekData['title'],
                          duration: weekData['duration']);
                    }
                    if (weekData['type'] == 'special_content') {
                      return _SpecialContentCard(
                          title: weekData['title'],
                          content: weekData['content'],
                          icon: weekData['icon']);
                    }
                    return WeekContentView(
                      lessonId: widget.lessonId,
                      gradeId: widget.gradeId,
                      weekNo: weekData['week_no'],
                    );
                  },
                );
              },
            ),
    );
  }
}

// ... Diğer kart widget'ları ...
class _SocialActivityCard extends StatelessWidget {
  final String title;
  const _SocialActivityCard({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.teal.shade400,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.celebration_outlined,
                  size: 80, color: Colors.white),
              const SizedBox(height: 24),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 16),
              const Text('Bu hafta için etkinlikler yakında eklenecek.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BreakCard extends StatelessWidget {
  final String title;
  final String duration;
  const _BreakCard({required this.title, required this.duration});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.blueGrey.shade400,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.beach_access_outlined,
                  size: 80, color: Colors.white),
              const SizedBox(height: 24),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 16),
              Text(duration,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpecialContentCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  const _SpecialContentCard(
      {required this.title, required this.content, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Theme.of(context).colorScheme.tertiaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(icon,
                  size: 60,
                  color: Theme.of(context).colorScheme.onTertiaryContainer),
              const SizedBox(height: 24),
              Text(title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color:
                          Theme.of(context).colorScheme.onTertiaryContainer)),
              const Divider(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  child: Html(data: content, style: {
                    "ul": Style(
                        padding: HtmlPaddings.zero,
                        listStyleType: ListStyleType.none),
                    "li": Style(
                        fontSize: FontSize.large,
                        color: Theme.of(context)
                            .colorScheme
                            .onTertiaryContainer,
                        padding: HtmlPaddings.symmetric(vertical: 4.0))
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WeekContentView extends StatefulWidget {
  final int lessonId;
  final int gradeId;
  final int weekNo;
  const WeekContentView(
      {super.key,
      required this.lessonId,
      required this.gradeId,
      required this.weekNo});
  @override
  State<WeekContentView> createState() => _WeekContentViewState();
}

class _WeekContentViewState extends State<WeekContentView> {
  late Future<Map<String, dynamic>> _contentFuture;
  Future<Map<String, dynamic>?>? _weeklyStatsFuture;
  List<Question>? _questions;
  final CacheService _cacheService = CacheService();
  int? _unitId;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  void _loadAllData() {
    _contentFuture = _fetchContentData();
    _loadQuestions();
    _contentFuture.then((data) {
      if (data.containsKey('unit_id')) {
        setState(() {
          _unitId = data['unit_id'];
          _weeklyStatsFuture = _loadWeeklyStats(); // İstatistikleri burada yükle
        });
      }
    });
  }

  void _refreshData() {
    setState(() {
      _questions = null;
      _weeklyStatsFuture = null;
      _loadAllData();
    });
  }

  Future<Map<String, dynamic>?> _loadWeeklyStats() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || _unitId == null) return Future.value(null);

    final params = {
      'p_user_id': userId,
      'p_unit_id': _unitId,
      'p_week_no': widget.weekNo,
    };

    debugPrint('[Stats] Fetching weekly stats with params: $params');

    return Supabase.instance.client
        .rpc('get_weekly_summary_stats', params: params)
        .then((response) {
      debugPrint('[Stats] Received data: $response');
      return response as Map<String, dynamic>?;
    }).catchError((error) {
      debugPrint('[Stats] Error fetching weekly stats: $error');
      return null;
    });
  }

  (DateTime, DateTime) _getWeekDateRange(int weekNo) {
    final schoolStart = DateTime(
        DateTime.now().month < 9 ? DateTime.now().year - 1 : DateTime.now().year,
        9,
        8);
    int offsetInWeeks = 0;
    for (final breakInfo in academicBreaks) {
      if (weekNo > breakInfo['after_week']) {
        offsetInWeeks += (breakInfo['weeks'] as List).length;
      }
    }
    final daysToAdd = ((weekNo - 1) + offsetInWeeks) * 7;
    final weekStartDate = schoolStart.add(Duration(days: daysToAdd));
    final weekEndDate = weekStartDate.add(const Duration(days: 6));
    return (weekStartDate, weekEndDate);
  }

  Future<Map<String, dynamic>> _fetchContentData() async {
    final cachedData = await _cacheService.getWeeklyCurriculumData(
      weekNo: widget.weekNo,
      lessonId: widget.lessonId,
      gradeId: widget.gradeId,
    );
    if (cachedData != null) {
      return cachedData;
    }
    return _fetchFullDataFromNetwork(cacheQuestions: false);
  }

  Future<void> _loadQuestions() async {
    try {
      final fullData = await _fetchFullDataFromNetwork(cacheQuestions: true);
      if (mounted) {
        final questionList = (fullData['mini_quiz_questions'] as List? ?? [])
            .map((q) => Question.fromMap(q as Map<String, dynamic>))
            .toList();
        setState(() {
          _questions = questionList;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _questions = [];
        });
      }
    }
  }

  Future<Map<String, dynamic>> _fetchFullDataFromNetwork(
      {required bool cacheQuestions}) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) throw Exception('Kullanıcı girişi gerekli.');
    await Supabase.instance.client.rpc('mark_week_as_started', params: {
      'p_user_id': userId,
      'p_lesson_id': widget.lessonId,
      'p_grade_id': widget.gradeId,
      'p_week_no': widget.weekNo
    }).catchError((_) {});
    final response = await Supabase.instance.client.rpc(
      'get_weekly_curriculum',
      params: {
        'p_user_id': userId,
        'p_grade_id': widget.gradeId,
        'p_lesson_id': widget.lessonId,
        'p_week_no': widget.weekNo
      },
    );
    if (response == null || (response as List).isEmpty) return {};
    final curriculumData = response as List;
    final firstItem = curriculumData.first;
    final dataToProcess = {
      'unit_title': firstItem['unit_title'],
      'topic_title': firstItem['topic_title'],
      'topic_id': firstItem['topic_id'],
      'unit_id': firstItem['unit_id'],
      'outcomes': curriculumData
          .map((item) => item['outcome_description'] as String)
          .toSet()
          .toList(),
      'contents': firstItem['contents'],
      'mini_quiz_questions': firstItem['mini_quiz_questions'],
      'is_last_week_of_unit': firstItem['is_last_week_of_unit'],
      'unit_summary': firstItem['unit_summary'],
    };
    final dataToCache = Map<String, dynamic>.from(dataToProcess);
    dataToCache.remove('mini_quiz_questions');
    await _cacheService.saveWeeklyCurriculumData(
      weekNo: widget.weekNo,
      lessonId: widget.lessonId,
      gradeId: widget.gradeId,
      data: dataToCache,
    );
    return dataToProcess;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _contentFuture,
      builder: (context, contentSnapshot) {
        if (contentSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (contentSnapshot.hasError) {
          return Center(child: Text('Hata: ${contentSnapshot.error}'));
        }
        if (!contentSnapshot.hasData || contentSnapshot.data!.isEmpty) {
          return Center(
              child: Text('${widget.weekNo}. hafta için içerik bulunamadı.'));
        }
        final data = contentSnapshot.data!;
        final (startDate, endDate) = _getWeekDateRange(widget.weekNo);
        final contents = (data['contents'] as List? ?? [])
            .map((c) => TopicContent.fromJson(c as Map<String, dynamic>))
            .toList();
        
        final isLastWeek = data['is_last_week_of_unit'] ?? false;
        final unitSummary = data['unit_summary'];

        return RefreshIndicator(
          onRefresh: () async => _refreshData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: FutureBuilder<Map<String, dynamic>?>(
              future: _weeklyStatsFuture,
              builder: (context, statsSnapshot) {
                final stats = statsSnapshot.data;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _WeekHeader(
                      weekNo: widget.weekNo,
                      startDate: startDate,
                      endDate: endDate,
                      unitTitle: data['unit_title'],
                      topicTitle: data['topic_title'],
                      stats: stats, // İstatistikleri Header'a gönder
                    ),
                    const SizedBox(height: 24),
                    if ((data['outcomes'] as List).isNotEmpty)
                      _CollapsibleSectionCard(
                        icon: Icons.flag_outlined,
                        title: 'Öğrenme Çıktıları ve Süreç Bileşenleri',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: (data['outcomes'] as List)
                              .map((outcome) =>
                                  _OutcomeTile(text: outcome as String))
                              .toList(),
                        ),
                      ),
                    ...contents.map((content) => _ContentCard(content: content)),
                    const SizedBox(height: 24),
                    
                    if (_questions != null && _questions!.isNotEmpty)
                      _MiniQuiz(key: ValueKey(widget.weekNo), questions: _questions!),
                    const SizedBox(height: 24),
                    if (_unitId != null)
                      _WeeklySummaryCard(
                        stats: stats, // İstatistikleri Summary Card'a gönder
                        unitId: _unitId!,
                        weekNo: widget.weekNo,
                        onRefresh: _refreshData,
                      ),
                    
                    if (isLastWeek && unitSummary != null) ...[
                      const Divider(height: 48, thickness: 1),
                      _UnitCompletionCard(
                        unitSummary: unitSummary,
                        unitId: data['unit_id'],
                      ),
                    ],

                    const SizedBox(height: 32),
                  ],
                );
              }
            ),
          ),
        );
      },
    );
  }
}

class _UnitCompletionCard extends StatelessWidget {
  final Map<String, dynamic> unitSummary;
  final int unitId;

  const _UnitCompletionCard({required this.unitSummary, required this.unitId});

  @override
  Widget build(BuildContext context) {
    final totalQuestions = unitSummary['total_questions'] ?? 0;
    final uniqueSolved = unitSummary['unique_solved_count'] ?? 0;
    final progress = totalQuestions > 0 ? uniqueSolved / totalQuestions : 0.0;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.deepPurple.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(Icons.military_tech_outlined, size: 40, color: Colors.deepPurple),
            const SizedBox(height: 12),
            Text(
              'Ünite Bitiş Çizgisi',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tebrikler! Bu ünitenin sonuna geldin. Genel bir tekrar yapmaya ne dersin?',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.deepPurple.shade700),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Ünite İlerlemen', style: Theme.of(context).textTheme.bodyMedium),
                Text('$uniqueSolved / $totalQuestions Soru', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            LinearPercentIndicator(
              percent: progress,
              lineHeight: 14,
              barRadius: const Radius.circular(7),
              backgroundColor: Colors.deepPurple.shade100,
              progressColor: Colors.deepPurple,
              center: Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UnitSummaryScreen(unitId: unitId),
                  ),
                );
              },
              icon: const Icon(Icons.quiz_outlined),
              label: const Text('Genel Ünite Testine Git'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _WeeklySummaryCard extends StatelessWidget {
  final Map<String, dynamic>? stats;
  final int unitId;
  final int weekNo;
  final VoidCallback onRefresh;

  const _WeeklySummaryCard({
    required this.stats,
    required this.unitId,
    required this.weekNo,
    required this.onRefresh,
  });

  Widget _buildCompletionCard(BuildContext context, double successRate) {
    final level = _SuccessLevel.fromRate(successRate);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: level.color.withOpacity(0.5)),
      ),
      color: level.color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(level.icon, size: 32, color: level.color),
            const SizedBox(height: 8),
            Text(
              level.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: level.color.shade800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              level.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: level.color.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (stats == null) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    
    final totalQuestions = stats?['total_questions'] ?? 0;
    final solvedUnique = stats?['solved_unique'] ?? 0;
    final correctCount = stats?['correct_count'] ?? 0;
    final wrongCount = stats?['wrong_count'] ?? 0;
    final activeSession = stats?['active_session'];
    final allQuestionsSolved = totalQuestions > 0 && solvedUnique >= totalQuestions;

    final double progress =
        totalQuestions > 0 ? solvedUnique / totalQuestions : 0.0;
    final double successRate = (correctCount + wrongCount) > 0
        ? correctCount / (correctCount + wrongCount)
        : 0.0;

    String buttonText;
    final IconData buttonIcon;
    final Color buttonColor;
    final VoidCallback onPressedAction;

    if (activeSession != null) {
      final answered = activeSession['answered_questions'] ?? 0;
      final total = activeSession['total_questions'] ?? 0;
      buttonText = 'Teste Devam Et ($answered/$total)';
      buttonIcon = Icons.play_arrow;
      buttonColor = Colors.green.shade600;
      onPressedAction = () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuestionsScreen(
              unitId: unitId,
              testMode: TestMode.weekly,
              sessionId: activeSession['id'],
            ),
          ),
        );
        onRefresh();
      };
    } else {
      buttonIcon = Icons.checklist_rtl_outlined;
      buttonColor = Theme.of(context).primaryColor;
      if (solvedUnique == 0) {
        buttonText = 'Haftalık Teste Başla';
      } else {
        buttonText = 'Kalan Soruları Çöz';
      }
      onPressedAction = () async {
        final prefs = await SharedPreferences.getInstance();
        final clientId = prefs.getString('client_id');
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (clientId == null || userId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Test başlatılamadı: Kullanıcı veya istemci bilgisi eksik.')),
          );
          return;
        }
        try {
          final sessionId = await Supabase.instance.client
              .rpc('start_weekly_test_session', params: {
            'p_user_id': userId,
            'p_unit_id': unitId,
            'p_week_no': weekNo,
            'p_client_id': clientId,
          });
          if (sessionId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'Bu hafta için çözülecek yeni soru bulunamadı.')),
            );
            return;
          }
          if (context.mounted) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QuestionsScreen(
                  unitId: unitId,
                  testMode: TestMode.weekly,
                  sessionId: sessionId,
                ),
              ),
            );
            onRefresh();
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Test başlatılamadı: $e')),
            );
          }
        }
      };
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Haftalık Pekiştirme Testi',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (totalQuestions > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('İlerleme',
                      style: Theme.of(context).textTheme.bodyMedium),
                  Text('$solvedUnique / $totalQuestions Soru',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              LinearPercentIndicator(
                percent: progress,
                lineHeight: 14,
                barRadius: const Radius.circular(7),
                backgroundColor: Colors.grey.shade300,
                progressColor: Colors.blue,
                center: Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatChip(
                    label: 'Başarı',
                    value: '${(successRate * 100).toStringAsFixed(0)}%',
                    color: Colors.green,
                  ),
                  _StatChip(
                    label: 'Doğru',
                    value: correctCount.toString(),
                    color: Colors.green,
                  ),
                  _StatChip(
                    label: 'Yanlış',
                    value: wrongCount.toString(),
                    color: Colors.red,
                  ),
                ],
              ),
            ] else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Text(
                  'Bu hafta için henüz pekiştirme sorusu eklenmemiş.',
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 20),
            if (totalQuestions > 0)
              if (allQuestionsSolved)
                _buildCompletionCard(context, successRate * 100)
              else
                ElevatedButton.icon(
                  onPressed: onPressedAction,
                  icon: Icon(buttonIcon),
                  label: Text(buttonText),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 18, color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _QuizLoadingIndicator extends StatelessWidget {
  const _QuizLoadingIndicator({super.key});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(top: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const Padding(
        padding: EdgeInsets.all(24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 3)),
            SizedBox(width: 16),
            Text('Mini Test Yükleniyor...',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _WeekHeader extends StatelessWidget {
  final int weekNo;
  final DateTime startDate;
  final DateTime endDate;
  final String? unitTitle;
  final String? topicTitle;
  final Map<String, dynamic>? stats;

  const _WeekHeader({
    required this.weekNo,
    required this.startDate,
    required this.endDate,
    this.unitTitle,
    this.topicTitle,
    this.stats,
  });

  Widget _buildStatusBadge(BuildContext context) {
    final solved = stats?['solved_unique'] ?? 0;
    final total = stats?['total_questions'] ?? 0;
    final successRate = stats != null && (stats!['correct_count'] + stats!['wrong_count']) > 0
        ? ((stats!['correct_count'] as int) / (stats!['correct_count'] + stats!['wrong_count'])) * 100
        : 0.0;

    if (total == 0) {
      return const SizedBox.shrink(); // Soru yoksa hiçbir şey gösterme
    }

    if (solved == 0) {
      return _StatusBadge(
        text: 'Başlanmadı',
        icon: Icons.lock_open_outlined,
        color: Colors.black.withOpacity(0.2),
        textColor: Colors.white70,
      );
    }

    final level = _SuccessLevel.fromRate(successRate);

    if (total > 0 && solved >= total) {
      return Column(
        children: [
          _StatusBadge(
            text: 'Tamamlandı!',
            icon: Icons.check_circle,
            color: Colors.green.withOpacity(0.9),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (index) {
              return Icon(
                index < level.starCount
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                color: Colors.amber,
                size: 20,
              );
            }),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(level.title,
              style: TextStyle(
                  color: level.color,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (index) {
              return Icon(
                index < level.starCount
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                color: Colors.amber,
                size: 18,
              );
            }),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 80,
            child: LinearPercentIndicator(
              percent: total > 0 ? solved / total : 0.0,
              lineHeight: 6,
              barRadius: const Radius.circular(3),
              backgroundColor: Colors.white.withOpacity(0.2),
              progressColor: level.color,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedStartDate = '${startDate.day} ${aylar[startDate.month - 1]}';
    final formattedEndDate =
        '${endDate.day} ${aylar[endDate.month - 1]} ${endDate.year}';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [Theme.of(context).primaryColor, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$weekNo. Hafta',
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('$formattedStartDate - $formattedEndDate',
                        style:
                            const TextStyle(fontSize: 16, color: Colors.white70)),
                  ],
                ),
              ),
              _buildStatusBadge(context),
            ],
          ),
          const Divider(color: Colors.white30, height: 24),
          _buildHierarchyRow(Icons.folder_open_outlined, unitTitle),
          _buildHierarchyRow(Icons.article_outlined, topicTitle),
        ],
      ),
    );
  }

  Widget _buildHierarchyRow(IconData icon, String? text) {
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: const TextStyle(color: Colors.white, fontSize: 16))),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final Color textColor;

  const _StatusBadge({
    required this.text,
    required this.icon,
    required this.color,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 16),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ],
      ),
    );
  }
}


class _CollapsibleSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const _CollapsibleSectionCard(
      {required this.icon, required this.title, required this.child});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(top: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: child,
          )
        ],
      ),
    );
  }
}

class _OutcomeTile extends StatelessWidget {
  final String text;
  const _OutcomeTile({required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline,
              color: Colors.green, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  final TopicContent content;
  const _ContentCard({required this.content});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(top: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.article_outlined,
                    color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(content.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold))),
              ],
            ),
            const Divider(height: 24),
            Html(
                data: content.content,
                extensions: const [TableHtmlExtension()],
                style: getBaseHtmlStyle(context)),
          ],
        ),
      ),
    );
  }
}

enum _MiniQuizState { notStarted, inProgress, finished }

class _MiniQuiz extends StatefulWidget {
  final List<Question> questions;
  const _MiniQuiz({super.key, required this.questions});
  @override
  State<_MiniQuiz> createState() => __MiniQuizState();
}

class __MiniQuizState extends State<_MiniQuiz> {
  final PageController _pageController = PageController();
  Map<int, int?> _selectedChoiceIds = {};
  Map<int, bool?> _results = {};
  int _currentPage = 0;
  _MiniQuizState _quizState = _MiniQuizState.notStarted;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      if (_pageController.page?.round() != _currentPage) {
        setState(() {
          _currentPage = _pageController.page!.round();
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _checkAnswer(Question question, int choiceId) {
    final correctChoice =
        question.choices.firstWhereOrNull((c) => c.isCorrect);
    setState(() {
      _selectedChoiceIds[question.id] = choiceId;
      _results[question.id] = (correctChoice?.id == choiceId);
      if (_results.length == widget.questions.length) {
        _quizState = _MiniQuizState.finished;
      }
    });
  }

  void _startQuiz() {
    setState(() {
      _quizState = _MiniQuizState.inProgress;
    });
  }

  void _resetQuiz() {
    setState(() {
      _selectedChoiceIds = {};
      _results = {};
      _currentPage = 0;
      _quizState = _MiniQuizState.notStarted;
      _pageController.jumpToPage(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(top: 16),
      shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.orange.shade200, width: 1),
          borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: Colors.orange.withOpacity(0.1),
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.orange.shade800),
                const SizedBox(width: 12),
                Text('Anladım mı? Kendini Sına!',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildCurrentStateWidget(),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStateWidget() {
    switch (_quizState) {
      case _MiniQuizState.notStarted:
        return _QuizStartCard(
          key: const ValueKey('start'),
          onStart: _startQuiz,
        );
      case _MiniQuizState.inProgress:
        return _QuizContent(
          key: const ValueKey('content'),
          pageController: _pageController,
          questions: widget.questions,
          results: _results,
          selectedChoiceIds: _selectedChoiceIds,
          currentPage: _currentPage,
          onAnswer: _checkAnswer,
        );
      case _MiniQuizState.finished:
        return _QuizResults(
          key: const ValueKey('results'),
          results: _results,
          totalQuestions: widget.questions.length,
          onRetry: _resetQuiz,
        );
    }
  }
}

class _QuizStartCard extends StatelessWidget {
  final VoidCallback onStart;
  const _QuizStartCard({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 350,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.quiz_outlined,
                size: 60, color: Colors.orange.shade700),
            const SizedBox(height: 16),
            Text(
              'Konuyu Pekiştir',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Bu haftanın konusunu ne kadar anladığını görmek için birkaç soruluk bu mini testi çözebilirsin.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('5 Soruluk Mini Quizi Çöz'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizContent extends StatelessWidget {
  final PageController pageController;
  final List<Question> questions;
  final Map<int, bool?> results;
  final Map<int, int?> selectedChoiceIds;
  final int currentPage;
  final Function(Question, int) onAnswer;
  const _QuizContent({
    super.key,
    required this.pageController,
    required this.questions,
    required this.results,
    required this.selectedChoiceIds,
    required this.currentPage,
    required this.onAnswer,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 350,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: pageController,
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final question = questions[index];
                final isChecked = results.containsKey(question.id);
                final selectedChoiceId = selectedChoiceIds[question.id];
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(question.text,
                          style: const TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 16)),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          itemCount: question.choices.length,
                          itemBuilder: (context, choiceIndex) {
                            final choice = question.choices[choiceIndex];
                            bool isSelected = (selectedChoiceId == choice.id);
                            Color? tileColor;
                            Icon? trailingIcon;
                            if (isChecked) {
                              if (choice.isCorrect) {
                                tileColor = Colors.green.withOpacity(0.15);
                                trailingIcon = const Icon(Icons.check_circle,
                                    color: Colors.green);
                              } else if (isSelected) {
                                tileColor = Colors.red.withOpacity(0.15);
                                trailingIcon = const Icon(Icons.cancel,
                                    color: Colors.red);
                              }
                            }
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                  color: tileColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: isSelected
                                          ? Theme.of(context).primaryColor
                                          : Colors.grey.shade300)),
                              child: ListTile(
                                dense: true,
                                title: Text(choice.text),
                                trailing: trailingIcon,
                                onTap: isChecked
                                    ? null
                                    : () => onAnswer(question, choice.id),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: DotsIndicator(
              dotsCount: questions.length,
              position: currentPage,
              decorator: DotsDecorator(
                activeColor: Theme.of(context).primaryColor,
                color: Colors.grey.shade300,
                size: const Size.square(9.0),
                activeSize: const Size(18.0, 9.0),
                activeShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizResults extends StatelessWidget {
  final Map<int, bool?> results;
  final int totalQuestions;
  final VoidCallback onRetry;
  const _QuizResults({
    super.key,
    required this.results,
    required this.totalQuestions,
    required this.onRetry,
  });
  @override
  Widget build(BuildContext context) {
    final correctAnswers = results.values.where((r) => r == true).length;
    final successRate =
        totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0.0;
    String message;
    IconData icon;
    Color color;
    if (successRate == 100) {
      message = 'Harika! Tamamı doğru.';
      icon = Icons.celebration;
      color = Colors.green;
    } else if (successRate >= 60) {
      message = 'Çok iyi! Konuyu anlamışsın.';
      icon = Icons.thumb_up_alt;
      color = Colors.blue;
    } else {
      message = 'Tekrar denemekte fayda var.';
      icon = Icons.sync_problem;
      color = Colors.orange;
    }
    return SizedBox(
      height: 350,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(icon, size: 60, color: color),
            const SizedBox(height: 16),
            Text(
              '$totalQuestions sorudan $correctAnswers tanesini doğru cevapladın.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.grey.shade600),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
                side: BorderSide(color: Theme.of(context).primaryColor),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
