import 'package:flutter/material.dart';
import 'package:egitim_uygulamasi/models/lesson_step_model.dart';

class IntroStepWidget extends StatelessWidget {
  final LessonStepModel step;
  final VoidCallback onCompleted;

  const IntroStepWidget({
    super.key,
    required this.step,
    required this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final text = (step.content['text'] ?? '').toString();
    final funFact = (step.content['fun_fact'] ?? '').toString();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(step.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(text),
          if (funFact.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text('💡 $funFact'),
              ),
            ),
          ],
          const Spacer(),
          FilledButton(onPressed: onCompleted, child: const Text('Got it')),
        ],
      ),
    );
  }
}
