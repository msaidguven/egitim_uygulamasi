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
  final _unitService = UnitService(); // Add service instance

  @override
  void initState() {
    super.initState();
    _weeksFuture = _fetchAvailableWeeks();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  /// Derse ait içeriklerin bulunduğu hafta numaralarını çeker.
  Future<List<Map<String, dynamic>>> _fetchAvailableWeeks() async {
    try {
      final List<dynamic> result = await Supabase.instance.client.rpc(
        'get_available_weeks',
        params: {'p_grade_id': widget.gradeId, 'p_lesson_id': widget.lessonId},
      );
      final weeks = List<Map<String, dynamic>>.from(result);
      return weeks;
    } catch (e) {
      debugPrint("Haftalar çekilirken hata (RPC): $e");
      rethrow;
    }
  }

  /// Hafta numarasına göre o haftanın başlangıç ve bitiş tarihlerini hesaplar.
  (DateTime, DateTime) _getWeekDateRange(int weekNo) {
    // Okul başlangıç tarihini burada da tanımlıyoruz.
    final schoolStart = _getCurrentAcademicYearStartDate();

    // İstenen haftanın başlangıç gününü hesapla (1 tabanlı olduğu için 1 çıkarıyoruz).
    final daysToAdd = (weekNo - 1) * 7;
    final weekStartDate = schoolStart.add(Duration(days: daysToAdd));

    // Haftanın bitiş gününü hesapla (başlangıca 6 gün ekleyerek).
    final weekEndDate = weekStartDate.add(const Duration(days: 6));

    return (weekStartDate, weekEndDate);
  }

  /// İçinde bulunulan akademik yılın başlangıç tarihini (örn: 9 Eylül) hesaplar.
  DateTime _getCurrentAcademicYearStartDate() {
    final now = DateTime.now();
    // Akademik yıl genellikle Eylül'de başlar.
    // Eğer mevcut ay Eylül'den önce ise (Ocak-Ağustos), başlangıç yılı bir önceki yıldır.
    final year = now.month < 9 ? now.year - 1 : now.year;
    // Başlangıç tarihini 8 Eylül olarak varsayalım. Bu tarih bir ayar olarak saklanabilir.
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
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                snapshot.hasError
                    ? 'Hata: ${snapshot.error}'
                    : 'Bu derse ait kazanım bulunamadı.',
              ),
            );
          }

          // Gelen veriden sadece 'week_no' değerlerini alıp bir liste oluşturuyoruz.
          final weeks = snapshot.data!
              .map<int>((e) => e['week_no'] as int)
              .toList();

          // Mevcut hafta numarasını dinamik başlangıç tarihine göre hesapla
          final schoolStart = _getCurrentAcademicYearStartDate();
          final now = DateTime.now();
          // RPC'den gelen hafta numaraları 1 tabanlı olduğu için,
          // mevcut hafta numarasını da 1 tabanlı hesaplıyoruz.
          final currentWeekNumber =
              ((now.difference(schoolStart).inDays) / 7).floor() + 1;

          // Mevcut haftanın listesindeki indeksi bul, bulunamazsa 0 ata.
          int initialPageIndex = weeks.indexOf(currentWeekNumber);

          // Eğer PageController daha önce oluşturulmadıysa, şimdi oluştur.
          // Bu, build metodunun her çağrısında yeniden oluşturulmasını engeller.
          if (_pageController == null) {
            if (initialPageIndex == -1) {
              // Mevcut hafta listede bulunamadı.
              // Kullanıcıya bilgi verip ilk haftayı açalım.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '$currentWeekNumber. hafta için kazanım bulunamadı. İlk hafta gösteriliyor.',
                      ),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              });
              initialPageIndex = 0; // İlk haftanın indeksine ayarla.
            }
            _pageController = PageController(initialPage: initialPageIndex);
          }

          return Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: weeks.length,
                  itemBuilder: (context, index) {
                    final weekNo = weeks[index];
                    final (startDate, endDate) = _getWeekDateRange(weekNo);
                    final formattedStartDate =
                        '${startDate.day} ${aylar[startDate.month - 1]}';
                    final formattedEndDate =
                        '${endDate.day} ${aylar[endDate.month - 1]} ${endDate.year}';

                    // Her sayfa, kendi başlığını ve içeriğini içeren
                    // dikey bir liste olacak.
                    return ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      children: [
                        _WeekHeaderCard(
                          weekNo: weekNo,
                          startDate: formattedStartDate,
                          endDate: formattedEndDate,
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

/// Hafta başlığını ve tarihini gösteren şık kart widget'ı.
class _WeekHeaderCard extends StatelessWidget {
  const _WeekHeaderCard({
    required this.weekNo,
    required this.startDate,
    required this.endDate,
  });

  final int weekNo;
  final String startDate;
  final String endDate;

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
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '$startDate - $endDate',
              style: Theme.of(context).textTheme.bodySmall,
            ),
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

/// Belirli bir haftanın kazanımlarını RPC ile çeken ve listeleyen Widget.
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

      // Use a Set to store unique TopicContent objects based on their ID.
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
              '*, questions(*, question_choices(*), question_blanks(*), question_classical(*))',
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

/// Tasarıma uygun olarak her bir kazanım ve içeriğini gösteren ana kart.
/// Bu widget artık tüm hafta içeriğini tek bir kartta birleştirir.
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
    // İlk kazanımdan hiyerarşi bilgilerini alalım (hepsi için aynı olmalı).
    final firstOutcome = outcomes.first;
    final unitTitle = firstOutcome['unit_title'] as String?;
    final topicTitle = firstOutcome['topic_title'] as String?;
    final topicId = firstOutcome['topic_id'] as int?;
    final theme = Theme.of(context);

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
            // 1. DERS HİYERARŞİSİ BÖLÜMÜ (YUKARI TAŞINDI)
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

            // 2. KAZANIM BÖLÜMÜ (GÖSTER/GİZLE)
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

            // 3. İÇERİKLER VE VİDEOLAR BÖLÜMÜ
            // İçerikler bölümü
            if (contents.isNotEmpty) ...[
              const Divider(height: 32),
              _TopicContentView(contents: contents),
            ],

            // Videolar bölümü
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
                        onPressed: () {
                          // TODO: url_launcher ile videoyu aç
                        },
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

            // 4. HAFTALIK SORULAR BÖLÜMÜ
            if (questions.isNotEmpty && topicId != null) ...[
              const Divider(height: 32),
              _InfoSection(
                icon: Icons.quiz_outlined,
                title: 'HAFTALIK DEĞERLENDİRME',
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              QuestionsScreen(topicId: topicId, weekNo: weekNo),
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: Text('${questions.length} Soru ile Başla'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      textStyle: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Topic contents listesini alan ve her bir içeriği
/// section_type'a göre uygun widget ile render eden widget.
class _TopicContentView extends StatelessWidget {
  final List<TopicContent> contents;
  const _TopicContentView({super.key, required this.contents});

  @override
  Widget build(BuildContext context) {
    // getBaseHtmlStyle'ı kullanabilmek için html_style.dart dosyasını import etmeliyiz.
    // Bu dosya zaten `outcomes_screen.dart` dosyasının üst kısımlarında import edilmiş olmalı.
    // Eğer edilmemişse, manuel olarak eklemek gerekir.
    // import 'package:egitim_uygulamasi/utils/html_style.dart';

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
            clipBehavior: Clip.antiAlias, // Köşelerin yuvarlak kalmasını sağlar
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
                      // Diğer extension'ları buraya ekleyebilirsiniz.
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

/// Başlık, ikon ve içerikten oluşan genel bir bölüm widget'ı.
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
        // Render either the content string or the child widget, but not both.
        // If a child widget is provided, it takes precedence.
        child ??
            (content != null
                ? ContentRenderer(content: content!)
                : const SizedBox.shrink()),
      ],
    );
  }
}

/// Ders -> Ünite -> Konu hiyerarşisini gösteren widget.
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
