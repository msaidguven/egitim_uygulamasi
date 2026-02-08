// lib/screens/home/widgets/guest_content_view.dart

import 'package:egitim_uygulamasi/models/grade_model.dart';
import 'package:egitim_uygulamasi/screens/home/widgets/common_widgets.dart';
import 'package:egitim_uygulamasi/widgets/grade_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class GuestContentView extends StatelessWidget {
  final List<Grade> grades;

  const GuestContentView({
    super.key,
    required this.grades,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Sınıflar',
          icon: Icons.folder_outlined,
        ),
        const SizedBox(height: 16),
        if (grades.isEmpty)
          const EmptyState()
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              if (kIsWeb) {
                int crossAxisCount;
                double childAspectRatio;

                if (maxWidth >= 1100) {
                  crossAxisCount = 4;
                  childAspectRatio = 1.05;
                } else if (maxWidth >= 800) {
                  crossAxisCount = 3;
                  childAspectRatio = 0.95;
                } else {
                  crossAxisCount = 2;
                  childAspectRatio = 0.9;
                }

                return Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: childAspectRatio,
                      ),
                      itemCount: grades.length,
                      itemBuilder: (context, index) {
                        final grade = grades[index];
                        return GradeCard(
                          grade: grade,
                          index: index,
                          variant: GradeCardVariant.standard,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/lessons',
                              arguments: grade,
                            );
                          },
                        );
                      },
                    ),
                  ),
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.0,
                ),
                itemCount: grades.length,
                itemBuilder: (context, index) {
                  final grade = grades[index];
                  return GradeCard(
                    grade: grade,
                    index: index,
                    variant: GradeCardVariant.compact,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/lessons',
                        arguments: grade,
                      );
                    },
                  );
                },
              );
            },
          ),
      ],
    );
  }
}
