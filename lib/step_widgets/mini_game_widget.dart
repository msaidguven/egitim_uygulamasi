import 'package:flutter/material.dart';
import 'package:egitim_uygulamasi/models/lesson_step_model.dart';

class MiniGameWidget extends StatefulWidget {
  final LessonStepModel step;
  final VoidCallback onCompleted;
  final bool isCompleted;

  const MiniGameWidget({
    super.key,
    required this.step,
    required this.onCompleted,
    required this.isCompleted,
  });

  @override
  State<MiniGameWidget> createState() => _MiniGameWidgetState();
}

class _MiniGameWidgetState extends State<MiniGameWidget> {
  final Map<int, bool> _answers = {};
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    final permissions = (widget.step.content['permissions'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();

    final done = _submitted && _answers.length == permissions.length;
    if (done && !widget.isCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onCompleted());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(widget.step.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text((widget.step.content['prompt'] ?? '').toString()),
        const SizedBox(height: 12),
        ...List.generate(permissions.length, (i) {
          final p = permissions[i];
          final current = _answers[i];
          return Card(
            child: ListTile(
              title: Text('${p['icon'] ?? ''} ${p['name'] ?? ''}'),
              subtitle: current == null || !_submitted
                  ? null
                  : Text((p['reason'] ?? '').toString()),
              trailing: Wrap(spacing: 6, children: [
                ChoiceChip(
                  label: const Text('Needed'),
                  selected: current == true,
                  onSelected: _submitted ? null : (_) => setState(() => _answers[i] = true),
                ),
                ChoiceChip(
                  label: const Text('Not needed'),
                  selected: current == false,
                  onSelected: _submitted ? null : (_) => setState(() => _answers[i] = false),
                ),
              ]),
            ),
          );
        }),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _answers.length == permissions.length && !_submitted
              ? () => setState(() => _submitted = true)
              : null,
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
