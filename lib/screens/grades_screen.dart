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

    if (_viewModel.grades.isEmpty) {
      return const Center(child: Text('Gösterilecek sınıf bulunamadı.'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Yan yana 2 kart
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 1.0, // Kare kartlar
      ),
      itemCount: _viewModel.grades.length,
      itemBuilder: (context, index) {
        final grade = _viewModel.grades[index];
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
                  builder: (context) => LessonsScreen(grade: grade),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.school, size: 50, color: Colors.white),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    grade.name,
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
