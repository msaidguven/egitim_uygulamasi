import 'package:flutter/material.dart';
import 'package:egitim_uygulamasi/models/lesson_step_model.dart';

class CertificateWidget extends StatelessWidget {
  final LessonStepModel step;
  final VoidCallback onCompleted;

  const CertificateWidget({
    super.key,
    required this.step,
    required this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final requirements = (step.content['requirements'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => e.toString())
        .toList();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('🏆', style: TextStyle(fontSize: 54)),
              const SizedBox(height: 8),
              Text(step.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text((step.content['description'] ?? '').toString(), textAlign: TextAlign.center),
              if (requirements.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...requirements.map((r) => Align(alignment: Alignment.centerLeft, child: Text('• $r'))),
              ],
              const SizedBox(height: 16),
              FilledButton(onPressed: onCompleted, child: const Text('Finish')),
            ]),
          ),
        ),
      ),
    );
  }
}
