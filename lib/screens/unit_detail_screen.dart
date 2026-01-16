import 'package:egitim_uygulamasi/main.dart';
import 'package:egitim_uygulamasi/models/topic_content.dart';
import 'package:egitim_uygulamasi/models/unit_model.dart';
import 'package:egitim_uygulamasi/screens/weekly_outcomes_screen.dart'; // Yeni ekran
import 'package:egitim_uygulamasi/utils/html_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart' as flutter_html;
import 'package:flutter_html_table/flutter_html_table.dart';

class UnitDetailScreen extends StatefulWidget {
  final Unit unit;
  const UnitDetailScreen({super.key, required this.unit});

  @override
  State<UnitDetailScreen> createState() => _UnitDetailScreenState();
}

class _UnitDetailScreenState extends State<UnitDetailScreen> {
  Future<List<Map<String, dynamic>>>? _topicsFuture;

  @override
  void initState() {
    super.initState();
    _topicsFuture = _fetchTopicsAndContents();
  }

  // Bu fonksiyon aynı kalabilir, sadece konuları listelemek için kullanılıyor.
  Future<List<Map<String, dynamic>>> _fetchTopicsAndContents() async {
    final topicsResponse = await supabase
        .from('topics')
        .select('id, title, order_no')
        .eq('unit_id', widget.unit.id)
        .eq('is_active', true)
        .eq('order_status', 'approved')
        .order('order_no');

    if (topicsResponse.isEmpty) {
      return [];
    }

    final contentsResponse = await supabase
        .from('topic_contents')
        .select('*')
        .inFilter('topic_id', topicsResponse.map((t) => t['id']).toList())
        .order('order_no');

    final Map<int, List<Map<String, dynamic>>> contentsByTopic = {};
    for (final c in contentsResponse) {
      contentsByTopic.putIfAbsent(c['topic_id'], () => []);
      contentsByTopic[c['topic_id']]!.add(c);
    }

    final List<Map<String, dynamic>> topicsWithContent = [];
    for (final topic in topicsResponse) {
      topicsWithContent.add({
        ...topic,
        'contents': contentsByTopic[topic['id']] ?? [],
      });
    }

    return topicsWithContent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.unit.title)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _topicsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Bu üniteye ait konu bulunamadı.'));
          }

          final topics = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: topics.length,
            itemBuilder: (context, index) {
              final topic = topics[index];
              final contents = (topic['contents'] as List)
                  .map((c) => TopicContent.fromJson(c))
                  .toList();

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                clipBehavior: Clip.antiAlias,
                child: ExpansionTile(
                  title: Text(
                    topic['title'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.fitness_center),
                          label: const Text('Alıştırma Yap'),
                          onPressed: () {
                            // Yeni ekrana yönlendir
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WeeklyOutcomesScreen(
                                  topicId: topic['id'],
                                  topicTitle: topic['title'],
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  children: contents.map((content) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: flutter_html.Html(
                        data: content.content,
                        extensions: const [TableHtmlExtension()],
                        style: getBaseHtmlStyle(context),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
