import 'package:flutter/foundation.dart';
import 'package:egitim_uygulamasi/screens/unit_summary_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with WidgetsBindingObserver {
  late Future<Map<String, dynamic>> _periodStatsFuture;
  late Future<Map<String, dynamic>> _activityFuture;
  late Future<List<Map<String, dynamic>>> _timeSeriesFuture;

  final Map<String, String> _periodLabels = {
    'daily': 'Bugün',
    'weekly': 'Bu Hafta',
    'monthly': 'Bu Ay',
    'academic_year': 'Akademik Yıl',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshData();
    }
  }

  void _loadData() {
    _periodStatsFuture = _fetchPeriodStats();
    _activityFuture = _fetchActivityAndStreak();
    _timeSeriesFuture = _fetchTimeSeriesData();
  }

  Future<void> _refreshData() async {
    setState(() {
      _loadData();
    });
  }

  Future<Map<String, dynamic>> _fetchPeriodStats() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception("İstatistikleri görmek için giriş yapmalısınız.");

    final result = <String, dynamic>{};

    try {
      final response = await Supabase.instance.client
          .from('user_time_based_stats')
          .select()
          .eq('user_id', user.id);

      final timeBasedStats = response as List;
      final latestStats = <String, dynamic>{};

      for (final stat in timeBasedStats) {
        final periodType = stat['period_type'] as String;
        if (!latestStats.containsKey(periodType) ||
            DateTime.parse(stat['period_date']).isAfter(DateTime.parse(latestStats[periodType]['period_date']))) {
          latestStats[periodType] = stat;
        }
      }

      latestStats.forEach((period, stats) {
        final total = (stats['total_questions'] as num?)?.toInt() ?? 0;
        final correct = (stats['correct_answers'] as num?)?.toInt() ?? 0;
        final incorrect = (stats['wrong_answers'] as num?)?.toInt() ?? 0;
        final successRate = total > 0 ? (correct * 100 / total) : 0.0;

        result[period] = {
          'general_stats': {
            'total_questions': total,
            'correct_answers': correct,
            'incorrect_answers': incorrect,
            'success_rate': successRate,
          }
        };
      });
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error fetching period stats: $e');
        print(stackTrace);
      }
      final periods = ['daily', 'weekly', 'monthly', 'academic_year'];
      for (var period in periods) {
        if (!result.containsKey(period)) {
          result[period] = {'error': e.toString()};
        }
      }
    }
    
    try {
        final detailedStats = await Supabase.instance.client.rpc(
          'get_detailed_statistics',
          params: {'p_user_id': user.id},
        );
        result['details'] = detailedStats;

    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error fetching detailed stats: $e');
        print(stackTrace);
      }
      result['details'] = {'error': e.toString()};
    }


    return result;
  }


  Future<Map<String, dynamic>> _fetchActivityAndStreak() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return {};

    try {
      final response = await Supabase.instance.client.rpc(
        'get_user_activity_and_streak_v2',
        params: {'p_user_id': user.id},
      );
      return response as Map<String, dynamic>;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error fetching activity and streak: $e');
        print(stackTrace);
      }
      return {'current_streak': 0, 'activity_dates': []};
    }
  }

  Future<List<Map<String, dynamic>>> _fetchTimeSeriesData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await Supabase.instance.client.rpc(
        'get_time_series_stats_v2',
        params: {'p_user_id': user.id, 'p_days': 7},
      );
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error fetching time series data: $e');
        print(stackTrace);
      }
      return []; // Hata durumunda boş liste döndür.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İstatistiklerim'),
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: Colors.blue,
        child: FutureBuilder(
          future: Future.wait([_periodStatsFuture, _activityFuture, _timeSeriesFuture]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState();
            }

            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }

            final allStats = snapshot.data![0] as Map<String, dynamic>;
            final activityData = snapshot.data![1] as Map<String, dynamic>;
            final timeSeriesData = snapshot.data![2] as List<Map<String, dynamic>>;
            final detailedStats = allStats['details'];

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeaderCards(activityData),
                const SizedBox(height: 20),

                _buildTimeSeriesChart(timeSeriesData),
                const SizedBox(height: 20),

                _buildPeriodsSummary(allStats),
                const SizedBox(height: 20),
                
                if (detailedStats != null && detailedStats is Map && !detailedStats.containsKey('error')) ...[
                  _buildLessonsChart(detailedStats),
                ]
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderCards(Map<String, dynamic> activityData) {
    final streak = activityData['current_streak'] as int? ?? 0;
    final activityDates = (activityData['activity_dates'] as List? ?? []).cast<String>();
    final activeDays = activityDates.length;
    final weekActivity = activityDates.where((date) {
      final d = DateTime.parse(date);
      return d.isAfter(DateTime.now().subtract(const Duration(days: 7)));
    }).length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: '$streak',
            subtitle: 'Günlük Seri',
            icon: Icons.local_fire_department,
            color: Colors.orange,
            gradient: [Colors.orange.shade600, Colors.red.shade400],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: '$weekActivity/7',
            subtitle: 'Haftalık Aktivite',
            icon: Icons.calendar_today,
            color: Colors.blue,
            gradient: [Colors.blue.shade600, Colors.blue.shade400],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: '$activeDays',
            subtitle: 'Toplam Aktif Gün',
            icon: Icons.timeline,
            color: Colors.green,
            gradient: [Colors.green.shade600, Colors.teal.shade400],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<Color> gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSeriesChart(List<Map<String, dynamic>> timeSeriesData) {
    if (timeSeriesData.isEmpty || timeSeriesData.every((d) => (d['total_questions'] as int? ?? 0) == 0)) {
      return _buildPlaceholderChart('Son 7 güne ait veri bulunamadı');
    }

    final chartData = timeSeriesData;
    final maxQuestions = chartData.map((d) => d['total_questions'] as int? ?? 0).reduce(max);
    final yAxisMax = maxQuestions == 0 ? 10.0 : (maxQuestions * 1.2); // Grafiğin üstünde boşluk bırak

    final activeDays = chartData.where((d) => (d['total_questions'] as int? ?? 0) > 0).toList();
    final averageQuestions = activeDays.isEmpty
        ? 0.0
        : activeDays.map((d) => d['total_questions'] as int).reduce((a, b) => a + b) / activeDays.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Son 7 Gün Soru Çözüm Trendi', // Başlık güncellendi
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => Colors.blue.shade800,
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: yAxisMax / 4, // Y eksenini 4 aralığa böl
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < chartData.length) {
                          final date = DateTime.parse(chartData[value.toInt()]['date']);
                          if (value.toInt() % 2 == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat('dd/MM').format(date),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            );
                          }
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: yAxisMax / 4, // Y eksenini 4 aralığa böl
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(), // Yüzde işareti kaldırıldı
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.shade200, width: 1),
                ),
                minX: 0,
                maxX: (chartData.length - 1).toDouble(),
                minY: 0,
                maxY: yAxisMax, // Dinamik Y ekseni
                lineBarsData: [
                  LineChartBarData(
                    spots: chartData.asMap().entries.map((entry) {
                      final index = entry.key;
                      final data = entry.value;
                      final count = (data['total_questions'] as int?)?.toDouble() ?? 0.0; // Değer güncellendi
                      return FlSpot(index.toDouble(), count);
                    }).toList(),
                    isCurved: true,
                    color: Colors.green.shade600, // Renk değiştirildi
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.shade600.withOpacity(0.3),
                          Colors.green.shade600.withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildChartSummaryItem('Ortalama Soru', averageQuestions.toStringAsFixed(1)),
              _buildChartSummaryItem('En Yüksek Soru', maxQuestions.toString()),
              _buildChartSummaryItem('Toplam Soru',
                  '${chartData.fold<int>(0, (sum, d) => sum + (d['total_questions'] as int? ?? 0))}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodsSummary(Map<String, dynamic> allStats) {
    final periods = ['daily', 'weekly', 'monthly', 'academic_year'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dönemsel Performans',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: periods.length,
            itemBuilder: (context, index) {
              final period = periods[index];
              final stats = allStats[period];

              if (stats == null || (stats is Map && stats.containsKey('error'))) {
                return _buildPeriodCard(period, 0, 0, 0, 0);
              }

              final generalStats = stats['general_stats'] as Map<String, dynamic>?;
              if (generalStats == null) {
                return _buildPeriodCard(period, 0, 0, 0, 0);
              }

              final successRate = (generalStats['success_rate'] as num?)?.toDouble() ?? 0;
              final total = (generalStats['total_questions'] as num?)?.toInt() ?? 0;
              final correct = (generalStats['correct_answers'] as num?)?.toInt() ?? 0;
              final incorrect = (generalStats['incorrect_answers'] as num?)?.toInt() ?? 0;

              return _buildPeriodCard(period, successRate, total, correct, incorrect);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodCard(String period, double successRate, int total, int correct, int incorrect) {
    final periodColors = {
      'daily': [Colors.blue.shade600, Colors.blue.shade300],
      'weekly': [Colors.green.shade600, Colors.green.shade300],
      'monthly': [Colors.orange.shade600, Colors.orange.shade300],
      'academic_year': [Colors.teal.shade600, Colors.teal.shade300],
    };

    final colors = periodColors[period] ?? [Colors.grey.shade600, Colors.grey.shade300];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors[0], colors[1]],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _periodLabels[period] ?? period,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '%${successRate.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$total soru',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          '$correct doğru',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.close, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          '$incorrect yanlış',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonsChart(dynamic detailedData) {
    if (detailedData is! Map || !detailedData.containsKey('lesson_stats')) {
      return _buildPlaceholderChart('Ders istatistikleri yüklenemedi');
    }

    final lessonStats = detailedData['lesson_stats'] as List;
    if (lessonStats.isEmpty) {
      return _buildPlaceholderChart('Henüz ders istatistiği yok');
    }

    final displayLessons = lessonStats.length > 5
        ? lessonStats.sublist(0, 5)
        : lessonStats;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ders Bazlı Başarı Oranları',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Daha küçük padding
                    tooltipRoundedRadius: 8, // Yuvarlatılmış köşeler
                    getTooltipColor: (touchedSpot) => Colors.grey.withOpacity(0.8),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final value = rod.toY.round();
                      return BarTooltipItem(
                        '${value}%',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < displayLessons.length) {
                          final lesson = displayLessons[value.toInt()] as Map<String, dynamic>;
                          final name = lesson['lesson_name'] as String;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              name.length > 8 ? '${name.substring(0, 8)}...' : name,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 25,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    );
                  },
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.shade200, width: 1),
                ),
                barGroups: displayLessons.asMap().entries.map((entry) {
                  final index = entry.key;
                  final lesson = entry.value as Map<String, dynamic>;
                  final rate = (lesson['success_rate'] as num).round().toDouble(); // Değer yuvarlandı

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: rate,
                        width: 20,
                        color: _getSuccessColor(rate),
                        borderRadius: BorderRadius.circular(4),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: 100,
                          color: Colors.grey.shade100,
                        ),
                      ),
                    ],
                    showingTooltipIndicators: [0],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderChart(String message) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.bar_chart_rounded,
            color: Colors.grey.shade300,
            size: 60,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('İstatistikler yükleniyor...', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Colors.red.shade400,
            size: 64,
          ),
          const SizedBox(height: 20),
          const Text(
            'Bir hata oluştu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tekrar Dene'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSuccessColor(double rate) {
    if (rate >= 70) return Colors.green.shade600;
    if (rate >= 40) return Colors.orange.shade600;
    return Colors.red.shade600;
  }
}
