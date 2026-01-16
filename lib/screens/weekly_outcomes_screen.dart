// DOĞRU DOSYA IMPORT EDİLDİ
import 'package:egitim_uygulamasi/screens/weekly_test_screen.dart';
import 'package:egitim_uygulamasi/providers/outcome_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WeeklyOutcomesScreen extends ConsumerWidget {
  final int topicId;
  final String topicTitle;

  const WeeklyOutcomesScreen({
    super.key,
    required this.topicId,
    required this.topicTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeksAsyncValue = ref.watch(weeksForTopicProvider(topicId));

    return Scaffold(
      appBar: AppBar(title: Text('$topicTitle - Haftalar')),
      body: weeksAsyncValue.when(
        data: (weeks) {
          if (weeks.isEmpty) {
            return const Center(
              child: Text('Bu konu için haftalık kazanım bulunamadı.'),
            );
          }
          return ListView.builder(
            itemCount: weeks.length,
            itemBuilder: (context, index) {
              final week = weeks[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text('Hafta ${week.startWeek}'),
                  subtitle: week.outcomeId != null 
                            ? Text('Kazanım ID: ${week.outcomeId}')
                            : null,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        // KESİN VE NİHAİ ÇÖZÜM: DOĞRU SINIF ADI KULLANILDI
                        builder: (context) => WeeklyTestScreen(
                          topicId: topicId,
                          weekNo: week.startWeek,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Hata: $err')),
      ),
    );
  }
}
