import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../unit_summary_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchUnitMapData();
  }

  Future<void> _fetchUnitMapData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // TODO: Implement current week calculation logic (can be passed from home or calculated)
      const currentWeek = 24; // Örnek değer

      final response = await _supabase.rpc(
        'get_unit_map_data',
        params: {
          'p_user_id': userId,
          'p_lesson_id': widget.lessonId,
          'p_grade_id': widget.gradeId,
          'p_current_week': currentWeek,
        },
      );

      final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(response);
      
      double totalSolved = 0;
      double totalQ = 0;
      for (var item in data) {
        totalSolved += (item['solved_questions'] as num).toDouble();
        totalQ += (item['total_questions'] as num).toDouble();
      }

      setState(() {
        _units = data;
        _totalProgress = totalQ > 0 ? (totalSolved / totalQ) : 0;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Unit map verisi çekilirken hata: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // Kaydırılabilir Harita
          if (!_isLoading) _buildMap(),

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
              child: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
            ),
          ),

          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return InteractiveViewer(
      constrained: false,
      boundaryMargin: const EdgeInsets.all(500),
      minScale: 0.5,
      maxScale: 2.0,
      child: Stack(
        children: [
          Image.asset(
            'assets/images/unit_map_v2.png',
            width: 1200,
            height: 1200,
            fit: BoxFit.cover,
          ),
          
          // Ünite Adaları/Simgeleri
          ..._buildUnitNodes(),
        ],
      ),
    );
  }

  List<Widget> _buildUnitNodes() {
    // Harita üzerindeki konumlar (Tahmini)
    final List<Offset> positions = [
      const Offset(200, 800),
      const Offset(350, 600),
      const Offset(550, 700),
      const Offset(700, 500),
      const Offset(850, 350),
      const Offset(650, 200),
      const Offset(1000, 250),
    ];

    List<Widget> nodes = [];

    for (int i = 0; i < _units.length; i++) {
      final unit = _units[i];
      final pos = positions[i % positions.length];
      final isSolved = (unit['solved_questions'] as num) > 0;
      final isCurrent = unit['is_current_week'] == true;
      
      nodes.add(
        Positioned(
          left: pos.dx,
          top: pos.dy,
          child: _UnitNode(
            title: unit['title'],
            isSolved: isSolved,
            isCurrent: isCurrent,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UnitSummaryScreen(unitId: unit['unit_id']),
                ),
              );
            },
          ),
        ),
      );
    }
    return nodes;
  }

  Widget _buildHUD() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.map_outlined, color: Color(0xFF6366F1)),
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
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Ünite Yolculuğu',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
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
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6366F1),
                ),
              ),
              const Text(
                'Toplam İlerleme',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0);
  }
}

class _UnitNode extends StatelessWidget {
  final String title;
  final bool isSolved;
  final bool isCurrent;
  final VoidCallback onTap;

  const _UnitNode({
    required this.title,
    required this.isSolved,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSolved 
        ? const Color(0xFF10B981) 
        : (isCurrent ? const Color(0xFF6366F1) : Colors.grey.shade400);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              if (isCurrent)
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2))
                  .fadeOut(),
              
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
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    isSolved ? Icons.check_circle : Icons.play_circle_fill,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(10),
            ),
            constraints: const BoxConstraints(maxWidth: 100),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
