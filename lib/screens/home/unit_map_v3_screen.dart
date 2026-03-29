import 'dart:async';
import 'package:flutter/material.dart';
import 'package:egitim_uygulamasi/main.dart';
import 'package:egitim_uygulamasi/utils/date_utils.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:egitim_uygulamasi/screens/lesson_content/lesson_v11/main.dart'
    as lesson_v11;
import 'package:egitim_uygulamasi/features/test/presentation/views/questions_screen.dart';
import 'package:egitim_uygulamasi/features/test/data/models/test_question.dart';
import 'package:egitim_uygulamasi/screens/outcomes/outcomes_screen_v2.dart';
import 'package:egitim_uygulamasi/screens/weekly_v11_topics_screen.dart';

// ========================================
// DESIGN TOKENS - Improved with better naming and organization
// ========================================

class _AppColors {
  static const navy = Color(0xFF0F1F5C);
  static const navyMid = Color(0xFF1E3A8A);
  static const blue = Color(0xFF3B82F6);
  static const blueLight = Color(0xFF60A5FA);
  static const blueMid = Color(0xFF2563EB);
  static const emerald = Color(0xFF10B981);
  static const emeraldDark = Color(0xFF059669);
  static const coral = Color(0xFFFF6B6B);
  static const coralLight = Color(0xFFFF8A8A);
  static const violet = Color(0xFF7C3AED);
  static const violetLight = Color(0xFF8B5CF6);
  static const amber = Color(0xFFF59E0B);
  static const slate50 = Color(0xFFF8FAFC);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B);
  static const slate600 = Color(0xFF475569);
  static const slate700 = Color(0xFF334155);
  static const slate800 = Color(0xFF1E293B);
  static const slate900 = Color(0xFF0F172A);
  static const white = Colors.white;
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [blue, navyMid],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient successGradient = LinearGradient(
    colors: [emerald, emeraldDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    colors: [violet, violetLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class _AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);
  static const Duration pageTransition = Duration(milliseconds: 400);
}

class _AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
}

// ========================================
// DATA MODELS (Unchanged - already good)
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

class TopicV3 {
  final int id;
  final String title;
  final List<int> outcomeIds;
  final bool isCompleted;

  const TopicV3({
    required this.id,
    required this.title,
    required this.outcomeIds,
    this.isCompleted = false,
  });
}

class UnitV3 {
  final int? id;
  final String title;
  final List<TopicV3> topics;

  const UnitV3({
    this.id,
    required this.title,
    this.topics = const [],
  });

  bool get isCompleted =>
      topics.isNotEmpty && topics.every((t) => t.isCompleted);
  double get progress =>
      topics.isEmpty
          ? 0.0
          : topics.where((t) => t.isCompleted).length / topics.length;
}

// ========================================
// SCREEN IMPLEMENTATION - Refactored
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

