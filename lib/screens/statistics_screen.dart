import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<Map<String, String>> _periods = [
    {'label': 'Genel', 'value': 'all'},
    {'label': 'Günlük', 'value': 'daily'},
    {'label': 'Haftalık', 'value': 'weekly'},
    {'label': 'Aylık', 'value': 'monthly'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _periods.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetchStats(String period) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception("İstatistikleri görmek için giriş yapmalısınız.");

    final response = await Supabase.instance.client.rpc(
      'get_user_stats_by_period',
      params: {
        'p_user_id': user.id,
        'p_period': period,
      },
    );

    return response as Map<String, dynamic>;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İstatistiklerim'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          tabs: _periods.map((p) => Tab(text: p['label'])).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _periods.map((p) => _StatsView(period: p['value']!, fetcher: _fetchStats)).toList(),
      ),
    );
  }
}

class _StatsView extends StatelessWidget {
  final String period;
  final Future<Map<String, dynamic>> Function(String) fetcher;

  const _StatsView({required this.period, required this.fetcher});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: fetcher(period),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }

        final data = snapshot.data!;
        final total = data['total_questions'] as int;

        if (total == 0) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Bu dönemde henüz çözülmüş soru yok.', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSummaryCard(context, data),
            const SizedBox(height: 24),
            const Text(
              'Ders Bazlı Başarı',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ... (data['lesson_stats'] as List).map((l) => _buildLessonCard(context, l)),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(BuildContext context, Map<String, dynamic> data) {
    final successRate = (data['success_rate'] as num).toDouble();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Toplam', data['total_questions'].toString(), Colors.blue),
                _buildStatItem('Doğru', data['correct_answers'].toString(), Colors.green),
                _buildStatItem('Yanlış', data['incorrect_answers'].toString(), Colors.red),
              ],
            ),
            const Divider(height: 32),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Başarı Oranı: %$successRate', 
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: successRate / 100,
                        backgroundColor: Colors.grey.shade200,
                        color: _getSuccessColor(successRate),
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonCard(BuildContext context, Map<String, dynamic> lesson) {
    final rate = (lesson['success_rate'] as num).toDouble();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(lesson['lesson_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Toplam: ${lesson['total_questions']} | D: ${lesson['correct_answers']} Y: ${lesson['incorrect_answers']}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getSuccessColor(rate).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '%$rate',
            style: TextStyle(color: _getSuccessColor(rate), fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Color _getSuccessColor(double rate) {
    if (rate >= 70) return Colors.green;
    if (rate >= 40) return Colors.orange;
    return Colors.red;
  }
}
