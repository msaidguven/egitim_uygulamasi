import 'dart:math';

import 'package:egitim_uygulamasi/screens/home/map/models/map_progress_models.dart';
import 'package:egitim_uygulamasi/screens/home/map/models/map_theme.dart';
import 'package:flutter/material.dart';

class ClassStrategyMap extends StatelessWidget {
  const ClassStrategyMap({
    super.key,
    required this.center,
    required this.subjects,
    required this.colorFor,
    required this.onTap,
    required this.theme,
  });

  final Widget center;
  final List<SubjectNodeData> subjects;
  final Color Function(SubjectNodeData subject) colorFor;
  final ValueChanged<SubjectNodeData> onTap;
  final MapThemeStyle theme;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final cx = w / 2;
        final cy = h / 2;
        final radiusX = (w * 0.34).clamp(120.0, 340.0);
        final radiusY = (h * 0.27).clamp(90.0, 250.0);
        final points = _radialPoints(subjects.length, cx, cy, radiusX, radiusY);

        return Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _TerrainPainter(theme: theme)),
            ...List.generate(subjects.length, (index) {
              final subject = subjects[index];
              final p = points[index];
              return Positioned(
                left: p.dx - 72,
                top: p.dy - 48,
                child: _CountryPolygonNode(
                  subject: subject,
                  accent: colorFor(subject),
                  seed: index + subject.lessonId,
                  onTap: () => onTap(subject),
                ),
              );
            }),
            Align(alignment: Alignment.center, child: center),
          ],
        );
      },
    );
  }
}

class SubjectTerritoryMap extends StatelessWidget {
  const SubjectTerritoryMap({
    super.key,
    required this.center,
    required this.units,
    required this.accent,
    required this.onTap,
    required this.theme,
  });

  final Widget center;
  final List<UnitNodeData> units;
  final Color accent;
  final ValueChanged<UnitNodeData> onTap;
  final MapThemeStyle theme;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final cx = w / 2;
        final cy = h / 2;
        final radiusX = (w * 0.33).clamp(120.0, 330.0);
        final radiusY = (h * 0.29).clamp(100.0, 260.0);
        final points = _radialPoints(units.length, cx, cy, radiusX, radiusY);

        return Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _TerrainPainter(theme: theme)),
            CustomPaint(
              painter: _RoadPainter(
                units: units,
                points: points,
                accent: accent,
                base: theme.routeBase,
              ),
            ),
            ...List.generate(units.length, (index) {
              final unit = units[index];
              final p = points[index];
              return Positioned(
                left: p.dx - 26,
                top: p.dy - 26,
                child: _CityMarker(
                  unit: unit,
                  accent: accent,
                  onTap: () => onTap(unit),
                ),
              );
            }),
            Align(alignment: Alignment.center, child: center),
          ],
        );
      },
    );
  }
}

List<Offset> _radialPoints(int count, double cx, double cy, double rx, double ry) {
  if (count <= 0) return const [];
  if (count == 1) return [Offset(cx, cy - ry * 0.9)];

  final pts = <Offset>[];
  final start = -pi / 2;
  final step = (2 * pi) / count;

  for (var i = 0; i < count; i++) {
    final a = start + (i * step);
    final wobble = (i % 2 == 0 ? 1.0 : 0.92);
    pts.add(Offset(cx + cos(a) * rx * wobble, cy + sin(a) * ry * wobble));
  }
  return pts;
}

class _CountryPolygonNode extends StatelessWidget {
  const _CountryPolygonNode({
    required this.subject,
    required this.accent,
    required this.seed,
    required this.onTap,
  });

