// lib/screens/home/widgets/guest_content_view.dart

import 'package:egitim_uygulamasi/models/grade_model.dart';
import 'package:egitim_uygulamasi/screens/home/widgets/common_widgets.dart';
import 'package:egitim_uygulamasi/screens/lessons_screen.dart';
import 'package:flutter/material.dart';

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
          GridView.builder(
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
              return _buildGradeCard(context, grade, index);
            },
          ),
      ],
    );
  }

  Widget _buildGradeCard(BuildContext context, Grade grade, int index) {
    // Renk paleti - Daha canlı ve modern renkler
    final List<List<Color>> gradients = [
      [const Color(0xFF6366F1), const Color(0xFF8B5CF6)], // Indigo -> Violet
      [const Color(0xFFEC4899), const Color(0xFFF43F5E)], // Pink -> Rose
      [const Color(0xFF10B981), const Color(0xFF059669)], // Emerald -> Green
      [const Color(0xFFF59E0B), const Color(0xFFD97706)], // Amber -> Orange
      [const Color(0xFF3B82F6), const Color(0xFF2563EB)], // Blue -> Blue Dark
      [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)], // Violet -> Purple
      [const Color(0xFFEF4444), const Color(0xFFDC2626)], // Red -> Red Dark
      [const Color(0xFF06B6D4), const Color(0xFF0891B2)], // Cyan -> Cyan Dark
    ];

    final gradient = gradients[index % gradients.length];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LessonsScreen(grade: grade),
            ),
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: gradient[0].withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: gradient[0].withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _getIconForGrade(index),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    grade.name,
                    style: TextStyle(
                      color: Colors.grey.shade900,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Derslere git',
                        style: TextStyle(
                          color: gradient[0],
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: gradient[0],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForGrade(int index) {
    final icons = [
      Icons.school_rounded,
      Icons.menu_book_rounded,
      Icons.auto_stories_rounded,
      Icons.cast_for_education_rounded,
      Icons.library_books_rounded,
      Icons.science_rounded,
      Icons.calculate_rounded,
      Icons.language_rounded,
    ];
    return icons[index % icons.length];
  }
}
