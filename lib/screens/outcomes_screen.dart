import 'package:egitim_uygulamasi/screens/questions_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_table/flutter_html_table.dart';
import 'package:egitim_uygulamasi/models/topic_content.dart';
import 'package:egitim_uygulamasi/utils/html_style.dart';
import 'dart:math';

// Test özetlerini tutacak model
class TestSummary {
  final int testNumber;
  final int lastSessionId;
  final int correctCount;
  final int incorrectCount;

  TestSummary({
    required this.testNumber,
    required this.lastSessionId,
    required this.correctCount,
    required this.incorrectCount,
  });

  factory TestSummary.fromJson(Map<String, dynamic> json) {
    return TestSummary(
      testNumber: json['test_number'] as int,
      lastSessionId: json['last_session_id'] as int,
      correctCount: json['correct_count'] as int,
      incorrectCount: json['incorrect_count'] as int,
    );
  }
}

const List<String> aylar = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];

final List<Map<String, dynamic>> _academicBreaks = [
  {'after_week': 9, 'weeks': [{'type': 'break', 'title': 'Ara Tatil', 'duration': '1. DÖNEM ARA TATİLİ: 10 - 14 Kasım'}]},
  {'after_week': 18, 'weeks': [{'type': 'break', 'title': 'Yarıyıl Tatili', 'duration': '1. Hafta (19 Ocak - 25 Ocak)'}, {'type': 'break', 'title': 'Yarıyıl Tatili', 'duration': '2. Hafta (26 Ocak - 2 Şubat)'}]},
  {'after_week': 26, 'weeks': [{'type': 'break', 'title': 'Ara Tatil', 'duration': '2. DÖNEM ARA TATİLİ'}]},
];

final List<Map<String, dynamic>> _specialWeeks = [
  {
    'grade_id': 5, 'lesson_id': 3, 'week_no': 1, 'type': 'special_content', 'title': 'FEN LABORATUVARI KURALLARI', 'icon': Icons.science, 'content': "<ul><li>...</li></ul>",
  },
];

class OutcomesScreen extends StatefulWidget {
  final int lessonId;
  final int gradeId;
  final String gradeName;
  final String lessonName;

  const OutcomesScreen({
    super.key,
    required this.lessonId,
    required this.gradeId,
    required this.gradeName,
    required this.lessonName,
  });

  @override
  State<OutcomesScreen> createState() => _OutcomesScreenState();
}

class _OutcomesScreenState extends State<OutcomesScreen> {
  PageController? _pageController;
  late final Future<List<Map<String, dynamic>>> _weeksFuture;

  @override
  void initState() {
    super.initState();
    _weeksFuture = _fetchAndProcessWeeks();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchAndProcessWeeks() async {
    try {
      final List<dynamic> dbResult = await Supabase.instance.client.rpc(
        'get_available_weeks',
        params: {'p_grade_id': widget.gradeId, 'p_lesson_id': widget.lessonId},
      );
      
      Map<int, Map<String, dynamic>> weeksMap = {};

      for (final specialWeek in _specialWeeks) {
        if (specialWeek['grade_id'] == widget.gradeId && specialWeek['lesson_id'] == widget.lessonId) {
          weeksMap[specialWeek['week_no']] = specialWeek;
        }
      }

      for (var item in dbResult) {
        final weekNo = item['week_no'] as int;
        if (!weeksMap.containsKey(weekNo)) {
          weeksMap[weekNo] = {'type': 'week', 'week_no': weekNo};
        }
      }

      List<Map<String, dynamic>> processedWeeks = weeksMap.values.toList();
      processedWeeks.sort((a, b) => (a['week_no'] as int).compareTo(b['week_no'] as int));

      for (final breakInfo in _academicBreaks.reversed) {
        int breakIndex = processedWeeks.indexWhere((week) => week['type'] == 'week' && week['week_no'] == breakInfo['after_week']);
        if (breakIndex != -1) {
          final breaks = (breakInfo['weeks'] as List).map((b) => Map<String, dynamic>.from(b)).toList();
          processedWeeks.insertAll(breakIndex + 1, breaks);
        }
      }

      int week36Index = processedWeeks.indexWhere((w) => w['type'] == 'week' && w['week_no'] == 36);
      if (week36Index != -1) {
        processedWeeks.insert(week36Index + 1, {'type': 'social_activity', 'week_no': 37, 'title': 'SOSYAL ETKİNLİK HAFTASI'});
      }

      return processedWeeks;
    } catch (e) {
      debugPrint("Haftalar çekilirken hata: $e");
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lessonName),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _weeksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text(snapshot.hasError ? 'Hata: ${snapshot.error}' : 'Bu derse ait hafta bulunamadı.'));
          }

