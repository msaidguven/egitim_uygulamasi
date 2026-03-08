import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:egitim_uygulamasi/main.dart';
import 'package:egitim_uygulamasi/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

// ========================================
// DATA MODELS
// ========================================

enum WeekAlignment { left, center, right }

class Unit {
  final String title;
  final int index;

  const Unit({required this.title, required this.index});
}

class Week {
  final int curriculumWeek;
  final String title;
  final String unitTitle;
  final int unitIndex;
  final bool isLocked;
  final bool isCompleted;
  final double progress;
  final WeekAlignment alignment;

  const Week({
    required this.curriculumWeek,
    required this.title,
    required this.unitTitle,
    required this.unitIndex,
    required this.isLocked,
    required this.isCompleted,
    required this.progress,
    required this.alignment,
  });
}

class _WeekUnitMeta {
  final int? unitId;
  final String unitTitle;

  const _WeekUnitMeta({required this.unitId, required this.unitTitle});
}

// ========================================
// SCREEN IMPLEMENTATION
// ========================================

class UnitMapV2Screen extends StatefulWidget {
  final int? lessonId;
  final String? lessonName;
  final int? gradeId;

  const UnitMapV2Screen({
    super.key,
    this.lessonId,
    this.lessonName,
    this.gradeId,
  });

  @override
  State<UnitMapV2Screen> createState() => _UnitMapV2ScreenState();
}

class _UnitMapV2ScreenState extends State<UnitMapV2Screen> with SingleTickerProviderStateMixin {
  // Controllers & Listeners
  final ItemScrollController _weekScrollController = ItemScrollController();
  final ItemPositionsListener _weekPositionsListener = ItemPositionsListener.create();
  final ScrollController _unitTabScrollController = ScrollController();
  final ValueNotifier<int> _activeUnitNotifier = ValueNotifier<int>(0);

  // Animation controller for pulsing nodes
  late AnimationController _pulseController;

  // Data
  final List<Unit> _units = [];
  final List<Week> _weeks = [];
  final Map<int, int> _unitFirstWeekIndex = {};
  final List<GlobalKey> _unitTabKeys = [];

