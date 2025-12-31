import 'package:egitim_uygulamasi/screens/outcomes_screen.dart';
import 'package:egitim_uygulamasi/models/lesson_model.dart';
import 'package:egitim_uygulamasi/models/grade_model.dart';
import 'package:egitim_uygulamasi/viewmodels/lesson_viewmodel.dart';
import 'package:flutter/material.dart';

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
    // Hata düzeltildi: Metod artık String (name) yerine int (id) bekliyor.
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
      body: _buildLessonList(),
    );
  }

  Widget _buildLessonList() {
    if (_viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_viewModel.errorMessage != null) {
      return Center(child: Text('Hata: ${_viewModel.errorMessage}'));
    }

    if (_viewModel.lessons.isEmpty) {
      return const Center(child: Text('Gösterilecek ders bulunamadı.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _viewModel.lessons.length,
      itemBuilder: (context, index) {
        final lesson = _viewModel.lessons[index];
        return Card(
          child: ListTile(
            // Hata düzeltildi: lesson.icon yerine varsayılan ikon kullanılıyor.
            leading: const Icon(Icons.class_),
            title: Text(lesson.name),
            // Hata düzeltildi: lesson.description alanı kaldırıldı.
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
          ),
        );
      },
    );
  }

  /// Ders ikonunu güvenli bir şekilde oluşturan yardımcı metot.
  Widget _buildLessonIcon(String? iconData) {
    if (iconData != null) {
      final codePoint = int.tryParse(iconData);
      if (codePoint != null) {
        return Icon(IconData(codePoint, fontFamily: 'MaterialIcons'));
      }
    }
    // Eğer ikon verisi yoksa veya geçersizse varsayılan ikonu döndür.
    return const Icon(Icons.class_);
  }
}
