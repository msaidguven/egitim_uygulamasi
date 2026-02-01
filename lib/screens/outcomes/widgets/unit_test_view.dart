import 'package:flutter/material.dart';
import 'package:egitim_uygulamasi/screens/unit_summary_screen.dart';

class UnitTestView extends StatelessWidget {
  final Map<String, dynamic> unitSummary;
  final int unitId;

  const UnitTestView({
    Key? key,
    required this.unitSummary,
    required this.unitId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final totalQuestions = unitSummary['total_questions'] ?? 0;
    final uniqueSolved = unitSummary['unique_solved_count'] ?? 0;
    final progress = totalQuestions > 0 ? uniqueSolved / totalQuestions : 0.0;
    final clampedProgress = progress.clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.deepPurple.shade50, Colors.blue.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepPurple.shade100, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.military_tech_rounded,
              size: 40,
              color: Colors.deepPurple.shade600,
            ),
            const SizedBox(height: 16),
            Text(
              'Ünite Bitiş Çizgisi',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.deepPurple.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tebrikler! Bu ünitenin sonuna geldin. Genel bir tekrar yapmaya ne dersin?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.deepPurple.shade700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ünite İlerlemen',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.deepPurple.shade600,
                  ),
                ),
                Text(
                  '$uniqueSolved / $totalQuestions Soru',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: clampedProgress,
              backgroundColor: Colors.deepPurple.shade100,
              color: Colors.deepPurple,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UnitSummaryScreen(unitId: unitId),
                    ),
                  );
                },
                icon: const Icon(Icons.quiz_rounded),
                label: const Text('Genel Ünite Testine Git'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