  bool _isAutoScrolling = false;
  Timer? _autoScrollTimer;
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _loadCurriculumData();
    _weekPositionsListener.itemPositions.addListener(_onScrollUpdate);
  }

  @override
  void dispose() {
    _weekPositionsListener.itemPositions.removeListener(_onScrollUpdate);
    _unitTabScrollController.dispose();
    _activeUnitNotifier.dispose();
    _pulseController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCurriculumData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    final lessonId = widget.lessonId;
    final gradeId = widget.gradeId;
    if (lessonId == null || gradeId == null) {
      setState(() {
        _isLoading = false;
        _loadError = 'Ders veya sınıf bilgisi eksik.';
      });
      return;
    }

    try {
      final userId = supabase.auth.currentUser?.id;

      final rawWeeks = await supabase.rpc(
        'get_available_weeks',
        params: {'p_grade_id': gradeId, 'p_lesson_id': lessonId},
      );

      final weekNumbers = (rawWeeks as List)
          .map((item) => item['curriculum_week'] as int?)
          .whereType<int>()
          .toSet()
          .toList()
        ..sort();

      if (weekNumbers.isEmpty) {
        setState(() {
          _units.clear();
          _weeks.clear();
          _unitFirstWeekIndex.clear();
          _unitTabKeys.clear();
          _isLoading = false;
        });
        return;
      }

      final weekUnitMap = <int, _WeekUnitMeta>{};
      for (final week in weekNumbers) {
        final weeklyData = await supabase.rpc(
          'get_weekly_curriculum',
          params: {
            'p_user_id': userId,
            'p_grade_id': gradeId,
            'p_lesson_id': lessonId,
            'p_curriculum_week': week,
            'p_is_admin': false,
          },
        );
        final rows = (weeklyData as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        int? unitId;
        String? unitTitle;
        for (final row in rows) {
          final candidateUnitId = row['unit_id'] as int?;
          final candidateUnitTitle = (row['unit_title'] as String?)?.trim();
          if (candidateUnitId != null || (candidateUnitTitle?.isNotEmpty ?? false)) {
            unitId = candidateUnitId;
            unitTitle = candidateUnitTitle;
            break;
          }
        }
        weekUnitMap[week] = _WeekUnitMeta(
          unitId: unitId,
          unitTitle: (unitTitle == null || unitTitle.isEmpty) ? 'Ünite' : unitTitle,
        );
      }

      _units.clear();
      _weeks.clear();
      _unitFirstWeekIndex.clear();
      _unitTabKeys.clear();

      final unitIndexByKey = <String, int>{};
      final currentAcademicWeek = calculateCurrentAcademicWeek();

      for (var i = 0; i < weekNumbers.length; i++) {
        final curriculumWeek = weekNumbers[i];
        final meta = weekUnitMap[curriculumWeek] ?? const _WeekUnitMeta(unitId: null, unitTitle: 'Ünite');
        final unitKey = meta.unitId != null ? 'id_${meta.unitId}' : 'title_${meta.unitTitle}';

        final unitIndex = unitIndexByKey.putIfAbsent(unitKey, () {
          final index = _units.length;
          _units.add(Unit(title: meta.unitTitle, index: index));
          _unitTabKeys.add(GlobalKey());
          return index;
        });

        _unitFirstWeekIndex.putIfAbsent(unitIndex, () => i);

        final cycle = i % 4;
        final alignment = cycle == 0
            ? WeekAlignment.left
            : (cycle == 2 ? WeekAlignment.right : WeekAlignment.center);

        final isCompleted = curriculumWeek < currentAcademicWeek;
        final isLocked = curriculumWeek > currentAcademicWeek;
        final progress = isCompleted ? 1.0 : (isLocked ? 0.0 : 0.55);

        _weeks.add(
          Week(
            curriculumWeek: curriculumWeek,
            title: '$curriculumWeek. Hafta',
            unitTitle: meta.unitTitle,
            unitIndex: unitIndex,
            isLocked: isLocked,
            isCompleted: isCompleted,
            progress: progress,
            alignment: alignment,
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_weekScrollController.isAttached || _weeks.isEmpty) return;
        final currentIndex = _weeks.indexWhere((w) => !w.isLocked && !w.isCompleted);
        final targetIndex = currentIndex == -1 ? _weeks.length - 1 : currentIndex;
        _weekScrollController.jumpTo(index: targetIndex, alignment: 0.45);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Haftalar yüklenirken hata oluştu.';
      });
      debugPrint('UnitMapV2 veri yükleme hatası: $e');
    }
  }

  void _onScrollUpdate() {
    if (_isAutoScrolling || _weeks.isEmpty) return;
    final positions = _weekPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    int dominantIndex = -1;
    double maxPresence = -1;

    for (final pos in positions) {
      final presence = (math.min(pos.itemTrailingEdge, 1.0) - math.max(pos.itemLeadingEdge, 0.0)).clamp(0.0, 1.0);
      if (presence > maxPresence) {
        maxPresence = presence;
        dominantIndex = pos.index;
      }
    }

    if (dominantIndex != -1) {
      final unitIndex = _weeks[dominantIndex].unitIndex;
      if (_activeUnitNotifier.value != unitIndex) {
        _activeUnitNotifier.value = unitIndex;
        _autoCenterUnitTab(unitIndex);
      }
    }
  }

  void _onUnitTabTap(int index) {
    if (_weeks.isEmpty) return;
    if (_activeUnitNotifier.value == index) return;
    _activeUnitNotifier.value = index;
    _isAutoScrolling = true;
    _autoCenterUnitTab(index);
    final targetIndex = _unitFirstWeekIndex[index] ?? 0;
    _weekScrollController.scrollTo(
      index: targetIndex,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutQuart,
      alignment: 0.45,
    ).then((_) {
      _autoScrollTimer?.cancel();
      _autoScrollTimer = Timer(const Duration(milliseconds: 150), () {
        _isAutoScrolling = false;
      });
    });
  }

  void _autoCenterUnitTab(int index) {
    if (index < 0 || index >= _unitTabKeys.length) return;
    if (!_unitTabScrollController.hasClients) return;
    final context = _unitTabKeys[index].currentContext;
    if (context == null) return;
    final box = context.findRenderObject() as RenderBox;
    final position = box.localToGlobal(Offset.zero, ancestor: context.findAncestorRenderObjectOfType<RenderBox>());
    final viewportWidth = MediaQuery.of(this.context).size.width;
    final targetOffset = _unitTabScrollController.offset + position.dx - (viewportWidth / 2) + (box.size.width / 2);
    _unitTabScrollController.animateTo(
      targetOffset.clamp(0.0, _unitTabScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF6FF), // Light game-themed blue
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.lessonName ?? 'Müfredat Yolculuğu', 
              style: const TextStyle(
                color: Color(0xFF1E3A8A), 
                fontWeight: FontWeight.w900, 
                fontSize: 22,
                letterSpacing: -0.8,
              )
            ),
            const Text(
              'Gelişimini takip et ve ilerle!',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(88),
          child: UnitTabBar(
            units: _units,
            activeUnitNotifier: _activeUnitNotifier,
            scrollController: _unitTabScrollController,
            unitTabKeys: _unitTabKeys,
            onTap: _onUnitTabTap,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Decorations
          Positioned.fill(child: _buildBackgroundDecorations()),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_loadError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _loadError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF334155),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else if (_weeks.isEmpty)
            const Center(
              child: Text(
                'Bu derse ait müfredat haftası bulunamadı.',
                style: TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w600),
              ),
            )
          else
            WeekTimeline(
              weeks: _weeks,
              itemScrollController: _weekScrollController,
              itemPositionsListener: _weekPositionsListener,
              pulseAnimation: _pulseController,
            ),
        ],
      ),
    );
  }

  Widget _buildBackgroundDecorations() {
    return Opacity(
      opacity: 0.05,
      child: CustomPaint(
        painter: GridPainter(),
      ),
    );
  }
}

