import 'dart:math';

import 'package:egitim_uygulamasi/screens/home/map/models/map_progress_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FloatingHUD extends StatelessWidget {
  const FloatingHUD({
    super.key,
    required this.lessonName,
    required this.activeUnitName,
    required this.progressPercent,
  });

  final String lessonName;
  final String activeUnitName;
  final int progressPercent;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.explore_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lessonName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  'Aktif: $activeUnitName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 10),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '%$progressPercent',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class UnitMapContainer extends StatefulWidget {
  const UnitMapContainer({
    super.key,
    required this.units,
    required this.accent,
    required this.onUnitTap,
  });

  final List<UnitNodeData> units;
  final Color accent;
  final ValueChanged<UnitNodeData> onUnitTap;

  @override
  State<UnitMapContainer> createState() => _UnitMapContainerState();
}

class _UnitMapContainerState extends State<UnitMapContainer> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant UnitMapContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.units.map((e) => e.unitId).toList(), widget.units.map((e) => e.unitId).toList())) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActive());
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActive());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  UnitNodeData? _activeUnit() {
    if (widget.units.isEmpty) return null;
    for (final u in widget.units) {
      if (u.isCurrentWeek) return u;
    }
    for (final u in widget.units) {
      if (u.state == ConquestState.inProgress) return u;
    }
    for (final u in widget.units) {
      if (u.state != ConquestState.conquered) return u;
    }
    return widget.units.first;
  }

  void _scrollToActive() {
    if (!_scrollController.hasClients || widget.units.isEmpty) return;
    final active = _activeUnit();
    if (active == null) return;
    final index = widget.units.indexWhere((u) => u.unitId == active.unitId);
    if (index < 0) return;

    const icon = 72.0;
    const spacing = 34.0;
    const horizontalPadding = 24.0;
    final target = horizontalPadding + (index * (icon + spacing)) - 120;
    final clamped = target.clamp(0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(
      clamped.toDouble(),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = _activeUnit();

    return LayoutBuilder(
      builder: (context, constraints) {
        final iconSize = (constraints.maxWidth * 0.15).clamp(56.0, 80.0);
        final spacing = (constraints.maxWidth * 0.07).clamp(22.0, 40.0);
        const horizontalPadding = 24.0;
        const yAmplitude = 22.0;
        final contentWidth = horizontalPadding * 2 +
            (widget.units.length * iconSize) +
            (max(0, widget.units.length - 1) * spacing);

        return Container(
          margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: max(contentWidth, constraints.maxWidth),
              height: 280,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _PathPainter(
                        units: widget.units,
                        iconSize: iconSize,
                        spacing: spacing,
                        padding: horizontalPadding,
                        yAmplitude: yAmplitude,
                        accent: widget.accent,
                      ),
                    ),
                  ),
                  ...List.generate(widget.units.length, (index) {
                    final unit = widget.units[index];
                    final x = horizontalPadding + index * (iconSize + spacing);
                    final y = 120 + (index.isEven ? -yAmplitude : yAmplitude);
                    final isActive = active?.unitId == unit.unitId;

                    return Positioned(
                      left: x,
                      top: y,
                      child: UnitIcon(
                        unit: unit,
                        accent: widget.accent,
                        size: iconSize,
                        isActive: isActive,
                        onTap: () {
                          debugPrint('Unit tapped -> id:${unit.unitId}, title:${unit.title}');
                          widget.onUnitTap(unit);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class UnitIcon extends StatefulWidget {
  const UnitIcon({
    super.key,
    required this.unit,
    required this.accent,
    required this.size,
    required this.isActive,
    required this.onTap,
  });

  final UnitNodeData unit;
  final Color accent;
  final double size;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<UnitIcon> createState() => _UnitIconState();
}

class _UnitIconState extends State<UnitIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.94,
      upperBound: 1.06,
    );
    if (widget.isActive) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant UnitIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isActive && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conquered = widget.unit.state == ConquestState.conquered;
    final muted = widget.unit.state == ConquestState.notStarted;

    final fillColor = conquered || widget.isActive ? widget.accent : Colors.white;
    final borderColor = conquered
        ? const Color(0xFFD4AF37)
        : widget.isActive
            ? widget.accent
            : const Color(0xFF94A3B8);
    final iconColor = conquered || widget.isActive ? Colors.white : const Color(0xFF64748B);

    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        children: [
          ScaleTransition(
            scale: _pulseController,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: muted ? const Color(0xFFF1F5F9) : fillColor,
                border: Border.all(color: borderColor, width: conquered ? 2.8 : 2.4),
                boxShadow: [
                  if (conquered || widget.isActive)
                    BoxShadow(
                      color: widget.accent.withValues(alpha: widget.isActive ? 0.34 : 0.22),
                      blurRadius: widget.isActive ? 16 : 10,
                      spreadRadius: widget.isActive ? 1 : 0,
                    ),
                ],
              ),
              child: Icon(
                conquered ? Icons.check_rounded : (widget.isActive ? Icons.play_arrow_rounded : Icons.lock_open_rounded),
                color: iconColor,
                size: widget.size * 0.38,
              ),
            ),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 90),
            child: Text(
              widget.unit.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PathPainter extends CustomPainter {
  const _PathPainter({
    required this.units,
    required this.iconSize,
    required this.spacing,
    required this.padding,
    required this.yAmplitude,
    required this.accent,
  });

  final List<UnitNodeData> units;
  final double iconSize;
  final double spacing;
  final double padding;
  final double yAmplitude;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    if (units.length < 2) return;

    final baseLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3
      ..color = const Color(0xFFCBD5E1);

    final progressLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.4
      ..color = accent.withValues(alpha: 0.7);

    final centers = <Offset>[];
    for (var i = 0; i < units.length; i++) {
      final x = padding + (i * (iconSize + spacing)) + (iconSize / 2);
      final y = 120 + (i.isEven ? -yAmplitude : yAmplitude) + (iconSize / 2);
      centers.add(Offset(x, y));
    }

    final basePath = Path()..moveTo(centers.first.dx, centers.first.dy);
    for (var i = 1; i < centers.length; i++) {
      final p1 = centers[i - 1];
      final p2 = centers[i];
      final ctrl = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2 - 10);
      basePath.quadraticBezierTo(ctrl.dx, ctrl.dy, p2.dx, p2.dy);
    }
    canvas.drawPath(basePath, baseLine);

    final completedCount = units.where((u) => u.state == ConquestState.conquered).length;
    if (completedCount <= 0) return;

    final progressPath = Path()..moveTo(centers.first.dx, centers.first.dy);
    final endIndex = min(completedCount, centers.length - 1);
    for (var i = 1; i <= endIndex; i++) {
      final p1 = centers[i - 1];
      final p2 = centers[i];
      final ctrl = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2 - 10);
      progressPath.quadraticBezierTo(ctrl.dx, ctrl.dy, p2.dx, p2.dy);
    }
    canvas.drawPath(progressPath, progressLine);
  }

  @override
  bool shouldRepaint(covariant _PathPainter oldDelegate) {
    return oldDelegate.units != units || oldDelegate.accent != accent;
  }
}
