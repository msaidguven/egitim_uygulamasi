import 'package:egitim_uygulamasi/screens/home/map/components/timeline_component.dart';
import 'package:egitim_uygulamasi/screens/home/map/models/map_progress_models.dart';
import 'package:egitim_uygulamasi/screens/home/map/screens/topic_content_screen.dart';
import 'package:egitim_uygulamasi/screens/home/map/services/progress_service.dart';
import 'package:egitim_uygulamasi/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UnitTimelineScreen extends StatefulWidget {
  const UnitTimelineScreen({
    super.key,
    required this.userId,
    required this.unitId,
    required this.lessonName,
    required this.unitTitle,
    required this.accent,
  });

  final String userId;
  final int unitId;
  final String lessonName;
  final String unitTitle;
  final Color accent;

  @override
  State<UnitTimelineScreen> createState() => _UnitTimelineScreenState();
}

class _UnitTimelineScreenState extends State<UnitTimelineScreen> {
  final ProgressService _progressService = ProgressService();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  String? _error;
  List<TopicNodeData> _topics = [];
  List<GlobalKey> _keys = [];

  int get _currentWeek => calculateCurrentAcademicWeek();

  @override
  void initState() {
    super.initState();
    _loadTimeline();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTimeline({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final topics = await _progressService.fetchUnitTimeline(
        userId: widget.userId,
        unitId: widget.unitId,
        currentWeek: _currentWeek,
        forceRefresh: forceRefresh,
      );

      if (!mounted) return;
      setState(() {
        _topics = topics;
        _keys = List.generate(topics.length, (_) => GlobalKey());
        _isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusFirstIncomplete();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _refreshSingleTopic(int topicId) async {
    final fresh = await _progressService.fetchSingleTopic(
      userId: widget.userId,
      unitId: widget.unitId,
      topicId: topicId,
      currentWeek: _currentWeek,
    );

    if (!mounted || fresh == null) return;

    final index = _topics.indexWhere((t) => t.topicId == topicId);
    if (index < 0) return;

    final updated = [..._topics];
    updated[index] = fresh;

    setState(() {
      _topics = updated;
    });
  }

  void _focusFirstIncomplete() {
    if (!_scrollController.hasClients || _topics.isEmpty) return;

    final firstIncomplete = _topics.indexWhere((t) => !t.isCompleted);
    final targetIndex = firstIncomplete == -1 ? 0 : firstIncomplete;

    if (targetIndex < 0 || targetIndex >= _keys.length) return;
    final targetContext = _keys[targetIndex].currentContext;
    if (targetContext == null) return;

    Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 600),
      alignment: 0.3,
      curve: Curves.easeInOut,
    ).then((_) => HapticFeedback.selectionClick());
  }

  Future<void> _openTopic(TopicNodeData topic) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TopicContentScreen(
          topicId: topic.topicId,
          topicTitle: topic.title,
        ),
      ),
    );

    await _refreshSingleTopic(topic.topicId);
  }

  @override
  Widget build(BuildContext context) {
    final completed = _topics.where((t) => t.isCompleted).length;
    final ratio = _topics.isEmpty ? 0.0 : (completed / _topics.length);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.unitTitle,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            ),
            Text(
              widget.lessonName,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _loadTimeline(forceRefresh: true),
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF334155)),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: widget.accent.withValues(alpha: 0.22)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.timeline_rounded, color: widget.accent, size: 17),
                    const SizedBox(width: 6),
                    Text(
                      '$completed/${_topics.length} konu tamamlandı',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: ratio,
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(6),
                  color: widget.accent,
                  backgroundColor: const Color(0xFFE2E8F0),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _topics.isEmpty
                        ? const Center(child: Text('Bu ünitede timeline konusu bulunamadı.'))
                        : TimelineComponent(
                            scrollController: _scrollController,
                            nodes: _topics,
                            keys: _keys,
                            accent: widget.accent,
                            onTopicTap: _openTopic,
                          ),
          ),
        ],
      ),
    );
  }
}
