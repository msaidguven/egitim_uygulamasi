// lib/screens/questions_for_unit_screen_silinecek.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuestionsForUnitScreen extends StatefulWidget {
  final int unitId;
  final String unitTitle;

  const QuestionsForUnitScreen({
    super.key,
    required this.unitId,
    required this.unitTitle,
  });

  @override
  State<QuestionsForUnitScreen> createState() => _QuestionsForUnitScreenState();
}

class _QuestionsForUnitScreenState extends State<QuestionsForUnitScreen> {
  final _supabase = Supabase.instance.client;
  late final Future<List<Map<String, dynamic>>> _questionsFuture;

  @override
  void initState() {
    super.initState();
    _questionsFuture = _fetchQuestionsForUnit();
  }

  Future<List<Map<String, dynamic>>> _fetchQuestionsForUnit() async {
    try {
      final response = await _supabase.rpc(
        'get_questions_for_unit',
        params: {'unit_id_param': widget.unitId},
      );
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Üniteye ait sorular çekilirken hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sorular yüklenirken bir hata oluştu.')),
        );
      }
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.unitTitle),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _questionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Bu üniteye ait soru bulunamadı.'));
          }

          final questions = snapshot.data!;

          return ListView.builder(
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final question = questions[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(question['question_text'] ?? 'Soru metni yok'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
