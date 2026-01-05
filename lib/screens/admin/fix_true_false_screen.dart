import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Basit bir model, RPC'den dönen veriyi tutmak için.
class UnconfiguredQuestion {
  final int id;
  final String text;

  UnconfiguredQuestion({required this.id, required this.text});

  factory UnconfiguredQuestion.fromJson(Map<String, dynamic> json) {
    return UnconfiguredQuestion(
      id: json['id'] as int,
      text: json['question_text'] as String,
    );
  }
}

class FixTrueFalseScreen extends StatefulWidget {
  const FixTrueFalseScreen({super.key});

  @override
  State<FixTrueFalseScreen> createState() => _FixTrueFalseScreenState();
}

class _FixTrueFalseScreenState extends State<FixTrueFalseScreen> {
  late Future<List<UnconfiguredQuestion>> _questionsFuture;

  @override
  void initState() {
    super.initState();
    _questionsFuture = _fetchUnconfiguredQuestions();
  }

  // Veritabanından bozuk soruları çeken fonksiyon.
  Future<List<UnconfiguredQuestion>> _fetchUnconfiguredQuestions() async {
    try {
      final response = await Supabase.instance.client.rpc('get_unconfigured_true_false_questions');
      final List<dynamic> data = response;
      return data.map((json) => UnconfiguredQuestion.fromJson(json)).toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sorular yüklenirken hata: $e'), backgroundColor: Colors.red),
        );
      }
      return [];
    }
  }

  // Bir soruyu düzelten ve listeyi yenileyen fonksiyon.
  Future<void> _fixQuestion(int questionId, bool isTrueCorrect) async {
    try {
      await Supabase.instance.client.rpc(
        'fix_true_false_question',
        params: {
          'p_question_id': questionId,
          'p_is_true_correct': isTrueCorrect,
        },
      );
      
      // Başarılı olursa listeyi yenile
      setState(() {
        _questionsFuture = _fetchUnconfiguredQuestions();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Soru #$questionId başarıyla düzeltildi.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Soru düzeltilirken hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bozuk D/Y Sorularını Düzelt'),
      ),
      body: FutureBuilder<List<UnconfiguredQuestion>>(
        future: _questionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
                  SizedBox(height: 16),
                  Text('Düzeltilecek soru bulunamadı!', style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          }

          final questions = snapshot.data!;

          return ListView.builder(
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final question = questions[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ID: ${question.id}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        question.text,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const Divider(height: 24),
                      Text(
                        'Doğru Cevap Hangisi?',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ElevatedButton(
                            onPressed: () => _fixQuestion(question.id, true),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600),
                            child: const Text('Doğru'),
                          ),
                          ElevatedButton(
                            onPressed: () => _fixQuestion(question.id, false),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
                            child: const Text('Yanlış'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
