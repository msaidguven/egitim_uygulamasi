// lib/screens/outcomes_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OutcomesScreen extends StatefulWidget {
  final int subjectId;
  final int gradeId;
  final String gradeName;
  final String subjectName;

  const OutcomesScreen({
    super.key,
    required this.subjectId,
    required this.gradeId,
    required this.gradeName,
    required this.subjectName,
  });

  @override
  State<OutcomesScreen> createState() => _OutcomesScreenState();
}

class _OutcomesScreenState extends State<OutcomesScreen> {
  PageController? _pageController;
  late final Future<List<int>> _weeksFuture;

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
  Future<List<int>> _fetchAvailableWeeks() async {
    try {
      // 1. Adımda oluşturduğumuz RPC fonksiyonunu çağırıyoruz.
      // Bu yöntem hem daha temiz, hem daha güvenli, hem de daha performanslıdır.
      final response = await Supabase.instance.client.rpc(
        'get_available_weeks_for_subject',
        params: {'p_subject_id': widget.subjectId},
      );

      // Gelen veri List<dynamic> olduğu için önce doğru tipe çeviriyoruz.
      final data = List<Map<String, dynamic>>.from(response);

      // Gelen veriden sadece 'week_number' değerlerini alıp bir liste oluşturuyoruz.
      final weeks = data.map<int>((e) => e['week_number'] as int).toList();
      return weeks;
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
      appBar: AppBar(title: Text(widget.subjectName)),
      // _weeksFuture null ise yükleniyor göster, değilse FutureBuilder'ı çiz.
      body: FutureBuilder<List<int>>(
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

          final weeks = snapshot.data!;

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
                      subjectId: widget.subjectId,
                      gradeId: widget.gradeId,
                      subjectName: widget.subjectName,
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
  final int subjectId;
  final int gradeId;
  final String subjectName;
  final String gradeName;
  final int weekNumber;

  const WeekOutcomesView({
    super.key,
    required this.subjectId,
    required this.gradeId,
    required this.subjectName,
    required this.gradeName,
    required this.weekNumber,
  });

  @override
  Widget build(BuildContext context) {
    final outcomesFuture = Supabase.instance.client
        .rpc(
          'get_outcomes_for_week', // Bu RPC'yi bir önceki adımda oluşturmuştuk.
          params: {
            'p_subject_id': subjectId,
            'p_grade_id': gradeId,
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
              subjectName: subjectName, // 'widget.' olmadan doğrudan kullan
              gradeName: gradeName, // 'widget.' olmadan doğrudan kullan
            );
          },
        );
      },
    );
  }
}

/// Tasarıma uygun olarak her bir kazanım ve içeriğini gösteren ana kart.
class _OutcomeCard extends StatelessWidget {
  final Map<String, dynamic> outcomeData;
  final String subjectName;
  final String gradeName;

  const _OutcomeCard({
    required this.outcomeData,
    required this.subjectName,
    required this.gradeName,
  });

  @override
  Widget build(BuildContext context) {
    // Verileri daha okunabilir değişkenlere atayalım
    final outcomeDescription = outcomeData['outcome_description'] as String?;
    final unitTitle = outcomeData['unit_title'] as String?;
    final topicTitle = outcomeData['topic_title'] as String?;
    final topicContent = outcomeData['topic_content'] as String?;
    final videoUrl = outcomeData['topic_video_url'] as String?;

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
                subject: subjectName,
                unit: unitTitle,
                topic: topicTitle,
              ),
            ),
            const Divider(height: 32),

            // 3. İÇERİKLER BÖLÜMÜ
            _InfoSection(
              icon: Icons.article_outlined,
              title: 'İÇERİKLER',
              content: topicContent,
            ),

            // Video butonu (sadece videoUrl varsa gösterilir)
            if (videoUrl != null && videoUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: url_launcher paketi ile videoyu aç
                  },
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('Konu Anlatım Videosu'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
          ],
        ),
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
        if (content != null)
          Text(
            content!,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        if (child != null) child!,
      ],
    );
  }
}

/// Ders -> Ünite -> Konu hiyerarşisini gösteren widget.
class _HierarchyView extends StatelessWidget {
  final String? subject;
  final String? unit;
  final String? topic;

  const _HierarchyView({this.subject, this.unit, this.topic});

  Widget _buildHierarchyItem(String label, String? value, {int level = 0}) {
    return Padding(
      padding: EdgeInsets.only(left: level * 16.0, top: 4, bottom: 4),
      child: Text.rich(
        TextSpan(
          text: '$label: ',
          style: const TextStyle(fontWeight: FontWeight.bold),
          children: [
            TextSpan(
              text: value ?? 'N/A',
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHierarchyItem('Ders', subject, level: 0),
        _buildHierarchyItem('Ünite', unit, level: 1),
        _buildHierarchyItem('Konu', topic, level: 2),
      ],
    );
  }
}
