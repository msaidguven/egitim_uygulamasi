import 'package:flutter/material.dart';
import 'package:egitim_uygulamasi/models/lesson_step_model.dart';

class ScenarioChoiceWidget extends StatefulWidget {
  final LessonStepModel step;
  final VoidCallback onCompleted;
  final bool isCompleted;

  const ScenarioChoiceWidget({
    super.key,
    required this.step,
    required this.onCompleted,
    required this.isCompleted,
  });

  @override
  State<ScenarioChoiceWidget> createState() => _ScenarioChoiceWidgetState();
}

class _ScenarioChoiceWidgetState extends State<ScenarioChoiceWidget> {
  int? _selected;
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    final options = (widget.step.content['options'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => e.toString())
        .toList();
    final correct = (widget.step.content['correct_index'] ?? widget.step.content['correct'] ?? -1) as int;

    final correctSelected = _selected != null && _selected == correct;
    if (_checked && correctSelected && !widget.isCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onCompleted());
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.step.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text((widget.step.content['context'] ?? widget.step.content['question'] ?? '').toString()),
        const SizedBox(height: 12),
        ...List.generate(options.length, (i) {
          Color border = Colors.grey.shade300;
          if (_checked && i == correct) border = Colors.green;
          if (_checked && i == _selected && i != correct) border = Colors.red;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              onPressed: _checked ? null : () => setState(() => _selected = i),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: border, width: 1.6),
                alignment: Alignment.centerLeft,
              ),
              child: Text(options[i]),
            ),
          );
        }),
        const SizedBox(height: 8),
        if (!_checked)
          FilledButton(
            onPressed: _selected == null ? null : () => setState(() => _checked = true),
            child: const Text('Check answer'),
          ),
        if (_checked)
          Card(
            color: correctSelected ? Colors.green.shade50 : Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Text((widget.step.content['explanation'] ?? '').toString()),
            ),
          ),
      ]),
    );
  }
}
