// lib/screens/outcomes_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:egitim_uygulamasi/models/topic_content.dart'; // Bu satır zaten vardı, referans için burada.
import 'package:egitim_uygulamasi/widgets/topic_section_renderer.dart';
import 'package:egitim_uygulamasi/widgets/common/content_renderer.dart'; // Bu import'u ekliyoruz

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
    _weeksFuture = _fetchAvailableWeeks();
  }

  @override
  void dispose() {
    _pageController?.dispose(); // Artık doğru çalışacak
    super.dispose();
  }

  /// Derse ait kazanımların bulunduğu hafta numaralarını çeker.
  Future<List<Map<String, dynamic>>> _fetchAvailableWeeks() async {
    try {
      // get_available_weeks RPC'sini çağırarak haftaları alıyoruz.
      // Bu RPC'nin de yukarıdaki gibi güncellendiğini varsayıyoruz.
      final response = await Supabase.instance.client.rpc(
        'get_available_weeks_for_lesson',
        params: {
          'p_lesson_id': widget.lessonId,
          'p_grade_id': widget.gradeId, // Artık doğrudan gradeId kullanıyoruz.
        },
      );

      // Gelen veri List<dynamic> olduğu için önce doğru tipe çeviriyoruz.
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Haftalar çekilirken hata: $e");
      rethrow;
    }
  }

  /// Hafta numarasına göre o haftanın başlangıç ve bitiş tarihlerini hesaplar.
  (DateTime, DateTime) _getWeekDateRange(int weekNumber) {
    // Okul başlangıç tarihini burada da tanımlıyoruz.
    final schoolStart = _getCurrentAcademicYearStartDate();

    // İstenen haftanın başlangıç gününü hesapla.
    final daysToAdd = (weekNumber - 1) * 7;
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
    // Başlangıç tarihini 9 Eylül olarak varsayalım. Bu tarih bir ayar olarak saklanabilir.
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

          // Gelen veriden sadece 'week_number' değerlerini alıp bir liste oluşturuyoruz.
          final weeks = snapshot.data!
              .map<int>((e) => e['week_number'] as int)
              .toList();

          // Mevcut hafta numarasını dinamik başlangıç tarihine göre hesapla
          final schoolStart = _getCurrentAcademicYearStartDate();
          final now = DateTime.now();
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
                    final weekNum = weeks[index];
                    final (startDate, endDate) = _getWeekDateRange(weekNum);
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
                          weekNum: weekNum,
                          startDate: formattedStartDate,
                          endDate: formattedEndDate,
                        ),
                        const SizedBox(height: 8),
                        WeekOutcomesView(
                          lessonId: widget.lessonId,
                          gradeId: widget.gradeId,
                          lessonName: widget.lessonName,
                          gradeName: widget.gradeName,
                          weekNumber: weekNum,
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
    required this.weekNum,
    required this.startDate,
    required this.endDate,
  });

  final int weekNum;
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
              '$weekNum. Hafta',
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
  final int weekNumber;

  const WeekOutcomesView({
    super.key,
    required this.lessonId,
    required this.gradeId,
    required this.lessonName,
    required this.gradeName,
    required this.weekNumber,
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

  /// Haftanın kazanımlarını ve bu kazanımlarla ilişkili konu içeriklerini tek seferde çeker.
  Future<Map<String, dynamic>> _fetchWeekData() async {
    // 1. Adım: Haftaya ait kazanımları çek.
    final outcomesResponse = await Supabase.instance.client.rpc(
      'get_outcomes_for_week',
      params: {
        'p_lesson_id': widget.lessonId,
        'p_grade_id': widget.gradeId,
        'p_week_number': widget.weekNumber,
      },
    );
    final outcomes = List<Map<String, dynamic>>.from(outcomesResponse);

    if (outcomes.isEmpty) {
      // Kazanım yoksa içerik de yoktur, boş veri dön.
      return {'outcomes': [], 'contents': [], 'videos': []};
    }

    // 2. Adım: İlk kazanımın topic_id'sini alarak içerikleri çek.
    // Varsayım: Bir haftadaki tüm kazanımlar aynı konuya (topic) aittir.
    final topicId = outcomes.first['topic_id'] as int?;

    if (topicId == null) {
      // Topic ID yoksa, sadece kazanımları dön.
      return {'outcomes': outcomes, 'contents': [], 'videos': []};
    }

    // 3. Adım: Konu içeriklerini ve videolarını çek.
    try {
      final results = await Future.wait([
        Supabase.instance.client
            .from('topic_contents')
            .select(
              'id, topic_id, title, content, section_type, display_week, order_no',
            )
            .eq('display_week', widget.weekNumber)
            .eq('topic_id', topicId)
            .order('order_no', ascending: true),
        Supabase.instance.client
            .from('topic_videos')
            .select('id, topic_id, title, video_url, order_no')
            .eq('topic_id', topicId)
            .order('order_no', ascending: true),
      ]);

      final contents = (results[0] as List)
          .map((json) => TopicContent.fromJson(json as Map<String, dynamic>))
          .toList();
      final videos = List<Map<String, dynamic>>.from(results[1]);

      return {'outcomes': outcomes, 'contents': contents, 'videos': videos};
    } catch (e) {
      debugPrint("Hafta verileri çekilirken hata: $e");
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

        final outcomes =
            (snapshot.data?['outcomes'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>() ??
            [];
        final contents =
            (snapshot.data?['contents'] as List<dynamic>?)
                ?.cast<TopicContent>() ??
            [];
        final videos =
            (snapshot.data?['videos'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>() ??
            [];

        if (outcomes == null || outcomes.isEmpty) {
          return Center(
            child: Text('${widget.weekNumber}. hafta için kazanım bulunamadı.'),
          );
        }

        // Artık _OutcomeCard yerine doğrudan verileri kullanarak
        // birleşik bir görünüm oluşturuyoruz.
        return _CombinedWeekContentCard(
          outcomes: outcomes,
          contents: contents,
          videos: videos,
          lessonName: widget.lessonName,
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
  final String lessonName;

  const _CombinedWeekContentCard({
    required this.outcomes,
    required this.contents,
    required this.videos,
    required this.lessonName,
  });

  @override
  Widget build(BuildContext context) {
    // İlk kazanımdan hiyerarşi bilgilerini alalım (hepsi için aynı olmalı).
    final firstOutcome = outcomes.first;
    final unitTitle = firstOutcome['unit_title'] as String?;
    final topicTitle = firstOutcome['topic_title'] as String?;

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
            // 1. KAZANIM BÖLÜMÜ
            _InfoSection(
              icon: Icons.flag_circle_outlined,
              title: 'KAZANIMLAR',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: outcomes.map((outcome) {
                  final description = outcome['description'] as String?;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    // Her kazanımı bir madde imi ile gösterelim.
                    child: ContentRenderer(content: '• ${description ?? ''}'),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 32),

            // 2. DERS HİYERARŞİSİ BÖLÜMÜ
            _InfoSection(
              icon: Icons.account_tree_outlined,
              title: 'DERS HİYERARŞİSİ',
              child: _HierarchyView(
                lesson: lessonName,
                unit: unitTitle,
                topic: topicTitle,
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
    return _InfoSection(
      icon: Icons.article_outlined,
      title: 'İÇERİKLER',
      // Use ListView.separated for performance and clean separation.
      // It builds items lazily as they scroll into view.
      child: ListView.separated(
        itemCount: contents.length,
        shrinkWrap: true, // Important for nesting in a Column
        physics: const NeverScrollableScrollPhysics(), // Let the parent scroll
        itemBuilder: (context, index) {
          return buildTopicSection(contents[index]);
        },
        separatorBuilder: (context, index) =>
            const SizedBox(height: 24.0), // Space between sections
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

  Widget _buildHierarchyItem(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: ContentRenderer(content: '• $label: ${value ?? 'N/A'}'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHierarchyItem('Ders', lesson),
        _buildHierarchyItem('Ünite', unit),
        _buildHierarchyItem('Konu', topic),
      ],
    );
  }
}
