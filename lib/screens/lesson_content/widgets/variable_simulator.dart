import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'common/lesson_step_card.dart';

class VariableSimulatorStep extends StatefulWidget {
  final Map<String, dynamic> step;
  final bool isActive;
  final ValueChanged<int> onSolved;

  const VariableSimulatorStep({
    super.key,
    required this.step,
    required this.isActive,
    required this.onSolved,
  });

  @override
  State<VariableSimulatorStep> createState() => _VariableSimulatorStepState();
}

class _VariableSimulatorStepState extends State<VariableSimulatorStep> {
  double sourceDistance = 50;
  double objectDistance = 50;
  double sourceSize = 50;
  double objectSize = 50;
  int _wrongAttempts = 0;
  String? _hint;

  double get _shadowSize {
    final raw =
        (sourceSize * 0.7 + objectSize * 1.1) *
        (1 + (100 - sourceDistance) / 120) *
        (1 + objectDistance / 180);
    return raw.clamp(10, 100);
  }

  void _checkGoal() {
    final target =
        (widget.step['targetRange'] as List?)
            ?.map((e) => (e as num).toDouble())
            .toList() ??
        const <double>[45, 60];
    final min = target.isNotEmpty ? target.first : 45;
    final max = target.length > 1 ? target[1] : 60;

    if (_shadowSize >= min && _shadowSize <= max) {
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
      badge: widget.step['badge']?.toString() ?? 'Simulasyon',
      title: widget.step['title']?.toString(),
      subtitle: widget.step['instruction']?.toString(),
      helperText: widget.step['helper']?.toString(),
      footer: widget.isActive
          ? SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _checkGoal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  widget.step['buttonText']?.toString() ?? 'Degeri Kilitle',
                ),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SliderTile(
            label: 'Isik kaynagi-cisim mesafesi',
            value: sourceDistance,
            onChanged: widget.isActive
                ? (v) => setState(() => sourceDistance = v)
                : null,
          ),
          _SliderTile(
            label: 'Cisim-ekran mesafesi',
            value: objectDistance,
            onChanged: widget.isActive
                ? (v) => setState(() => objectDistance = v)
                : null,
          ),
          _SliderTile(
            label: 'Isik kaynagi boyutu',
            value: sourceSize,
            onChanged: widget.isActive
                ? (v) => setState(() => sourceSize = v)
                : null,
          ),
          _SliderTile(
            label: 'Cisim boyutu',
            value: objectSize,
            onChanged: widget.isActive
                ? (v) => setState(() => objectSize = v)
                : null,
          ),
          const SizedBox(height: 8),
          const Text('Anlik golge boyu'),
          const SizedBox(height: 6),
          Container(
            height: 14,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _shadowSize / 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF334155)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text('Golge boyu skoru: ${_shadowSize.toStringAsFixed(1)}'),
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
    ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.08, end: 0);
  }
}

class _SliderTile extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double>? onChanged;

  const _SliderTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        Slider(value: value, max: 100, onChanged: onChanged),
      ],
    );
  }
}
