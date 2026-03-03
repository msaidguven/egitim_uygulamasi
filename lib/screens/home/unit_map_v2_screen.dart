import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../unit_summary_screen.dart';

abstract class TimelineItem {}

class UnitHeaderItem extends TimelineItem {
  final int unitId;
  final String title;
  final int totalQuestions;
  final int solvedQuestions;
  UnitHeaderItem(this.unitId, this.title, this.totalQuestions, this.solvedQuestions);
}

class WeekItem extends TimelineItem {
  final int weekNo;
  final int unitId;
  final bool isCurrent;
  final bool isCompleted;
  final bool isLocked;
  final String topics;
  final int totalQuestions;
  final int solvedQuestions;
  
  WeekItem({
    required this.weekNo,
    required this.unitId,
    required this.isCurrent,
    required this.isCompleted,
    required this.isLocked,
    required this.topics,
    required this.totalQuestions,
    required this.solvedQuestions,
  });
}

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
  List<TimelineItem> _timeline = [];
  List<GlobalKey> _keys = [];
  bool _isLoading = true;
  int _activeItemIndex = -1;
  final ScrollController _scrollController = ScrollController();

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
      if (userId == null) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        return;
      }
      
      const currentWeek = 24;

      final response = await _supabase.rpc(
        'get_weekly_timeline_data',
        params: {
          'p_user_id': userId,
          'p_lesson_id': widget.lessonId,
          'p_grade_id': widget.gradeId,
          'p_current_week': currentWeek,
        },
      );

      final List<Map<String, dynamic>> rawData =
          List<Map<String, dynamic>>.from(response);

      List<TimelineItem> newTimeline = [];
      List<GlobalKey> newKeys = [];
      int activeIndex = -1;
      int? lastUnitId;

      for (var row in rawData) {
        final unitId = row['unit_id'] as int;
        
        // Ünite Başlığı eklendi (Eğer yeni bir üniteye geçildiyse)
        if (lastUnitId != unitId) {
           newTimeline.add(UnitHeaderItem(
              unitId, 
              row['unit_title'] ?? 'Ünite',
              ((row['unit_total_questions'] ?? 0) as num).toInt(),
              ((row['unit_solved_questions'] ?? 0) as num).toInt()
           ));
           newKeys.add(GlobalKey());
           lastUnitId = unitId;
        }
        
        // Hafta eklendi
        final isCurrent = row['is_current'] as bool;
        newTimeline.add(WeekItem(
            weekNo: row['week_no'] as int,
            unitId: unitId,
            isCurrent: isCurrent,
            isCompleted: row['is_completed'] as bool,
            isLocked: row['is_locked'] as bool,
            topics: row['topic_names'] ?? '',
            totalQuestions: ((row['week_total_questions'] ?? 0) as num).toInt(),
            solvedQuestions: ((row['week_solved_questions'] ?? 0) as num).toInt(),
        ));
        newKeys.add(GlobalKey());
        
        if (isCurrent) {
            activeIndex = newTimeline.length - 1;
        }
      }

      if (!mounted) return;
      setState(() {
        _timeline = newTimeline;
        _keys = newKeys;
        _activeItemIndex = activeIndex;
        _isLoading = false;
      });

      // Kaydırma bitince aktif haftaya odaklan ve hafif titret
      WidgetsBinding.instance.addPostFrameCallback((_) {
         final activeContext =
             (_activeItemIndex != -1 && _activeItemIndex < _keys.length)
                 ? _keys[_activeItemIndex].currentContext
                 : null;
         if (activeContext != null && _scrollController.hasClients) {
            Scrollable.ensureVisible(
               activeContext,
               duration: const Duration(milliseconds: 1000),
               curve: Curves.easeInOutCubic,
               alignment: 0.5,
            ).then((_) => HapticFeedback.mediumImpact());
         }
      });

    } catch (e) {
      debugPrint('Timeline verisi çekilirken hata: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Color get _lessonColor {
    final lower = widget.lessonName.toLowerCase();
    if (lower.contains('mat')) return const Color(0xFF3B82F6);
    if (lower.contains('fen')) return const Color(0xFF10B981);
    if (lower.contains('türk')) return const Color(0xFFEF4444);
    if (lower.contains('sos')) return const Color(0xFFF59E0B);
    if (lower.contains('ing')) return const Color(0xFF8B5CF6);
    return const Color(0xFF6366F1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _timeline.isEmpty
              ? const Center(
                  child: Text(
                    'Henüz gösterilecek hafta verisi yok.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                )
          : Stack(
              children: [
                // İnce Dikey İlerleme Çizgisi
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: MediaQuery.of(context).size.width / 2 - 1,
                  child: Container(width: 2, color: Colors.grey.shade300),
                ),

                // Akış
                ListView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(top: 20, bottom: 100),
                  itemCount: _timeline.length,
                  itemBuilder: (context, index) {
                     final item = _timeline[index];
                     final key = _keys[index];
                     
                     if (item is UnitHeaderItem) {
                        return _buildHeader(item, key, index);
                     } else if (item is WeekItem) {
                        return _buildWeekNode(item, key, index);
                     }
                     return const SizedBox.shrink();
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildHeader(UnitHeaderItem item, GlobalKey key, int index) {
     bool isCompletedOrCurrent = index <= _activeItemIndex;
     double progress = item.totalQuestions > 0 ? (item.solvedQuestions / item.totalQuestions).clamp(0, 1) : 0;

     return Stack(
        alignment: Alignment.center,
        children: [
           // İlerleme yolu (Header boyunca)
           if (isCompletedOrCurrent)
              Positioned(
                 top: 0, bottom: 0,
                 child: Container(width: 2, color: _lessonColor),
              ),
           Container(
              key: key,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              child: Column(
                children: [
                   Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                         color: const Color(0xFFFAFAFA),
                         border: Border(bottom: BorderSide(color: _lessonColor.withValues(alpha: 0.3), width: 2))
                      ),
                      child: Text(
                         item.title.toUpperCase(),
                         style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: _lessonColor,
                         ),
                         textAlign: TextAlign.center,
                      ),
                   ),
                   const SizedBox(height: 12),
                   // Ünite İlerleme Barı
                   Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                         SizedBox(
                            width: 120,
                            child: ClipRRect(
                               borderRadius: BorderRadius.circular(4),
                               child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 4,
                                  backgroundColor: Colors.grey.shade200,
                                  color: _lessonColor.withValues(alpha: 0.6),
                               ),
                            ),
                         ),
                         const SizedBox(width: 8),
                         Text(
                            '%${(progress * 100).toInt()}',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                         )
                      ],
                   )
                ],
              ).animate().fadeIn(duration: 800.ms),
           ),
        ],
     );
  }

  Widget _buildWeekNode(WeekItem item, GlobalKey key, int index) {
     bool isLeftText = item.weekNo % 2 != 0;
     Color nodeColor = item.isCompleted ? _lessonColor : (item.isCurrent ? _lessonColor : Colors.white);
     Color borderColor = item.isCompleted || item.isCurrent ? _lessonColor : Colors.grey.shade400;

     double weekProgress = item.totalQuestions > 0 ? (item.solvedQuestions / item.totalQuestions).clamp(0, 1) : 0;

     Widget textWidget = Column(
        crossAxisAlignment: isLeftText ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
           Text(
              'Hafta ${item.weekNo}',
              style: TextStyle(
                 fontSize: 14,
                 fontWeight: item.isCurrent ? FontWeight.bold : FontWeight.w600,
                 color: item.isLocked ? Colors.grey.shade500 : Colors.black87,
              ),
           ),
           if (item.topics.isNotEmpty)
              Padding(
                 padding: const EdgeInsets.only(top: 4),
                 child: Text(
                    item.topics,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                    textAlign: isLeftText ? TextAlign.right : TextAlign.left,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                 ),
              ),
           // Hafta içi mini bar
           if (!item.isLocked && item.totalQuestions > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                      Container(
                         width: 40, height: 3,
                         decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(2),
                         ),
                         child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                               width: 40 * weekProgress,
                               height: 3,
                               decoration: BoxDecoration(
                                  color: _lessonColor.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(2),
                               ),
                            ),
                         ),
                      ),
                      const SizedBox(width: 4),
                      Text('%${(weekProgress * 100).toInt()}', style: TextStyle(fontSize: 8, color: Colors.grey.shade500)),
                   ],
                ),
              )
        ],
     );

     Widget nodeContent = Stack(
        alignment: Alignment.center,
        children: [
           if (item.isCurrent)
              Container(
                 width: 45, height: 45,
                 decoration: BoxDecoration(shape: BoxShape.circle, color: _lessonColor.withValues(alpha: 0.2)),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.4, 1.4)).fadeOut(),
           Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                 color: nodeColor,
                 shape: item.isCompleted ? BoxShape.rectangle : BoxShape.circle,
                 borderRadius: item.isCompleted ? BorderRadius.circular(8) : null,
                 border: Border.all(color: borderColor, width: item.isCurrent ? 4 : 3),
                 boxShadow: item.isCurrent || item.isCompleted ? [BoxShadow(color: _lessonColor.withValues(alpha: 0.3), blurRadius: 10, spreadRadius: 2)] : [],
              ),
              child: Center(
                 child: item.isCompleted 
                    ? const Icon(Icons.star_rounded, size: 18, color: Colors.white) 
                    : (item.isCurrent ? const Icon(Icons.play_arrow_rounded, size: 16, color: Colors.white) : const SizedBox()),
              ),
           ),
        ],
     );

     return Stack(
        alignment: Alignment.center,
        children: [
           // Dolum Yolu
           if (item.isCompleted || item.isCurrent)
              Positioned(
                 top: 0,
                 bottom: item.isCurrent ? 48 : 0, 
                 child: Container(width: 2, color: _lessonColor),
              ),
           InkWell(
              key: key,
              onTap: () {
                 HapticFeedback.lightImpact();
                 if (item.isLocked) {
                    final messages = [
                      "Heyecanını anlıyoruz ama o haftaya daha var! 🕰️",
                      "Zaman makinesi henüz icat edilmedi, kendi haftana dön! 🚀",
                      "Geleceği göremezsin ama çalışarak inşa edebilirsin! 🔮"
                    ];
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                       content: Text(messages[item.weekNo % messages.length]),
                       backgroundColor: const Color(0xFF0F172A),
                       behavior: SnackBarBehavior.floating,
                       margin: const EdgeInsets.all(16),
                    ));
                 } else {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => UnitSummaryScreen(unitId: item.unitId)));
                 }
              },
              child: Padding(
                 padding: const EdgeInsets.symmetric(vertical: 36),
                 child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       Expanded(child: Align(alignment: Alignment.centerRight, child: isLeftText ? Padding(padding: const EdgeInsets.only(right: 24), child: textWidget) : const SizedBox())),
                       nodeContent,
                       Expanded(child: Align(alignment: Alignment.centerLeft, child: !isLeftText ? Padding(padding: const EdgeInsets.only(left: 24), child: textWidget) : const SizedBox())),
                    ],
                 ),
              ),
           ),
        ],
     );
  }
}
