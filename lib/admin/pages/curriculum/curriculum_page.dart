import 'package:egitim_uygulamasi/admin/admin_router.dart';
import 'package:egitim_uygulamasi/admin/pages/curriculum/widgets/filtered_unit_list.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'widgets/class_lesson_list.dart';
import 'widgets/grade_management_widget.dart';

class CurriculumPage extends StatefulWidget {
  final String? gradeId;
  final String? lessonId;

  const CurriculumPage({
    super.key,
    this.gradeId,
    this.lessonId,
  });

  @override
  State<CurriculumPage> createState() => _CurriculumPageState();
}

class _CurriculumPageState extends State<CurriculumPage> {
  String? _selectedGradeId;
  String? _selectedLessonId;

  @override
  void initState() {
    super.initState();
    _selectedGradeId = widget.gradeId;
    _selectedLessonId = widget.lessonId;
  }

  @override
  void didUpdateWidget(covariant CurriculumPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.gradeId != oldWidget.gradeId ||
        widget.lessonId != oldWidget.lessonId) {
      setState(() {
        _selectedGradeId = widget.gradeId;
        _selectedLessonId = widget.lessonId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Müfredat Yönetimi'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Müfredat Görüntüleyici'),
              Tab(text: 'Sınıf Yönetimi'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Curriculum Browser Tab
            Row(
              children: [
                // Left Panel
                SizedBox(
                  width: 300,
                  child: ClassLessonList(
                    onLessonSelected: (gradeId, lessonId, lessonName) {
                      setState(() {
                        _selectedGradeId = gradeId.toString();
                        _selectedLessonId = lessonId.toString();
                      });
                      GoRouter.of(context).go(
                        '${AdminRoutes.curriculum}?gradeId=${gradeId.toString()}&lessonId=${lessonId.toString()}',
                      );
                      debugPrint(
                          'Selected: Grade $_selectedGradeId, Lesson $_selectedLessonId ($lessonName)');
                    },
                  ),
                ),
                const VerticalDivider(width: 1, thickness: 1),
                // Right Panel (Placeholder)
                Expanded(
                  child: Center(
                    child: _selectedGradeId == null || _selectedLessonId == null
                        ? const Text('Ders seçin.')
                        : FilteredUnitList(
                            gradeId: _selectedGradeId!,
                            lessonId: _selectedLessonId!,
                          ),
                  ),
                ),
              ],
            ),
            // Grade Management Tab
            const GradeManagementWidget(),
          ],
        ),
      ),
    );
  }
}
