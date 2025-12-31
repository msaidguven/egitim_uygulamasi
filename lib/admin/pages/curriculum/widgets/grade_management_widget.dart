import 'package:egitim_uygulamasi/models/grade_model.dart';
import 'package:egitim_uygulamasi/services/grade_service.dart';
import 'package:flutter/material.dart';

class GradeManagementWidget extends StatefulWidget {
  const GradeManagementWidget({super.key});

  @override
  State<GradeManagementWidget> createState() => _GradeManagementWidgetState();
}

class _GradeManagementWidgetState extends State<GradeManagementWidget> {
  final GradeService _gradeService = GradeService();
  late Future<List<Grade>> _gradesFuture;

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  void _loadGrades() {
    setState(() {
      _gradesFuture = _gradeService.getGrades();
    });
  }

  Future<void> _toggleGradeStatus(Grade grade, bool isActive) async {
    try {
      await _gradeService.updateGradeStatus(grade.id, isActive);
      _loadGrades(); // Refresh the list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${grade.name} durumu güncellendi.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, st) {
      debugPrint('Sınıf durumu güncellenirken hata oluştu: $e');
      debugPrint('Stack Trace: $st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Grade>>(
      future: _gradesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Sınıf bulunamadı.'));
        }

        final grades = snapshot.data!;

        return ListView.builder(
          itemCount: grades.length,
          itemBuilder: (context, index) {
            final grade = grades[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(grade.name),
                trailing: Switch(
                  value: grade.isActive,
                  onChanged: (value) {
                    _toggleGradeStatus(grade, value);
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
