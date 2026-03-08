import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'common/lesson_step_card.dart';

class ErrorHuntStep extends StatefulWidget {
  final Map<String, dynamic> step;
  final bool isActive;
  final ValueChanged<int> onSolved;

  const ErrorHuntStep({
    super.key,
    required this.step,
    required this.isActive,
    required this.onSolved,
  });

  @override
  State<ErrorHuntStep> createState() => _ErrorHuntStepState();
}

class _ErrorHuntStepState extends State<ErrorHuntStep> {
  final Set<String> _selected = {};
  int _wrongAttempts = 0;
  String? _hint;

  List<Map<String, dynamic>> get _items =>
      (widget.step['items'] as List?)
          ?.whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList() ??
      const <Map<String, dynamic>>[];

  void _check() {
    final errorIds = _items
        .where((e) => e['isError'] == true)
        .map((e) => e['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();

    if (_selected.length == errorIds.length &&
        _selected.containsAll(errorIds)) {
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
      badge: widget.step['badge']?.toString() ?? 'Hata Avi',
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
                  widget.step['buttonText']?.toString() ?? 'Hatalari Onayla',
                ),
              ),
            )
          : null,
      child: Column(
        children: [
          for (final item in _items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: widget.isActive
                    ? () {
                        final id = item['id']?.toString() ?? '';
                        if (id.isEmpty) return;
                        setState(() {
                          if (_selected.contains(id)) {
                            _selected.remove(id);
                          } else {
                            _selected.add(id);
                          }
                        });
                      }
                    : null,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _selected.contains(item['id'])
                        ? const Color(0xFFFFF1F2)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selected.contains(item['id'])
                          ? const Color(0xFFF43F5E)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Text(item['label']?.toString() ?? ''),
                ),
              ),
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
