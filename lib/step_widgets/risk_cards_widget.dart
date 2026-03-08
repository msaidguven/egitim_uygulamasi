import 'package:flutter/material.dart';
import 'package:egitim_uygulamasi/models/lesson_step_model.dart';

class RiskCardsWidget extends StatefulWidget {
  final LessonStepModel step;
  final VoidCallback onCompleted;
  final bool isCompleted;

  const RiskCardsWidget({
    super.key,
    required this.step,
    required this.onCompleted,
    required this.isCompleted,
  });

  @override
  State<RiskCardsWidget> createState() => _RiskCardsWidgetState();
}

class _RiskCardsWidgetState extends State<RiskCardsWidget> {
  final Set<int> _opened = {};

  @override
  Widget build(BuildContext context) {
    final items = (widget.step.content['items'] as List<dynamic>? ??
            widget.step.content['cases'] as List<dynamic>? ??
            const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();

    final done = widget.isCompleted || (items.isNotEmpty && _opened.length == items.length);
    if (done && !widget.isCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onCompleted());
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length + 1,
      itemBuilder: (_, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(widget.step.title, style: Theme.of(context).textTheme.titleLarge),
          );
        }

        final i = index - 1;
        final item = items[i];
        final opened = _opened.contains(i);
        final title = (item['text'] ?? item['title'] ?? '').toString();
        final detail = (item['example'] ?? item['description'] ?? item['lesson'] ?? '').toString();

        return Card(
          child: ExpansionTile(
            onExpansionChanged: (_) => setState(() => _opened.add(i)),
            title: Text(title),
            children: [
              if (detail.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text(detail),
                ),
              if (!opened)
                const SizedBox.shrink(),
            ],
          ),
        );
      },
    );
  }
}
