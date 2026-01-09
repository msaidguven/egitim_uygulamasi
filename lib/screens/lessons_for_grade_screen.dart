// lib/screens/lessons_for_grade_screen.dart

import 'package:egitim_uygulamasi/screens/units_for_lesson_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LessonsForGradeScreen extends StatefulWidget {
  final int gradeId;
  final String gradeName;

  const LessonsForGradeScreen({
    super.key,
    required this.gradeId,
    required this.gradeName,
  });

  @override
  State<LessonsForGradeScreen> createState() =>
      _LessonsForGradeScreenState();
}

class _LessonsForGradeScreenState extends State<LessonsForGradeScreen> {
  final _supabase = Supabase.instance.client;
  late final Future<List<Map<String, dynamic>>> _lessonsFuture;

  @override
  void initState() {
    super.initState();
    _lessonsFuture = _fetchLessonsForGrade();
  }

  Future<List<Map<String, dynamic>>> _fetchLessonsForGrade() async {
    try {
      final response = await _supabase.rpc(
        'get_lessons_for_grade',
        params: {'grade_id_param': widget.gradeId},
      );
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Dersler çekilirken hata: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.gradeName} - Dersler'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _lessonsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Bu sınıfa ait ders bulunamadı.'));
          }

          final lessons = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
            itemCount: lessons.length,
            itemBuilder: (context, index) {
              final lesson = lessons[index];
              final questionCount = lesson['question_count'] ?? 0;

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
                    child: const Icon(Icons.book_outlined),
                  ),
                  title: Text(
                    lesson['name'],
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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UnitsForLessonScreen(
                          gradeId: widget.gradeId,
                          lessonId: lesson['id'],
                          lessonName: lesson['name'],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
