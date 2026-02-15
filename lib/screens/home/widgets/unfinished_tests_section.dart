// lib/screens/home/widgets/unfinished_tests_section.dart

import 'package:egitim_uygulamasi/features/test/data/models/test_question.dart';
import 'package:egitim_uygulamasi/features/test/data/models/test_session.dart';
import 'package:egitim_uygulamasi/features/test/presentation/views/questions_screen.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class UnfinishedTestsSection extends StatelessWidget {
  final List<TestSession>? unfinishedSessions;
  final bool isLoading;
  final VoidCallback onRefresh;

  const UnfinishedTestsSection({
    super.key,
    this.unfinishedSessions,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (unfinishedSessions == null || unfinishedSessions!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(),
        const SizedBox(height: 16),
        _buildTestsList(context),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Icon(Icons.pending_outlined, color: Colors.grey.shade900, size: 22),
        const SizedBox(width: 12),
        Text(
          'Yarım Kalan Testler',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade900,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            itemBuilder: (context, index) {
              return Shimmer.fromColors(
                baseColor: Colors.grey.shade200,
                highlightColor: Colors.grey.shade50,
                child: Container(
                  width: 180,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildTestsList(BuildContext context) {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: unfinishedSessions!.length,
        itemBuilder: (context, index) {
          final session = unfinishedSessions![index];
          return _buildTestCard(context, session);
        },
      ),
    );
  }

  Widget _buildTestCard(BuildContext context, TestSession session) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _resumeTest(context, session),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFFFFF), Color(0xFFF5F8FF)],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2F6FE4).withValues(alpha: 0.1),
                  blurRadius: 13,
                  offset: const Offset(0, 7),
                ),
              ],
              border: Border.all(color: const Color(0xFFD8E6FF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (session.unitId == null || session.unitId == 0)
                          ? 'Tüm Dersler'
                          : (session.lessonName ?? 'Ders'),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (session.unitId == null || session.unitId == 0)
                          ? 'Genel Tekrar'
                          : (session.unitName ?? 'Ünite'),
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade900,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Devam Et',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: const Color(0xFF2F6FE4),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2F6FE4).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Color(0xFF2F6FE4),
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _resumeTest(BuildContext context, TestSession session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionsScreen(
          unitId: session.unitId ?? 0,
          sessionId: session.id,
          testMode: (session.unitId == null || session.unitId == 0)
              ? TestMode.srs
              : TestMode.normal,
        ),
      ),
    ).then((_) {
      onRefresh();
    });
  }
}
