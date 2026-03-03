import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../unit_summary_screen.dart';
import 'dart:ui' as dart_ui;

class UnitMapV2Screen extends ConsumerStatefulWidget {
  final int lessonId;
  final String lessonName;
  final int gradeId;

  const UnitMapV2Screen({
    super.key,
    required this.lessonId,
    required this.lessonName,
    required this.gradeId,
  });

  @override
  ConsumerState<UnitMapV2Screen> createState() => _UnitMapV2ScreenState();
}

class _UnitMapV2ScreenState extends ConsumerState<UnitMapV2Screen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _units = [];
  bool _isLoading = true;
  double _totalProgress = 0;
  List<GlobalKey> _unitKeys = [];
  final ScrollController _scrollController = ScrollController();
  int _activeUnitIndex = -1;

  @override
  void initState() {
    super.initState();
    _fetchUnitMapData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchUnitMapData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      const currentWeek = 24;

      final response = await _supabase.rpc(
        'get_unit_map_data',
        params: {
          'p_user_id': userId,
          'p_lesson_id': widget.lessonId,
          'p_grade_id': widget.gradeId,
          'p_current_week': currentWeek,
        },
      );

      final List<Map<String, dynamic>> data =
          List<Map<String, dynamic>>.from(response);

      double totalSolved = 0;
      double totalQ = 0;
      int activeIndex = -1;
      
      for (int i = 0; i < data.length; i++) {
        var item = data[i];
        totalSolved += (item['solved_questions'] as num).toDouble();
        totalQ += (item['total_questions'] as num).toDouble();
        
        if (activeIndex == -1 && (item['solved_questions'] as num) < (item['total_questions'] as num)) {
           activeIndex = i;
        } else if (activeIndex == -1 && item['is_current_week'] == true) {
           activeIndex = i;
        }
      }
      
      if (activeIndex == -1 && data.isNotEmpty) {
          activeIndex = data.length - 1;
      }

      setState(() {
        _units = data;
        _totalProgress = totalQ > 0 ? (totalSolved / totalQ) : 0;
        _activeUnitIndex = activeIndex;
        _unitKeys = List.generate(data.length, (_) => GlobalKey());
        _isLoading = false;
      });
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
         if (_activeUnitIndex != -1 && _scrollController.hasClients) {
             _scrollToActiveUnit();
         }
      });
    } catch (e) {
      debugPrint('Unit map verisi çekilirken hata: $e');
      setState(() => _isLoading = false);
    }
  }

  void _scrollToActiveUnit() {
     if (_activeUnitIndex < 0 || _activeUnitIndex >= _unitKeys.length) return;
     
     final screenHeight = MediaQuery.of(context).size.height;
     // 140 is node distance, + 100 is padding etc. Center it gracefully.
     final double estimatedOffset = (_activeUnitIndex * 140.0) - (screenHeight / 2) + 70.0;
     
     final targetOffset = estimatedOffset.clamp(
        0.0, 
        _scrollController.position.maxScrollExtent
     );
     
     _scrollController.animateTo(
         targetOffset, 
         duration: const Duration(milliseconds: 800), 
         curve: Curves.easeOutCubic
     );
  }

  Color get _lessonColor {
    final name = widget.lessonName.toLowerCase();
    if (name.contains('mat')) return const Color(0xFF3B82F6); // Blue
    if (name.contains('fen')) return const Color(0xFF10B981); // Emerald
    if (name.contains('türk')) return const Color(0xFFEF4444); // Red
    if (name.contains('sos')) return const Color(0xFFF59E0B); // Amber
    if (name.contains('ing')) return const Color(0xFF8B5CF6); // Violet
    return const Color(0xFF6366F1); // Indigo default
  }

  Color get _progressColor {
    if (_totalProgress < 0.3) return Colors.grey.shade500;
    if (_totalProgress < 0.7) return _lessonColor;
    return const Color(0xFF10B981); // Vibrant Green
  }

  String get _activeUnitName {
      if (_activeUnitIndex != -1 && _activeUnitIndex < _units.length) {
          return '${_activeUnitIndex + 1}'; // Aktif ünite numarası
      }
      return 'Tamamlandı';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Sade, temiz arkaplan
      appBar: AppBar(
        title: Text(
          widget.lessonName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Üst HUD Panel
          _buildHUD(),

          // Ana Dikey Harita Yolu
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildVerticalScrollableMap(),
          ),
        ],
      ),
    );
  }

  Widget _buildHUD() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _progressColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.school_rounded, color: _progressColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.lessonName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Aktif Ünite: $_activeUnitName',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '%${(_totalProgress * 100).toInt()}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _progressColor,
                ),
              ),
              const Text(
                'İlerleme',
                style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildVerticalScrollableMap() {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: CustomPaint(
        painter: _VerticalMapPathPainter(
            unitsCount: _units.length,
            activeIndex: _activeUnitIndex,
            lessonColor: _lessonColor,
        ),
        child: Column(
          children: List.generate(_units.length, (index) {
            return _buildUnitNodeWrapper(index);
          }),
        ),
      ),
    );
  }

  Widget _buildUnitNodeWrapper(int index) {
      final unit = _units[index];
      
      final isLeft = index % 2 == 0;
      final xOffset = isLeft ? -50.0 : 50.0;
      
      final bool isCompleted = index < _activeUnitIndex || (index == _activeUnitIndex && _totalProgress >= 1.0);
      final bool isActive = index == _activeUnitIndex;
      final bool isLocked = index > _activeUnitIndex;

      _UnitStatus status = isActive ? _UnitStatus.active : (isCompleted ? _UnitStatus.completed : _UnitStatus.locked);

      return Container(
          key: _unitKeys[index],
          height: 140, // Dikey mesafe
          alignment: Alignment.center,
          transform: Matrix4.translationValues(xOffset, 0, 0),
          child: _UnitNode(
            title: unit['title'] ?? 'Ünite ${index + 1}',
            status: status,
            primaryColor: _lessonColor,
            onTap: () {
              if (isLocked) {
                 debugPrint('Locked Unit Tapped: ${unit['title']}');
                 return;
              }
              debugPrint('Unit Tapped: ${unit['title']}');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UnitSummaryScreen(unitId: unit['unit_id']),
                ),
              );
            },
            index: index,
          ),
      );
  }
}

