import 'package:egitim_uygulamasi/screens/outcomes_screen.dart';
import 'package:egitim_uygulamasi/models/lesson_model.dart';
import 'package:egitim_uygulamasi/models/grade_model.dart';
import 'package:egitim_uygulamasi/viewmodels/lesson_viewmodel.dart';
import 'package:flutter/material.dart';

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

class LessonsScreen extends StatefulWidget {
  final Grade grade;
  const LessonsScreen({super.key, required this.grade});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  final LessonViewModel _viewModel = LessonViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(() {
      if (mounted) setState(() {});
    });
    _viewModel.fetchLessonsForGrade(widget.grade.id!);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.grade.name} Dersleri')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_viewModel.errorMessage != null) {
      return Center(child: Text('Hata: ${_viewModel.errorMessage}'));
    }

    if (_viewModel.lessons.isEmpty) {
      return const Center(child: Text('Gösterilecek ders bulunamadı.'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 1.0,
      ),
      itemCount: _viewModel.lessons.length,
      itemBuilder: (context, index) {
        final lesson = _viewModel.lessons[index];
        final color = Colors.primaries[(index + 2) % Colors.primaries.length].shade700;
        final icon = _getIconFromString(lesson.icon);

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
                  builder: (context) => OutcomesScreen(
                    gradeId: widget.grade.id!,
                    lessonId: lesson.id,
                    gradeName: widget.grade.name,
                    lessonName: lesson.name,
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    lesson.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
