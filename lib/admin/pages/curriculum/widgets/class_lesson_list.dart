import 'package:egitim_uygulamasi/models/grade_with_lessons_model.dart';
import 'package:egitim_uygulamasi/services/curriculum_service.dart';
import 'package:flutter/material.dart';

class ClassLessonList extends StatefulWidget {
  final Function(int gradeId, int lessonId, String lessonName) onLessonSelected;

  const ClassLessonList({
    super.key,
    required this.onLessonSelected,
  });

  @override
  State<ClassLessonList> createState() => _ClassLessonListState();
}

class _ClassLessonListState extends State<ClassLessonList> {
  final CurriculumService _curriculumService = CurriculumService();
  Future<List<GradeWithLessons>>? _gradesAndLessonsFuture;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _gradesAndLessonsFuture = _curriculumService.getGradesWithLessons();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<GradeWithLessons>>(
      future: _gradesAndLessonsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Hata: ${snapshot.error}'),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Sınıf ve ders bulunamadı.'));
        }

        final gradesWithLessons = snapshot.data!;

        return Material(
          child: RefreshIndicator(
            onRefresh: _fetchData,
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: gradesWithLessons.length,
              itemBuilder: (context, index) {
                final item = gradesWithLessons[index];
                return Card(
                  elevation: 1.0,
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ExpansionTile(
                    key: PageStorageKey('grade_${item.grade.id}'),
                    title: Text(
                      item.grade.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    initiallyExpanded: true, // Keep all tiles expanded
                    childrenPadding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
                    children: item.lessons.map((lesson) {
                      return ListTile(
                        title: Text(lesson.name),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        onTap: () => widget.onLessonSelected(item.grade.id, lesson.id, lesson.name),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
