/*

// lib/screens/tests_screen_silinecek.dart

import 'package:egitim_uygulamasi/screens/lessons_for_grade_screen_silinecek.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TestsScreen extends StatefulWidget {
  const TestsScreen({super.key});

  @override
  State<TestsScreen> createState() => _TestsScreenState();
}

class _TestsScreenState extends State<TestsScreen> {
  final _supabase = Supabase.instance.client;
  late final Future<List<Map<String, dynamic>>> _gradesFuture;

  @override
  void initState() {
    super.initState();
    _gradesFuture = _fetchGrades();
  }

  Future<List<Map<String, dynamic>>> _fetchGrades() async {
    try {
      // SORGUNU GÜNCELLE: question_count sütununu da seç
      final response = await _supabase
          .from('grades')
          .select('id, name, question_count') // question_count eklendi
          .eq('is_active', true)
          .order('order_no', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Sınıflar çekilirken hata: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Testler - Sınıf Seçimi'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _gradesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aktif sınıf bulunamadı.'));
          }

          final grades = snapshot.data!;

          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 1.0,
            ),
            itemCount: grades.length,
            itemBuilder: (context, index) {
              final grade = grades[index];
              // question_count verisini al (null ise 0 kabul et)
              final questionCount = grade['question_count'] ?? 0;
              final color = Colors.primaries[index % Colors.primaries.length].shade700;

              return Card(
                elevation: 4.0,
                color: color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LessonsForGradeScreen(
                          gradeId: grade['id'],
                          gradeName: grade['name'],
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.school, size: 50, color: Colors.white),
                      const SizedBox(height: 12),
                      Text(
                        grade['name'],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // ARAYÜZÜ GÜNCELLE: Soru sayısını göster
                      Text(
                        '$questionCount Soru',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
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

*/
