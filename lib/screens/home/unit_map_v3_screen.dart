import 'dart:async';
import 'package:flutter/material.dart';
import 'package:egitim_uygulamasi/main.dart';
import 'package:egitim_uygulamasi/utils/date_utils.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ========================================
// DATA MODELS
// ========================================

class WeekV3 {
  final int curriculumWeek;
  final String title;
  final bool isLocked;
  final bool isCompleted;
  final List<UnitV3> units;

  const WeekV3({
    required this.curriculumWeek,
    required this.title,
    required this.isLocked,
    required this.isCompleted,
    required this.units,
  });

  double get progress {
    if (units.isEmpty) return 0.0;
    int completedCount = units.where((u) => u.isCompleted).length;
    return completedCount / units.length;
  }
}

class UnitV3 {
  final int? id;
  final String title;
  final bool isCompleted;
  final double progress;

  const UnitV3({
    this.id,
    required this.title,
    this.isCompleted = false,
    this.progress = 0.0,
  });
}

// ========================================
// SCREEN IMPLEMENTATION
// ========================================

class UnitMapV3Screen extends StatefulWidget {
  final int lessonId;
  final String lessonName;
  final int gradeId;

  const UnitMapV3Screen({
    super.key,
    required this.lessonId,
    required this.lessonName,
    required this.gradeId,
  });

  @override
  State<UnitMapV3Screen> createState() => _UnitMapV3ScreenState();
}

class _UnitMapV3ScreenState extends State<UnitMapV3Screen> {
  final List<WeekV3> _weeks = [];
  bool _isLoading = true;
  String? _loadError;
  int _selectedWeekIndex = 0;
  final ScrollController _weekScrollController = ScrollController();
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _weekScrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _weekScrollController.removeListener(_onScroll);
    _weekScrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _weekScrollController.offset;
      
      // Calculate which week is closest to the center
      // Each week node is 100px high. 
      // The viewport center is roughly (context.size.height / 2)
      // For now, let's use a simple calculation based on item height
      final centerOffset = _scrollOffset + (MediaQuery.of(context).size.height - kToolbarHeight) / 2;
      // Subtract the top padding of the list (which we will add)
      final adjustedOffset = centerOffset - (MediaQuery.of(context).size.height / 2 - 50);
      
