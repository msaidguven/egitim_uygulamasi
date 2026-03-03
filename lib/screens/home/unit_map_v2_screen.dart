import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../unit_summary_screen.dart';
import 'dart:math' as math;
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
        
        // Aktif üniteyi bul (Ya çözülmemiş ilk ünite ya da is_current_week = true olan)
        // Eğer her şey çözülmüşse en sonuncusu olsun.
        if (activeIndex == -1 && (item['solved_questions'] as num) < (item['total_questions'] as num)) {
           activeIndex = i;
        } else if (activeIndex == -1 && item['is_current_week'] == true) {
           activeIndex = i;
        }
      }
      
      if (activeIndex == -1 && data.isNotEmpty) {
          activeIndex = data.length - 1; // Hepsi bittiyse sonuncusu aktif olsun
      }
      

      setState(() {
        _units = data;
        _totalProgress = totalQ > 0 ? (totalSolved / totalQ) : 0;
        _activeUnitIndex = activeIndex;
        _unitKeys = List.generate(data.length, (_) => GlobalKey());
        _isLoading = false;
      });
      
      // Data yüklendikten sonra aktif üniteye kaydır
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
     
     // Her ünitenin genişliği yaklaşık 150 birim, ekran genişliğinin yarısını çıkararak ortalayalım
     final screenWidth = MediaQuery.of(context).size.width;
     final double estimatedOffset = (_activeUnitIndex * 150.0) - (screenWidth / 2) + 75.0; // 150 genislik tahmini
     
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

  Color get _dominantColor {
    if (_totalProgress < 0.3) return Colors.grey.shade400;
    if (_totalProgress < 0.7) return const Color(0xFF6366F1); // Indigo dominant
    return const Color(0xFF10B981); // Emerald (Green) for high progress
  }

  String get _activeUnitName {
      if (_activeUnitIndex != -1 && _activeUnitIndex < _units.length) {
          return _units[_activeUnitIndex]['title'] ?? 'Belirsiz';
      }
      return 'Tamamlandı';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark slate background
      body: Stack(
        children: [
          // Ana Harita Yolu
          if (!_isLoading) _buildScrollableMap(),

          // Üst HUD Panel
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: _buildHUD(),
          ),

          // Geri Butonu
          Positioned(
            bottom: 30,
            left: 20,
            child: FloatingActionButton(
              heroTag: 'back_btn',
              onPressed: () => Navigator.pop(context),
              backgroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                 borderRadius: BorderRadius.circular(16)
              ),
              child: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
            ),
          ),

          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildHUD() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _dominantColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.map_rounded, color: _dominantColor, size: 28),
          ),
          const SizedBox(width: 16),
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
                  'Aktif: $_activeUnitName',
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
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _dominantColor,
                ),
              ),
              const Text(
                'İlerleme',
                style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildScrollableMap() {
    return Center(
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(
           horizontal: MediaQuery.of(context).size.width / 2 - 75, // İlk ünite ortadan başlasın
           vertical: 100
        ),
        child: SizedBox(
           height: 300, // Yükseklik zik-zak için yeterli alan
           child: CustomPaint(
              painter: _MapPathPainter(
                 unitsCount: _units.length,
                 activeIndex: _activeUnitIndex
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(_units.length, (index) {
                  return _buildUnitNodeWrapper(index);
                }),
              ),
           ),
        ),
      ),
    );
  }

  Widget _buildUnitNodeWrapper(int index) {
      final unit = _units[index];
      
      // Zik-Zak animasyonu için offset
      final isUp = index % 2 == 0;
      final yOffset = isUp ? -60.0 : 60.0;
      
      final bool isCompleted = index < _activeUnitIndex || (index == _activeUnitIndex && _totalProgress >= 1.0);
      final bool isActive = index == _activeUnitIndex;
      final bool isLocked = index > _activeUnitIndex;

      // Status enum benzeri yapı
      _UnitStatus status = isActive ? _UnitStatus.active : (isCompleted ? _UnitStatus.completed : _UnitStatus.locked);

      return Container(
          key: _unitKeys[index],
          width: 150, // Her bir düğüm arası mesafe
          alignment: Alignment.center,
          transform: Matrix4.translationValues(0, yOffset, 0),
          child: _UnitNode(
            title: unit['title'] ?? 'Ünite ${index + 1}',
            status: status,
            onTap: () {
              if (isLocked) {
                 debugPrint('Locked Unit Tapped: ${unit['title']}');
                 return; // Kilitliyse bir şey yapma
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

  const _UnitNode({
    required this.title,
    required this.status,
    required this.onTap,
    required this.index,
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
        nodeColor = const Color(0xFF10B981); // Emerald
        iconData = Icons.star_rounded;
        showGlow = true;
        break;
      case _UnitStatus.active:
        nodeColor = const Color(0xFF6366F1); // Indigo
        iconData = Icons.play_arrow_rounded;
        scale = 1.25; // %25 daha büyük
        showPulse = true;
        showGlow = true;
        break;
       case _UnitStatus.locked:
        nodeColor = Colors.grey.shade600;
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
                // Pulse Animation Background (Sadece aktifte)
                if (showPulse)
                  Container(
                    width: 70 * scale,
                    height: 70 * scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: nodeColor.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                   .scale(begin: const Offset(1, 1), end: const Offset(1.3, 1.3), duration: 1200.ms)
                   .fadeOut(duration: 1200.ms),
                
                // Sabit Glow (Tamamlanan ve Aktif)
                if (showGlow && !showPulse)
                   Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                         shape: BoxShape.circle,
                         boxShadow: [
                            BoxShadow(
                               color: nodeColor.withOpacity(0.3),
                               blurRadius: 15,
                               spreadRadius: 2,
                            )
                         ]
                      ),
                   ),

                // Main Node Circle
                Container(
                  width: 50 * scale,
                  height: 50 * scale,
                  decoration: BoxDecoration(
                    color: status == _UnitStatus.locked ? const Color(0xFF1E293B) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                       color: nodeColor, 
                       width: status == _UnitStatus.active ? 4 : 3
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      iconData,
                      color: status == _UnitStatus.locked ? Colors.grey.shade400 : nodeColor,
                      size: 28 * scale,
                    ),
                  ),
                ),
                
                // Level Badge
                Positioned(
                   top: 0,
                   right: 0,
                   child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                         color: const Color(0xFF0F172A),
                         shape: BoxShape.circle,
                         border: Border.all(color: nodeColor, width: 2)
                      ),
                      child: Text(
                         '${index + 1}',
                         style: const TextStyle(
                            color: Colors.white, 
                            fontSize: 10, 
                            fontWeight: FontWeight.bold
                         ),
                      ),
                   ),
                )
              ],
            ),
            const SizedBox(height: 12),
            // Title Label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: status == _UnitStatus.locked ? Colors.transparent : Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
                border: status == _UnitStatus.locked ? Border.all(color: Colors.grey.shade700) : null,
              ),
              constraints: const BoxConstraints(maxWidth: 110),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: status == _UnitStatus.locked ? Colors.grey.shade400 : Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );

    // Bounce animasyonu (aktif widget için)
    if (status == _UnitStatus.active) {
       content = content.animate(onPlay: (c) => c.repeat())
                        .moveY(begin: -5, end: 5, duration: 1500.ms, curve: Curves.easeInOutSine)
                        .then()
                        .moveY(begin: 5, end: -5, duration: 1500.ms, curve: Curves.easeInOutSine);
    }
    
    return content;
  }
}

