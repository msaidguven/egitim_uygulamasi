// lib/screens/lessons_for_grade_screen.dart

import 'package:egitim_uygulamasi/screens/units_for_lesson_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// İkon isimlerini Flutter ikonlarına çevirmek için bir yardımcı map
const Map<String, IconData> _iconMap = {
  'calculate': Icons.calculate,
  'science': Icons.science,
  'book': Icons.book,
  'translate': Icons.translate,
  'history_edu': Icons.history_edu,
  'public': Icons.public,
  'church': Icons.church,
  // Diğer ikonları buraya ekleyebilirsiniz
};

IconData _getIconFromString(String? iconName) {
  if (iconName == null) return Icons.class_; // Varsayılan ikon
  return _iconMap[iconName] ?? Icons.class_;
}

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
      // Bu RPC'nin artık question_count döndürdüğünü varsayıyoruz.
      final response = await _supabase.rpc(
        'get_lessons_for_grade',
        params: {'grade_id_param': widget.gradeId},
      );
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Derse ait dersler çekilirken hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dersler yüklenirken bir hata oluştu.')),
        );
      }
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

          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 1.0,
            ),
            itemCount: lessons.length,
            itemBuilder: (context, index) {
              final lesson = lessons[index];
              final questionCount = lesson['question_count'] ?? 0; // Veriyi al
              final color = Colors.primaries[(index + 2) % Colors.primaries.length].shade700;
              final icon = _getIconFromString(lesson['icon']);

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
                        builder: (context) => UnitsForLessonScreen(
                          gradeId: widget.gradeId,
                          lessonId: lesson['id'],
                          lessonName: lesson['name'],
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 50, color: Colors.white),
                      const SizedBox(height: 12),
                      Text(
                        lesson['name'],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Soru sayısını göster
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
