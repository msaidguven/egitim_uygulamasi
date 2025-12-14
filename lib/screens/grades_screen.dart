// lib/screens/grades_screen.dart

import 'package:egitim_uygulamasi/widgets/common/content_renderer.dart';
import 'package:egitim_uygulamasi/screens/lessons_screen.dart';
import 'package:egitim_uygulamasi/viewmodels/grade_viewmodel.dart';
import 'package:flutter/material.dart';

class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  final GradeViewModel _viewModel = GradeViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(() {
      if (mounted) setState(() {});
    });
    _viewModel.fetchGrades();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sınıflar')),
      body: _buildGradeList(),
    );
  }

  Widget _buildGradeList() {
    if (_viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_viewModel.errorMessage != null) {
      return Center(child: Text('Hata: ${_viewModel.errorMessage}'));
    }

    if (_viewModel.grades.isEmpty) {
      return const Center(child: Text('Gösterilecek sınıf bulunamadı.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _viewModel.grades.length,
      itemBuilder: (context, index) {
        final grade = _viewModel.grades[index];
        return Card(
          child: ListTile(
            title: ContentRenderer(content: grade.name),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  // LessonsScreen'e seçilen sınıf bilgisini iletiyoruz.
                  builder: (context) => LessonsScreen(grade: grade),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