class _MapPathPainter extends CustomPainter {
   final int unitsCount;
   final int activeIndex;
   
   _MapPathPainter({required this.unitsCount, required this.activeIndex});

  @override
  void paint(Canvas canvas, Size size) {
    if (unitsCount < 2) return;

    final double nodeWidth = 150.0;
    
    // Çizgi Stilleri
    final Paint completedPaint = Paint()
      ..color = const Color(0xFF10B981) // Emerald (Completed)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint lockedPaint = Paint()
      ..color = Colors.grey.shade700
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Noktalı çizgi efekti için Paint
    final dashedPaint = Paint()
      ..color = Colors.grey.shade700
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < unitsCount - 1; i++) {
        // İki düğümün merkez noktalarını hesapla
        final isUp1 = i % 2 == 0;
        final isUp2 = (i + 1) % 2 == 0;
        
        final dx1 = (i * nodeWidth) + (nodeWidth / 2);
        final dy1 = (size.height / 2) + (isUp1 ? -60.0 : 60.0);
        
        final dx2 = ((i + 1) * nodeWidth) + (nodeWidth / 2);
        final dy2 = (size.height / 2) + (isUp2 ? -60.0 : 60.0);
        
        final p1 = Offset(dx1, dy1);
        final p2 = Offset(dx2, dy2);

        // Path çizimi (Hafif kavisli)
        final path = Path();
        path.moveTo(p1.dx, p1.dy);
        
        // Bezier eğrisi ile yumuşak geçiş
        final controlPoint1 = Offset(dx1 + (nodeWidth / 3), dy1);
        final controlPoint2 = Offset(dx2 - (nodeWidth / 3), dy2);
        
        path.cubicTo(
           controlPoint1.dx, controlPoint1.dy, 
           controlPoint2.dx, controlPoint2.dy, 
           p2.dx, p2.dy
        );

        if (i < activeIndex) {
            // Tamamlanmış yol
            canvas.drawPath(path, completedPaint);
        } else {
            // Kilitli yol (Kesikli yapalım daha estetik durur)
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
    return true; // Animasyonlar eklenebileceği için true
  }
}
