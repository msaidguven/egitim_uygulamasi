import 'package:flutter/material.dart';
import 'package:egitim_uygulamasi/models/lesson_step_model.dart';

class SecurityScoreWidget extends StatefulWidget {
  final LessonStepModel step;
  final VoidCallback onCompleted;
  final bool isCompleted;

  const SecurityScoreWidget({
    super.key,
    required this.step,
    required this.onCompleted,
    required this.isCompleted,
  });

  @override
  State<SecurityScoreWidget> createState() => _SecurityScoreWidgetState();
}

class _SecurityScoreWidgetState extends State<SecurityScoreWidget> {
  final Set<int> _selected = {};
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    final items = (widget.step.content['items'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();

    final total = _selected.fold<int>(0, (acc, i) {
      final points = (items[i]['points'] as num?)?.toInt() ?? 0;
      return acc + points;
    });

    if (_submitted && !widget.isCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onCompleted());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(widget.step.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        ...List.generate(items.length, (i) {
          final item = items[i];
          return CheckboxListTile(
            value: _selected.contains(i),
            onChanged: _submitted
                ? null
                : (_) => setState(() {
                      if (_selected.contains(i)) {
                        _selected.remove(i);
                      } else {
                        _selected.add(i);
                      }
                    }),
            title: Text('${item['icon'] ?? '•'} ${(item['text'] ?? '').toString()}'),
            subtitle: Text('+${(item['points'] ?? 0)} points'),
          );
        }),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _submitted ? null : () => setState(() => _submitted = true),
          child: const Text('Calculate Score'),
        ),
        if (_submitted) ...[
          const SizedBox(height: 10),
          Card(child: Padding(padding: const EdgeInsets.all(12), child: Text('Your score: $total'))),
        ],
      ],
    );
  }
}
