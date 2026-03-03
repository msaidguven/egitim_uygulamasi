import 'package:egitim_uygulamasi/screens/home/map/components/map_layout_component.dart';
import 'package:egitim_uygulamasi/screens/home/map/components/radial_node_component.dart';
import 'package:egitim_uygulamasi/screens/home/map/models/map_progress_models.dart';
import 'package:egitim_uygulamasi/screens/home/map/screens/unit_timeline_screen.dart';
import 'package:egitim_uygulamasi/screens/home/map/services/progress_service.dart';
import 'package:egitim_uygulamasi/utils/date_utils.dart';
import 'package:flutter/material.dart';

class SubjectMapScreen extends StatefulWidget {
  const SubjectMapScreen({
    super.key,
    required this.userId,
    required this.gradeId,
    required this.gradeName,
    required this.lessonId,
    required this.lessonName,
  });

  final String userId;
  final int gradeId;
  final String gradeName;
  final int lessonId;
  final String lessonName;

  @override
  State<SubjectMapScreen> createState() => _SubjectMapScreenState();
}

class _SubjectMapScreenState extends State<SubjectMapScreen> {
  final ProgressService _progressService = ProgressService();

  SubjectMapData? _mapData;
  bool _isLoading = true;
  String? _error;

  int get _currentWeek => calculateCurrentAcademicWeek();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _progressService.fetchSubjectMapData(
        userId: widget.userId,
        gradeId: widget.gradeId,
        lessonId: widget.lessonId,
        lessonName: widget.lessonName,
        currentWeek: _currentWeek,
        forceRefresh: forceRefresh,
      );

      if (!mounted) return;
      setState(() {
        _mapData = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshUnit(int unitId) async {
    final mapData = _mapData;
    if (mapData == null) return;

    final updated = await _progressService.fetchSingleUnitProgress(
      userId: widget.userId,
      gradeId: widget.gradeId,
      lessonId: widget.lessonId,
      unitId: unitId,
      currentWeek: _currentWeek,
    );

    if (!mounted || updated == null) return;

    final newUnits = [...mapData.units];
    final idx = newUnits.indexWhere((u) => u.unitId == unitId);
    if (idx >= 0) {
      newUnits[idx] = updated;
      setState(() {
        _mapData = SubjectMapData(
          lessonId: mapData.lessonId,
          lessonName: mapData.lessonName,
          gradeId: mapData.gradeId,
          units: newUnits,
        );
      });
    }
  }

  Color get _accent {
    final lower = widget.lessonName.toLowerCase();
    if (lower.contains('mat')) return const Color(0xFF2563EB);
    if (lower.contains('fen')) return const Color(0xFF059669);
    if (lower.contains('türk')) return const Color(0xFFDC2626);
    if (lower.contains('sos')) return const Color(0xFFD97706);
    if (lower.contains('ing')) return const Color(0xFF7C3AED);
    if (lower.contains('din')) return const Color(0xFF0F766E);
    return const Color(0xFF334155);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          widget.lessonName,
          style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
        ),
        actions: [
          IconButton(
            onPressed: () => _load(forceRefresh: true),
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF334155)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _mapData == null || _mapData!.units.isEmpty
                  ? const Center(child: Text('Bu ders için ünite bulunamadı.'))
                  : MapLayoutComponent(
                      center: _SubjectCastle(
                        lessonName: widget.lessonName,
                        progress: _mapData!.completionRate,
                        conqueredCount: _mapData!.conqueredCount,
                        totalCount: _mapData!.units.length,
                        accent: _accent,
                      ),
                      nodes: _mapData!.units.map((unit) {
                        return RadialNodeComponent(
                          title: unit.title,
                          subtitle:
                              '${(unit.progressRate * 100).round()}% • ${unit.topicsCompleted}/${unit.topicsTotal} konu',
                          progress: unit.progressRate,
                          state: unit.state,
                          accent: _accent,
                          isCurrent: unit.isCurrentWeek,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UnitTimelineScreen(
                                  userId: widget.userId,
                                  unitId: unit.unitId,
                                  lessonName: widget.lessonName,
                                  unitTitle: unit.title,
                                  accent: _accent,
                                ),
                              ),
                            );
                            await _refreshUnit(unit.unitId);
                          },
                        );
                      }).toList(),
                    ),
    );
  }
}

class _SubjectCastle extends StatelessWidget {
  const _SubjectCastle({
    required this.lessonName,
    required this.progress,
    required this.conqueredCount,
    required this.totalCount,
    required this.accent,
  });

  final String lessonName;
  final double progress;
  final int conqueredCount;
  final int totalCount;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 2),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fort_rounded, color: accent, size: 34),
          const SizedBox(height: 8),
          Text(
            lessonName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            borderRadius: BorderRadius.circular(8),
            color: accent,
            backgroundColor: const Color(0xFFE2E8F0),
          ),
          const SizedBox(height: 8),
          Text(
            '$conqueredCount/$totalCount ünite fethedildi',
            style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