      int newIndex = (adjustedOffset / 100).floor().clamp(0, _weeks.length - 1);
      if (newIndex != _selectedWeekIndex) {
        _selectedWeekIndex = newIndex;
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final userId = supabase.auth.currentUser?.id;
      final currentAcademicWeek = calculateCurrentAcademicWeek();

      // 1. Fetch available weeks
      final rawWeeks = await supabase.rpc(
        'get_available_weeks',
        params: {'p_grade_id': widget.gradeId, 'p_lesson_id': widget.lessonId},
      );

      final weekNumbers = (rawWeeks as List)
          .map((item) => item['curriculum_week'] as int?)
          .whereType<int>()
          .toSet()
          .toList()
        ..sort();

      if (weekNumbers.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        return;
      }

      _weeks.clear();

      // 2. Fetch units for each week
      for (final weekNum in weekNumbers) {
        final weeklyData = await supabase.rpc(
          'get_weekly_curriculum',
          params: {
            'p_user_id': userId,
            'p_grade_id': widget.gradeId,
            'p_lesson_id': widget.lessonId,
            'p_curriculum_week': weekNum,
            'p_is_admin': false,
          },
        );

        final rows = (weeklyData as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        final units = rows.map((row) {
          final solvedQ = (row['solved_questions'] as num? ?? 0).toInt();
          final totalQ = (row['total_questions'] as num? ?? 1).toInt();
          final progress = totalQ > 0 ? solvedQ / totalQ : 0.0;
          
          return UnitV3(
            id: row['unit_id'] as int?,
            title: row['unit_title']?.toString() ?? 'Ünite',
            isCompleted: progress >= 1.0,
            progress: progress,
          );
        }).toList();

        final isCompleted = weekNum < currentAcademicWeek;
        final isLocked = weekNum > currentAcademicWeek;

        _weeks.add(
          WeekV3(
            curriculumWeek: weekNum,
            title: '$weekNum. Hafta',
            isLocked: isLocked,
            isCompleted: isCompleted,
            units: units,
          ),
        );
      }

      if (!mounted) return;
      
      // Set initial selected week to current academic week or first available
      final currentIdx = _weeks.indexWhere((w) => w.curriculumWeek == currentAcademicWeek);
      _selectedWeekIndex = currentIdx != -1 ? currentIdx : 0;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('UnitMapV3 Error: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Ders verileri yüklenirken bir hata oluştu.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? _buildErrorView()
              : _weeks.isEmpty
                  ? _buildEmptyView()
                  : _buildMainLayout(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E3A8A), size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.lessonName,
            style: const TextStyle(
              color: Color(0xFF1E3A8A),
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const Text(
            'Haftalık Başarı Yolculuğun',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
          onPressed: _loadData,
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(_loadError!, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text('Tekrar Dene')),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return const Center(
      child: Text('Bu derse ait müfredat bilgisi bulunamadı.'),
    );
  }

  Widget _buildMainLayout() {
    final screenHeight = MediaQuery.of(context).size.height;
    final centerLineY = (screenHeight - kToolbarHeight) / 2;

    return Stack(
      children: [
        // Background pattern for the units area
        Positioned.fill(
          left: 100,
          child: Opacity(
            opacity: 0.03,
            child: CustomPaint(
              painter: _GridPainter(),
            ),
          ),
        ),

        // Viewfinder Lines (Background layer of the viewfinder)
        Positioned(
          left: 0,
          right: 0,
          top: centerLineY - 60,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              border: Border.symmetric(
                horizontal: BorderSide(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  width: 2,
                ),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF3B82F6).withValues(alpha: 0.02),
                  const Color(0xFF3B82F6).withValues(alpha: 0.05),
                  const Color(0xFF3B82F6).withValues(alpha: 0.02),
                ],
              ),
            ),
          ),
        ),
        
        Row(
          children: [
            // Left Column: Week Rail
            Container(
              width: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(2, 0),
                  ),
                ],
              ),
              child: _buildWeekRail(),
            ),

            // Right Column: Units Area
            Expanded(
              child: _buildUnitsList(),
            ),
          ],
        ),