// ========================================
// COMPONENT: UNIT TAB BAR
// ========================================

class UnitTabBar extends StatelessWidget {
  final List<Unit> units;
  final ValueNotifier<int> activeUnitNotifier;
  final ScrollController scrollController;
  final List<GlobalKey> unitTabKeys;
  final ValueChanged<int> onTap;

  const UnitTabBar({
    super.key,
    required this.units,
    required this.activeUnitNotifier,
    required this.scrollController,
    required this.unitTabKeys,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFDBEAFE), width: 1.5)),
      ),
      child: ValueListenableBuilder<int>(
        valueListenable: activeUnitNotifier,
        builder: (context, activeIndex, _) {
          return ListView.builder(
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: units.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              return UnitTabItem(
                key: unitTabKeys[index],
                unit: units[index],
                isActive: index == activeIndex,
                onTap: () => onTap(index),
              );
            },
          );
        },
      ),
    );
  }
}

class UnitTabItem extends StatelessWidget {
  final Unit unit;
  final bool isActive;
  final VoidCallback onTap;

  const UnitTabItem({
    super.key,
    required this.unit,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isActive ? 1.05 : 0.95,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isActive ? const Color(0xFF3B82F6) : const Color(0xFFF1F5F9),
            boxShadow: isActive ? [
              BoxShadow(
                color: const Color(0xFF3B82F6).withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ] : [],
          ),
          child: Text(
            unit.title,
            style: TextStyle(
              color: isActive ? Colors.white : const Color(0xFF64748B),
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ),
    );
  }
}

// ========================================
// COMPONENT: WEEK TIMELINE (ZIGZAG)
// ========================================

class WeekTimeline extends StatelessWidget {
  final List<Week> weeks;
  final ItemScrollController itemScrollController;
  final ItemPositionsListener itemPositionsListener;
  final Animation<double> pulseAnimation;

  const WeekTimeline({
    super.key,
    required this.weeks,
    required this.itemScrollController,
    required this.itemPositionsListener,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return ScrollablePositionedList.builder(
      reverse: true,
      itemCount: weeks.length,
      itemScrollController: itemScrollController,
      itemPositionsListener: itemPositionsListener,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final week = weeks[index];
        final nextWeek = (index + 1 < weeks.length) ? weeks[index + 1] : null;

        return WeekZigzagItem(
          week: week,
          nextWeek: nextWeek,
          pulseAnimation: pulseAnimation,
          isFirst: index == 0,
          isLast: index == weeks.length - 1,
        );
      },
    );
  }
}

class WeekZigzagItem extends StatelessWidget {
  final Week week;
  final Week? nextWeek;
  final Animation<double> pulseAnimation;
  final bool isFirst;
  final bool isLast;

  const WeekZigzagItem({
    super.key,
    required this.week,
    this.nextWeek,
    required this.pulseAnimation,
    required this.isFirst,
    required this.isLast,
  });

