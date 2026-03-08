import 'dart:math';

import 'package:egitim_uygulamasi/screens/home/map/models/map_progress_models.dart';
import 'package:flutter/material.dart';

enum TimelineVariant { minimal, quest }
enum TimelineNodeType { regular, milestone, major }

class TimelineNode {
  final String id;
  final String title;
  final String subtitle;
  final ConquestState state;
  final TimelineNodeType type;
  final double progress;
  final TopicNodeData? topic;

  const TimelineNode({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.state,
    required this.type,
    required this.progress,
    this.topic,
  });
}

class MinimalStrategyTimeline extends StatelessWidget {
  const MinimalStrategyTimeline({
    super.key,
    required this.nodes,
    required this.accent,
    required this.onTap,
  });

  final List<TimelineNode> nodes;
  final Color accent;
  final ValueChanged<TimelineNode> onTap;

  @override
  Widget build(BuildContext context) {
    final active = _activeIndex(nodes);

    return Stack(
      children: [
        Positioned(
          left: MediaQuery.of(context).size.width / 2 - 1.5,
          top: 0,
          bottom: 0,
          child: Container(
            width: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFCBD5E1),
                  accent.withValues(alpha: 0.55),
                  const Color(0xFFCBD5E1),
                ],
              ),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(10, 14, 10, 40),
          itemCount: nodes.length,
          itemBuilder: (context, i) {
            final node = nodes[i];
            final left = i.isEven;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                children: [
                  Expanded(
                    child: left
                        ? _LabelCard(node: node, left: true)
                        : const SizedBox.shrink(),
                  ),
                  _TapScale(
                    onTap: () => onTap(node),
                    child: _NodeView(
                      node: node,
                      accent: accent,
                      pulse: i == active,
                    ),
                  ),
                  Expanded(
                    child: !left
                        ? _LabelCard(node: node, left: false)
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class QuestJourneyTimeline extends StatelessWidget {
  const QuestJourneyTimeline({
    super.key,
    required this.nodes,
    required this.accent,
    required this.onTap,
  });

  final List<TimelineNode> nodes;
  final Color accent;
  final ValueChanged<TimelineNode> onTap;

  @override
  Widget build(BuildContext context) {
    if (nodes.isEmpty) return const SizedBox.shrink();
    final active = _activeIndex(nodes);

    const startY = 86.0;
    const stepY = 128.0;
    final points = List<Offset>.generate(nodes.length, (i) {
      final x = switch (i % 4) {
        0 => 0.0,
        1 => -68.0,
        2 => 62.0,
        _ => -24.0,
      };
      return Offset(x, startY + i * stepY);
    });

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFF8FAFC),
            accent.withValues(alpha: 0.05),
            const Color(0xFFF1F5F9),
          ],
        ),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 42),
          child: SizedBox(
            height: points.last.dy + 190,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _QuestPathPainter(
                      points: points,
                      activeIndex: active,
                      accent: accent,
                    ),
                  ),
                ),
                ...List.generate(nodes.length, (i) {
                  final node = nodes[i];
                  final p = points[i];
                  return Positioned(
                    top: p.dy,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Transform.translate(
                        offset: Offset(p.dx, 0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _TapScale(
                              onTap: () => onTap(node),
                              child: _NodeView(
                                node: node,
                                accent: accent,
                                pulse: i == active,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: 150,
                              child: Text(
                                node.title,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            Text(
                              node.subtitle,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
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

class _LabelCard extends StatelessWidget {
  const _LabelCard({required this.node, required this.left});

  final TimelineNode node;
  final bool left;

  @override
  Widget build(BuildContext context) {
    final locked = node.state == ConquestState.locked;
    return Align(
      alignment: left ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(left: left ? 16 : 0, right: left ? 0 : 16),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Opacity(
          opacity: locked ? 0.6 : 1,
          child: Column(
            crossAxisAlignment: left ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                node.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
              Text(
                node.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NodeView extends StatelessWidget {
  const _NodeView({
    required this.node,
    required this.accent,
    required this.pulse,
  });

  final TimelineNode node;
  final Color accent;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    final locked = node.state == ConquestState.locked;
    final progress = node.state == ConquestState.inProgress;
    final conquered = node.state == ConquestState.conquered;

    final size = switch (node.type) {
      TimelineNodeType.regular => 48.0,
      TimelineNodeType.milestone => 68.0,
      TimelineNodeType.major => 88.0,
    };

    final widgetNode = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: locked
            ? const Color(0xFFE2E8F0)
            : conquered
                ? const Color(0xFF16A34A)
                : progress
                    ? accent
                    : const Color(0xFF94A3B8),
        shape: node.type == TimelineNodeType.regular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: node.type == TimelineNodeType.regular
            ? null
            : BorderRadius.circular(node.type == TimelineNodeType.major ? 24 : 16),
        border: Border.all(
          color: conquered
              ? const Color(0xFFD4AF37)
              : progress
                  ? accent
                  : const Color(0xFFCBD5E1),
          width: node.type == TimelineNodeType.major ? 3 : 2.4,
        ),
        boxShadow: [
          if (progress || conquered)
            BoxShadow(
              color: (conquered ? const Color(0xFFD4AF37) : accent).withValues(alpha: 0.26),
              blurRadius: node.type == TimelineNodeType.major ? 18 : 12,
            ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            locked
                ? Icons.lock_rounded
                : conquered
                    ? Icons.check_rounded
                    : node.type == TimelineNodeType.major
                        ? Icons.workspace_premium_rounded
                        : node.type == TimelineNodeType.milestone
                            ? Icons.shield_rounded
                            : Icons.adjust_rounded,
            size: size * 0.34,
            color: locked ? const Color(0xFF94A3B8) : Colors.white,
          ),
          if (progress)
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: max(0.12, node.progress),
                strokeWidth: 2.6,
                color: accent,
                backgroundColor: Colors.transparent,
              ),
            ),
          if (conquered)
            Positioned(
              top: 6,
              right: 6,
              child: Icon(Icons.flag_rounded, size: size * 0.18, color: const Color(0xFFD4AF37)),
            ),
        ],
      ),
    );

    return Opacity(
      opacity: locked ? 0.48 : 1,
      child: pulse ? _Pulse(child: widgetNode) : widgetNode,
    );
  }
}

class _Pulse extends StatefulWidget {
  const _Pulse({required this.child});

  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      lowerBound: 0.97,
      upperBound: 1.05,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _controller, child: widget.child);
  }
}

class _TapScale extends StatefulWidget {
  const _TapScale({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 100),
        scale: _down ? 1.06 : 1,
        child: widget.child,
      ),
    );
  }
}

class _QuestPathPainter extends CustomPainter {
  const _QuestPathPainter({
    required this.points,
    required this.activeIndex,
    required this.accent,
  });

  final List<Offset> points;
  final int activeIndex;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final mapped = points.map((p) => Offset(size.width / 2 + p.dx, p.dy + 24)).toList();

    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFCBD5E1);

    final active = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = accent.withValues(alpha: 0.74);

    canvas.drawPath(_path(mapped), base);

    if (activeIndex > 0) {
      canvas.drawPath(_path(mapped.sublist(0, min(activeIndex + 1, mapped.length))), active);
    }

    if (activeIndex >= 0 && activeIndex < mapped.length) {
      final c = mapped[activeIndex];
      final p = Paint()..color = accent.withValues(alpha: 0.30);
      for (var i = 0; i < 8; i++) {
        final a = i / 8 * pi * 2;
        final r = 14 + (i % 3) * 4;
        canvas.drawCircle(Offset(c.dx + cos(a) * r, c.dy + sin(a) * r), 1.2, p);
      }
    }
  }

  Path _path(List<Offset> pts) {
    final p = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final prev = pts[i - 1];
      final cur = pts[i];
      final control = Offset((prev.dx + cur.dx) / 2, (prev.dy + cur.dy) / 2 - 10);
      p.quadraticBezierTo(control.dx, control.dy, cur.dx, cur.dy);
    }
    return p;
  }

  @override
  bool shouldRepaint(covariant _QuestPathPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.activeIndex != activeIndex || oldDelegate.accent != accent;
  }
}

int _activeIndex(List<TimelineNode> nodes) {
  final p = nodes.indexWhere((n) => n.state == ConquestState.inProgress);
  if (p != -1) return p;
  final n = nodes.indexWhere((n) => n.state == ConquestState.notStarted);
  if (n != -1) return n;
  return nodes.isEmpty ? -1 : nodes.length - 1;
}
