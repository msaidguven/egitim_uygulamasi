import 'package:flutter/material.dart';
import 'package:egitim_uygulamasi/models/lesson_step_model.dart';

class ConceptCardsWidget extends StatefulWidget {
  final LessonStepModel step;
  final VoidCallback onCompleted;
  final bool isCompleted;

  const ConceptCardsWidget({
    super.key,
    required this.step,
    required this.onCompleted,
    required this.isCompleted,
  });

  @override
  State<ConceptCardsWidget> createState() => _ConceptCardsWidgetState();
}

class _ConceptCardsWidgetState extends State<ConceptCardsWidget> {
  final Set<int> _opened = {};

  @override
  Widget build(BuildContext context) {
    final items = (widget.step.content['items'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();
    final done = widget.isCompleted || (items.isNotEmpty && _opened.length == items.length);

    if (done && !widget.isCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onCompleted());
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.step.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 260,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemBuilder: (_, i) {
                final item = items[i];
                final open = _opened.contains(i);
                return InkWell(
                  onTap: () => setState(() => _opened.add(i)),
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text((item['icon'] ?? '📘').toString(), style: const TextStyle(fontSize: 24)),
                          const SizedBox(height: 8),
                          Text((item['title'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(open ? (item['description'] ?? '').toString() : 'Tap to reveal'),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
