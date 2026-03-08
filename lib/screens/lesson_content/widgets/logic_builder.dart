import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'common/lesson_step_card.dart';

class LogicBuilderStep extends StatefulWidget {
  final Map<String, dynamic> step;
  final bool isActive;
  final VoidCallback onComplete;

  const LogicBuilderStep({
    super.key,
    required this.step,
    required this.isActive,
    required this.onComplete,
  });

  @override
  State<LogicBuilderStep> createState() => _LogicBuilderStepState();
}

class _LogicBuilderStepState extends State<LogicBuilderStep> {
  final Map<int, String> _answers = {};
  bool _completed = false;

  List<Map<String, dynamic>> get _rows =>
      (widget.step['rows'] as List?)
          ?.whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList() ??
      const <Map<String, dynamic>>[];

  bool _isRowCorrect(int index) {
    final correct = _rows[index]['correct']?.toString();
    final selected = _answers[index];
    return correct != null && selected == correct;
  }

  bool get _allCorrect {
    if (_rows.isEmpty) return false;
    for (var i = 0; i < _rows.length; i++) {
      if (!_isRowCorrect(i)) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return LessonStepCard(
      badge: widget.step['badge']?.toString() ?? 'Mantik Oyunu',
      title: widget.step['title']?.toString(),
      subtitle: widget.step['instruction']?.toString(),
      footer: widget.isActive
          ? SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _allCorrect
                    ? () {
                        if (_completed) return;
                        setState(() => _completed = true);
                        widget.onComplete();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  widget.step['buttonText']?.toString() ??
                      'Mantik Zincirini Tamamla',
                ),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _rows.length; i++) ...[
            _LogicRow(
              row: _rows[i],
              selected: _answers[i],
              enabled: widget.isActive,
              onSelect: (value) {
                setState(() {
                  _answers[i] = value;
                });
              },
            ),
            const SizedBox(height: 12),
          ],
          if (_answers.isNotEmpty && !_allCorrect)
            const Text(
              'Ipuclari takip ederek secenekleri duzelt.',
              style: TextStyle(
                color: Color(0xFFB45309),
                fontWeight: FontWeight.w600,
              ),
            ),
          if (_allCorrect)
            const Text(
              'Mukemmel. Sebep-sonuc zinciri tamamlandi.',
              style: TextStyle(
                color: Color(0xFF166534),
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.08, end: 0);
  }
}

class _LogicRow extends StatelessWidget {
  final Map<String, dynamic> row;
  final String? selected;
  final bool enabled;
  final ValueChanged<String> onSelect;

  const _LogicRow({
    required this.row,
    required this.selected,
    required this.enabled,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final prefix = row['prefix']?.toString() ?? '';
    final suffix = row['suffix']?.toString() ?? '';
    final options =
        (row['options'] as List?)?.map((e) => e.toString()).toList() ??
        const <String>[];
    final correct = row['correct']?.toString();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(
                color: Color(0xFF1E293B),
                height: 1.5,
                fontSize: 15,
              ),
              children: [
                TextSpan(text: prefix),
                TextSpan(
                  text: selected == null ? ' [sec] ' : ' $selected ',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: selected == null
                        ? const Color(0xFF64748B)
                        : (selected == correct
                              ? const Color(0xFF166534)
                              : const Color(0xFFB91C1C)),
                  ),
                ),
                TextSpan(text: suffix),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options
                .map(
                  (option) => ChoiceChip(
                    label: Text(option),
                    selected: selected == option,
                    onSelected: enabled ? (_) => onSelect(option) : null,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
