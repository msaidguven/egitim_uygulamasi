import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'common/lesson_step_card.dart';

class TimelineBuilderStep extends StatefulWidget {
  final Map<String, dynamic> step;
  final bool isActive;
  final ValueChanged<int> onSolved;

  const TimelineBuilderStep({
    super.key,
    required this.step,
    required this.isActive,
    required this.onSolved,
  });

  @override
  State<TimelineBuilderStep> createState() => _TimelineBuilderStepState();
}

class _TimelineBuilderStepState extends State<TimelineBuilderStep> {
  late List<Map<String, dynamic>> _items;
  int _wrongAttempts = 0;
  String? _hint;

  @override
  void initState() {
    super.initState();
    _items =
        (widget.step['items'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        <Map<String, dynamic>>[];
  }

  bool get _isCorrect {
    final correct =
        (widget.step['correctOrder'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];
    if (_items.length != correct.length) return false;
    for (var i = 0; i < correct.length; i++) {
      if ((_items[i]['id']?.toString() ?? '') != correct[i]) return false;
    }
    return true;
  }

  void _check() {
    if (_isCorrect) {
      widget.onSolved(_wrongAttempts);
      return;
    }
    final hints =
        (widget.step['hints'] as List?)?.map((e) => e.toString()).toList() ??
        const <String>[];
    setState(() {
      _wrongAttempts += 1;
      if (hints.isNotEmpty) {
        _hint = hints[math.min(_wrongAttempts - 1, hints.length - 1)];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LessonStepCard(
      badge: widget.step['badge']?.toString() ?? 'Zaman Seridi',
      title: widget.step['title']?.toString(),
      subtitle: widget.step['instruction']?.toString(),
      helperText: widget.step['helper']?.toString(),
      footer: widget.isActive
          ? SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _check,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  widget.step['buttonText']?.toString() ?? 'Siralamayi Onayla',
                ),
              ),
            )
          : null,
      child: Column(
        children: [
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              return Container(
                key: ValueKey(item['id']?.toString() ?? '$index'),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: const Color(0xFFEEF2FF),
                      child: Text('${index + 1}'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item['label']?.toString() ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    ReorderableDragStartListener(
                      index: index,
                      enabled: widget.isActive,
                      child: const Icon(Icons.drag_handle_rounded),
                    ),
                  ],
                ),
              );
            },
            onReorder: widget.isActive
                ? (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final moved = _items.removeAt(oldIndex);
                      _items.insert(newIndex, moved);
                    });
                  }
                : (oldIndex, newIndex) {},
          ),
          if (_hint != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Ipucu: $_hint',
                style: const TextStyle(
                  color: Color(0xFFB45309),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0);
  }
}