          final allWeeksData = snapshot.data!;
          final now = DateTime.now();
          final schoolStart = DateTime(now.month < 9 ? now.year - 1 : now.year, 9, 8);
          int currentWeekNumber = (now.difference(schoolStart).inDays / 7).floor() + 1;
          int initialPageIndex = allWeeksData.indexWhere((w) => w['type'] == 'week' && w['week_no'] == currentWeekNumber);
          if (initialPageIndex == -1) initialPageIndex = 0;

          _pageController ??= PageController(initialPage: initialPageIndex);

          return PageView.builder(
            controller: _pageController,
            itemCount: allWeeksData.length,
            itemBuilder: (context, index) {
              final weekData = allWeeksData[index];

              if (weekData['type'] == 'social_activity') {
                return _SocialActivityCard(title: weekData['title']);
              }
              if (weekData['type'] == 'break') {
                return _BreakCard(title: weekData['title'], duration: weekData['duration']);
              }
              if (weekData['type'] == 'special_content') {
                return _SpecialContentCard(title: weekData['title'], content: weekData['content'], icon: weekData['icon']);
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
              const Icon(Icons.celebration_outlined, size: 80, color: Colors.white),
              const SizedBox(height: 24),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              const Text('Bu hafta için etkinlikler yakında eklenecek.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.white70)),
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
              const Icon(Icons.beach_access_outlined, size: 80, color: Colors.white),
              const SizedBox(height: 24),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              Text(duration, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.white70)),
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

  const _SpecialContentCard({required this.title, required this.content, required this.icon});

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
              Icon(icon, size: 60, color: Theme.of(context).colorScheme.onTertiaryContainer),
              const SizedBox(height: 24),
              Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onTertiaryContainer)),
              const Divider(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  child: Html(data: content, style: {"ul": Style(padding: HtmlPaddings.zero, listStyleType: ListStyleType.none), "li": Style(fontSize: FontSize.large, color: Theme.of(context).colorScheme.onTertiaryContainer, padding: HtmlPaddings.symmetric(vertical: 4.0))}),
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

  const WeekContentView({super.key, required this.lessonId, required this.gradeId, required this.weekNo});

  @override
  State<WeekContentView> createState() => _WeekContentViewState();
}

class _WeekContentViewState extends State<WeekContentView> {
  late Future<Map<String, dynamic>> _weekDataFuture;

  @override
  void initState() {
    super.initState();
    _weekDataFuture = _fetchWeekData();
  }

  (DateTime, DateTime) _getWeekDateRange(int weekNo) {
    final schoolStart = DateTime(DateTime.now().month < 9 ? DateTime.now().year - 1 : DateTime.now().year, 9, 8);
    
    int offsetInWeeks = 0;
    for (final breakInfo in _academicBreaks) {
      if (weekNo > breakInfo['after_week']) {
        offsetInWeeks += (breakInfo['weeks'] as List).length;
      }
    }

    final daysToAdd = ((weekNo - 1) + offsetInWeeks) * 7;
    final weekStartDate = schoolStart.add(Duration(days: daysToAdd));
    final weekEndDate = weekStartDate.add(const Duration(days: 6));
    return (weekStartDate, weekEndDate);
  }

  Future<Map<String, dynamic>> _fetchWeekData() async {
    try {
      final response = await Supabase.instance.client.rpc(
        'get_weekly_curriculum',
        params: {'p_grade_id': widget.gradeId, 'p_lesson_id': widget.lessonId, 'p_week_no': widget.weekNo},
      );
      if (response == null || (response as List).isEmpty) return {};

      final curriculumData = response as List;
      final firstItem = curriculumData.first;
      final topicId = firstItem['topic_id'];

      final outcomes = curriculumData.map((item) => item['outcome_description'] as String).toSet().toList();
      final contents = curriculumData.expand((item) => (item['contents'] as List)).map((c) => TopicContent.fromJson(c)).toSet().toList();
      
      int questionCount = 0;
      List<TestSummary> testSummaries = [];

      if (topicId != null) {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        
        final results = await Future.wait([
          Supabase.instance.client.rpc(
            'get_weekly_question_count',
            params: {'p_topic_id': topicId, 'p_week_no': widget.weekNo},
          ),
          if (userId != null)
            Supabase.instance.client.rpc(
              'get_test_summaries_for_topic',
              params: {'p_topic_id': topicId, 'p_user_id': userId},
            )
        ]);

        questionCount = results[0] as int;
        
        if (results.length > 1 && results[1] != null) {
          final summaryData = results[1] as List<dynamic>;
          testSummaries = summaryData.map((json) => TestSummary.fromJson(json)).toList();
        }
      }

      return {
        'unit_title': firstItem['unit_title'],
        'topic_title': firstItem['topic_title'],
        'topic_id': topicId,
        'outcomes': outcomes,
        'contents': contents,
        'question_count': questionCount,
        'test_summaries': testSummaries,
      };
    } catch (e, st) {
      debugPrint("Haftalık veri çekilirken hata: $e\n$st");
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _weekDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('${widget.weekNo}. hafta için içerik bulunamadı.'));
        }

        final data = snapshot.data!;
        final unitTitle = data['unit_title'] as String?;
        final topicTitle = data['topic_title'] as String?;
        final topicId = data['topic_id'] as int?;
        final outcomes = (data['outcomes'] as List<dynamic>?)?.cast<String>() ?? [];
        final contents = (data['contents'] as List<dynamic>?)?.cast<TopicContent>() ?? [];
        final questionCount = data['question_count'] as int? ?? 0;
        final testSummaries = (data['test_summaries'] as List<dynamic>?)?.cast<TestSummary>() ?? [];
        final (startDate, endDate) = _getWeekDateRange(widget.weekNo);

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _weekDataFuture = _fetchWeekData();
            });
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _WeekHeader(
                  weekNo: widget.weekNo,
                  startDate: startDate,
                  endDate: endDate,
                  unitTitle: unitTitle,
                  topicTitle: topicTitle,
                ),
                const SizedBox(height: 24),
                _CollapsibleSectionCard(
                  icon: Icons.flag_outlined,
                  title: 'Öğrenme Çıktıları ve Süreç Bileşenleri',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: outcomes.map((outcome) => _OutcomeTile(text: outcome)).toList(),
                  ),
                ),
                ...contents.map((content) => _ContentCard(content: content)),
                if (questionCount > 0 && topicId != null) ...[
                  const SizedBox(height: 16),
                  _QuizCard(
                    topicId: topicId,
                    questionCount: questionCount,
                    weekNo: widget.weekNo,
                    summaries: testSummaries,
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WeekHeader extends StatelessWidget {
  final int weekNo;
  final DateTime startDate;
  final DateTime endDate;
  final String? unitTitle;
  final String? topicTitle;

  const _WeekHeader({required this.weekNo, required this.startDate, required this.endDate, this.unitTitle, this.topicTitle});

  Widget _buildHierarchyRow(IconData icon, String? text) {
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedStartDate = '${startDate.day} ${aylar[startDate.month - 1]}';
    final formattedEndDate = '${endDate.day} ${aylar[endDate.month - 1]} ${endDate.year}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [Theme.of(context).primaryColor, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$weekNo. Hafta', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text('$formattedStartDate - $formattedEndDate', style: const TextStyle(fontSize: 16, color: Colors.white70)),
          const Divider(color: Colors.white30, height: 24),
          _buildHierarchyRow(Icons.folder_open_outlined, unitTitle),
          _buildHierarchyRow(Icons.article_outlined, topicTitle),
        ],
      ),
    );
  }
}

