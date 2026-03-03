import 'package:egitim_uygulamasi/models/profile_model.dart';
import 'package:egitim_uygulamasi/screens/home/map/components/map_layout_component.dart';
import 'package:egitim_uygulamasi/screens/home/map/components/radial_node_component.dart';
import 'package:egitim_uygulamasi/screens/home/map/models/map_progress_models.dart';
import 'package:egitim_uygulamasi/screens/home/map/screens/subject_map_screen.dart';
import 'package:egitim_uygulamasi/screens/home/map/services/progress_service.dart';
import 'package:egitim_uygulamasi/utils/date_utils.dart';
import 'package:flutter/material.dart';

class ClassMapScreen extends StatefulWidget {
  const ClassMapScreen({super.key, this.profile});

  final Profile? profile;

  @override
  State<ClassMapScreen> createState() => _ClassMapScreenState();
}

class _ClassMapScreenState extends State<ClassMapScreen> {
  final ProgressService _progressService = ProgressService();

  ClassMapData? _mapData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    final profile = widget.profile;
    if (profile == null || profile.gradeId == null) {
      setState(() {
        _isLoading = false;
        _error = 'Haritayı görmek için giriş yapman gerekiyor.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _progressService.fetchClassMapData(
        userId: profile.id,
        gradeId: profile.gradeId!,
        gradeName: profile.grade?.name ?? 'Sınıf',
        currentWeek: calculateCurrentAcademicWeek(),
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
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Color _subjectColor(String lessonName) {
    final lower = lessonName.toLowerCase();
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
        title: const Text(
          'Sınıf Haritası',
          style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
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
              ? _ErrorPanel(message: _error!, onRetry: _load)
              : _mapData == null || _mapData!.subjects.isEmpty
                  ? const Center(child: Text('Bu sınıf için ders bulunamadı.'))
                  : MapLayoutComponent(
                      center: _ClassCastle(
                        gradeName: _mapData!.gradeName,
                        progress: _mapData!.completionRate,
                        conquered: _mapData!.conqueredCount,
                        total: _mapData!.subjects.length,
                      ),
                      nodes: _mapData!.subjects.map((subject) {
                        final color = _subjectColor(subject.lessonName);
                        return RadialNodeComponent(
                          title: subject.lessonName,
                          subtitle: '${(subject.progressRate * 100).round()}% • ${subject.unitsConquered}/${subject.unitsTotal} ünite',
                          progress: subject.progressRate,
                          state: subject.state,
                          accent: color,
                          onTap: () async {
                            final profile = widget.profile;
                            if (profile == null || profile.gradeId == null) return;
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SubjectMapScreen(
                                  userId: profile.id,
                                  gradeId: profile.gradeId!,
                                  gradeName: profile.grade?.name ?? 'Sınıf',
                                  lessonId: subject.lessonId,
                                  lessonName: subject.lessonName,
                                ),
                              ),
                            );
                            if (mounted) {
                              await _load(forceRefresh: true);
                            }
                          },
                        );
                      }).toList(),
                    ),
    );
  }
}

class _ClassCastle extends StatelessWidget {
  const _ClassCastle({
    required this.gradeName,
    required this.progress,
    required this.conquered,
    required this.total,
  });

  final String gradeName;
  final double progress;
  final int conquered;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.26),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.castle_rounded, color: Colors.white, size: 34),
          const SizedBox(height: 8),
          Text(
            gradeName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xFFF59E0B),
            backgroundColor: Colors.white24,
          ),
          const SizedBox(height: 8),
          Text(
            '$conquered/$total ders fethedildi',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function({bool forceRefresh}) onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 44, color: Color(0xFFDC2626)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => onRetry(forceRefresh: true),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}
