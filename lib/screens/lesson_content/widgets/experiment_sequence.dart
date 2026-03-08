import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'common/lesson_step_card.dart';

class ExperimentSequenceStep extends StatefulWidget {
  final Map<String, dynamic> step;
  final bool isActive;
  final VoidCallback onComplete;

  const ExperimentSequenceStep({
    super.key,
    required this.step,
    required this.isActive,
    required this.onComplete,
  });

  @override
  State<ExperimentSequenceStep> createState() => _ExperimentSequenceStepState();
}

class _ExperimentSequenceStepState extends State<ExperimentSequenceStep> {
  late List<Map<String, dynamic>> _order;
  bool _showError = false;

  List<String> get _correctOrder =>
      (widget.step['correctOrder'] as List?)
          ?.map((e) => e.toString())
          .toList() ??
      const <String>[];

  @override
  void initState() {
    super.initState();
    _order =
        (widget.step['cards'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        <Map<String, dynamic>>[];
  }

  bool get _isCorrect {
    if (_order.length != _correctOrder.length) return false;
    for (var i = 0; i < _correctOrder.length; i++) {
      if ((_order[i]['id']?.toString() ?? '') != _correctOrder[i]) {
        return false;
      }
    }
    return true;
  }

  IconData _iconFromName(String name) {
    switch (name) {
      case 'flashlight_on':
        return Icons.flashlight_on_rounded;
      case 'straighten':
        return Icons.straighten_rounded;
      case 'wall':
        return Icons.crop_16_9_rounded;
      case 'visibility':
        return Icons.visibility_rounded;
      default:
        return Icons.science_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LessonStepCard(
      badge: widget.step['badge']?.toString() ?? 'Deney Simulasyonu',
      title: widget.step['title']?.toString(),
      subtitle: widget.step['instruction']?.toString(),
      helperText: widget.step['helper']?.toString(),
      footer: widget.isActive
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: () {
                    if (_isCorrect) {
                      widget.onComplete();
                      return;
                    }
                    setState(() => _showError = true);
                  },
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
                        'Deney Sirasini Onayla',
                  ),
                ),
                if (_showError)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      widget.step['hint']?.toString() ??
                          'Sirayi tekrar duzenle.',
                      style: const TextStyle(
                        color: Color(0xFFB45309),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            )
          : null,
      child: ReorderableListView.builder(
        shrinkWrap: true,
        buildDefaultDragHandles: false,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _order.length,
        onReorder: widget.isActive
            ? (oldIndex, newIndex) {
                setState(() {
                  _showError = false;
                  if (newIndex > oldIndex) newIndex -= 1;
                  final moved = _order.removeAt(oldIndex);
                  _order.insert(newIndex, moved);
                });
              }
            : (oldIndex, newIndex) {},
        itemBuilder: (context, index) {
          final card = _order[index];
          final iconName = card['icon']?.toString() ?? 'science';
          return Container(
            key: ValueKey(card['id']?.toString() ?? '$index'),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEEF2FF), Color(0xFFF8FAFC)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFC7D2FE)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  child: Icon(_iconFromName(iconName), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card['title']?.toString() ?? '',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        card['detail']?.toString() ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
                ReorderableDragStartListener(
                  index: index,
                  enabled: widget.isActive,
                  child: const Icon(
                    Icons.drag_indicator_rounded,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.08, end: 0);
  }
}