  double _getHorizontalOffset(WeekAlignment alignment, double width) {
    switch (alignment) {
      case WeekAlignment.left: return width * 0.15;
      case WeekAlignment.center: return width * 0.5;
      case WeekAlignment.right: return width * 0.85;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isCurrent = !week.isLocked && !week.isCompleted;
    final double screenWidth = MediaQuery.of(context).size.width - 40;

    return Container(
      height: 180, // Consistent height for zigzag segments
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // The Path Line (behind)
          if (!isLast && nextWeek != null)
            CustomPaint(
              size: Size(screenWidth, 180),
              painter: PathSegmentPainter(
                startAlign: week.alignment,
                endAlign: nextWeek!.alignment,
                isCompleted: week.isCompleted && nextWeek!.isCompleted,
              ),
            ),
          
          // The Node and Card
          Positioned(
            left: _getHorizontalOffset(week.alignment, screenWidth) - 30, // center the 60px node
            top: 20,
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    _buildNodeIndicator(isCurrent),
                    if (isCurrent)
                      Positioned(
                        top: -45,
                        child: _buildMascot(pulseAnimation),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildIslandCard(context, isCurrent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMascot(Animation<double> pulse) {
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 1.1).animate(pulse),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1E3A8A),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.face_retouching_natural_rounded, color: Colors.white, size: 16),
            SizedBox(width: 4),
            Text(
              'Buradasın!',
              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNodeIndicator(bool isCurrent) {
    return ScaleTransition(
      scale: isCurrent ? Tween(begin: 1.0, end: 1.15).animate(pulseAnimation) : const AlwaysStoppedAnimation(1.0),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: week.isCompleted 
                ? [const Color(0xFF10B981), const Color(0xFF059669)]
                : (week.isLocked 
                    ? [const Color(0xFFCBD5E1), const Color(0xFF94A3B8)]
                    : [const Color(0xFF3B82F6), const Color(0xFF2563EB)]),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: (week.isCompleted ? const Color(0xFF10B981) : (week.isLocked ? Colors.transparent : const Color(0xFF3B82F6))).withOpacity(0.4),
              blurRadius: isCurrent ? 20 : 10,
              spreadRadius: isCurrent ? 4 : 0,
              offset: const Offset(0, 4),
            )
          ],
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Icon(
          week.isCompleted ? Icons.check_rounded : (week.isLocked ? Icons.lock_outline : Icons.star_rounded),
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildIslandCard(BuildContext context, bool isCurrent) {
    double cardWidth = 140;
    
    // Calculate offset based on alignment to keep card centered or shifted appropriately
    double xOffset = 0;
    if (week.alignment == WeekAlignment.left) {
      xOffset = 60; // Shift right
    } else if (week.alignment == WeekAlignment.right) {
      xOffset = -60; // Shift left
    }

    return Transform.translate(
      offset: Offset(xOffset, 0),
      child: Container(
        width: cardWidth,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isCurrent ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0), width: 2),
          boxShadow: [
            // 3D Depth Shadow
            BoxShadow(
              color: (isCurrent ? const Color(0xFF1E3A8A) : Colors.black).withOpacity(0.1),
              offset: const Offset(0, 8),
              blurRadius: 0,
            ),
            const BoxShadow(
              color: Colors.white,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              week.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: week.isLocked ? const Color(0xFF94A3B8) : const Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              week.unitTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            ),
            if (!week.isLocked) ...[
              const SizedBox(height: 6),
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FractionallySizedBox(
                  widthFactor: week.progress,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ========================================
// PAINTERS
// ========================================

class PathSegmentPainter extends CustomPainter {
  final WeekAlignment startAlign;
  final WeekAlignment endAlign;
  final bool isCompleted;

  PathSegmentPainter({required this.startAlign, required this.endAlign, required this.isCompleted});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isCompleted ? const Color(0xFF10B981).withOpacity(0.5) : const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final dashPaint = Paint()
      ..color = const Color(0xFF94A3B8).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    double startX = _getX(startAlign, size.width);
    double endX = _getX(endAlign, size.width);
    
    final path = Path();
    path.moveTo(startX, 50); // From below the node
    
    // Bezier curve for a "game map" look
    double controlY = size.height * 0.5;
    path.quadraticBezierTo(startX, controlY, (startX + endX) / 2, controlY);
    path.quadraticBezierTo(endX, controlY, endX, size.height + 20);

    if (isCompleted) {
      canvas.drawPath(path, paint);
    } else {
      // Draw dotted/dashed line for locked path
      _drawDashedPath(canvas, path, dashPaint);
    }
  }

  double _getX(WeekAlignment align, double width) {
    switch (align) {
      case WeekAlignment.left: return width * 0.15;
      case WeekAlignment.center: return width * 0.5;
      case WeekAlignment.right: return width * 0.85;
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const double dashWidth = 10.0;
    const double dashSpace = 10.0;
    double distance = 0.0;
    for (PathMetric measurePath in path.computeMetrics()) {
      while (distance < measurePath.length) {
        canvas.drawPath(
          measurePath.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3B82F6)
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
