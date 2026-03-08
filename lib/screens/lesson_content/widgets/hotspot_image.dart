import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'common/lesson_step_card.dart';

class HotspotImageStep extends StatefulWidget {
  final Map<String, dynamic> step;
  final bool isActive;
  final ValueChanged<int> onSolved;

  const HotspotImageStep({
    super.key,
    required this.step,
    required this.isActive,
    required this.onSolved,
  });

  @override
  State<HotspotImageStep> createState() => _HotspotImageStepState();
}

class _HotspotImageStepState extends State<HotspotImageStep> {
  int _wrongAttempts = 0;
  String? _hint;
  bool _completed = false;

  List<Map<String, dynamic>> get _hotspots =>
      (widget.step['hotspots'] as List?)
          ?.whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList() ??
      const <Map<String, dynamic>>[];

  void _onTapHotspot(Map<String, dynamic> hotspot) {
    if (!widget.isActive || _completed) return;
    final isCorrect = hotspot['correct'] == true;
    if (isCorrect) {
      setState(() {
        _completed = true;
        _hint = null;
      });
      Future.delayed(const Duration(milliseconds: 320), () {
        widget.onSolved(_wrongAttempts);
      });
      return;
    }

    final hints =
        (widget.step['hints'] as List?)?.map((e) => e.toString()).toList() ??
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
    final imageAsset = widget.step['imageAsset']?.toString();

    return LessonStepCard(
      badge: widget.step['badge']?.toString() ?? 'Hotspot Gorevi',
      title: widget.step['title']?.toString(),
      subtitle: widget.step['instruction']?.toString(),
      helperText: widget.step['helper']?.toString(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = width * 0.58;
              return Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFC7D2FE)),
                  color: const Color(0xFFEFF6FF),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: imageAsset == null
                            ? _PlaceholderDiagram(step: widget.step)
                            : Image.asset(
                                imageAsset,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _PlaceholderDiagram(step: widget.step);
                                },
                              ),
                      ),
                    ),
                    for (final hotspot in _hotspots)
                      Positioned(
                        left:
                            width *
                                ((hotspot['x'] as num?)?.toDouble() ?? 0.5) -
                            (((hotspot['radius'] as num?)?.toDouble() ?? 18)),
                        top:
                            height *
                                ((hotspot['y'] as num?)?.toDouble() ?? 0.5) -
                            (((hotspot['radius'] as num?)?.toDouble() ?? 18)),
                        child: GestureDetector(
                          onTap: () => _onTapHotspot(hotspot),
                          child: Container(
                            width:
                                (((hotspot['radius'] as num?)?.toDouble() ??
                                    18) *
                                2),
                            height:
                                (((hotspot['radius'] as num?)?.toDouble() ??
                                    18) *
                                2),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF4F46E5,
                              ).withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF4F46E5),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.touch_app_rounded,
                              size: 18,
                              color: Color(0xFF312E81),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          if (_hint != null)
            Text(
              'Ipucu: $_hint',
              style: const TextStyle(
                color: Color(0xFFB45309),
                fontWeight: FontWeight.w700,
              ),
            ),
          if (_completed)
            const Text(
              'Dogru bolge!',
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

class _PlaceholderDiagram extends StatelessWidget {
  final Map<String, dynamic> step;

  const _PlaceholderDiagram({required this.step});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFDBEAFE), Color(0xFFEDE9FE)],
        ),
      ),
      child: Center(
        child: Text(
          step['placeholderLabel']?.toString() ?? 'Diyagram',
          style: const TextStyle(
            color: Color(0xFF1E3A8A),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