  final SubjectNodeData subject;
  final Color accent;
  final int seed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final conquered = subject.state == ConquestState.conquered;
    final path = _buildCountryPath(const Size(144, 96), seed);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: CustomPaint(
          size: const Size(144, 96),
          painter: _CountryPainter(
            path: path,
            accent: accent,
            conquered: conquered,
            progress: subject.progressRate,
          ),
          child: SizedBox(
            width: 144,
            height: 96,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject.lessonName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                  LinearProgressIndicator(
                    value: subject.progressRate,
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(8),
                    color: conquered ? const Color(0xFFD4AF37) : accent,
                    backgroundColor: Colors.white.withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${subject.unitsConquered}/${subject.unitsTotal} şehir  ·  %${(subject.progressRate * 100).round()}',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF334155),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CountryPainter extends CustomPainter {
  const _CountryPainter({
    required this.path,
    required this.accent,
    required this.conquered,
    required this.progress,
  });

  final Path path;
  final Color accent;
  final bool conquered;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = _mix(accent, Colors.white, 0.80)
      ..style = PaintingStyle.fill;

    final border = Paint()
      ..color = conquered ? const Color(0xFFD4AF37) : _mix(accent, Colors.black, 0.25)
      ..strokeWidth = conquered ? 2.4 : 1.6
      ..style = PaintingStyle.stroke;

    final glow = Paint()
      ..color = (conquered ? const Color(0xFFD4AF37) : accent).withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawPath(path, glow);
    canvas.drawPath(path, fill);
    canvas.drawPath(path, border);

    if (conquered) {
      final iconPainter = TextPainter(
        text: const TextSpan(text: '⚑', style: TextStyle(fontSize: 14, color: Color(0xFFD4AF37))),
        textDirection: TextDirection.ltr,
      )..layout();
      iconPainter.paint(canvas, const Offset(118, 8));
    }

    final progressBand = Paint()
      ..color = accent.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    final bandRect = Rect.fromLTWH(8, size.height - 22, (size.width - 16) * progress.clamp(0, 1), 10);
    canvas.drawRRect(RRect.fromRectAndRadius(bandRect, const Radius.circular(8)), progressBand);
  }

  @override
  bool shouldRepaint(covariant _CountryPainter oldDelegate) {
    return oldDelegate.accent != accent || oldDelegate.conquered != conquered || oldDelegate.progress != progress;
  }
}

class _CityMarker extends StatelessWidget {
  const _CityMarker({
    required this.unit,
    required this.accent,
    required this.onTap,
  });

  final UnitNodeData unit;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final conquered = unit.state == ConquestState.conquered;
    final inProgress = unit.state == ConquestState.inProgress;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: conquered || inProgress ? accent : Colors.white,
              border: Border.all(
                color: conquered ? const Color(0xFFD4AF37) : accent,
                width: conquered ? 2.4 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: unit.isCurrentWeek ? 0.34 : 0.18),
                  blurRadius: unit.isCurrentWeek ? 14 : 8,
                  spreadRadius: unit.isCurrentWeek ? 1.5 : 0,
                ),
              ],
            ),
            child: Icon(
              conquered ? Icons.flag_rounded : Icons.location_city_rounded,
              size: 18,
              color: conquered || inProgress ? Colors.white : accent,
            ),
          ),
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 108),
            child: Text(
              unit.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: Color(0xFF0F172A), fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            _weekLabel(unit),
            style: const TextStyle(fontSize: 8.5, color: Color(0xFF475569), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _weekLabel(UnitNodeData unit) {
    if (unit.startWeek > 0 && unit.endWeek >= unit.startWeek) {
      if (unit.startWeek == unit.endWeek) return 'Hf ${unit.startWeek}';
      return 'Hf ${unit.startWeek}-${unit.endWeek}';
    }
    return 'Hafta yok';
  }
}

class _RoadPainter extends CustomPainter {
  const _RoadPainter({
    required this.units,
    required this.points,
    required this.accent,
    required this.base,
  });

  final List<UnitNodeData> units;
  final List<Offset> points;
  final Color accent;
  final Color base;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2 || units.length != points.length) return;

    final orderPairs = List.generate(units.length, (i) => MapEntry(i, units[i].orderNo))
      ..sort((a, b) => a.value.compareTo(b.value));

    final main = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.8
      ..color = accent.withValues(alpha: 0.34);

    for (var i = 0; i < orderPairs.length - 1; i++) {
      final p1 = points[orderPairs[i].key];
      final p2 = points[orderPairs[i + 1].key];
      final ctrl = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2 - 12);
      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, p2.dx, p2.dy);
      canvas.drawPath(path, main);
    }

    final side = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.2
      ..color = base.withValues(alpha: 0.18);

    for (var i = 0; i < points.length; i++) {
      final a = points[i];
      final b = points[(i + 1) % points.length];
      canvas.drawLine(a, b, side);
    }
  }

  @override
  bool shouldRepaint(covariant _RoadPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.accent != accent || oldDelegate.base != base;
  }
}

class _TerrainPainter extends CustomPainter {
  const _TerrainPainter({required this.theme});

  final MapThemeStyle theme;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: theme.backgroundGradient,
      ).createShader(rect);
    canvas.drawRect(rect, bg);

    final contour = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = theme.contour.withValues(alpha: 0.22);

    final center = Offset(size.width / 2, size.height / 2);
    for (var i = 1; i <= 5; i++) {
      final r = min(size.width, size.height) * (0.17 + (i * 0.11));
      canvas.drawOval(
        Rect.fromCenter(
          center: center.translate(i.isEven ? 12 : -8, i * 3.0),
          width: r * 1.9,
          height: r * 1.35,
        ),
        contour,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TerrainPainter oldDelegate) => oldDelegate.theme != theme;
}

Path _buildCountryPath(Size size, int seed) {
  final rnd = Random(seed);
  final cx = size.width / 2;
  final cy = size.height / 2;
  final radius = min(size.width, size.height) * 0.42;
  const points = 8;

  final path = Path();
  for (var i = 0; i < points; i++) {
    final angle = (-pi / 2) + (2 * pi * i / points);
    final jitter = 0.78 + rnd.nextDouble() * 0.38;
    final r = radius * jitter;
    final x = cx + cos(angle) * r * (1.0 + (i % 3) * 0.07);
    final y = cy + sin(angle) * r * (0.85 + (i % 2) * 0.1);
    if (i == 0) {
      path.moveTo(x, y);
    } else {
      path.lineTo(x, y);
    }
  }
  path.close();
  return path;
}

Color _mix(Color a, Color b, double t) {
  final clamped = t.clamp(0.0, 1.0);
  return Color.lerp(a, b, clamped) ?? a;
}
