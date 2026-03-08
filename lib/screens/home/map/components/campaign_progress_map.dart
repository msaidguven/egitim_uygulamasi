import 'dart:math';

import 'package:egitim_uygulamasi/screens/home/map/models/map_progress_models.dart';
import 'package:flutter/material.dart';

enum CampaignStageType { regular, milestone, major }

class CampaignStageData {
  final String id;
  final String title;
  final String subtitle;
  final String? badge;
  final ConquestState state;
  final CampaignStageType type;
  final double progress;
  final dynamic payload;

  const CampaignStageData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.state,
    required this.type,
    this.badge,
    this.progress = 0,
    this.payload,
  });
}

class CampaignProgressMap extends StatefulWidget {
  const CampaignProgressMap({
    super.key,
    required this.stages,
    required this.accent,
    required this.onStageTap,
    this.emptyText = 'İçerik bulunamadı.',
  });

  final List<CampaignStageData> stages;
  final Color accent;
  final ValueChanged<CampaignStageData> onStageTap;
  final String emptyText;

  @override
  State<CampaignProgressMap> createState() => _CampaignProgressMapState();
}

class _CampaignProgressMapState extends State<CampaignProgressMap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  int _selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      lowerBound: 0.97,
      upperBound: 1.06,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  int _currentIndex() {
    final active = widget.stages.indexWhere((s) => s.state == ConquestState.inProgress);
    if (active != -1) return active;
    final open = widget.stages.indexWhere((s) => s.state == ConquestState.notStarted);
    if (open != -1) return open;
    return widget.stages.isEmpty ? -1 : widget.stages.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stages.isEmpty) {
      return Center(child: Text(widget.emptyText));
    }

    final current = _currentIndex();
    const startY = 68.0;
    const stepY = 124.0;

    final points = List<Offset>.generate(widget.stages.length, (index) {
      final x = switch (index % 5) {
        0 => 0.0,
        1 => -58.0,
        2 => 52.0,
        3 => -22.0,
        _ => 36.0,
      };
      return Offset(x, startY + index * stepY);
    });

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
        ),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 42),
          child: SizedBox(
            height: points.last.dy + 180,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CampaignPainter(
                      points: points,
                      currentIndex: current,
                      selectedIndex: _selectedIndex,
                      accent: widget.accent,
                    ),
                  ),
                ),
                ...List.generate(widget.stages.length, (index) {
                  final stage = widget.stages[index];
                  final point = points[index];
                  return Positioned(
                    top: point.dy,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Transform.translate(
                        offset: Offset(point.dx, 0),
                        child: _CampaignNode(
                          stage: stage,
                          accent: widget.accent,
                          selected: _selectedIndex == index,
                          pulse: current == index ? _pulse : null,
                          onTap: () {
                            setState(() => _selectedIndex = index);
                            widget.onStageTap(stage);
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

class _CampaignNode extends StatelessWidget {
  const _CampaignNode({
    required this.stage,
    required this.accent,
    required this.selected,
    required this.onTap,
    this.pulse,
  });

  final CampaignStageData stage;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;
  final AnimationController? pulse;

  @override
  Widget build(BuildContext context) {
    final locked = stage.state == ConquestState.locked;
    final inProgress = stage.state == ConquestState.inProgress;
    final conquered = stage.state == ConquestState.conquered;

    final nodeSize = switch (stage.type) {
      CampaignStageType.regular => 50.0,
      CampaignStageType.milestone => 70.0,
      CampaignStageType.major => 92.0,
    };

    final body = AnimatedScale(
      duration: const Duration(milliseconds: 130),
      scale: selected ? 1.05 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: nodeSize,
          height: nodeSize,
          decoration: _decoration(locked, inProgress, conquered),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                locked
                    ? Icons.lock_rounded
                    : conquered
                        ? Icons.check_rounded
                        : stage.type == CampaignStageType.major
                            ? Icons.workspace_premium_rounded
                            : stage.type == CampaignStageType.milestone
                                ? Icons.shield_rounded
                                : Icons.adjust_rounded,
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
              if (conquered)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Icon(Icons.flag_rounded, size: nodeSize * 0.18, color: const Color(0xFFD4AF37)),
                ),
            ],
          ),
        ),
      ),
    );

    return Opacity(
      opacity: locked ? 0.46 : 1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pulse != null) ScaleTransition(scale: pulse!, child: body) else body,
          const SizedBox(height: 8),
          SizedBox(
            width: 146,
            child: Column(
              children: [
                Text(
                  stage.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 1),
                Text(
                  stage.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
                if (stage.badge != null)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      stage.badge!,
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: accent),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _decoration(bool locked, bool inProgress, bool conquered) {
    final fill = locked
        ? const Color(0xFFE2E8F0)
        : conquered
            ? const Color(0xFF16A34A)
            : inProgress
                ? accent
                : const Color(0xFF94A3B8);

    final border = conquered
        ? const Color(0xFFD4AF37)
        : inProgress
            ? accent
            : const Color(0xFFCBD5E1);

    return BoxDecoration(
      color: fill,
      shape: stage.type == CampaignStageType.regular ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: stage.type == CampaignStageType.regular
          ? null
          : BorderRadius.circular(stage.type == CampaignStageType.major ? 26 : 18),
      border: Border.all(color: border, width: stage.type == CampaignStageType.major ? 3 : 2.4),
      boxShadow: [
        if (inProgress || conquered)
          BoxShadow(
            color: (conquered ? const Color(0xFFD4AF37) : accent).withValues(alpha: 0.25),
            blurRadius: stage.type == CampaignStageType.major ? 20 : 12,
          ),
      ],
    );
  }
}

class _CampaignPainter extends CustomPainter {
  const _CampaignPainter({
    required this.points,
    required this.currentIndex,
    required this.selectedIndex,
    required this.accent,
  });

  final List<Offset> points;
  final int currentIndex;
  final int selectedIndex;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final mapped = points.map((p) => Offset(size.width / 2 + p.dx, p.dy + 26)).toList();

    final basePath = _path(mapped);

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFCBD5E1);

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = accent.withValues(alpha: 0.72);

    final focusPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = accent.withValues(alpha: 0.24);

    canvas.drawPath(basePath, basePaint);

    if (currentIndex > 0) {
      final progressPath = _path(mapped.sublist(0, min(currentIndex + 1, mapped.length)));
      canvas.drawPath(progressPath, progressPaint);
    }

    if (selectedIndex > 0) {
      final s = max(0, selectedIndex - 1);
      final e = min(mapped.length, selectedIndex + 1);
      canvas.drawPath(_path(mapped.sublist(s, e)), focusPaint);
    }

    if (currentIndex >= 0 && currentIndex < mapped.length) {
      final c = mapped[currentIndex];
      final trail = Paint()..color = accent.withValues(alpha: 0.30);
      for (var i = 0; i < 8; i++) {
        final a = i / 8 * pi * 2;
        final r = 14 + (i % 3) * 4;
        canvas.drawCircle(Offset(c.dx + cos(a) * r, c.dy + sin(a) * r), 1.3, trail);
      }
    }
  }

  Path _path(List<Offset> pts) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final prev = pts[i - 1];
      final cur = pts[i];
      final control = Offset((prev.dx + cur.dx) / 2, (prev.dy + cur.dy) / 2 - 12);
      path.quadraticBezierTo(control.dx, control.dy, cur.dx, cur.dy);
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant _CampaignPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.currentIndex != currentIndex ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.accent != accent;
  }
}
