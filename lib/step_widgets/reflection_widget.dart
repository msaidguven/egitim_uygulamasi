import 'package:flutter/material.dart';
import 'package:egitim_uygulamasi/models/lesson_step_model.dart';

class ReflectionWidget extends StatefulWidget {
  final LessonStepModel step;
  final VoidCallback onCompleted;
  final bool isCompleted;

  const ReflectionWidget({
    super.key,
    required this.step,
    required this.onCompleted,
    required this.isCompleted,
  });

  @override
  State<ReflectionWidget> createState() => _ReflectionWidgetState();
}

class _ReflectionWidgetState extends State<ReflectionWidget> {
  final Set<int> _checked = {};

  @override
  Widget build(BuildContext context) {
    final questions = (widget.step.content['questions'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => e.toString())
        .toList();

    final done = questions.isNotEmpty && _checked.length == questions.length;
    if (done && !widget.isCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onCompleted());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(widget.step.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text((widget.step.content['prompt'] ?? '').toString()),
        const SizedBox(height: 10),
        ...List.generate(questions.length, (i) {
          return CheckboxListTile(
            value: _checked.contains(i),
            onChanged: (_) => setState(() {
              if (_checked.contains(i)) {
                _checked.remove(i);
              } else {
                _checked.add(i);
              }
            }),
            title: Text(questions[i]),
          );
        }),
        if ((widget.step.content['note'] ?? '').toString().isNotEmpty)
          Card(child: Padding(padding: const EdgeInsets.all(12), child: Text((widget.step.content['note'] ?? '').toString()))),
      ],
    );
  }
}
