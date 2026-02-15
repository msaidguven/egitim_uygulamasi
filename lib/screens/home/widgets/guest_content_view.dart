// lib/screens/home/widgets/guest_content_view.dart

import 'package:egitim_uygulamasi/models/grade_model.dart';
import 'package:egitim_uygulamasi/screens/home/widgets/common_widgets.dart';
import 'package:egitim_uygulamasi/widgets/grade_card.dart';
import 'package:egitim_uygulamasi/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:egitim_uygulamasi/screens/lessons_screen.dart';

class GuestContentView extends StatelessWidget {
  final List<Grade> grades;

  const GuestContentView({super.key, required this.grades});

  @override
  Widget build(BuildContext context) {
    final classesAnchorKey = GlobalKey();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GuestWelcomeCard(
          onTapLogin: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
          onTapExploreClasses: () {
            final targetContext = classesAnchorKey.currentContext;
            if (targetContext == null) return;
            Scrollable.ensureVisible(
              targetContext,
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutCubic,
              alignment: 0.05,
            );
          },
        ),
        const SizedBox(height: 18),
        Container(
          key: classesAnchorKey,
          child: const SectionHeader(
            title: 'Sınıflar',
            icon: Icons.folder_outlined,
          ),
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    LessonsScreen(grade: grade),
                              ),
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LessonsScreen(grade: grade),
                        ),
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

class _GuestWelcomeCard extends StatelessWidget {
  final VoidCallback onTapLogin;
  final VoidCallback onTapExploreClasses;

  const _GuestWelcomeCard({
    required this.onTapLogin,
    required this.onTapExploreClasses,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2F6FE4), Color(0xFF4F8BFF), Color(0xFF34D399)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F6FE4).withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -18,
            right: -10,
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
          ),
          Positioned(
            bottom: -24,
            left: -14,
            child: Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.auto_awesome_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Hoş Geldin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Sınıfını seç, dersleri keşfet, mini testlerle puanını artır.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip('Renkli Ders Kartları'),
                  _chip('Mini Testler'),
                  _chip('Haftalık Plan'),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: onTapLogin,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1D4ED8),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.login_rounded, size: 16),
                    label: const Text(
                      'Giriş Yap / Kayıt Ol',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onTapExploreClasses,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.explore_rounded, size: 16),
                    label: const Text(
                      'Sınıf Seç',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