class _UnitMapV3ScreenState extends State<UnitMapV3Screen>
    with SingleTickerProviderStateMixin {
  final List<WeekV3> _weeks = [];
  bool _isLoading = true;
  String? _loadError;
  int _selectedWeekIndex = 0;
  final ScrollController _weekScrollController = ScrollController();
  int _currentWeekIndex = -1;
  String _gradeName = '';
  late AnimationController _pulseController;
  
  // Constants
  static const double _kItemHeight = 88.0;
  static const double _kWeekRailWidth = 100.0;
  static const int _kSkeletonItemCount = 3;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadData();
    _weekScrollController.addListener(_onScroll);
  }

  void _initControllers() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _weekScrollController.removeListener(_onScroll);
    _weekScrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_weeks.isEmpty) return;
    
    final centerOffset = _weekScrollController.offset +
        (MediaQuery.of(context).size.height - kToolbarHeight) / 2;
    final adjustedOffset =
        centerOffset - (MediaQuery.of(context).size.height / 2 - 44);
    int newIndex =
        (adjustedOffset / _kItemHeight).floor().clamp(0, _weeks.length - 1);
    
    if (newIndex != _selectedWeekIndex) {
      setState(() => _selectedWeekIndex = newIndex);
    }
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollEndNotification && _weeks.isNotEmpty) {
      final index = (_weekScrollController.offset / _kItemHeight).round();
      final targetOffset = (index * _kItemHeight).clamp(
        0.0,
        _weekScrollController.position.maxScrollExtent,
      );
      
      if ((_weekScrollController.offset - targetOffset).abs() > 1) {
        _weekScrollController.animateTo(
          targetOffset,
          duration: _AppDurations.normal,
          curve: Curves.easeOutCubic,
        );
      }
    }
    return false;
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      await _fetchGradeName();
      await _fetchWeeks();
      
      if (_weeks.isEmpty) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        return;
      }
      
      _setInitialWeekIndex();
      
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      _scrollToInitialWeek();
      await _loadAllWeeksContent();
      
    } catch (e) {
      debugPrint('UnitMapV3 Error: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Ders verileri yüklenirken bir hata oluştu.';
      });
    }
  }
  
  Future<void> _fetchGradeName() async {
    try {
      final gradeData = await supabase
          .from('grades')
          .select('name')
          .eq('id', widget.gradeId)
          .maybeSingle();
      if (gradeData != null) {
        _gradeName = gradeData['name'] as String;
      }
    } catch (e) {
      debugPrint('Error fetching grade name: $e');
    }
  }
  
  Future<void> _fetchWeeks() async {
    final rawWeeks = await supabase.rpc(
      'get_available_weeks',
      params: {
        'p_grade_id': widget.gradeId,
        'p_lesson_id': widget.lessonId,
      },
    );
    
    final weekNumbers = (rawWeeks as List)
        .map((item) => item['curriculum_week'] as int?)
        .whereType<int>()
        .toSet()
        .toList()
      ..sort();
    
    final currentAcademicWeek = calculateCurrentAcademicWeek();
    
    _weeks.clear();
    for (final weekNum in weekNumbers) {
      final isLocked = weekNum > currentAcademicWeek;
      final isCompleted = weekNum < currentAcademicWeek;
      _weeks.add(
        WeekV3(
          curriculumWeek: weekNum,
          title: '$weekNum. Hafta',
          isLocked: isLocked,
          isCompleted: isCompleted,
          units: const [],
        ),
      );
    }
  }
  
  void _setInitialWeekIndex() {
    final currentAcademicWeek = calculateCurrentAcademicWeek();
    _currentWeekIndex = _weeks.indexWhere(
      (w) => w.curriculumWeek == currentAcademicWeek,
    );
    
    int initialIndex = _weeks.indexWhere(
      (w) => w.curriculumWeek == currentAcademicWeek,
    );
    
    if (initialIndex == -1) {
      initialIndex = _weeks.lastIndexWhere((w) => !w.isLocked);
      if (initialIndex == -1) initialIndex = 0;
    }
    _selectedWeekIndex = initialIndex;
  }
  
  void _scrollToInitialWeek() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_weekScrollController.hasClients) {
        _weekScrollController.jumpTo(_selectedWeekIndex * _kItemHeight);
      }
    });
  }
  
  Future<void> _loadAllWeeksContent() async {
    await _loadWeekContent(_selectedWeekIndex);
    
    // Load surrounding weeks in background
    for (int i = _selectedWeekIndex - 1; i >= 0; i--) {
      await _loadWeekContent(i);
    }
    for (int i = _selectedWeekIndex + 1; i < _weeks.length; i++) {
      await _loadWeekContent(i);
    }
  }

  Future<void> _loadWeekContent(int index) async {
    if (!mounted) return;
    final week = _weeks[index];
    if (week.isLocked) return;

    try {
      final userId = supabase.auth.currentUser?.id;
      final weeklyData = await supabase.rpc(
        'get_weekly_curriculum',
        params: {
          'p_user_id': userId,
          'p_grade_id': widget.gradeId,
          'p_lesson_id': widget.lessonId,
          'p_curriculum_week': week.curriculumWeek,
          'p_is_admin': false,
        },
      );

      final units = _processWeeklyData(weeklyData);
      
      if (!mounted) return;
      setState(() {
        _weeks[index] = WeekV3(
          curriculumWeek: week.curriculumWeek,
          title: week.title,
          isLocked: week.isLocked,
          isCompleted: week.isCompleted,
          units: units,
        );
      });
    } catch (e) {
      debugPrint('Week load error for week ${week.curriculumWeek}: $e');
    }
  }
  
  List<UnitV3> _processWeeklyData(dynamic weeklyData) {
    final rows = (weeklyData as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final Map<int, Map<String, dynamic>> unitsMap = {};
    final Map<int, Map<String, dynamic>> topicsMap = {};

    for (final row in rows) {
      final unitId = row['unit_id'] as int?;
      final topicId = row['topic_id'] as int?;
      if (unitId == null) continue;

      if (!unitsMap.containsKey(unitId)) {
        unitsMap[unitId] = {
          'id': unitId,
          'title': row['unit_title']?.toString() ?? 'Ünite',
          'topic_ids': <int>[],
        };
      }

      if (topicId != null) {
        if (!(unitsMap[unitId]!['topic_ids'] as List<int>).contains(topicId)) {
          (unitsMap[unitId]!['topic_ids'] as List<int>).add(topicId);
        }

        if (!topicsMap.containsKey(topicId)) {
          topicsMap[topicId] = {
            'id': topicId,
            'title': row['topic_title']?.toString() ?? 'Konu',
            'outcome_ids': <int>{},
            'is_completed':
                (row['solved_questions'] as num? ?? 0) > 0 &&
                    (row['solved_questions'] as num? ?? 0) >=
                        (row['total_questions'] as num? ?? 1),
          };
        }

        final outcomeId = row['outcome_id'] as int?;
        if (outcomeId != null) {
          (topicsMap[topicId]!['outcome_ids'] as Set<int>).add(outcomeId);
        }
      }
    }

    return unitsMap.values.map((uData) {
      final topicIds = uData['topic_ids'] as List<int>;
      final topics = topicIds.map((tid) {
        final tData = topicsMap[tid]!;
        return TopicV3(
          id: tData['id'],
          title: tData['title'],
          outcomeIds: (tData['outcome_ids'] as Set<int>).toList(),
          isCompleted: tData['is_completed'] ?? false,
        );
      }).toList();

      return UnitV3(
        id: uData['id'],
        title: uData['title'],
        topics: topics,
      );
    }).toList();
  }

  void _scrollToCurrentWeek() {
    if (_currentWeekIndex != -1 && _weekScrollController.hasClients) {
      _weekScrollController.animateTo(
        _currentWeekIndex * _kItemHeight,
        duration: _AppDurations.slow,
        curve: Curves.easeInOutCubic,
      );
      setState(() => _selectedWeekIndex = _currentWeekIndex);
    }
  }

  String _formatWeekDateRange(int curriculumWeek, {bool compact = false}) {
    final (startDate, endDate) = getWeekDateRangeForAcademicWeek(curriculumWeek);
    if (compact) {
      return '${startDate.day}.${startDate.month} - ${endDate.day}.${endDate.month}';
    }
    return '${startDate.day} ${aylar[startDate.month - 1]} - '
        '${endDate.day} ${aylar[endDate.month - 1]} ${endDate.year}';
  }

  String _buildSelectedWeekSubtitle() {
    if (_weeks.isEmpty) return 'Haftalık Öğrenme Haritası';
    final safeIndex = _selectedWeekIndex.clamp(0, _weeks.length - 1);
    final selectedWeek = _weeks[safeIndex];
    return '${selectedWeek.curriculumWeek}. Hafta • '
        '${_formatWeekDateRange(selectedWeek.curriculumWeek)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppColors.slate50,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _buildLoadingView();
    if (_loadError != null) return _buildErrorView();
    if (_weeks.isEmpty) return _buildEmptyView();
    return _buildMainLayout();
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: _AppColors.white,
      surfaceTintColor: Colors.transparent,
      leading: _buildBackButton(),
      title: _buildAppBarTitle(),
      actions: [_buildRefreshButton(), const SizedBox(width: 8)],
      bottom: _buildAppBarBottom(),
    );
  }
  
  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.only(left: _AppSpacing.xs),
      child: IconButton(
        icon: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _AppColors.slate100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _AppColors.navyMid,
            size: 16,
          ),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
  
  Widget _buildAppBarTitle() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: _AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: _AppColors.blue.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(Icons.school_rounded,
              color: Colors.white, size: 20),
        ),
        const SizedBox(width: _AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.lessonName,
                style: const TextStyle(
                  color: _AppColors.navy,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: -0.4,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _buildSelectedWeekSubtitle(),
                style: const TextStyle(
                  color: _AppColors.slate400,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildRefreshButton() {
    return IconButton(
      icon: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _AppColors.slate100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.refresh_rounded,
            color: _AppColors.slate500, size: 18),
      ),
      onPressed: _loadData,
    );
  }


  
  PreferredSizeWidget _buildAppBarBottom() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(
        height: 1,
        color: _AppColors.slate200.withOpacity(0.7),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: _AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _AppColors.blue.withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                begin: const Offset(0.95, 0.95),
                end: const Offset(1.05, 1.05),
                duration: _AppDurations.slow,
                curve: Curves.easeInOut,
              ),
          const SizedBox(height: _AppSpacing.xl),
          const Text(
            'Müfredat yükleniyor...',
            style: TextStyle(
              color: _AppColors.slate500,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(_AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.error_outline_rounded,
                  size: 36, color: Color(0xFFEF4444)),
            ),
            const SizedBox(height: _AppSpacing.xl),
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: _AppColors.slate700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: _AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _AppColors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: _AppSpacing.xl, vertical: _AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _AppColors.slate100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.inbox_rounded,
                size: 36, color: _AppColors.slate400),
          ),
          const SizedBox(height: _AppSpacing.lg),
          const Text(
            'Müfredat bulunamadı',
            style: TextStyle(
              color: _AppColors.slate500,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainLayout() {
    return Row(
      children: [
        // Left: Week Rail
        Container(
          width: _kWeekRailWidth,
          decoration: const BoxDecoration(
            color: _AppColors.white,
            border: Border(
              right: BorderSide(color: _AppColors.slate200, width: 1),
            ),
          ),
          child: _buildWeekRail(),
        ),
        // Right: Units area
        Expanded(child: _buildUnitsList()),
      ],
    );
  }

  Widget _buildWeekRail() {
    final screenHeight = MediaQuery.of(context).size.height;
    final verticalPadding = screenHeight / 2 - 44;

    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: SingleChildScrollView(
        controller: _weekScrollController,
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Connector line
            Positioned(
              left: 47,
              top: _kItemHeight / 2,
              bottom: _kItemHeight / 2,
              child: CustomPaint(
                size: Size(2, (_weeks.length - 1) * _kItemHeight),
                painter: _ConnectorLinePainter(),
              ),
            ),
            // Week nodes
            Column(
              children: List.generate(_weeks.length, (index) {
                final week = _weeks[index];
                final isSelected = _selectedWeekIndex == index;
                final isCurrent = index == _currentWeekIndex;

                return _buildWeekItem(week, index, isSelected, isCurrent);
              }),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWeekItem(WeekV3 week, int index, bool isSelected, bool isCurrent) {
    return GestureDetector(
      onTap: () {
        _weekScrollController.animateTo(
          index * _kItemHeight,
          duration: _AppDurations.normal,
          curve: Curves.easeInOutCubic,
        );
      },
      child: SizedBox(
        height: _kItemHeight,
        width: _kWeekRailWidth,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildWeekNode(week, isSelected, isCurrent),
              const SizedBox(height: _AppSpacing.sm),
              AnimatedDefaultTextStyle(
                duration: _AppDurations.normal,
                style: TextStyle(
                  fontSize: isSelected ? 10 : 9,
                  fontWeight: isSelected
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: isSelected
                      ? _AppColors.navyMid
                      : _AppColors.slate400,
                  letterSpacing: 0.2,
                ),
                child: Text('Hafta ${week.curriculumWeek}'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekNode(WeekV3 week, bool isSelected, bool isCurrent) {
    final double size = isSelected ? 50 : 42;

    Color bgColor;
    Color borderColor;
    Color iconColor;
    Widget icon;
    List<BoxShadow> shadows = [];

    if (week.isCompleted) {
      bgColor = _AppColors.emerald;
      borderColor = _AppColors.emeraldDark;
      iconColor = Colors.white;
      icon = Icon(Icons.check_rounded, color: iconColor, size: 20);
      shadows = [
        BoxShadow(
          color: _AppColors.emerald.withOpacity(0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
    } else if (!week.isLocked) {
      if (isSelected) {
        bgColor = _AppColors.blue;
        borderColor = _AppColors.blueMid;
        iconColor = Colors.white;
        shadows = [
          BoxShadow(
            color: _AppColors.blue.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ];
      } else {
        bgColor = _AppColors.white;
        borderColor = isCurrent
            ? _AppColors.blue.withOpacity(0.5)
            : _AppColors.slate200;
        iconColor = isCurrent ? _AppColors.blue : _AppColors.slate400;
      }
      icon = Text(
        '${week.curriculumWeek}',
        style: TextStyle(
          color: iconColor,
          fontWeight: FontWeight.w800,
          fontSize: isSelected ? 18 : 14,
        ),
      );
    } else {
      bgColor = _AppColors.slate100;
      borderColor = _AppColors.slate200;
      iconColor = _AppColors.slate300;
      icon = Icon(Icons.lock_rounded, color: iconColor, size: 14);
    }

    Widget node = AnimatedContainer(
      duration: _AppDurations.normal,
      curve: Curves.easeOutCubic,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
        border: Border.all(
          color: borderColor,
          width: isSelected ? 2.5 : 2,
        ),
        boxShadow: shadows,
      ),
      child: Center(child: icon),
    );

    // Pulse ring for current active week
    if (isCurrent && !week.isCompleted && !week.isLocked) {
      node = AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: size + 12 + (_pulseController.value * 6),
                height: size + 12 + (_pulseController.value * 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _AppColors.blue.withOpacity(
                      0.12 * (1 - _pulseController.value)),
                ),
              ),
              child!,
            ],
          );
        },
        child: node,
      );
    }

    return node;
  }

  Widget _buildUnitsList() {
    if (_weeks.isEmpty) return const SizedBox.shrink();
    
    final selectedWeek = _weeks[_selectedWeekIndex];

    return AnimatedSwitcher(
      duration: _AppDurations.normal,
      child: WeeklyV11TopicsScreen(
        key: ValueKey<int>(selectedWeek.curriculumWeek),
        gradeId: widget.gradeId,
        lessonId: widget.lessonId,
        gradeName: _gradeName,
        lessonName: widget.lessonName,
        curriculumWeek: selectedWeek.curriculumWeek,
      ),
    );
  }
  
  Widget _buildWeekContent(WeekV3 selectedWeek) {
    if (selectedWeek.isLocked) {
      return _buildLockedWeekView(selectedWeek);
    }
    
    if (selectedWeek.units.isEmpty) {
      return _buildLoadingUnitsView();
    }
    
    return ListView.separated(
      key: ValueKey<int>(selectedWeek.curriculumWeek),
      padding: const EdgeInsets.fromLTRB(_AppSpacing.lg, _AppSpacing.lg, _AppSpacing.lg, _AppSpacing.xxl),
      itemCount: selectedWeek.units.length,
      separatorBuilder: (_, __) => const SizedBox(height: _AppSpacing.md),
      itemBuilder: (context, index) {
        final unit = selectedWeek.units[index];
        return _buildUnitCard(unit, index, selectedWeek.curriculumWeek);
      },
    );
  }

  Widget _buildWeekHeader(WeekV3 selectedWeek) {
  final Color accentColor = selectedWeek.isCompleted
      ? _AppColors.emerald
      : selectedWeek.isLocked
          ? _AppColors.slate400
          : _AppColors.blue;

  return Container(
    constraints: const BoxConstraints(minHeight: 80), // MIN HEIGHT EKLENDİ
    padding: const EdgeInsets.fromLTRB(_AppSpacing.xl, _AppSpacing.lg, _AppSpacing.xl, _AppSpacing.lg),
    decoration: BoxDecoration(
      color: _AppColors.white,
      border: Border(
        bottom: BorderSide(
          color: _AppColors.slate200.withOpacity(0.7),
        ),
      ),
    ),
    child: IntrinsicHeight( // INTRINSIC HEIGHT EKLENDİ
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: _AppSpacing.sm, vertical: 3),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${selectedWeek.curriculumWeek}. HAFTA',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: _AppSpacing.sm),
                Text(
                  selectedWeek.isCompleted
                      ? 'Tamamlandı, harika iş! ✨'
                      : selectedWeek.isLocked
                          ? 'Bu hafta henüz açılmadı'
                          : 'Bu haftanın konuları',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _AppColors.navy,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          if (!selectedWeek.isLocked && selectedWeek.units.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: _AppSpacing.md),
              child: _buildCircularProgress(selectedWeek.progress),
            ),
        ],
      ),
    ),
  );
}

  Widget _buildCircularProgress(double progress) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 4,
            backgroundColor: _AppColors.slate200,
            valueColor: const AlwaysStoppedAnimation<Color>(_AppColors.blue),
            strokeCap: StrokeCap.round,
          ),
          Text(
            '${(progress * 100).round()}%',
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: _AppColors.navyMid,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedWeekView(WeekV3 week) {
    return Center(
      key: ValueKey<int>(week.curriculumWeek),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _AppColors.slate100,
              shape: BoxShape.circle,
              border: Border.all(color: _AppColors.slate200, width: 2),
            ),
            child: const Icon(Icons.lock_rounded,
                size: 32, color: _AppColors.slate300),
          ),
          const SizedBox(height: _AppSpacing.lg),
          const Text(
            'Bu hafta henüz açılmadı',
            style: TextStyle(
              color: _AppColors.slate500,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: _AppSpacing.sm),
          Text(
            '${week.curriculumWeek}. hafta aktif olduğunda\niçerik burada görünecek.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _AppColors.slate400,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingUnitsView() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(_AppSpacing.lg, _AppSpacing.lg, _AppSpacing.lg, _AppSpacing.xxl),
      itemCount: _kSkeletonItemCount,
      separatorBuilder: (_, __) => const SizedBox(height: _AppSpacing.md),
      itemBuilder: (_, index) => _buildSkeletonCard(index),
    );
  }

  Widget _buildSkeletonCard(int index) {
    return Container(
      decoration: BoxDecoration(
        color: _AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _AppColors.slate200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(_AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _skeletonBox(width: 80, height: 18, radius: 6),
            const SizedBox(height: _AppSpacing.md),
            _skeletonBox(width: double.infinity, height: 14, radius: 4),
            const SizedBox(height: _AppSpacing.sm),
            _skeletonBox(width: 200, height: 14, radius: 4),
            const SizedBox(height: _AppSpacing.lg),
            Row(
              children: [
                Expanded(child: _skeletonBox(height: 36, radius: 10)),
                const SizedBox(width: _AppSpacing.sm),
                Expanded(child: _skeletonBox(height: 36, radius: 10)),
              ],
            ),
          ],
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(
          duration: 1200.ms,
          delay: (index * 150).ms,
          color: _AppColors.slate100,
        );
  }

  Widget _skeletonBox(
      {double? width, required double height, required double radius}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _AppColors.slate100,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _buildUnitCard(
      UnitV3 unit, int index, int curriculumWeek) {
    final completedCount =
        unit.topics.where((t) => t.isCompleted).length;
    final totalCount = unit.topics.length;

    return Container(
      decoration: BoxDecoration(
        color: _AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _AppColors.slate200.withOpacity(0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Unit header
          Container(
            padding: const EdgeInsets.fromLTRB(_AppSpacing.lg, _AppSpacing.lg, _AppSpacing.lg, _AppSpacing.md),
            decoration: BoxDecoration(
              color: _AppColors.navyMid.withOpacity(0.03),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border(
                bottom: BorderSide(
                    color: _AppColors.slate200.withOpacity(0.5)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: _AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: _AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ÜNİTE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: _AppColors.slate400,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        unit.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _AppColors.slate800,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (totalCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: _AppSpacing.sm, vertical: _AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: unit.isCompleted
                          ? _AppColors.emerald.withOpacity(0.1)
                          : _AppColors.slate100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$completedCount/$totalCount',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: unit.isCompleted
                            ? _AppColors.emerald
                            : _AppColors.slate500,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Progress bar
          if (totalCount > 0)
            LinearProgressIndicator(
              value: unit.progress,
              backgroundColor: _AppColors.slate100,
              valueColor: AlwaysStoppedAnimation<Color>(
                unit.isCompleted ? _AppColors.emerald : _AppColors.blue,
              ),
              minHeight: 3,
            ),

          // Topics
          Padding(
            padding: const EdgeInsets.all(_AppSpacing.lg),
            child: Column(
              children: unit.topics
                  .map((topic) =>
                      _buildTopicItem(unit, topic, curriculumWeek))
                  .toList(),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 60).ms, duration: _AppDurations.normal).slideY(
          begin: 0.03,
          end: 0,
          delay: (index * 60).ms,
          duration: _AppDurations.normal,
          curve: Curves.easeOut,
        );
  }

  Widget _buildTopicItem(
      UnitV3 unit, TopicV3 topic, int curriculumWeek) {
    return Padding(
      padding: const EdgeInsets.only(bottom: _AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Completion dot
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: AnimatedContainer(
                  duration: _AppDurations.normal,
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: topic.isCompleted
                        ? _AppColors.emerald
                        : _AppColors.slate300,
                  ),
                ),
              ),
              const SizedBox(width: _AppSpacing.md),
              Expanded(
                child: Text(
                  topic.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: topic.isCompleted
                        ? _AppColors.slate500
                        : _AppColors.slate800,
                    height: 1.35,
                    decoration: topic.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    decorationColor: _AppColors.slate400,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: _AppSpacing.md),
          Padding(
            padding: const EdgeInsets.only(left: 18),
            child: Row(
              children: [
                Expanded(
                  child: _TopicActionButton(
                    label: 'Konu Anlatımı',
                    icon: Icons.auto_stories_rounded,
                    color: _AppColors.violet,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WeeklyV11TopicsScreen(
                            gradeId: widget.gradeId,
                            lessonId: widget.lessonId,
                            gradeName: _gradeName,
                            lessonName: widget.lessonName,
                            curriculumWeek: curriculumWeek,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: _AppSpacing.sm),
                Expanded(
                  child: _TopicActionButton(
                    label: 'Testi Başlat',
                    icon: Icons.quiz_rounded,
                    color: _AppColors.coral,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuestionsScreen(
                            unitId: unit.id!,
                            testMode: TestMode.weekly,
                            sessionId: null,
                          ),
                          settings: RouteSettings(
                            arguments: {
                              'curriculum_week': curriculumWeek,
                              'topic_id': topic.id,
                              'outcome_ids': topic.outcomeIds,
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (unit.topics.last != topic)
            Padding(
              padding: const EdgeInsets.only(top: _AppSpacing.lg, left: 18),
              child: Divider(
                  height: 1,
                  color: _AppColors.slate200.withOpacity(0.6)),
            ),
        ],
      ),
    );
  }
}

// ========================================
// TOPIC ACTION BUTTON - Improved with better animations
// ========================================

class _TopicActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Future<void> Function() onTap;

  const _TopicActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_TopicActionButton> createState() => _TopicActionButtonState();
}

class _TopicActionButtonState extends State<_TopicActionButton> {
  bool _isLoading = false;
  bool _isHovered = false;

  Future<void> _handleTap() async {
    if (_isLoading) return;
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      await Future.delayed(const Duration(milliseconds: 150));
      await widget.onTap();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(10),
          splashColor: widget.color.withOpacity(0.1),
          highlightColor: widget.color.withOpacity(0.06),
          child: AnimatedContainer(
            duration: _AppDurations.fast,
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: widget.color.withOpacity(_isLoading ? 0.12 : (_isHovered ? 0.12 : 0.07)),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.color.withOpacity(_isHovered ? 0.4 : 0.2),
                width: _isHovered ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading)
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: widget.color,
                    ),
                  )
                else
                  Icon(widget.icon, size: 15, color: widget.color),
                const SizedBox(width: 5),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: widget.color,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ========================================
// PAINTERS - Improved connector line
// ========================================

class _ConnectorLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dashPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const double dashHeight = 6;
    const double gap = 4;
    double y = 0;
    
    while (y < size.height) {
      canvas.drawLine(
        const Offset(0, 0),
        Offset(0, dashHeight),
        dashPaint,
      );
      y += dashHeight + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
