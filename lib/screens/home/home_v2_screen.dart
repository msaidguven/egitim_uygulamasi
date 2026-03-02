import 'package:egitim_uygulamasi/main.dart';
import 'package:egitim_uygulamasi/screens/unit_summary_screen.dart';
import 'package:egitim_uygulamasi/screens/units_for_lesson_screen.dart';
import 'package:egitim_uygulamasi/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:egitim_uygulamasi/models/profile_model.dart';
import 'package:egitim_uygulamasi/viewmodels/profile_viewmodel.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeV2Screen extends ConsumerStatefulWidget {
  final Profile? profile;

  const HomeV2Screen({super.key, this.profile});

  @override
  ConsumerState<HomeV2Screen> createState() => _HomeV2ScreenState();
}

class _HomeV2ScreenState extends ConsumerState<HomeV2Screen> {
  final TransformationController _transformationController =
      TransformationController();
  List<Map<String, dynamic>> _agendaData = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  @override
  void dispose() {
    _transformationController.dispose();
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
        // Öncelik ID eşleşmesinde
        if (lessonId != null && item['lesson_id'] == lessonId) return true;
        
        final dbName = item['lesson_name'].toString().toLowerCase();
        final searchName = lessonName.toLowerCase();
        return dbName == searchName || 
               dbName.contains(searchName) || 
               searchName.contains(dbName);
      },
      orElse: () => {},
    );

    final unitId = lessonData['current_unit_id'];
    final foundLessonId = lessonData['lesson_id'];

    if (unitId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UnitSummaryScreen(unitId: unitId),
        ),
      );
    } else if (foundLessonId != null && widget.profile!.gradeId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UnitsForLessonScreen(
            gradeId: widget.profile!.gradeId!,
            lessonId: foundLessonId,
            lessonName: lessonName,
          ),
        ),
      );
    } else {
      debugPrint('$lessonName için unitId veya lessonId bulunamadı. Agenda size: ${_agendaData.length}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$lessonName dersine ait aktif ünite bulunamadı.')),
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
      backgroundColor: Colors.white,
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
          // 1. Harita Arka Planı (InteractiveViewer)
          Positioned.fill(
            child: _MapContainerV2(
              onLessonTap: _handleLessonTap,
            ),
          ),

          // 2. HUD Panel (Sağ Üst)
          Positioned(
            top: 16,
            right: 16,
            child: _FloatingHUD(agendaData: _agendaData),
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
                  _handleLessonTap(lastStudied['lesson_name']);
                }
              },
            ),
          ),

          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
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
        const Icon(Icons.explore_rounded, color: Color(0xFF6366F1), size: 24),
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
            color: Colors.black.withOpacity(0.1),
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

class _MapContainerV2 extends StatelessWidget {
  final void Function(String, {int? lessonId}) onLessonTap;

  const _MapContainerV2({required this.onLessonTap});

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      panEnabled: true,
      scaleEnabled: false,
      minScale: 1.0,
      maxScale: 1.0,
      constrained: false,
      boundaryMargin: const EdgeInsets.all(500),
      child: Stack(
        children: [
          // Harita Görseli
          Image.asset(
            'assets/images/turkey_map_v2.png',
            width: 1500, // Geniş harita daha iyi pan tecrübesi sağlar
            fit: BoxFit.cover,
          ),

          // Ders İkonları - Türkiye Haritası üzerinde responsive konumlandırma (Tahmini %)
          _CourseIconV2(
            label: 'Matematik',
            lessonId: 1,
            top: 250, // Marmara/İstanbul civarı
            left: 280,
            icon: Icons.calculate_rounded,
            color: const Color(0xFF3B82F6),
            onTap: () => onLessonTap('Matematik', lessonId: 1),
          ),
          _CourseIconV2(
            label: 'Türkçe',
            lessonId: 2,
            top: 350, // Doğu Anadolu civarı
            left: 1100,
            icon: Icons.menu_book_rounded,
            color: const Color(0xFFEF4444),
            onTap: () => onLessonTap('Türkçe', lessonId: 2),
          ),
          _CourseIconV2(
            label: 'Fen Bilimleri',
            lessonId: 3,
            top: 380, // İç Anadolu/Ankara civarı
            left: 650,
            icon: Icons.biotech_rounded,
            color: const Color(0xFF10B981),
            onTap: () => onLessonTap('Fen Bilimleri', lessonId: 3),
          ),
          _CourseIconV2(
            label: 'Sosyal Bilgiler',
            lessonId: 4,
            top: 500, // Ege civarı
            left: 200,
            icon: Icons.history_edu_rounded,
            color: const Color(0xFFF59E0B),
            onTap: () => onLessonTap('Sosyal Bilgiler', lessonId: 4),
          ),
          _CourseIconV2(
            label: 'İngilizce',
            lessonId: 6,
            top: 650, // Akdeniz civarı
            left: 450,
            icon: Icons.translate_rounded,
            color: const Color(0xFF8B5CF6),
            onTap: () => onLessonTap('İngilizce', lessonId: 6),
          ),
        ],
      ),
    );
  }
}

class _CourseIconV2 extends StatelessWidget {
  final double top;
  final double left;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final int? lessonId;

  const _CourseIconV2({
    required this.top,
    required this.left,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.lessonId,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Pulsating Glow
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .scale(begin: const Offset(1, 1), end: const Offset(1.3, 1.3), duration: 1000.ms)
                    .fadeOut(duration: 1000.ms),

                // Main Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade900,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingHUD extends StatelessWidget {
  final List<Map<String, dynamic>> agendaData;
  const _FloatingHUD({required this.agendaData});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'İlerleme',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const Divider(height: 12),
          ...agendaData.take(4).map((item) {
            final double progress = ((item['solved_questions'] ?? 0) as num).toDouble() /
                (max(1, ((item['total_questions'] ?? 10) as num).toInt()).toDouble());
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['lesson_name'],
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: Colors.grey.shade200,
                    color: progress > 0 
                      ? _getLessonColor(item['lesson_name'])
                      : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    ).animate().slideX(begin: 1).fadeIn();
  }

  Color _getLessonColor(String name) {
    if (name.contains('Mat')) return Colors.blue;
    if (name.contains('Fen')) return Colors.green;
    if (name.contains('Türk')) return Colors.red;
    if (name.contains('Sos')) return Colors.orange;
    return Colors.purple;
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
    String subtitle = isLoggedIn ? 'Veri yükleniyor...' : 'Başlamak için ders seç';

    if (isLoggedIn && lastStudied != null) {
      title = '📌 Son Çalıştığın: ${lastStudied!['lesson_name']}';
      subtitle = 'Konu: ${lastStudied!['current_topic_title'] ?? 'Derse Devam Et'}';
    }

    return Container(
      height: 90,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.3),
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
                ),
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
          ElevatedButton(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
    ).animate().slideY(begin: 1, duration: 500.ms, curve: Curves.easeOutCubic);
  }
}

int max(int a, int b) => a > b ? a : b;
