import 'package:egitim_uygulamasi/screens/questions_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_table/flutter_html_table.dart';
import 'package:egitim_uygulamasi/models/topic_content.dart';
import 'package:egitim_uygulamasi/services/unit_service.dart';
import 'package:egitim_uygulamasi/services/topic_service.dart';
import 'package:egitim_uygulamasi/services/outcome_service.dart';
import 'package:egitim_uygulamasi/models/topic_model.dart';
import 'package:egitim_uygulamasi/models/unit_model.dart';
import 'package:egitim_uygulamasi/models/outcome_model.dart';
import 'package:egitim_uygulamasi/widgets/topic_section_renderer.dart';
import 'package:egitim_uygulamasi/widgets/common/content_renderer.dart';
import 'package:egitim_uygulamasi/utils/html_style.dart';

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

  final List<Map<String, dynamic>> _academicBreaks = [

    {
      'after_week': 9,
      'weeks': [
        {
          'type': 'break',
          'title': 'Ara Tatil',
          'duration': '1.  DÖNEM ARA TATİLİ: 10 Kasım - 14 Kasım 2024',
          'description': 'Dinlenmek ve konuları tekrar etmek için harika bir fırsat!',
        },
      ],
    },
    {
      'after_week': 18,
      'weeks': [
        {
          'type': 'break',
          'title': 'Yarıyıl Tatili',
          'duration': '1. Hafta',
          'description': 'Dinlenmek ve konuları tekrar etmek için harika bir fırsat!',
        },
        {
          'type': 'break',
          'title': 'Yarıyıl Tatili',
          'duration': '2. Hafta',
          'description': 'Tatilin tadını çıkarın! Yeni döneme enerjik bir başlangıç yapın.',
        },
      ],
    },
    {
      'after_week': 26,
      'weeks': [
        {
          'type': 'break',
          'title': 'Ara Tatil',
          'duration': '2. DÖNEM ARA TATİLİ: 30 Mart - 3 Nisan 2025',
          'description': 'Dinlenmek ve konuları tekrar etmek için harika bir fırsat!',
        },
      ],
    },
  ];

  final Map<int, Map<String, dynamic>> _weekNotes = {
    8: {'note': 'Sınav Haftası', 'icon': Icons.edit_note},
    16: {'note': 'Sınav Haftası', 'icon': Icons.edit_note},
    //17: {'note': 'Proje Teslim Haftası', 'icon': Icons.assignment},
  };

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
      final List<dynamic> result = await Supabase.instance.client.rpc(
        'get_available_weeks',
        params: {'p_grade_id': widget.gradeId, 'p_lesson_id': widget.lessonId},
      );
      
      List<Map<String, dynamic>> processedWeeks = result.map((item) {
        final weekNo = item['week_no'];
        final weekData = {'type': 'week', 'week_no': weekNo};
        if (_weekNotes.containsKey(weekNo)) {
          weekData.addAll(_weekNotes[weekNo]!);
        }
        return weekData;
      }).toList();

      for (final breakInfo in _academicBreaks) {
        int breakIndex = processedWeeks.indexWhere((week) => week['type'] == 'week' && week['week_no'] == breakInfo['after_week']);
        if (breakIndex != -1) {
          processedWeeks.insertAll(breakIndex + 1, breakInfo['weeks']);
        }
      }

      return processedWeeks;
    } catch (e) {
      debugPrint("Haftalar çekilirken ve işlenirken hata: $e");
      rethrow;
    }
  }

  (DateTime, DateTime) _getWeekDateRange(int weekNo) {
    final schoolStart = _getCurrentAcademicYearStartDate();
    
    int weekOffset = 0;
    for (final breakInfo in _academicBreaks) {
      if (weekNo > breakInfo['after_week']) {
        weekOffset += (breakInfo['weeks'] as List).length;
      }
    }

    final adjustedWeekNo = weekNo + weekOffset;
    final daysToAdd = (adjustedWeekNo - 1) * 7;
    final weekStartDate = schoolStart.add(Duration(days: daysToAdd));
    final weekEndDate = weekStartDate.add(const Duration(days: 6));

    return (weekStartDate, weekEndDate);
  }

  DateTime _getCurrentAcademicYearStartDate() {
    final now = DateTime.now();
    final year = now.month < 9 ? now.year - 1 : now.year;
    return DateTime(year, 9, 8);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.lessonName)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _weeksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                snapshot.hasError ? 'Hata: ${snapshot.error}' : 'Bu derse ait hafta bulunamadı.',
              ),
            );
          }

          final allWeeksData = snapshot.data!;

          final schoolStart = _getCurrentAcademicYearStartDate();
          final now = DateTime.now();
          final totalDays = now.difference(schoolStart).inDays;
          
          int currentWeekNumber = (totalDays / 7).floor() + 1;
          int breakWeeksPassed = 0;
          for (final breakInfo in _academicBreaks) {
            final breakStartDay = (breakInfo['after_week']) * 7;
            if (totalDays > breakStartDay) {
               breakWeeksPassed += (breakInfo['weeks'] as List).length;
            }
          }
          currentWeekNumber -= breakWeeksPassed;

          int initialPageIndex = allWeeksData.indexWhere((week) => week['type'] == 'week' && week['week_no'] == currentWeekNumber);

          if (_pageController == null) {
             if (initialPageIndex == -1) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$currentWeekNumber. hafta için içerik bulunamadı. İlk hafta gösteriliyor.'),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              });
              initialPageIndex = 0;
            }
            _pageController = PageController(initialPage: initialPageIndex);
          }

          return Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: allWeeksData.length,
                  itemBuilder: (context, index) {
                    final weekData = allWeeksData[index];

                    if (weekData['type'] == 'break') {
                      return _BreakCard(
                        title: weekData['title'],
                        duration: weekData['duration'],
                        description: weekData['description'],
                      );
                    }

                    final weekNo = weekData['week_no'];
                    final (startDate, endDate) = _getWeekDateRange(weekNo);
                    final formattedStartDate = '${startDate.day} ${aylar[startDate.month - 1]}';
                    final formattedEndDate = '${endDate.day} ${aylar[endDate.month - 1]} ${endDate.year}';

                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      children: [
                        _WeekHeaderCard(
                          weekNo: weekNo,
                          startDate: formattedStartDate,
                          endDate: formattedEndDate,
                          note: weekData['note'],
                          noteIcon: weekData['icon'],
                        ),
                        const SizedBox(height: 8),
                        WeekOutcomesView(
                          lessonId: widget.lessonId,
                          gradeId: widget.gradeId,
                          lessonName: widget.lessonName,
                          gradeName: widget.gradeName,
                          weekNo: weekNo,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BreakCard extends StatelessWidget {
  final String title;
  final String duration;
  final String description;

  const _BreakCard({
    required this.title,
    required this.duration,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.beach_access,
                size: 60,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                duration,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSecondaryContainer.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekHeaderCard extends StatelessWidget {
  const _WeekHeaderCard({
    required this.weekNo,
    required this.startDate,
    required this.endDate,
    this.note,
    this.noteIcon,
  });

  final int weekNo;
  final String startDate;
  final String endDate;
  final String? note;
  final IconData? noteIcon;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          children: [
            Text(
              '$weekNo. Hafta',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '$startDate - $endDate',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (note != null) ...[
              const SizedBox(height: 8),
              Chip(
                avatar: noteIcon != null ? Icon(noteIcon, size: 16) : null,
                label: Text(note!),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

const List<String> aylar = [
  'Ocak',
  'Şubat',
  'Mart',
  'Nisan',
  'Mayıs',
  'Haziran',
  'Temmuz',
  'Ağustos',
  'Eylül',
  'Ekim',
  'Kasım',
  'Aralık',
];

class WeekOutcomesView extends StatefulWidget {
  final int lessonId;
  final int gradeId;
  final String lessonName;
  final String gradeName;
  final int weekNo;

  const WeekOutcomesView({
    super.key,
    required this.lessonId,
    required this.gradeId,
    required this.lessonName,
    required this.gradeName,
    required this.weekNo,
  });

  @override
  State<WeekOutcomesView> createState() => _WeekOutcomesViewState();
}

class _WeekOutcomesViewState extends State<WeekOutcomesView> {
  late final Future<Map<String, dynamic>> _weekDataFuture;

  @override
  void initState() {
    super.initState();
    _weekDataFuture = _fetchWeekData();
  }

  Future<Map<String, dynamic>> _fetchWeekData() async {
    try {
      final response = await Supabase.instance.client.rpc(
        'get_weekly_curriculum',
        params: {
          'p_grade_id': widget.gradeId,
          'p_lesson_id': widget.lessonId,
          'p_week_no': widget.weekNo,
        },
      );

      if (response == null || (response as List).isEmpty) {
        return {'outcomes': [], 'contents': [], 'videos': [], 'questions': []};
      }

      final curriculumData = response as List;
      final topicId = curriculumData.first['topic_id'];

      final outcomesData = curriculumData
          .map((item) => {
                'description': item['outcome_description'],
                'unit_title': item['unit_title'],
                'topic_title': item['topic_title'],
                'topic_id': item['topic_id'],
              })
          .toList();

      final uniqueContents = curriculumData
          .expand((item) => (item['contents'] as List))
          .map((content) => TopicContent.fromJson(content as Map<String, dynamic>))
          .toSet()
          .toList();

      List<Map<String, dynamic>> videos = [];
      if (topicId != null) {
        final unitId = curriculumData.first['unit_id'];
        final videosResponse = await Supabase.instance.client
            .from('unit_videos')
            .select('id, unit_id, title, video_url, order_no')
            .eq('unit_id', unitId)
            .order('order_no', ascending: true);
        videos = List<Map<String, dynamic>>.from(videosResponse);
      }

      List<Map<String, dynamic>> questions = [];
      if (topicId != null) {
        final questionsResponse = await Supabase.instance.client
            .from('question_usages')
            .select(
              '*, questions(*, question_choices(*), question_blank_options!question_blank_options_question_id_fkey(*), question_classical(*))',
            )
            .eq('topic_id', topicId)
            .eq('usage_type', 'weekly')
            .eq('display_week', widget.weekNo);

        if (questionsResponse is List) {
          questions = questionsResponse
              .map((e) => e['questions'] as Map<String, dynamic>?)
              .where((q) => q != null)
              .cast<Map<String, dynamic>>()
              .toList();
        }
      }

      return {
        'outcomes': outcomesData,
        'contents': uniqueContents,
        'videos': videos,
        'questions': questions,
      };
    } catch (e, st) {
      debugPrint("Hafta verileri çekilirken hata: $e");
      debugPrint("Stack trace: $st");
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _weekDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Kazanımlar yüklenemedi: ${snapshot.error}'),
          );
        }

        final data = snapshot.data ?? {};
        final outcomes =
            (data['outcomes'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>() ??
            [];
        final contents =
            (data['contents'] as List<dynamic>?)?.cast<TopicContent>() ?? [];
        final videos =
            (data['videos'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
            [];
        final questions =
            (data['questions'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>() ??
            [];

        if (outcomes.isEmpty) {
          return Center(
            child: Text('${widget.weekNo}. hafta için içerik bulunamadı.'),
          );
        }

        return _CombinedWeekContentCard(
          outcomes: outcomes,
          contents: contents,
          videos: videos,
          questions: questions,
          lessonName: widget.lessonName,
          weekNo: widget.weekNo,
        );
      },
    );
  }
}

class _CombinedWeekContentCard extends StatelessWidget {
  final List<Map<String, dynamic>> outcomes;
  final List<TopicContent> contents;
  final List<Map<String, dynamic>> videos;
  final List<Map<String, dynamic>> questions;
  final String lessonName;
  final int weekNo;

  const _CombinedWeekContentCard({
    required this.outcomes,
    required this.contents,
    required this.videos,
    required this.questions,
    required this.lessonName,
    required this.weekNo,
  });

  @override
  Widget build(BuildContext context) {
    final firstOutcome = outcomes.first;
    final unitTitle = firstOutcome['unit_title'] as String?;
    final topicTitle = firstOutcome['topic_title'] as String?;
    final topicId = firstOutcome['topic_id'] as int?;
    final theme = Theme.of(context);

    final easyQuestions = questions.where((q) => (q['difficulty'] ?? 1) == 1).toList();
    final mediumQuestions = questions.where((q) => (q['difficulty'] ?? 1) == 2).toList();
    final hardQuestions = questions.where((q) => (q['difficulty'] ?? 1) == 3).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 24.0),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoSection(
              icon: Icons.account_tree_outlined,
              title: 'DERS HİYERARŞİSİ',
              child: _HierarchyView(
                lesson: lessonName,
                unit: unitTitle,
                topic: topicTitle,
              ),
            ),
            const Divider(height: 32),

            Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: _InfoSection(
                  icon: Icons.flag_circle_outlined,
                  title: 'KAZANIMLAR',
                ),
                initiallyExpanded: false,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16.0,
                      right: 16.0,
                      bottom: 8.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: outcomes.asMap().entries.map((entry) {
                        final index = entry.key;
                        final outcome = entry.value;
                        final description = outcome['description'] as String?;
                        final letter = String.fromCharCode(
                          'a'.codeUnitAt(0) + index,
                        );

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Html(
                            data: '$letter) ${description ?? ''}',
                            style: getBaseHtmlStyle(context),
                            extensions: const [TableHtmlExtension()],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            if (contents.isNotEmpty) ...[
              const Divider(height: 32),
              _TopicContentView(contents: contents),
            ],

            if (videos.isNotEmpty) ...[
              const Divider(height: 32),
              _InfoSection(
                icon: Icons.video_collection_outlined,
                title: 'VİDEOLAR',
                child: Column(
                  children: videos.map((video) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.play_circle_outline),
                        label: Text(
                          video['title'] as String? ?? 'Konu Anlatım Videosu',
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 44),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            if (questions.isNotEmpty && topicId != null) ...[
              const Divider(height: 32),
              _InfoSection(
                icon: Icons.quiz_outlined,
                title: 'HAFTALIK DEĞERLENDİRME',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (easyQuestions.isNotEmpty)
                      _buildDifficultyButton(context, topicId, 1, 'Kolay', easyQuestions.length, Colors.green),
                    if (mediumQuestions.isNotEmpty)
                      _buildDifficultyButton(context, topicId, 2, 'Orta', mediumQuestions.length, Colors.orange),
                    if (hardQuestions.isNotEmpty)
                      _buildDifficultyButton(context, topicId, 3, 'Zor', hardQuestions.length, Colors.red),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyButton(BuildContext context, int topicId, int difficulty, String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuestionsScreen(
                topicId: topicId,
                weekNo: weekNo,
                difficulty: difficulty,
              ),
            ),
          );
        },
        icon: const Icon(Icons.arrow_forward),
        label: Text('$label Seviye ($count Soru)'),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 12,
          ),
          textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}

class _TopicContentView extends StatelessWidget {
  final List<TopicContent> contents;
  const _TopicContentView({super.key, required this.contents});

  @override
  Widget build(BuildContext context) {
    return _InfoSection(
      icon: Icons.article_outlined,
      title: 'İÇERİKLER',
      child: ListView.builder(
        itemCount: contents.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final content = contents[index];
          final hasTitle = content.title.isNotEmpty;

          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasTitle) ...[
                    Text(
                      content.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 24),
                  ],
                  Html(
                    data: content.content,
                    extensions: const [
                      TableHtmlExtension(),
                    ],
                    style: getBaseHtmlStyle(context),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? content;
  final Widget? child;

  const _InfoSection({
    required this.icon,
    required this.title,
    this.content,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: theme.primaryColor, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child ??
            (content != null
                ? ContentRenderer(content: content!)
                : const SizedBox.shrink()),
      ],
    );
  }
}

class _HierarchyView extends StatelessWidget {
  final String? lesson;
  final String? unit;
  final String? topic;

  const _HierarchyView({this.lesson, this.unit, this.topic});

  Widget _buildHierarchyItem(
    BuildContext context,
    String label,
    String? value,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• $label: ',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHierarchyItem(context, 'Ders', lesson),
        _buildHierarchyItem(context, 'Ünite', unit),
        _buildHierarchyItem(context, 'Konu', topic),
      ],
    );
  }
}
