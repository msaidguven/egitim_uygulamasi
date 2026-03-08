import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'common/lesson_step_card.dart';

class MicroReviewStep extends StatefulWidget {
  final Map<String, dynamic> step;
  final bool isActive;
  final List<Map<String, dynamic>> questions;
  final ValueChanged<int> onSolved;

  const MicroReviewStep({
    super.key,
    required this.step,
    required this.isActive,
    required this.questions,
    required this.onSolved,
  });

  @override
  State<MicroReviewStep> createState() => _MicroReviewStepState();
}

class _MicroReviewStepState extends State<MicroReviewStep> {
  int _index = 0;
  int _wrongAttempts = 0;
  String? _hint;

  bool get _done => _index >= widget.questions.length;

  void _answer(String selected) {
    if (_done || !widget.isActive) return;
    final q = widget.questions[_index];
    final correct = q['correct']?.toString();
    if (selected == correct) {
      setState(() {
        _index += 1;
        _hint = null;
      });
      if (_index >= widget.questions.length) {
        widget.onSolved(_wrongAttempts);
      }
      return;
    }

    final hints =
        (q['hints'] as List?)?.map((e) => e.toString()).toList() ??
        const <String>[];
    setState(() {
      _wrongAttempts += 1;
      if (hints.isNotEmpty) {
        final idx = math.min(_wrongAttempts - 1, hints.length - 1);
        _hint = hints[idx];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return LessonStepCard(
        badge: widget.step['badge']?.toString() ?? 'Mikro Tekrar',
        title: widget.step['title']?.toString(),
        subtitle: 'Bu ders icin tekrar karti yok.',
        footer: widget.isActive
            ? SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => widget.onSolved(0),
                  child: const Text('Devam Et'),
                ),
              )
            : null,
        child: const SizedBox.shrink(),
      );
    }

    final q = widget.questions[_index];
    final options =
        (q['options'] as List?)?.map((e) => e.toString()).toList() ??
        const <String>[];

    return LessonStepCard(
      badge: widget.step['badge']?.toString() ?? 'Mikro Tekrar',
      title: widget.step['title']?.toString(),
      subtitle: '${_index + 1} / ${widget.questions.length}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            q['question']?.toString() ?? '',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options
                .map(
                  (o) => ChoiceChip(
                    label: Text(o),
                    selected: false,
                    onSelected: widget.isActive ? (_) => _answer(o) : null,
                  ),
                )
                .toList(),
          ),
          if (_hint != null) ...[
            const SizedBox(height: 8),
            Text(
              'Ipucu: $_hint',
              style: const TextStyle(
                color: Color(0xFFB45309),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