        // Viewfinder Decorative Markers (Above everything)
        Positioned(
          left: 100 - 10,
          top: centerLineY - 50,
          child: _buildViewfinderMarker(isLeft: true),
        ),
        Positioned(
          left: 100 - 10,
          top: centerLineY + 30,
          child: _buildViewfinderMarker(isLeft: true),
        ),
      ],
    );
  }

  Widget _buildViewfinderMarker({required bool isLeft}) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF3B82F6), width: 3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
            blurRadius: 8,
          )
        ],
      ),
      child: Center(
        child: Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xFF3B82F6),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildWeekRail() {
    final screenHeight = MediaQuery.of(context).size.height;
    // Padding to allow first and last items to reach center
    final verticalPadding = screenHeight / 2 - 50;

    return SingleChildScrollView(
      controller: _weekScrollController,
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Path Line Background
          Positioned(
            left: 50 - 2,
            top: 50,
            bottom: 50,
            child: CustomPaint(
              size: Size(4, (_weeks.length - 1) * 100),
              painter: _VerticalPathPainter(weeks: _weeks),
            ),
          ),
          
          // Nodes
          Column(
            children: List.generate(_weeks.length, (index) {
              final week = _weeks[index];
              final isSelected = _selectedWeekIndex == index;
              
              return GestureDetector(
                onTap: () {
                  _weekScrollController.animateTo(
                    index * 100.0,
                    duration: 500.ms,
                    curve: Curves.easeInOutCubic,
                  );
                },
                child: Container(
                  height: 100,
                  width: 100,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildWeekNode(week, isSelected),
                      const SizedBox(height: 6),
                      AnimatedDefaultTextStyle(
                        duration: 300.ms,
                        style: TextStyle(
                          fontSize: isSelected ? 12 : 10,
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                          color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF94A3B8),
                        ),
                        child: Text('Hafta ${week.curriculumWeek}'),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekNode(WeekV3 week, bool isSelected) {
    Color nodeColor = Colors.white;
    Color borderColor = const Color(0xFFCBD5E1);
    Widget? icon;

    if (week.isCompleted) {
      nodeColor = const Color(0xFFDCFCE7);
      borderColor = const Color(0xFF10B981);
      icon = const Icon(Icons.check_rounded, color: Color(0xFF10B981), size: 22);
    } else if (!week.isLocked) {
      nodeColor = isSelected ? const Color(0xFF3B82F6) : Colors.white;
      borderColor = const Color(0xFF3B82F6);
      icon = Text(
        '${week.curriculumWeek}',
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF3B82F6),
          fontWeight: FontWeight.w900,
          fontSize: 16,
        ),
      );
    } else {
      icon = Icon(Icons.lock_rounded, color: const Color(0xFF94A3B8), size: 18);
    }

    Widget node = AnimatedContainer(
      duration: 300.ms,
      width: isSelected ? 56 : 48,
      height: isSelected ? 56 : 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: nodeColor,
        border: Border.all(color: borderColor, width: isSelected ? 4 : 3),
        boxShadow: isSelected ? [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
            blurRadius: 12,
            spreadRadius: 4,
          )
        ] : [],
      ),
      child: Center(child: icon),
    );

    if (isSelected && !week.isCompleted) {
      return node.animate(onPlay: (controller) => controller.repeat(reverse: true))
          .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 1000.ms, curve: Curves.easeInOut);
    }
    
    return node;
  }

  Widget _buildUnitsList() {
    final selectedWeek = _weeks[_selectedWeekIndex];
    
    return Column(
      children: [
        // Header for selected week
        Container(
          padding: const EdgeInsets.all(20),
          width: double.infinity,
          color: Colors.blue.withValues(alpha: 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${selectedWeek.curriculumWeek}. HAFTA',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF3B82F6),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Bu haftaki görevlerin hazır!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ],
          ),
        ),

        // List of units
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: selectedWeek.units.length,
            itemBuilder: (context, index) {
              final unit = selectedWeek.units[index];
              return _buildUnitCard(unit, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUnitCard(UnitV3 unit, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Accent
              Container(
                width: 8,
                color: unit.isCompleted ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
              ),
              
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              unit.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                          ),
                          if (unit.isCompleted)
                            const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 20),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Progress Bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0).withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: unit.progress,
                                  minHeight: 8,
                                  backgroundColor: const Color(0xFFE2E8F0),
                                  color: unit.isCompleted ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '%${(unit.progress * 100).toInt()}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: unit.isCompleted ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Action Button
              Container(
                width: 90,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    left: BorderSide(color: const Color(0xFFE2E8F0).withValues(alpha: 0.5)),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      // TODO: Navigation to unit detail/questions
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (unit.isCompleted ? const Color(0xFF10B981) : const Color(0xFF3B82F6)).withValues(alpha: 0.1),
                          ),
                          child: Icon(
                            unit.isCompleted ? Icons.check_circle_rounded : Icons.play_arrow_rounded,
                            color: unit.isCompleted ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          unit.isCompleted ? 'TEKRAR' : 'BAŞLA',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: unit.isCompleted ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 100).ms, duration: 400.ms).slideX(begin: 0.1, end: 0);
  }
}

class _VerticalPathPainter extends CustomPainter {
  final List<WeekV3> weeks;
  const _VerticalPathPainter({required this.weeks});

  @override
  void paint(Canvas canvas, Size size) {
    if (weeks.length < 2) return;

    final paint = Paint()
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < weeks.length - 1; i++) {
      final week = weeks[i];
      paint.color = week.isCompleted ? const Color(0xFF10B981) : const Color(0xFFE2E8F0);
      
      canvas.drawLine(
        Offset(2, i * 100),
        Offset(2, (i + 1) * 100),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VerticalPathPainter oldDelegate) => oldDelegate.weeks != weeks;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3B82F6)
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 30) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double j = 0; j < size.height; j += 30) {
      canvas.drawLine(Offset(0, j), Offset(size.width, j), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

