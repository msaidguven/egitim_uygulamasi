import 'package:egitim_uygulamasi/main.dart';
import 'package:egitim_uygulamasi/models/profile_model.dart';
import 'package:egitim_uygulamasi/screens/home/unit_map_v2_screen.dart';
import 'package:egitim_uygulamasi/screens/lesson_content/lesson_page.dart';
import 'package:egitim_uygulamasi/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

class HomeV5Screen extends ConsumerStatefulWidget {
  final Profile? profile;

  const HomeV5Screen({super.key, this.profile});

  @override
  ConsumerState<HomeV5Screen> createState() => _HomeV5ScreenState();
}

class _HomeV5ScreenState extends ConsumerState<HomeV5Screen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _lessonData = [];
  List<Map<String, dynamic>> _dailyQuests = [];
  List<Map<String, dynamic>> _achievements = [];
  bool _isLoading = false;
  int _userLevel = 1;
  int _userXP = 0;
  int _nextLevelXP = 1000;
  int _streakDays = 0;

  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _fetchGameData();

    _floatController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _fetchGameData() async {
    if (widget.profile == null || widget.profile!.gradeId == null) return;

    setState(() => _isLoading = true);

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

      if (!mounted) return;

      // Rastgele görev ve başarım verileri oluştur (gerçek API'den gelecek)
      final mockQuests = _generateDailyQuests();
      final mockAchievements = _generateAchievements();

      // Kullanıcı seviyesini hesapla (toplam çözülen sorulara göre)
      final totalSolved = (response as List).fold<int>(
        0,
        (sum, item) => sum + ((item['solved_questions'] as num? ?? 0).toInt()),
      );

      final level = (totalSolved / 50).floor() + 1;
      final xp = totalSolved % 50;
      final nextLevelXp = 50;

      setState(() {
        _lessonData = List<Map<String, dynamic>>.from(response);
        _dailyQuests = mockQuests;
        _achievements = mockAchievements;
        _userLevel = level;
        _userXP = xp;
        _nextLevelXP = nextLevelXp;
        _streakDays = _calculateStreak();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('HomeV5 veri çekme hatası: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _generateDailyQuests() {
    return [
      {
        'id': 1,
        'title': '10 Matematik Sorusu Çöz',
        'progress': 3,
        'total': 10,
        'xp': 50,
        'completed': false,
      },
      {
        'id': 2,
        'title': '5 Fen Sorusu Çöz',
        'progress': 5,
        'total': 5,
        'xp': 40,
        'completed': true,
      },
      {
        'id': 3,
        'title': 'Kesintisiz 20 Dakika Çalış',
        'progress': 15,
        'total': 20,
        'xp': 60,
        'completed': false,
      },
      {
        'id': 4,
        'title': '2 Farklı Dersten Soru Çöz',
        'progress': 1,
        'total': 2,
        'xp': 30,
        'completed': false,
      },
    ];
  }

  List<Map<String, dynamic>> _generateAchievements() {
    return [
      {
        'id': 1,
        'title': 'Matematik Dehası',
        'description': '100 matematik sorusu çöz',
        'progress': 67,
        'total': 100,
        'icon': Icons.calculate_rounded,
        'color': const Color(0xFF2563EB),
      },
      {
        'id': 2,
        'title': 'Fen Kaşifi',
        'description': '50 fen sorusu çöz',
        'progress': 32,
        'total': 50,
        'icon': Icons.biotech_rounded,
        'color': const Color(0xFF059669),
      },
      {
        'id': 3,
        'title': 'Türkçe Üstadı',
        'description': '75 Türkçe sorusu çöz',
        'progress': 45,
        'total': 75,
        'icon': Icons.menu_book_rounded,
        'color': const Color(0xFFDC2626),
      },
      {
        'id': 4,
        'title': '7 Gün Seri',
        'description': '7 gün boyunca her gün soru çöz',
        'progress': 4,
        'total': 7,
        'icon': Icons.whatshot_rounded,
        'color': const Color(0xFFD97706),
      },
    ];
  }

  int _calculateStreak() {
    // Gerçek uygulamada veritabanından gelecek
    return math.Random().nextInt(15) + 1;
  }

  int _totalSolved() {
    return _lessonData.fold<int>(
      0,
      (sum, item) => sum + ((item['solved_questions'] as num? ?? 0).toInt()),
    );
  }

  void _handleLessonTap(String lessonName, {int? lessonId}) {
    if (widget.profile == null) {
      _showLoginDialog();
      return;
    }

    if (lessonId != null && widget.profile!.gradeId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UnitMapV2Screen(
            lessonId: lessonId,
            lessonName: lessonName,
            gradeId: widget.profile!.gradeId!,
          ),
        ),
      );
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Giriş Gerekli'),
        content: const Text(
          'Görevlere erişmek ve ilerlemeni kaydetmek için giriş yap.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Giriş Yap'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = widget.profile != null;
    final fullName = widget.profile?.fullName ?? 'Kaşif';
    final firstName = fullName.trim().split(' ').first;
    final totalSolved = _totalSolved();
    final canGoBack = Navigator.of(context).canPop();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E1B4B), Color(0xFF2D1B4B), Color(0xFF1A1A2E)],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : Stack(
                  children: [
                    // Arkaplan yıldızları
                    ...List.generate(30, (index) => _buildStar()),

                    // Ana içerik
                    Column(
                      children: [
                        _buildProfileHeader(
                          firstName,
                          totalSolved,
                          isLoggedIn,
                          canGoBack,
                        ),
                        const SizedBox(height: 8),
                        _buildLevelProgress(),
                        const SizedBox(height: 16),
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Column(
                              children: [
                                _buildDailyQuests(),
                                const SizedBox(height: 24),
                                _buildAchievements(),
                                const SizedBox(height: 24),
                                _buildLessonGrid(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildStar() {
    final random = math.Random();
    final size = random.nextDouble() * 4 + 2;
    final left = random.nextDouble() * MediaQuery.of(context).size.width;
    final top = random.nextDouble() * MediaQuery.of(context).size.height;
    final delay = random.nextInt(2000);

    return Positioned(
      left: left,
      top: top,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.3, end: 1.0),
        duration: Duration(milliseconds: 1500 + delay),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5 + (value * 0.3)),
                shape: BoxShape.circle,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(
    String name,
    int totalSolved,
    bool isLoggedIn,
    bool canGoBack,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          if (canGoBack) ...[
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.12),
                foregroundColor: Colors.white,
                minimumSize: const Size(38, 38),
              ),
            ),
            const SizedBox(width: 8),
          ],
          PopupMenuButton<String>(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            offset: const Offset(0, 65),
            onSelected: (value) {
              if (value == 'lesson_preview') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LessonPage()),
                );
              }
            },
            itemBuilder: (context) => [
              if (widget.profile?.role == 'admin')
                const PopupMenuItem(
                  value: 'lesson_preview',
                  child: Row(
                    children: [
                      Icon(Icons.visibility_rounded, color: Color(0xFF4F46E5)),
                      SizedBox(width: 12),
                      Text('Ders Sayfası Önizleme'),
                    ],
                  ),
                ),
            ],
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFBBF24), width: 2),
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFF4F46E5),
                child: Text(
                  name[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLoggedIn ? 'MERHABA, $name!' : 'MİSAFİR KAŞİF',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBBF24).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFFBBF24),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFBBF24),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Seviye $_userLevel',
                            style: const TextStyle(
                              color: Color(0xFFFBBF24),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFEF4444),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.whatshot_rounded,
                            color: Color(0xFFEF4444),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$_streakDays Gün',
                            style: const TextStyle(
                              color: Color(0xFFEF4444),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.diamond_rounded,
                  color: Color(0xFFFBBF24),
                  size: 24,
                ),
                Text(
                  '$totalSolved',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildLevelProgress() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Seviye $_userLevel',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _userXP / _nextLevelXP,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFFBBF24),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_userXP / $_nextLevelXP XP',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Transform.translate(
            offset: Offset(0, _floatAnimation.value),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.rocket_launch_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildDailyQuests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Icon(
                Icons.event_available_rounded,
                color: Color(0xFF4F46E5),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'GÜNLÜK GÖREVLER',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_dailyQuests.where((q) => q['completed'] == true).length}/${_dailyQuests.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _dailyQuests.length,
            itemBuilder: (context, index) {
              final quest = _dailyQuests[index];
              final progress = quest['progress'] / quest['total'];
              final isCompleted = quest['completed'];

              return Container(
                    width: 180,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isCompleted
                            ? [const Color(0xFF059669), const Color(0xFF10B981)]
                            : [
                                const Color(0xFF2D2D4A),
                                const Color(0xFF1E1E3F),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isCompleted
                            ? const Color(0xFF10B981)
                            : const Color(0xFF4F46E5),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                quest['title'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isCompleted)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 4,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.2,
                                  ),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Color(0xFFFBBF24),
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${quest['progress']}/${quest['total']}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFBBF24),
                              size: 14,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '+${quest['xp']} XP',
                              style: const TextStyle(
                                color: Color(0xFFFBBF24),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(delay: (300 + index * 100).ms)
                  .slideX(begin: 0.2, end: 0);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAchievements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(
                Icons.emoji_events_rounded,
                color: Color(0xFFFBBF24),
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'BAŞARIMLAR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _achievements.length,
            itemBuilder: (context, index) {
              final achievement = _achievements[index];
              final progress = achievement['progress'] / achievement['total'];

              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D4A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 50,
                          height: 50,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 3,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.1,
                            ),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              achievement['color'],
                            ),
                          ),
                        ),
                        Icon(
                          achievement['icon'],
                          color: achievement['color'],
                          size: 24,
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            achievement['title'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            achievement['description'],
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${achievement['progress']}/${achievement['total']}',
                            style: TextStyle(
                              color: achievement['color'],
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: (400 + index * 100).ms);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLessonGrid() {
    if (_lessonData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Sınıfına ait ders bulunamadı.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(Icons.map_rounded, color: Color(0xFF10B981), size: 24),
              SizedBox(width: 8),
              Text(
                'DERS HARİTASI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final maxGridWidth = width >= 1700
                ? 1480.0
                : width >= 1300
                ? 1260.0
                : 1080.0;

            int crossAxisCount;
            double childAspectRatio;
            if (width >= 1700) {
              crossAxisCount = 6;
              childAspectRatio = 1.18;
            } else if (width >= 1400) {
              crossAxisCount = 5;
              childAspectRatio = 1.15;
            } else if (width >= 1100) {
              crossAxisCount = 5;
              childAspectRatio = 1.1;
            } else if (width >= 840) {
              crossAxisCount = 4;
              childAspectRatio = 1.08;
            } else if (width >= 620) {
              crossAxisCount = 3;
              childAspectRatio = 1.06;
            } else {
              crossAxisCount = 2;
              childAspectRatio = 1.16;
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxGridWidth),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: childAspectRatio,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _lessonData.length,
                    itemBuilder: (context, index) {
                      final item = _lessonData[index];
                      final name = item['lesson_name'] as String;
                      final solvedQ = ((item['solved_questions'] ?? 0) as num)
                          .toInt();
                      final totalQ = ((item['total_questions'] ?? 10) as num)
                          .toInt();
                      final safeTotalQ = totalQ <= 0 ? 1 : totalQ;
                      final progress = solvedQ / safeTotalQ;

                      return _buildLessonCard(
                        index: index,
                        name: name,
                        icon: _getIconForLesson(name),
                        color: _getLessonColor(name),
                        progress: progress,
                        solved: solvedQ,
                        total: safeTotalQ,
                        onTap: () => _handleLessonTap(
                          name,
                          lessonId: item['lesson_id'] as int?,
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLessonCard({
    required int index,
    required String name,
    required IconData icon,
    required Color color,
    required double progress,
    required int solved,
    required int total,
    required VoidCallback onTap,
  }) {
    return InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withValues(alpha: 0.2), const Color(0xFF2D2D4A)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$solved/$total',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: (500 + index * 100).ms)
        .scale(begin: const Offset(0.95, 0.95));
  }

  Color _getLessonColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('mat')) return const Color(0xFF2563EB);
    if (lower.contains('fen')) return const Color(0xFF059669);
    if (lower.contains('türk')) return const Color(0xFFDC2626);
    if (lower.contains('sos')) return const Color(0xFFD97706);
    if (lower.contains('ing')) return const Color(0xFF7C3AED);
    return const Color(0xFF0EA5E9);
  }

  IconData _getIconForLesson(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('mat')) return Icons.calculate_rounded;
    if (lower.contains('türk')) return Icons.menu_book_rounded;
    if (lower.contains('fen')) return Icons.biotech_rounded;
    if (lower.contains('sos')) return Icons.history_edu_rounded;
    if (lower.contains('din')) return Icons.mosque_rounded;
    if (lower.contains('ing')) return Icons.translate_rounded;
    return Icons.school_rounded;
  }
}
