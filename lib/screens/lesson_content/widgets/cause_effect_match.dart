import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'common/lesson_step_card.dart';

class CauseEffectMatchStep extends StatefulWidget {
  final Map<String, dynamic> step;
  final bool isActive;
  final ValueChanged<int> onSolved;

  const CauseEffectMatchStep({
    super.key,
    required this.step,
    required this.isActive,
    required this.onSolved,
  });

  @override
  State<CauseEffectMatchStep> createState() => _CauseEffectMatchStepState();
}

class _CauseEffectMatchStepState extends State<CauseEffectMatchStep> {
  final Map<String, String> _assignments = {};
  int _wrongAttempts = 0;
  String? _hint;

  List<Map<String, dynamic>> get _pairs =>
      (widget.step['pairs'] as List?)
          ?.whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList() ??
      const <Map<String, dynamic>>[];

  List<String> get _causes =>
      _pairs.map((e) => e['cause']?.toString() ?? '').toList();

  List<String> get _effects =>
      _pairs.map((e) => e['effect']?.toString() ?? '').toList();

  void _check() {
    var ok = true;
    for (final pair in _pairs) {
      final effect = pair['effect']?.toString() ?? '';
      final cause = pair['cause']?.toString() ?? '';
      if (_assignments[effect] != cause) {
        ok = false;
        break;
      }
    }
    if (ok) {
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
      badge: widget.step['badge']?.toString() ?? 'Neden-Sonuc',
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
                  widget.step['buttonText']?.toString() ??
                      'Eslestirmeyi Onayla',
                ),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Neden kartlari'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _causes
                .map(
                  (cause) => Draggable<String>(
                    data: cause,
                    feedback: Material(
                      color: Colors.transparent,
                      child: Chip(label: Text(cause)),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.3,
                      child: Chip(label: Text(cause)),
                    ),
                    child: Chip(label: Text(cause)),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          const Text('Sonuc alanlari'),
          const SizedBox(height: 8),
          for (final effect in _effects)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: DragTarget<String>(
                onAcceptWithDetails: widget.isActive
                    ? (details) {
                        setState(() {
                          _assignments[effect] = details.data;
                        });
                      }
                    : null,
                builder: (context, candidateData, rejectedData) {
                  final selected = _assignments[effect];
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: candidateData.isNotEmpty
                          ? const Color(0xFFEEF2FF)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          effect,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          selected == null
                              ? 'Nedeni buraya birak'
                              : 'Neden: $selected',
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          if (_hint != null)
            Text(
              'Ipucu: $_hint',
              style: const TextStyle(
                color: Color(0xFFB45309),
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0);
  }
}
