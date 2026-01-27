import 'package:egitim_uygulamasi/models/grade_model.dart';
import 'package:egitim_uygulamasi/models/lesson_model.dart';
import 'package:egitim_uygulamasi/models/unit_model.dart';
import 'package:egitim_uygulamasi/screens/unit_detail_screen.dart';
import 'package:egitim_uygulamasi/services/unit_service.dart';
import 'package:flutter/material.dart';

class UnitsScreen extends StatefulWidget {
  final Grade grade;
  final Lesson lesson;

  const UnitsScreen({super.key, required this.grade, required this.lesson});

  @override
  State<UnitsScreen> createState() => _UnitsScreenState();
}

class _UnitsScreenState extends State<UnitsScreen> {
  Future<List<Unit>>? _unitsFuture;
  final UnitService _unitService = UnitService();

  @override
  void initState() {
    super.initState();
    _unitsFuture = _unitService.getUnitsForGradeAndLesson(widget.grade.id, widget.lesson.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.lesson.name)),
      body: FutureBuilder<List<Unit>>(
        future: _unitsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Bu derse ait ünite bulunamadı.'));
          }

          final units = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: units.length,
            itemBuilder: (context, index) {
              final unit = units[index];
              return Card(
                child: ListTile(
                  title: Text(unit.title),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UnitDetailScreen(unit: unit),
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
