import 'package:egitim_uygulamasi/screens/outcomes_screen.dart';
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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      itemCount: _viewModel.lessons.length,
      itemBuilder: (context, index) {
        final lesson = _viewModel.lessons[index];

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
              lesson.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
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
}
