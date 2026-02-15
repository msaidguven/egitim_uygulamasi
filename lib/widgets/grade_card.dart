// lib/widgets/grade_card.dart

import 'package:egitim_uygulamasi/models/grade_model.dart';
import 'package:egitim_uygulamasi/screens/home/widgets/pressable_card.dart';
import 'package:flutter/material.dart';

enum GradeCardVariant { standard, compact }

class GradeCard extends StatelessWidget {
  final Grade grade;
  final int index;
  final VoidCallback onTap;
  final GradeCardVariant variant;

  const GradeCard({
    super.key,
    required this.grade,
    required this.index,
    required this.onTap,
    this.variant = GradeCardVariant.standard,
  });

  @override
  Widget build(BuildContext context) {
    if (variant == GradeCardVariant.compact) {
      return _buildCompactCard(context);
    }

    final colors = _getGradientColor(index);

    return PressableCard(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.first.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background Pattern
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              left: -30,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon with background
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getIconForGrade(index),
                      color: Colors.white,
                      size: 26,
                    ),
                  ),

                  const Spacer(),

                  // Grade Name
                  Text(
                    grade.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Action Button
                  Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'Derslere Git',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Shine Effect
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.3),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCard(BuildContext context) {
    final gradients = [
      [const Color(0xFF1E88E5), const Color(0xFF4FC3F7)],
      [const Color(0xFFFF7043), const Color(0xFFFFB74D)],
      [const Color(0xFF26A69A), const Color(0xFF66BB6A)],
      [const Color(0xFF5C6BC0), const Color(0xFF42A5F5)],
      [const Color(0xFFEC407A), const Color(0xFFFF8A80)],
      [const Color(0xFF8D6E63), const Color(0xFFFFB74D)],
      [const Color(0xFF7CB342), const Color(0xFFAED581)],
      [const Color(0xFF29B6F6), const Color(0xFF26C6DA)],
    ];

    final gradient = gradients[index % gradients.length];

    return PressableCard(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              gradient[0].withValues(alpha: 0.96),
              gradient[1].withValues(alpha: 0.94),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 9),
            ),
          ],
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -24,
              right: -20,
              child: Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.18),
                ),
              ),
            ),
            Positioned(
              bottom: -28,
              left: -16,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.13),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    _getIconForCompact(index),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      grade.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.24),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Derslere git',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 5),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getGradientColor(int index) {
    final gradients = [
      [const Color(0xFF667EEA), const Color(0xFF764BA2)],
      [const Color(0xFFF093FB), const Color(0xFFF5576C)],
      [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
      [const Color(0xFF43E97B), const Color(0xFF38F9D7)],
      [const Color(0xFFFA709A), const Color(0xFFFEE140)],
      [const Color(0xFF30CFD0), const Color(0xFF330867)],
      [const Color(0xFFA8EDEA), const Color(0xFFFED6E3)],
      [const Color(0xFF5EE7DF), const Color(0xFFB490CA)],
    ];

    return gradients[index % gradients.length];
  }

  IconData _getIconForCompact(int index) {
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

  IconData _getIconForGrade(int index) {
    final icons = [
      Icons.school_rounded,
      Icons.book_rounded,
      Icons.auto_stories_rounded,
      Icons.cast_for_education_rounded,
      Icons.menu_book_rounded,
      Icons.science_rounded,
      Icons.calculate_rounded,
      Icons.language_rounded,
    ];

    return icons[index % icons.length];
  }
}
