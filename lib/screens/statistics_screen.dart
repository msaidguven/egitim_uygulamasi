import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  _StatisticsScreenState createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  // Future'ı initState'ten kaldırıyoruz.
  // late final Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    // _statsFuture = _fetchUserStats(); // Bu satırı kaldırıyoruz.
  }

  // Fonksiyonu _fetchUserStats'ten fetchUserStats'e çeviriyoruz ve widget'ın içinden çağıracağız.
  Future<Map<String, dynamic>> fetchUserStats() async {
    // build metodu sık sık çağrılabileceği için, context'i burada kullanmak riskli olabilir.
    // SnackBar gösterimi için bir kontrol ekleyelim.
    if (!mounted) return {};

    final userId = Supabase.instance.client.auth.currentUser!.id;
    try {
      final response = await Supabase.instance.client.rpc(
        'get_user_stats',
        params: {'p_user_id': userId},
      );
      return response as Map<String, dynamic>;
    } on PostgrestException catch (e) {
      print('Error fetching stats: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İstatistikler yüklenirken bir hata oluştu: ${e.message}')),
        );
      }
      return {}; // Hata durumunda boş harita döndür.
    } catch (e) {
      print('An unexpected error occurred: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Beklenmedik bir hata oluştu.')),
        );
      }
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İstatistiklerim'),
        // Yenileme butonu ekleyerek manuel olarak da güncellemeyi sağlayalım.
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                // State'i yeniden oluşturarak FutureBuilder'ın tekrar çalışmasını tetikler.
              });
            },
          ),
        ],
      ),
      // Future'ı doğrudan FutureBuilder'a veriyoruz.
      // Bu, setState çağrıldığında veya ekran yeniden çizildiğinde Future'ın tekrar çalışmasını sağlar.
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchUserStats(), // Future'ı burada çağırıyoruz.
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('İstatistikler yüklenemedi veya henüz veri yok.'),
            );
          }

          final stats = snapshot.data!;
          final lessonStats = (stats['lesson_stats'] as List<dynamic>?)
              ?.map((item) => item as Map<String, dynamic>)
              .toList() ?? []; // Null gelme ihtimaline karşı kontrol

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverallStatsCard(stats),
                const SizedBox(height: 24),
                Text(
                  'Derse Göre Başarı',
                  style: Theme.of(context).textTheme.headline6,
                ),
                const SizedBox(height: 12),
                if (lessonStats.isEmpty)
                  const Text('Henüz ders bazında bir istatistik bulunmuyor.')
                else
                  _buildLessonStatsList(lessonStats),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverallStatsCard(Map<String, dynamic> stats) {
    final double successRate = (stats['success_rate'] as num? ?? 0).toDouble();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Genel Bakış',
              style: Theme.of(context).textTheme.headline5,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Testler', (stats['total_tests'] ?? 0).toString()),
                _buildStatItem('Sorular', (stats['total_questions'] ?? 0).toString()),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Doğru', (stats['correct_answers'] ?? 0).toString(), color: Colors.green),
                _buildStatItem('Yanlış', (stats['incorrect_answers'] ?? 0).toString(), color: Colors.red),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Başarı Oranı',
              style: Theme.of(context).textTheme.subtitle1,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: successRate / 100,
              minHeight: 10,
              backgroundColor: Colors.grey[300],
              color: Colors.blue,
            ),
            const SizedBox(height: 4),
            Text(
              '${successRate.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.headline6?.copyWith(color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headline4?.copyWith(color: color ?? Theme.of(context).textTheme.bodyText1?.color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyText2,
        ),
      ],
    );
  }

  Widget _buildLessonStatsList(List<Map<String, dynamic>> lessonStats) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: lessonStats.length,
      itemBuilder: (context, index) {
        final lesson = lessonStats[index];
        final double successRate = (lesson['success_rate'] as num? ?? 0).toDouble();
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(lesson['lesson_name'] ?? 'Bilinmeyen Ders'),
            subtitle: Text('${lesson['total_questions'] ?? 0} soru, ${lesson['correct_answers'] ?? 0} doğru'),
            trailing: Text(
              '${successRate.toStringAsFixed(1)}%',
              style: TextStyle(
                color: successRate > 75 ? Colors.green : (successRate > 50 ? Colors.orange : Colors.red),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
