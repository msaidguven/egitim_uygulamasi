import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'common/lesson_step_card.dart';

class MemoryGridStep extends StatefulWidget {
  final Map<String, dynamic> step;
  final bool isActive;
  final ValueChanged<int> onSolved;

  const MemoryGridStep({
    super.key,
    required this.step,
    required this.isActive,
    required this.onSolved,
  });

  @override
  State<MemoryGridStep> createState() => _MemoryGridStepState();
}

class _MemoryGridStepState extends State<MemoryGridStep> {
  late List<_MemoryCard> _cards;
  int _wrongAttempts = 0;
  String? _hint;
  int? _firstIndex;

  @override
  void initState() {
    super.initState();
    final pairs =
        (widget.step['pairs'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        <Map<String, dynamic>>[];

    _cards = [];
    for (final p in pairs) {
      final id = p['id']?.toString() ?? p['left']?.toString() ?? 'p';
      _cards.add(_MemoryCard(pairId: id, label: p['left']?.toString() ?? ''));
      _cards.add(_MemoryCard(pairId: id, label: p['right']?.toString() ?? ''));
    }
    _cards.shuffle();
  }

  bool get _allMatched => _cards.every((c) => c.matched);

  Future<void> _tapCard(int index) async {
    if (!widget.isActive) return;
    if (_cards[index].matched || _cards[index].revealed) return;

    setState(() {
      _cards[index] = _cards[index].copyWith(revealed: true);
    });

    if (_firstIndex == null) {
      _firstIndex = index;
      return;
    }

    final first = _cards[_firstIndex!];
    final second = _cards[index];

    if (first.pairId == second.pairId) {
      setState(() {
        _cards[_firstIndex!] = _cards[_firstIndex!].copyWith(matched: true);
        _cards[index] = _cards[index].copyWith(matched: true);
      });
      _firstIndex = null;
      if (_allMatched) {
        widget.onSolved(_wrongAttempts);
      }
      return;
    }

    final hints =
        (widget.step['hints'] as List?)?.map((e) => e.toString()).toList() ??
        const <String>[];

    _wrongAttempts += 1;
    if (hints.isNotEmpty) {
      _hint = hints[math.min(_wrongAttempts - 1, hints.length - 1)];
    }

    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    setState(() {
      _cards[_firstIndex!] = _cards[_firstIndex!].copyWith(revealed: false);
      _cards[index] = _cards[index].copyWith(revealed: false);
      _firstIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LessonStepCard(
      badge: widget.step['badge']?.toString() ?? 'Hafiza Oyunu',
      title: widget.step['title']?.toString(),
      subtitle: widget.step['instruction']?.toString(),
      helperText: widget.step['helper']?.toString(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _cards.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.35,
            ),
            itemBuilder: (context, index) {
              final c = _cards[index];
              final visible = c.revealed || c.matched;
              return GestureDetector(
                onTap: () => _tapCard(index),
                child: Container(
                  decoration: BoxDecoration(
                    color: visible
                        ? const Color(0xFFEEF2FF)
                        : const Color(0xFF4F46E5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    visible ? c.label : '?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: visible ? const Color(0xFF1E293B) : Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );
            },
          ),
          if (_hint != null) ...[
            const SizedBox(height: 10),
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
    ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.08, end: 0);
  }
}

class _MemoryCard {
  final String pairId;
  final String label;
  final bool revealed;
  final bool matched;

  const _MemoryCard({
    required this.pairId,
    required this.label,
    this.revealed = false,
    this.matched = false,
  });

  _MemoryCard copyWith({bool? revealed, bool? matched}) {
    return _MemoryCard(
      pairId: pairId,
      label: label,
      revealed: revealed ?? this.revealed,
      matched: matched ?? this.matched,
    );
  }
}