class _CollapsibleSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _CollapsibleSectionCard({required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(top: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
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
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
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
                Icon(Icons.article_outlined, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Expanded(child: Text(content.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
              ],
            ),
            const Divider(height: 24),
            Html(data: content.content, extensions: const [TableHtmlExtension()], style: getBaseHtmlStyle(context)),
          ],
        ),
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  final int topicId;
  final int questionCount;
  final int weekNo;
  final List<TestSummary> summaries;
  final int questionsPerTest = 10;

  const _QuizCard({
    required this.topicId,
    required this.questionCount,
    required this.weekNo,
    required this.summaries,
  });

  @override
  Widget build(BuildContext context) {
    final totalTests = (questionCount / questionsPerTest).ceil();
    final summaryMap = {for (var s in summaries) s.testNumber: s};

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
                Icon(Icons.quiz_outlined, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text('Haftalık Testler', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.5,
              ),
              itemCount: totalTests,
              itemBuilder: (context, index) {
                final testNumber = index + 1;
                final summary = summaryMap[testNumber];

                return _TestButton(
                  topicId: topicId,
                  testNumber: testNumber,
                  questionsPerTest: questionsPerTest,
                  weekNo: weekNo,
                  summary: summary,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TestButton extends StatelessWidget {
  final int topicId;
  final int testNumber;
  final int questionsPerTest;
  final int weekNo;
  final TestSummary? summary;

  const _TestButton({
    required this.topicId,
    required this.testNumber,
    required this.questionsPerTest,
    required this.weekNo,
    this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final localSummary = summary;
    final bool isReviewMode = localSummary != null;

    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuestionsScreen(
              topicId: topicId,
              testNumber: testNumber,
              questionsPerTest: questionsPerTest,
              weekNo: weekNo,
              previousSessionId: localSummary?.lastSessionId,
            ),
          ),
        ).then((_) {
          (context as Element).markNeedsBuild();
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.withOpacity(0.1),
        foregroundColor: Colors.blue.shade800,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Test $testNumber',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (localSummary != null) ...[
            const SizedBox(height: 4),
            Text(
              '${localSummary.correctCount}D / ${localSummary.incorrectCount}Y',
              style: TextStyle(
                fontSize: 12,
                color: localSummary.correctCount >= localSummary.incorrectCount ? Colors.green : Colors.red,
              ),
            )
          ]
        ],
      ),
    );
  }
}
