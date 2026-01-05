// lib/screens/units_for_lesson_screen.dart

import 'package:egitim_uygulamasi/screens/questions_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UnitsForLessonScreen extends StatefulWidget {
  final int gradeId;
  final int lessonId;
  final String lessonName;

  const UnitsForLessonScreen({
    super.key,
    required this.gradeId,
    required this.lessonId,
    required this.lessonName,
  });

  @override
  State<UnitsForLessonScreen> createState() => _UnitsForLessonScreenState();
}

class _UnitsForLessonScreenState extends State<UnitsForLessonScreen> {
  final _supabase = Supabase.instance.client;
  late final Future<List<Map<String, dynamic>>> _unitsFuture;

  @override
  void initState() {
    super.initState();
    _unitsFuture = _fetchUnitsForLesson();
  }

  Future<List<Map<String, dynamic>>> _fetchUnitsForLesson() async {
    try {
      final response = await _supabase.rpc(
        'get_units_for_lesson_and_grade',
        params: {
          'lesson_id_param': widget.lessonId,
          'grade_id_param': widget.gradeId,
        },
      );
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Üniteler çekilirken hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Üniteler yüklenirken bir hata oluştu.')),
        );
      }
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.lessonName} - Üniteler'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _unitsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Bu derse ait ünite bulunamadı.'));
          }

          final units = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
            itemCount: units.length,
            itemBuilder: (context, index) {
              final unit = units[index];
              final questionCount = unit['question_count'] ?? 0;

              return Card(
                elevation: 2.0,
                margin: const EdgeInsets.symmetric(vertical: 6.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    foregroundColor: Theme.of(context).primaryColor,
                    child: const Icon(Icons.library_books_outlined),
                  ),
                  title: Text(
                    unit['title'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: Text(
                    '$questionCount Soru',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  onTap: questionCount > 0 ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UnitTestsScreen(
                          unitId: unit['id'],
                          unitTitle: unit['title'],
                          questionCount: questionCount,
                        ),
                      ),
                    );
                  } : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class UnitTestsScreen extends StatelessWidget {
  final int unitId;
  final String unitTitle;
  final int questionCount;
  final int questionsPerTest = 10;

  const UnitTestsScreen({
    super.key,
    required this.unitId,
    required this.unitTitle,
    required this.questionCount,
  });

  @override
  Widget build(BuildContext context) {
    final totalTests = (questionCount / questionsPerTest).ceil();

    return Scaffold(
      appBar: AppBar(
        title: Text('$unitTitle - Testler'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.8,
          ),
          itemCount: totalTests,
          itemBuilder: (context, index) {
            final testNumber = index + 1;
            return ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuestionsScreen(
                      unitId: unitId, // DÜZELTME: Artık unitId gönderiyoruz
                      testNumber: testNumber,
                      questionsPerTest: questionsPerTest,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                foregroundColor: Theme.of(context).primaryColor,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
              ),
              child: Text('Test $testNumber'),
            );
          },
        ),
      ),
    );
  }
}
