import 'package:egitim_uygulamasi/main.dart';
import 'unit_map_v2_screen.dart';
import 'package:egitim_uygulamasi/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:egitim_uygulamasi/models/profile_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeV2Screen extends ConsumerStatefulWidget {
  final Profile? profile;

  const HomeV2Screen({super.key, this.profile});

  @override
  ConsumerState<HomeV2Screen> createState() => _HomeV2ScreenState();
}

class _HomeV2ScreenState extends ConsumerState<HomeV2Screen> {
  List<Map<String, dynamic>> _agendaData = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchDashboardData() async {
    if (widget.profile == null || widget.profile!.gradeId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentWeek = calculateCurrentAcademicWeek();
      final response = await supabase.rpc(
        'get_weekly_dashboard_agenda',
        params: {
          'p_user_id': widget.profile!.id,
          'p_grade_id': widget.profile!.gradeId,
          'p_curriculum_week': currentWeek,
        },
      );

      setState(() {
        _agendaData = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
      debugPrint('HomeV2 Agenda: ${_agendaData.map((e) => e['lesson_name']).toList()}');
    } catch (e) {
      debugPrint('Dashboard verisi çekilirken hata: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleLessonTap(String lessonName, {int? lessonId}) {
    debugPrint('Tapped Lesson: $lessonName (ID: $lessonId)');
    if (widget.profile == null) {
      _showLoginDialog();
      return;
    }

    final lessonData = _agendaData.firstWhere(
      (item) {
        if (lessonId != null && item['lesson_id'] == lessonId) return true;
        
        final dbName = item['lesson_name'].toString().toLowerCase();
        final searchName = lessonName.toLowerCase();
        return dbName == searchName || 
               dbName.contains(searchName) || 
               searchName.contains(dbName);
      },
      orElse: () => {},
    );

    final foundLessonId = lessonData['lesson_id'] ?? lessonId;

    if (foundLessonId != null && widget.profile!.gradeId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UnitMapV2Screen(
            lessonId: foundLessonId,
            lessonName: lessonName,
            gradeId: widget.profile!.gradeId!,
          ),
        ),
      );
    } else {
      debugPrint('$lessonName için lessonId bulunamadı. Agenda size: ${_agendaData.length}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$lessonName dersine ait bilgi bulunamadı.')),
      );
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Giriş Gerekli'),
        content: const Text(
          'Ders içeriklerine erişmek ve ilerlemeni kaydetmek için lütfen giriş yap.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Giriş Yap'),
          ),
        ],
      ),
    );
  }

  Color _getLessonColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('mat')) return const Color(0xFF3B82F6);
    if (lower.contains('fen')) return const Color(0xFF10B981);
    if (lower.contains('türk')) return const Color(0xFFEF4444);
    if (lower.contains('sos')) return const Color(0xFFF59E0B);
    if (lower.contains('ing')) return const Color(0xFF8B5CF6);
    return const Color(0xFF6366F1); // Default
  }

  IconData _getIconForLesson(String name) {
     final lower = name.toLowerCase();
     if (lower.contains('mat')) return Icons.calculate_rounded;
     if (lower.contains('türk')) return Icons.menu_book_rounded;
     if (lower.contains('fen')) return Icons.biotech_rounded;
     if (lower.contains('sos')) return Icons.history_edu_rounded;
     if (lower.contains('din')) return Icons.mosque_rounded;
     if (lower.contains('ing')) return Icons.translate_rounded;
     return Icons.school_rounded; // Default
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = widget.profile != null;
    final fullName = widget.profile?.fullName;
    final initials = fullName != null && fullName.isNotEmpty
        ? fullName.substring(0, 1).toUpperCase()
        : '?';

    final lastStudied = _agendaData.isNotEmpty
        ? _agendaData.reduce((a, b) =>
            ((a['solved_questions'] ?? 0) as num) >=
                    ((b['solved_questions'] ?? 0) as num)
                ? a
                : b)
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Sade, temiz oyun arkaplanı
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: _LogoTextV3(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _UserAvatar(initials: initials),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Yatay Scroll Haritası
          Positioned.fill(
             child: _isLoading 
                ? const Center(child: CircularProgressIndicator()) 
                : _buildHorizontalMap(),
          ),

          // 2. HUD Panel (Sağ Üst)
          Positioned(
            top: 16,
            right: 16,
            child: _FloatingHUD(
               agendaData: _agendaData,
               getColorFn: _getLessonColor,
            ),
          ),

          // 3. Alt Panel (BottomInfoPanel)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomInfoPanelV2(
              isLoggedIn: isLoggedIn,
              lastStudied: lastStudied,
              onAction: () {
                if (lastStudied != null) {
                  _handleLessonTap(lastStudied['lesson_name'], lessonId: lastStudied['lesson_id']);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalMap() {
     if (_agendaData.isEmpty) {
        return const Center(child: Text("Sınıfınıza atanmış ders bulunamadı."));
     }

     return Center(
        child: SingleChildScrollView(
           controller: _scrollController,
           scrollDirection: Axis.horizontal,
           physics: const BouncingScrollPhysics(),
           padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width / 4, 
              vertical: 100
           ),
           child: SizedBox(
              height: 380, // Zikzak yükseklik alanı
              child: CustomPaint(
                 painter: _LessonPathPainter(lessonsCount: _agendaData.length),
                 child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: List.generate(_agendaData.length, (index) {
                       return _buildLessonNodeWrapper(index);
                    }),
                 ),
              ),
           ),
        ),
     );
  }

  Widget _buildLessonNodeWrapper(int index) {
      final item = _agendaData[index];
      final lessonId = item['lesson_id'] as int;
      final name = item['lesson_name'] as String;
      
      final color = _getLessonColor(name);
      final icon = _getIconForLesson(name);

      final int solvedQ = ((item['solved_questions'] ?? 0) as num).toInt();
      final int totalQ = max(1, ((item['total_questions'] ?? 10) as num).toInt()); // 0'a bölme olmasın
      final double progress = (solvedQ / totalQ).clamp(0.0, 1.0);

      // Zik-Zak animasyonu için offset
      final isUp = index % 2 == 0;
      final yOffset = isUp ? -80.0 : 80.0;
      
      return Container(
          width: 200, // Her bir düğüm arası mesafe
          alignment: Alignment.center,
          transform: Matrix4.translationValues(0, yOffset, 0),
          child: _CourseIconV3(
            label: name,
            lessonId: lessonId,
            icon: icon,
            color: color,
            progress: progress,
            onTap: () => _handleLessonTap(name, lessonId: lessonId),
          ),
      );
  }
}

class _LogoTextV3 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.explore_rounded, color: Color(0xFF6366F1), size: 28),
        const SizedBox(width: 8),
        Text(
          'Öğrenme Haritası',
          style: TextStyle(
            color: Colors.grey.shade900,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final String initials;
  const _UserAvatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: const Color(0xFF6366F1),
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _LessonPathPainter extends CustomPainter {
   final int lessonsCount;
   
   _LessonPathPainter({required this.lessonsCount});

  @override
  void paint(Canvas canvas, Size size) {
    if (lessonsCount < 2) return;

    final double nodeWidth = 200.0;
    
    // Çizgi Stilleri
    final Paint linePaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < lessonsCount - 1; i++) {
        final isUp1 = i % 2 == 0;
        final isUp2 = (i + 1) % 2 == 0;
        
        final dx1 = (i * nodeWidth) + (nodeWidth / 2);
        final dy1 = (size.height / 2) + (isUp1 ? -80.0 : 80.0);
        
        final dx2 = ((i + 1) * nodeWidth) + (nodeWidth / 2);
        final dy2 = (size.height / 2) + (isUp2 ? -80.0 : 80.0);
        
        final p1 = Offset(dx1, dy1);
        final p2 = Offset(dx2, dy2);

        final path = Path();
        path.moveTo(p1.dx, p1.dy);
        
        // Bezier eğrisi
        final controlPoint1 = Offset(dx1 + (nodeWidth / 3), dy1);
        final controlPoint2 = Offset(dx2 - (nodeWidth / 3), dy2);
        
        path.cubicTo(
           controlPoint1.dx, controlPoint1.dy, 
           controlPoint2.dx, controlPoint2.dy, 
           p2.dx, p2.dy
        );

        canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CourseIconV3 extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final int lessonId;
  final double progress;

  const _CourseIconV3({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.lessonId,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    bool hasProgress = progress > 0;

    Widget content = GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Pulse Glow Animation
              Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 15,
                      spreadRadius: 8,
                    ),
                  ],
                ),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
               .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 2000.ms)
               .fadeOut(duration: 2000.ms),

              // Main Circular Icon
              Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                   // Eğer %100 değilse progress indicator
                   child: hasProgress 
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                             CircularProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.transparent,
                                color: color.withValues(alpha: 0.3),
                                strokeWidth: 5,
                             ),
                             Icon(icon, color: color, size: 30),
                          ],
                        )
                      : Icon(icon, color: color, size: 30),
                ),
              ),

              // Progress Badge
              if (hasProgress)
                 Positioned(
                    top: -5,
                    right: -5,
                    child: Container(
                       padding: const EdgeInsets.all(4),
                       decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          shape: BoxShape.circle,
                          border: Border.all(color: color, width: 2),
                       ),
                       child: Text(
                          '%${(progress * 100).toInt()}',
                          style: const TextStyle(
                             color: Colors.white,
                             fontSize: 9,
                             fontWeight: FontWeight.bold,
                          ),
                       ),
                    ),
                 )
            ],
          ),
          const SizedBox(height: 12),
          
          // Modern Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade900,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );

    // Floating effect
    return content.animate(onPlay: (c) => c.repeat())
                  .moveY(begin: -6, end: 6, duration: 2500.ms, curve: Curves.easeInOutSine)
                  .then()
                  .moveY(begin: 6, end: -6, duration: 2500.ms, curve: Curves.easeInOutSine);
  }
}

