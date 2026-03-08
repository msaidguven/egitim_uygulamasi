import 'package:flutter/material.dart';
import 'package:egitim_uygulamasi/models/lesson_step_model.dart';

class RolePlayWidget extends StatefulWidget {
  final LessonStepModel step;
  final VoidCallback onCompleted;
  final bool isCompleted;

  const RolePlayWidget({
    super.key,
    required this.step,
    required this.onCompleted,
    required this.isCompleted,
  });

  @override
  State<RolePlayWidget> createState() => _RolePlayWidgetState();
}

class _RolePlayWidgetState extends State<RolePlayWidget> {
  int? _selected;
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    final choices = (widget.step.content['choices'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();

    if (_confirmed && _selected != null && !widget.isCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onCompleted());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(widget.step.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text((widget.step.content['character'] ?? 'Character').toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text((widget.step.content['scenario'] ?? '').toString()),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(choices.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              onPressed: _confirmed ? null : () => setState(() => _selected = i),
              child: Text((choices[i]['text'] ?? '').toString()),
            ),
          );
        }),
        if (_selected != null && !_confirmed)
          FilledButton(
            onPressed: () => setState(() => _confirmed = true),
            child: const Text('Confirm choice'),
          ),
        if (_confirmed && _selected != null) ...[
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text((choices[_selected!]['feedback'] ?? '').toString()),
            ),
          ),
        ],
      ],
    );
  }
}
