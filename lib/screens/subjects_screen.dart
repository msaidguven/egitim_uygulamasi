// lib/screens/subjects_screen.dart

import 'package:egitim_uygulamasi/models/grade_model.dart';
import 'package:egitim_uygulamasi/viewmodels/subject_viewmodel.dart';
import 'package:flutter/material.dart';

class SubjectsScreen extends StatefulWidget {
  final Grade grade;
  const SubjectsScreen({super.key, required this.grade});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  final SubjectViewModel _viewModel = SubjectViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(() {
      if (mounted) setState(() {});
    });
    _viewModel.fetchSubjectsByGrade(widget.grade.id);
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
      body: _buildSubjectList(),
    );
  }

  Widget _buildSubjectList() {
    if (_viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_viewModel.errorMessage != null) {
      return Center(child: Text('Hata: ${_viewModel.errorMessage}'));
    }

    if (_viewModel.subjects.isEmpty) {
      return const Center(child: Text('Bu sınıfa ait ders bulunamadı.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _viewModel.subjects.length,
      itemBuilder: (context, index) {
        final subject = _viewModel.subjects[index];
        return Card(
          child: ListTile(
            // İkon verisi varsa göster, yoksa varsayılan bir ikon göster
            leading: subject.icon != null
                ? Icon(
                    IconData(
                      int.parse(subject.icon!),
                      fontFamily: 'MaterialIcons',
                    ),
                  )
                : const Icon(Icons.class_),
            title: Text(subject.name),
            subtitle: subject.description != null
                ? Text(subject.description!)
                : null,
          ),
        );
      },
    );
  }
}