class _FloatingHUD extends StatelessWidget {
  final List<Map<String, dynamic>> agendaData;
  final Color Function(String) getColorFn;

  const _FloatingHUD({
     required this.agendaData,
     required this.getColorFn,
  });

  @override
  Widget build(BuildContext context) {
    if (agendaData.isEmpty) return const SizedBox.shrink();

    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
             children: [
                Icon(Icons.bar_chart_rounded, size: 16, color: Colors.indigo.shade400),
                const SizedBox(width: 4),
                const Text(
                  'Genel Durum',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
             ],
          ),
          const Divider(height: 12),
          ...agendaData.take(4).map((item) {
            final double progress = ((item['solved_questions'] ?? 0) as num).toDouble() /
                (max(1, ((item['total_questions'] ?? 10) as num).toInt()).toDouble());
            final color = getColorFn(item['lesson_name']);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                        Text(
                          item['lesson_name'],
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                        ),
                        Text(
                           '%${(progress * 100).toInt()}',
                           style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
                        )
                     ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                     borderRadius: BorderRadius.circular(4),
                     child: LinearProgressIndicator(
                       value: progress > 0 ? progress : 0,
                       minHeight: 5,
                       backgroundColor: Colors.grey.shade200,
                       color: progress > 0 ? color : Colors.grey.shade400,
                     ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    ).animate().slideX(begin: 1).fadeIn();
  }
}

class _BottomInfoPanelV2 extends StatelessWidget {
  final bool isLoggedIn;
  final Map<String, dynamic>? lastStudied;
  final VoidCallback onAction;

  const _BottomInfoPanelV2({
    required this.isLoggedIn,
    this.lastStudied,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    String title = isLoggedIn ? '📌 Son Çalıştığın' : 'Hoş geldin 👋';
    String subtitle = isLoggedIn ? 'Derse devam etmek için tıkla' : 'Başlamak için haritadan ders seç';

    if (isLoggedIn && lastStudied != null) {
      title = '📌 Son Çalıştığın: ${lastStudied!['lesson_name']}';
      subtitle = 'Konu: ${lastStudied!['current_topic_title'] ?? 'Derse Devam Et'}';
    }

    return Container(
      height: 90,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Slate 900
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.blueGrey.shade300,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1), // Indigo 500
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: const Color(0xFF6366F1).withValues(alpha: 0.5),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              isLoggedIn ? 'Devam Et' : 'Dersleri Gör',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: 1, duration: 600.ms, curve: Curves.easeOutCubic);
  }
}

int max(int a, int b) => a > b ? a : b;