enum _UnitStatus { completed, active, locked }

class _UnitNode extends StatelessWidget {
  final String title;
  final _UnitStatus status;
  final VoidCallback onTap;
  final int index;
  final Color primaryColor;

  const _UnitNode({
    required this.title,
    required this.status,
    required this.onTap,
    required this.index,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    Color nodeColor;
    IconData iconData;
    double scale = 1.0;
    double opacity = 1.0;
    bool showPulse = false;
    bool showGlow = false;

    switch (status) {
      case _UnitStatus.completed:
        nodeColor = primaryColor;
        iconData = Icons.check_rounded;
        showGlow = true;
        break;
      case _UnitStatus.active:
        nodeColor = primaryColor;
        iconData = Icons.play_arrow_rounded;
        scale = 1.1; // %10 büyük
        showPulse = true;
        showGlow = true;
        break;
       case _UnitStatus.locked:
        nodeColor = Colors.grey.shade400;
        iconData = Icons.lock_rounded;
        opacity = 0.6;
        break;
    }

    Widget content = GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: opacity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Pulse Animation Background
                if (showPulse)
                  Container(
                    width: 70 * scale,
                    height: 70 * scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: nodeColor.withValues(alpha: 0.4),
                          blurRadius: 15,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                  ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                   .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 1500.ms)
                   .fadeOut(duration: 1500.ms),
                
                // Fixed Glow
                if (showGlow && !showPulse)
                   Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                         shape: BoxShape.circle,
                         boxShadow: [
                            BoxShadow(
                               color: nodeColor.withValues(alpha: 0.3),
                               blurRadius: 10,
                               spreadRadius: 2,
                            )
                         ]
                      ),
                   ),

                // Main Circle
                Container(
                  width: 50 * scale,
                  height: 50 * scale,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                       color: nodeColor, 
                       width: status == _UnitStatus.active ? 4 : 3
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      iconData,
                      color: nodeColor,
                      size: 26 * scale,
                    ),
                  ),
                ),
                
                // Unit Number Badge
                Positioned(
                   bottom: 0,
                   right: 0,
                   child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                         color: Colors.white,
                         shape: BoxShape.circle,
                         border: Border.all(color: nodeColor, width: 2),
                         boxShadow: [
                           BoxShadow(
                             color: Colors.black.withValues(alpha: 0.1),
                             blurRadius: 4,
                           )
                         ]
                      ),
                      child: Text(
                         '${index + 1}',
                         style: TextStyle(
                            color: nodeColor, 
                            fontSize: 10, 
                            fontWeight: FontWeight.bold
                         ),
                      ),
                   ),
                )
              ],
            ),
            const SizedBox(height: 8),
            // Title Label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              ),
              constraints: const BoxConstraints(maxWidth: 100),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );

    return content;
  }
}

class _VerticalMapPathPainter extends CustomPainter {
   final int unitsCount;
   final int activeIndex;
   final Color lessonColor;
   
   _VerticalMapPathPainter({
      required this.unitsCount, 
      required this.activeIndex,
      required this.lessonColor,
   });

  @override
  void paint(Canvas canvas, Size size) {
    if (unitsCount < 2) return;

    final double nodeHeight = 140.0;
    
    final Paint completedPaint = Paint()
      ..color = lessonColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint dashedPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < unitsCount - 1; i++) {
        final isLeft1 = i % 2 == 0;
        final isLeft2 = (i + 1) % 2 == 0;
        
        // Merkez noktalar
        final dx1 = (size.width / 2) + (isLeft1 ? -50.0 : 50.0);
        final dy1 = (i * nodeHeight) + (nodeHeight / 2);
        
        final dx2 = (size.width / 2) + (isLeft2 ? -50.0 : 50.0);
        final dy2 = ((i + 1) * nodeHeight) + (nodeHeight / 2);
        
        final p1 = Offset(dx1, dy1);
        final p2 = Offset(dx2, dy2);

        final path = Path();
        path.moveTo(p1.dx, p1.dy);
        
        final controlPoint1 = Offset(dx1, dy1 + (nodeHeight / 3));
        final controlPoint2 = Offset(dx2, dy2 - (nodeHeight / 3));
        
        path.cubicTo(
           controlPoint1.dx, controlPoint1.dy, 
           controlPoint2.dx, controlPoint2.dy, 
           p2.dx, p2.dy
        );

        if (i < activeIndex) {
            canvas.drawPath(path, completedPaint);
        } else {
            _drawDashedPath(canvas, path, dashedPaint);
        }
    }
  }
  
  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const double dashWidth = 8.0;
    const double dashSpace = 6.0;
    double distance = 0.0;

    for (dart_ui.PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        final Path extractPath = pathMetric.extractPath(
          distance,
          distance + dashWidth,
        );
        try {
            canvas.drawPath(extractPath, paint);
        } catch (e) {
            // ignore
        }
        distance += dashWidth + dashSpace;
      }
      distance = 0.0; // reset for next metric
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; 
  }
}
