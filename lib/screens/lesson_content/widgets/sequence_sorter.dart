import 'package:flutter/material.dart';

import 'common/lesson_step_card.dart';

class SequenceSorter extends StatefulWidget {
  final Map<String, dynamic> step;
  final bool isActive;
  final VoidCallback onComplete;

  const SequenceSorter({
    super.key,
    required this.step,
    required this.isActive,
    required this.onComplete,
  });

  @override
  State<SequenceSorter> createState() => _SequenceSorterState();
}

class _SequenceSorterState extends State<SequenceSorter> {
  late List<String> currentOrder;

  @override
  void initState() {
    super.initState();
    currentOrder =
        (widget.step['items'] as List?)?.map((e) => e.toString()).toList() ??
        <String>[];
  }

  bool _checkOrder() {
    final correct =
        (widget.step['correctOrder'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];
    if (correct.length != currentOrder.length) return false;
    for (var i = 0; i < correct.length; i++) {
      if (currentOrder[i] != correct[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isCorrect = _checkOrder();

    return LessonStepCard(
      badge: widget.step['badge']?.toString() ?? 'Siralama Gorevi',
      title: widget.step['title']?.toString(),
      subtitle:
          widget.step['question']?.toString() ??
          widget.step['instruction']?.toString(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            children: [
              for (int i = 0; i < currentOrder.length; i++)
                ReorderableDragStartListener(
                  key: ValueKey(currentOrder[i]),
                  index: i,
                  enabled: widget.isActive,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFC7D2FE)),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.drag_handle_rounded,
                        color: Color(0xFF6366F1),
                      ),
                      title: Text(
                        currentOrder[i],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
            ],
            onReorder: (oldIndex, newIndex) {
              if (!widget.isActive) return;
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final item = currentOrder.removeAt(oldIndex);
                currentOrder.insert(newIndex, item);
                if (_checkOrder()) {
                  Future.delayed(
                    const Duration(milliseconds: 800),
                    widget.onComplete,
                  );
                }
              });
            },
          ),
          if (widget.isActive && isCorrect)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Center(
                child: Text(
                  'Mukemmel siralama!',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (widget.step['hint'] != null && widget.isActive && !isCorrect)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Ipucu: ${widget.step['hint']}',
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
