import 'package:flutter/material.dart';
import 'package:egitim_uygulamasi/models/lesson_step_model.dart';

class SummaryWidget extends StatelessWidget {
  final LessonStepModel step;
  final VoidCallback onCompleted;

  const SummaryWidget({
    super.key,
    required this.step,
    required this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final bullets = (step.content['points'] as List<dynamic>? ??
            step.content['items'] as List<dynamic>? ??
            const <dynamic>[])
        .map((e) => e.toString())
        .toList();

    final text = (step.content['text'] ?? step.content['description'] ?? '').toString();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(step.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (text.isNotEmpty) Text(text),
        if (bullets.isNotEmpty) ...[
          const SizedBox(height: 10),
          ...bullets.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('• $b'),
              )),
        ],
        const Spacer(),
        FilledButton(onPressed: onCompleted, child: const Text('Continue')),
      ]),
    );
  }
}
