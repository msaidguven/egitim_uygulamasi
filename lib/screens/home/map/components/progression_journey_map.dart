import 'dart:math';

import 'package:egitim_uygulamasi/screens/home/map/models/map_progress_models.dart';
import 'package:flutter/material.dart';

enum JourneyStageType { regular, milestone, major }

class JourneyStage {
  final String id;
  final String title;
  final String subtitle;
  final double progress;
  final ConquestState state;
  final JourneyStageType type;
  final TopicNodeData? topic;

  const JourneyStage({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.state,
    required this.type,
    this.topic,
  });
}

class ProgressionJourneyMap extends StatefulWidget {
  const ProgressionJourneyMap({
    super.key,
    required this.stages,
    required this.accent,
    required this.onTapStage,
  });

  final List<JourneyStage> stages;
  final Color accent;
  final ValueChanged<JourneyStage> onTapStage;

  @override
  State<ProgressionJourneyMap> createState() => _ProgressionJourneyMapState();
}

class _ProgressionJourneyMapState extends State<ProgressionJourneyMap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  int _selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
      lowerBound: 0.97,
      upperBound: 1.05,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  int _currentIndex() {
    final progressIdx = widget.stages.indexWhere((s) => s.state == ConquestState.inProgress);
    if (progressIdx != -1) return progressIdx;
    final availableIdx = widget.stages.indexWhere((s) => s.state == ConquestState.notStarted);
    if (availableIdx != -1) return availableIdx;
    return widget.stages.isEmpty ? -1 : widget.stages.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stages.isEmpty) return const SizedBox.shrink();

    final current = _currentIndex();
    const startY = 72.0;
    const stepY = 122.0;
    final points = List<Offset>.generate(widget.stages.length, (index) {
      final shift = switch (index % 4) {
        0 => 0.0,
        1 => -54.0,
        2 => 58.0,
        _ => -20.0,
      };
      return Offset(shift, startY + index * stepY);
    });

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
        ),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 44),
          child: SizedBox(
            height: points.last.dy + 180,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _JourneyPathPainter(
                      points: points,
                      accent: widget.accent,
                      currentIndex: current,
                      selectedIndex: _selectedIndex,
                    ),
                  ),
                ),
                ...List.generate(widget.stages.length, (index) {
                  final p = points[index];
                  final stage = widget.stages[index];

                  return Positioned(
                    top: p.dy,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Transform.translate(
                        offset: Offset(p.dx, 0),
                        child: _StageTile(
                          stage: stage,
                          accent: widget.accent,
                          selected: _selectedIndex == index,
                          pulse: current == index ? _pulse : null,
                          onTap: () {
                            setState(() => _selectedIndex = index);
                            widget.onTapStage(stage);
                          },
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StageTile extends StatelessWidget {
  const _StageTile({
    required this.stage,
    required this.accent,
    required this.selected,
    required this.onTap,
    this.pulse,
  });

  final JourneyStage stage;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;
  final AnimationController? pulse;

  @override
  Widget build(BuildContext context) {
    final locked = stage.state == ConquestState.locked;
    final inProgress = stage.state == ConquestState.inProgress;
    final completed = stage.state == ConquestState.conquered;

    final nodeSize = switch (stage.type) {
      JourneyStageType.regular => 48.0,
      JourneyStageType.milestone => 66.0,
      JourneyStageType.major => 84.0,
    };

    final node = AnimatedScale(
      duration: const Duration(milliseconds: 140),
      scale: selected ? 1.06 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: nodeSize,
          height: nodeSize,
          decoration: _nodeDecoration(stage.type, locked, inProgress, completed),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                _iconFor(stage.type, locked, completed),
                size: nodeSize * 0.34,
                color: locked ? const Color(0xFF94A3B8) : Colors.white,
              ),
              if (inProgress)
                SizedBox(
                  width: nodeSize,
                  height: nodeSize,
                  child: CircularProgressIndicator(
                    value: max(stage.progress, 0.12),
                    strokeWidth: 2.8,
                    color: accent,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              if (completed)
                Positioned(
                  top: 5,
                  right: 5,
                  child: Icon(Icons.flag_rounded, size: nodeSize * 0.18, color: const Color(0xFFD4AF37)),
                ),
            ],
          ),
        ),
      ),
    );

    return Opacity(
      opacity: locked ? 0.48 : 1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pulse != null) ScaleTransition(scale: pulse!, child: node) else node,
          const SizedBox(height: 8),
          SizedBox(
            width: 140,
            child: Column(
              children: [
                Text(
                  stage.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 1),
                Text(
                  stage.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(JourneyStageType type, bool locked, bool completed) {
    if (locked) return Icons.lock_rounded;
    if (completed) return Icons.check_rounded;
    return switch (type) {
      JourneyStageType.regular => Icons.circle,
      JourneyStageType.milestone => Icons.shield_rounded,
      JourneyStageType.major => Icons.workspace_premium_rounded,
    };
  }

  BoxDecoration _nodeDecoration(
    JourneyStageType type,
    bool locked,
    bool inProgress,
    bool completed,
  ) {
    final fill = locked
        ? const Color(0xFFE2E8F0)
        : completed
            ? const Color(0xFF16A34A)
            : inProgress
                ? accent
                : const Color(0xFF94A3B8);

    final border = completed
        ? const Color(0xFFD4AF37)
        : inProgress
            ? accent
            : const Color(0xFFCBD5E1);

    return BoxDecoration(
      color: fill,
      shape: type == JourneyStageType.regular ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: type == JourneyStageType.regular ? null : BorderRadius.circular(type == JourneyStageType.major ? 24 : 16),
      border: Border.all(color: border, width: type == JourneyStageType.major ? 3 : 2.4),
      boxShadow: [
        if (inProgress || completed)
          BoxShadow(
            color: (completed ? const Color(0xFFD4AF37) : accent).withValues(alpha: 0.24),
            blurRadius: type == JourneyStageType.major ? 18 : 12,
          ),
      ],
    );
  }
}

class _JourneyPathPainter extends CustomPainter {
  const _JourneyPathPainter({
    required this.points,
    required this.accent,
    required this.currentIndex,
    required this.selectedIndex,
  });

  final List<Offset> points;
  final Color accent;
  final int currentIndex;
  final int selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final mapped = points.map((p) => Offset(size.width / 2 + p.dx, p.dy + 24)).toList();

    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFCBD5E1);

    final progressed = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.8
      ..strokeCap = StrokeCap.round
      ..color = accent.withValues(alpha: 0.74);

    final focus = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = accent.withValues(alpha: 0.24);

    canvas.drawPath(_path(mapped), base);

    if (currentIndex > 0) {
      canvas.drawPath(_path(mapped.sublist(0, min(currentIndex + 1, mapped.length))), progressed);
    }

    if (selectedIndex > 0) {
      final start = max(0, selectedIndex - 1);
      final end = min(mapped.length, selectedIndex + 1);
      canvas.drawPath(_path(mapped.sublist(start, end)), focus);
    }

    if (currentIndex >= 0 && currentIndex < mapped.length) {
      final c = mapped[currentIndex];
      final particle = Paint()..color = accent.withValues(alpha: 0.35);
      for (var i = 0; i < 7; i++) {
        final angle = (i / 7) * 2 * pi;
        final r = 14 + (i % 3) * 5;
        canvas.drawCircle(Offset(c.dx + cos(angle) * r, c.dy + sin(angle) * r), 1.4, particle);
      }
    }
  }

  Path _path(List<Offset> pts) {
    final p = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final a = pts[i - 1];
      final b = pts[i];
      final control = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2 - 12);
      p.quadraticBezierTo(control.dx, control.dy, b.dx, b.dy);
    }
    return p;
  }

  @override
  bool shouldRepaint(covariant _JourneyPathPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.accent != accent ||
        oldDelegate.currentIndex != currentIndex ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}
