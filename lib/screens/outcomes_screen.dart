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
    return DateTime(year, 9, 9);
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

          // Sayfa değişimlerini dinlemek için bir ValueNotifier kullanalım.
          final currentPageNotifier = ValueNotifier<int>(initialPageIndex);

          _pageController!.addListener(() {
            if (_pageController!.page?.round() != currentPageNotifier.value) {
              currentPageNotifier.value = _pageController!.page!.round();
            }
          });

          return Column(
            children: [
              ValueListenableBuilder<int>(
                valueListenable: currentPageNotifier,
                builder: (context, currentPage, child) {
                  final weekNum = weeks[currentPage];
                  final (startDate, endDate) = _getWeekDateRange(weekNum);
                  final formattedStartDate =
                      '${startDate.day} ${aylar[startDate.month - 1]}';
                  final formattedEndDate =
                      '${endDate.day} ${aylar[endDate.month - 1]} ${endDate.year}';

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$weekNum. Hafta',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$formattedStartDate - $formattedEndDate',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                },
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: weeks.length,
                  itemBuilder: (context, index) {
                    return WeekOutcomesView(
                      lessonId: widget.lessonId,
                      gradeId: widget.gradeId,
                      lessonName: widget.lessonName,
                      gradeName: widget.gradeName,
                      weekNumber: weeks[index],
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
class WeekOutcomesView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final outcomesFuture = Supabase.instance.client
        .rpc(
          'get_outcomes_for_week', // Bu RPC'yi bir önceki adımda oluşturmuştuk.
          params: {
            'p_lesson_id': lessonId,
            'p_grade_id': gradeId, // Artık doğrudan gradeId kullanıyoruz.
            'p_week_number': weekNumber,
          },
        )
        .then((response) => List<Map<String, dynamic>>.from(response));

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: outcomesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Kazanımlar yüklenemedi: ${snapshot.error}'),
          );
        }
        final outcomes = snapshot.data;
        if (outcomes == null || outcomes.isEmpty) {
          return Center(
            child: Text('$weekNumber. hafta için kazanım bulunamadı.'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          itemCount: outcomes.length,
          itemBuilder: (context, index) {
            final outcome = outcomes[index];
            return _OutcomeCard(
              outcomeData: outcome,
              lessonName: lessonName,
              gradeName: gradeName,
              weekNumber: weekNumber, // Hafta numarasını doğrudan iletiyoruz
            );
          },
        );
      },
    );
  }
}

/// Tasarıma uygun olarak her bir kazanım ve içeriğini gösteren ana kart.
class _OutcomeCard extends StatefulWidget {
  final Map<String, dynamic> outcomeData;
  final String lessonName;
  final String gradeName;
  final int weekNumber;

  const _OutcomeCard({
    required this.outcomeData,
    required this.lessonName,
    required this.gradeName,
    required this.weekNumber,
  });

  @override
  State<_OutcomeCard> createState() => _OutcomeCardState();
}

class _OutcomeCardState extends State<_OutcomeCard> {
  late final Future<Map<String, List<dynamic>>> _topicDetailsFuture;

  @override
  void initState() {
    super.initState();
    // RPC'den gelen 'topic_id'yi alıyoruz. Bu ID null olabilir.
    // _fetchTopicDetails metodu bu durumu kontrol edecektir.
    final topicId = widget.outcomeData['topic_id'] as int?;
    _topicDetailsFuture = _fetchTopicDetails(topicId, widget.weekNumber);
  }

  /// Konuya ait içerikleri ve videoları çeken metot.
  Future<Map<String, List<dynamic>>> _fetchTopicDetails(
    int? topicId,
    int? weekNumber,
  ) async {
    if (topicId == null || weekNumber == null) {
      // Eğer topicId yoksa, sorgu yapmadan boş dön.
      return {'contents': [], 'videos': []};
    }

    try {
      // İçerikleri ve videoları topic_id kullanarak aynı anda çekiyoruz.
      final results = await Future.wait([
        Supabase.instance.client
            .from('topic_contents')
            .select()
            .eq('display_week', weekNumber)
            .eq('topic_id', topicId) // 'outcome_id' yerine 'topic_id' kullan
            .order('order_no', ascending: true),
        Supabase.instance.client
            .from('topic_videos')
            .select()
            .eq('topic_id', topicId), // Videoları da topic_id ile çek
      ]);

      final contents = (results[0] as List)
          .map((json) => TopicContent.fromJson(json as Map<String, dynamic>))
          .toList();

      return {
        'contents': contents,
        'videos': List<Map<String, dynamic>>.from(results[1]),
      };
    } catch (e) {
      debugPrint("Konu detayları çekilirken hata: $e");
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Verileri daha okunabilir değişkenlere atayalım
    final outcomeDescription =
        widget.outcomeData['outcome_description'] as String?;
    final unitTitle = widget.outcomeData['unit_title'] as String?;
    final topicTitle = widget.outcomeData['topic_title'] as String?;

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
              title: 'KAZANIM',
              content: outcomeDescription,
            ),
            const Divider(height: 32),

            // 2. DERS HİYERARŞİSİ BÖLÜMÜ
            _InfoSection(
              icon: Icons.account_tree_outlined,
              title: 'DERS HİYERARŞİSİ',
              child: _HierarchyView(
                lesson: widget.lessonName,
                unit: unitTitle,
                topic: topicTitle,
              ),
            ),
            const Divider(height: 32),

            // 3. İÇERİKLER VE VİDEOLAR BÖLÜMÜ (FutureBuilder ile)
            FutureBuilder<Map<String, List<dynamic>>>(
              future: _topicDetailsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('İçerikler yüklenemedi.'));
                }
                // Gelen 'contents' listesini güvenli bir şekilde TopicContent listesine dönüştürüyoruz.
                // `snapshot.data?['contents']` bir `List<dynamic>` döndürür.
                // Bu listeyi `map` ile gezip her bir elemanı `TopicContent.fromJson` ile oluşturuyoruz.
                final List<TopicContent> contents =
                    (snapshot.data?['contents'] as List<dynamic>?)
                        ?.map((item) => item as TopicContent)
                        .toList() ??
                    [];

                final videos = snapshot.data?['videos'] ?? [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // İçerikler bölümü
                    if (contents.isNotEmpty)
                      _TopicContentView(contents: contents),

                    // Videolar bölümü
                    if (videos.isNotEmpty) ...[
                      if (contents.isNotEmpty) const Divider(height: 32),
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
                                  video['title'] as String? ??
                                      'Konu Anlatım Videosu',
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
                );
              },
            ),
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
