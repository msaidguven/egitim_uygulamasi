import 'package:egitim_uygulamasi/admin/pages/smart_content_addition/smart_content_addition_page.dart';
import 'package:egitim_uygulamasi/features/test/data/models/test_question.dart';
import 'package:egitim_uygulamasi/features/test/presentation/views/questions_screen.dart';
import 'package:egitim_uygulamasi/screens/lesson_content/lesson_v11/main.dart'
    as lesson_v11;
import 'package:egitim_uygulamasi/screens/outcomes/outcomes_screen_v2.dart';
import 'package:egitim_uygulamasi/screens/outcomes/widgets/admin_copy_button.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WeeklyV11TopicsScreen extends StatefulWidget {
  final int gradeId;
  final int lessonId;
  final String gradeName;
  final String lessonName;
  final int curriculumWeek;

  const WeeklyV11TopicsScreen({
    super.key,
    required this.gradeId,
    required this.lessonId,
    required this.gradeName,
    required this.lessonName,
    required this.curriculumWeek,
  });

  @override
  State<WeeklyV11TopicsScreen> createState() => _WeeklyV11TopicsScreenState();
}

class _WeeklyV11TopicsScreenState extends State<WeeklyV11TopicsScreen>
    with SingleTickerProviderStateMixin {
  final SupabaseClient _client = Supabase.instance.client;

  bool _loading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _topics = const [];
  List<Map<String, dynamic>> _allCurriculumTopics = const [];
  bool _isAdmin = false;

  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadTopics();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadTopics() async {
    try {
      final user = _client.auth.currentUser;
      final response = await _client.rpc(
        'get_weekly_curriculum',
        params: {
          'p_user_id': user?.id,
          'p_grade_id': widget.gradeId,
          'p_lesson_id': widget.lessonId,
          'p_curriculum_week': widget.curriculumWeek,
          'p_is_admin': false,
        },
      );

      final rows = (response as List? ?? const [])
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();

      final roleRow = user == null
          ? null
          : await _client
                .from('profiles')
                .select('role')
                .eq('id', user.id)
                .maybeSingle();
      final isAdmin = (roleRow?['role'] as String?) == 'admin';

      final topicMap = <int, Map<String, dynamic>>{};
      for (final row in rows) {
        final topicId = row['topic_id'] as int?;
        if (topicId == null) {
          continue;
        }

        final topic = topicMap.putIfAbsent(topicId, () {
          final unitTitle = (row['unit_title'] as String? ?? '').trim();
          final topicTitle = (row['topic_title'] as String? ?? '').trim();
          return {
            'topic_id': topicId,
            'unit_id': row['unit_id'] as int?,
            'unit_title': unitTitle,
            'topic_title': topicTitle,
            'outcomes': <String>{},
            'outcome_ids': <int>{},
          };
        });

        final outcomeText = (row['outcome_description'] as String? ?? '')
            .trim();
        if (outcomeText.isNotEmpty) {
          (topic['outcomes'] as Set<String>).add(outcomeText);
        }
        final outcomeId = row['outcome_id'] as int?;
        if (outcomeId != null) {
          (topic['outcome_ids'] as Set<int>).add(outcomeId);
        }
      }

      final allTopics =
          topicMap.values.map((data) {
            final outcomes = (data['outcomes'] as Set<String>).toList()..sort();
            final outcomeIds = (data['outcome_ids'] as Set<int>).toList()
              ..sort();
            final map = Map<String, dynamic>.from(data);
            map['outcomes'] = outcomes;
            map['outcome_ids'] = outcomeIds;
            return map;
          }).toList()
            ..sort((a, b) {
              final unitCompare = ((a['unit_title'] as String?) ?? '')
                  .compareTo((b['unit_title'] as String?) ?? '');
              if (unitCompare != 0) return unitCompare;
              return ((a['topic_title'] as String?) ?? '').compareTo(
                (b['topic_title'] as String?) ?? '',
              );
            });

      if (topicMap.isEmpty) {
        if (!mounted) return;
        setState(() {
          _topics = const [];
          _allCurriculumTopics = const [];
          _errorMessage = null;
          _loading = false;
          _isAdmin = isAdmin;
        });
        return;
      }

      final allOutcomeIds = topicMap.values
          .expand((t) => t['outcome_ids'] as Set<int>)
          .toList();

      final publishedRows = await _client
          .from('topic_content_outcomes_v11')
          .select('outcome_id, topic_contents_v11!inner(topic_id, is_published)')
          .inFilter('outcome_id', allOutcomeIds)
          .eq('topic_contents_v11.is_published', true);

      final publishedTopicIds = (publishedRows as List).map((row) {
        final content = row['topic_contents_v11'] as Map<String, dynamic>?;
        return content?['topic_id'] as int?;
      }).whereType<int>().toSet();

      final topicsWithFlags = allTopics.map((t) {
        final result = Map<String, dynamic>.from(t);
        result['has_published_content'] = publishedTopicIds.contains(t['topic_id']);
        return result;
      }).toList();

      if (!mounted) return;
      setState(() {
        _topics = topicsWithFlags;
        _allCurriculumTopics = allTopics;
        _errorMessage = null;
        _loading = false;
        _isAdmin = isAdmin;
      });
      _animController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _loading = false;
      });
    }
  }

  void _openClassic() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OutcomesScreenV2(
          gradeId: widget.gradeId,
          lessonId: widget.lessonId,
          gradeName: widget.gradeName,
          lessonName: widget.lessonName,
          initialCurriculumWeek: widget.curriculumWeek,
        ),
      ),
    );
  }

  Future<void> _openAdminContentAddition([Map<String, dynamic>? topic]) async {
    int? initialUnitId;
    int? initialTopicId;

    if (topic != null) {
      initialUnitId = topic['unit_id'] as int?;
      initialTopicId = topic['topic_id'] as int?;
    } else {
      try {
        final user = _client.auth.currentUser;
        final response = await _client.rpc(
          'get_weekly_curriculum',
          params: {
            'p_user_id': user?.id,
            'p_grade_id': widget.gradeId,
            'p_lesson_id': widget.lessonId,
            'p_curriculum_week': widget.curriculumWeek,
            'p_is_admin': true,
          },
        );

        final rows =
            (response as List? ?? const [])
                .whereType<Map>()
                .map((row) => Map<String, dynamic>.from(row))
                .where((row) => row['unit_id'] is int && row['topic_id'] is int)
                .toList()
              ..sort((a, b) {
                final unitCompare = (a['unit_id'] as int).compareTo(
                  b['unit_id'] as int,
                );
                if (unitCompare != 0) return unitCompare;
                return (a['topic_id'] as int).compareTo(b['topic_id'] as int);
              });

        if (rows.isNotEmpty) {
          initialUnitId = rows.first['unit_id'] as int?;
          initialTopicId = rows.first['topic_id'] as int?;
        }
      } catch (_) {
        initialUnitId = null;
        initialTopicId = null;
      }
    }

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SmartContentAdditionPage(
          initialGradeId: widget.gradeId,
          initialLessonId: widget.lessonId,
          initialUnitId: initialUnitId,
          initialTopicId: initialTopicId,
          initialCurriculumWeek: widget.curriculumWeek,
        ),
      ),
    );
  }

  Future<void> _openTopic(Map<String, dynamic> topic) async {
    final topicId = topic['topic_id'] as int?;
    if (topicId == null) {
      return;
    }
    final outcomeIds = (topic['outcome_ids'] as List?)?.whereType<int>().toList() ?? [];

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            lesson_v11.LessonPage(
              topicId: topicId,
              outcomeIds: outcomeIds,
              useAssetFallback: false,
            ),
      ),
    );
  }

  Future<void> _startTopicQuestions(Map<String, dynamic> topic) async {
    final topicId = topic['topic_id'] as int?;
    final unitId = topic['unit_id'] as int?;
    if (topicId == null || unitId == null) {
      return;
    }

    final outcomeIds =
        (topic['outcome_ids'] as List?)?.whereType<int>().toList() ??
        const <int>[];

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionsScreen(
          unitId: unitId,
          testMode: TestMode.weekly,
          sessionId: null,
        ),
        settings: RouteSettings(
          arguments: {
            'curriculum_week': widget.curriculumWeek,
            'topic_id': topicId,
            'outcome_ids': outcomeIds,
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Sliver AppBar ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            stretch: true,
            backgroundColor: colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: _CircleBackButton(colorScheme: colorScheme),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.fadeTitle,
              ],
              titlePadding: const EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: 16,
              ),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.gradeName} ${widget.lessonName}'.trim(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${widget.curriculumWeek}. hafta konuları',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              background: _AppBarBackground(colorScheme: colorScheme),
            ),
          ),

          // ── Body ───────────────────────────────────────────────────────
          if (_loading)
            const SliverFillRemaining(child: Center(child: _PulsingLoader()))
          else if (_errorMessage != null)
            SliverFillRemaining(
              child: _ErrorState(
                message: _errorMessage!,
                colorScheme: colorScheme,
                theme: theme,
                onRetry: () {
                  setState(() {
                    _loading = true;
                    _errorMessage = null;
                  });
                  _loadTopics();
                },
              ),
            )
          else if (_topics.isEmpty)
            SliverFillRemaining(
              child: _EmptyState(
                colorScheme: colorScheme,
                theme: theme,
                curriculumWeek: widget.curriculumWeek,
                isAdmin: _isAdmin,
                onOpenClassic: _openClassic,
                onOpenAdmin: _openAdminContentAddition,
                gradeName: widget.gradeName,
                lessonName: widget.lessonName,
                allCurriculumTopics: _allCurriculumTopics,
              ),
            )
          else ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              sliver: SliverToBoxAdapter(
                child: Text(
                  '${_topics.length} konu',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              sliver: SliverList.separated(
                itemCount: _topics.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final topic = _topics[index];
                  return _AnimatedTopicCard(
                    topic: topic,
                    index: index,
                    colorScheme: colorScheme,
                    theme: theme,
                    onShowContent: () => _openTopic(topic),
                    onStartQuestions: () => _startTopicQuestions(topic),
                    controller: _animController,
                    gradeName: widget.gradeName,
                    lessonName: widget.lessonName,
                    isAdmin: _isAdmin,
                    onOpenAdmin: () => _openAdminContentAddition(topic),
                    onOpenClassic: _openClassic,
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers / sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _CircleBackButton extends StatelessWidget {
  const _CircleBackButton({required this.colorScheme});
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colorScheme.surfaceContainerHighest.withOpacity(0.85),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.maybePop(context),
        child: Center(
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _AppBarBackground extends StatelessWidget {
  const _AppBarBackground({required this.colorScheme});
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withOpacity(0.55),
            colorScheme.secondaryContainer.withOpacity(0.35),
            colorScheme.surface,
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            top: 30,
            right: 60,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.tertiary.withOpacity(0.1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingLoader extends StatefulWidget {
  const _PulsingLoader();

  @override
  State<_PulsingLoader> createState() => _PulsingLoaderState();
}

class _PulsingLoaderState extends State<_PulsingLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 0.85,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ScaleTransition(
      scale: _scale,
      child: Icon(
        Icons.auto_stories_rounded,
        size: 48,
        color: colorScheme.primary.withOpacity(0.55),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.colorScheme,
    required this.theme,
    required this.onRetry,
  });

  final String message;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 38,
              color: colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Konular yüklenemedi',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Tekrar Dene'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.colorScheme,
    required this.theme,
    required this.curriculumWeek,
    required this.isAdmin,
    required this.onOpenClassic,
    required this.onOpenAdmin,
    required this.gradeName,
    required this.lessonName,
    required this.allCurriculumTopics,
  });

  final ColorScheme colorScheme;
  final ThemeData theme;
  final int curriculumWeek;
  final bool isAdmin;
  final VoidCallback onOpenClassic;
  final void Function([Map<String, dynamic>?]) onOpenAdmin;
  final String gradeName;
  final String lessonName;
  final List<Map<String, dynamic>> allCurriculumTopics;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.surfaceContainerHighest,
                  colorScheme.surfaceContainerLow,
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.menu_book_outlined,
              size: 44,
              color: colorScheme.onSurface.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'İçerik Henüz Yok',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bu hafta için yayınlanmış V11 içeriği bulunamadı.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Mevcut hafta: $curriculumWeek',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onOpenClassic,
              icon: const Icon(Icons.view_list_rounded, size: 18),
              label: const Text('Klasik konu ekranını aç'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                side: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
              ),
            ),
          ),
          if (isAdmin) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => onOpenAdmin(null),
                icon: const Icon(Icons.admin_panel_settings_rounded, size: 18),
                label: const Text('Haftaya Yeni İçerik Ekle'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnimatedTopicCard extends StatelessWidget {
  const _AnimatedTopicCard({
    required this.topic,
    required this.index,
    required this.colorScheme,
    required this.theme,
    required this.onShowContent,
    required this.onStartQuestions,
    required this.controller,
    required this.gradeName,
    required this.lessonName,
    required this.isAdmin,
    required this.onOpenAdmin,
    required this.onOpenClassic,
  });

  final Map<String, dynamic> topic;
  final int index;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final VoidCallback onShowContent;
  final VoidCallback onStartQuestions;
  final AnimationController controller;
  final String gradeName;
  final String lessonName;
  final bool isAdmin;
  final VoidCallback onOpenAdmin;
  final VoidCallback onOpenClassic;

  @override
  Widget build(BuildContext context) {
    final unitTitle = (topic['unit_title'] as String? ?? '').trim();
    final topicTitle = (topic['topic_title'] as String? ?? '').trim();
    final outcomes =
        (topic['outcomes'] as List?)?.whereType<String>().toList() ??
        const <String>[];

    final delay = (index * 0.08).clamp(0.0, 0.6);
    final start = delay;
    final end = (delay + 0.4).clamp(0.0, 1.0);

    final slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero).animate(
          CurvedAnimation(
            parent: controller,
            curve: Interval(start, end, curve: Curves.easeOutCubic),
          ),
        );

    final fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(start, end, curve: Curves.easeOut),
      ),
    );

    return FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(
        position: slideAnim,
        child: _TopicCard(
          topic: topic,
          unitTitle: unitTitle,
          topicTitle: topicTitle,
          outcomes: outcomes,
          colorScheme: colorScheme,
          theme: theme,
          onShowContent: onShowContent,
          onStartQuestions: onStartQuestions,
          index: index,
          gradeName: gradeName,
          lessonName: lessonName,
          isAdmin: isAdmin,
          onOpenAdmin: onOpenAdmin,
          onOpenClassic: onOpenClassic,
        ),
      ),
    );
  }
}

class _TopicCard extends StatefulWidget {
  const _TopicCard({
    required this.topic,
    required this.unitTitle,
    required this.topicTitle,
    required this.outcomes,
    required this.colorScheme,
    required this.theme,
    required this.onShowContent,
    required this.onStartQuestions,
    required this.index,
    required this.gradeName,
    required this.lessonName,
    required this.isAdmin,
    required this.onOpenAdmin,
    required this.onOpenClassic,
  });

  final Map<String, dynamic> topic;
  final String unitTitle;
  final String topicTitle;
  final List<String> outcomes;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final VoidCallback onShowContent;
  final VoidCallback onStartQuestions;
  final int index;
  final String gradeName;
  final String lessonName;
  final bool isAdmin;
  final VoidCallback onOpenAdmin;
  final VoidCallback onOpenClassic;

  @override
  State<_TopicCard> createState() => _TopicCardState();
}

class _TopicCardState extends State<_TopicCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = widget.colorScheme;

    // Subtle per-card accent from primary with slight hue rotation feel
    final accentOpacity = widget.index.isEven ? 0.07 : 0.04;

    final bool isPublished = widget.topic['has_published_content'] == true;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (isPublished) {
          widget.onShowContent();
        } else {
          widget.onOpenClassic();
        }
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.977 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.55),
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: colorScheme.primary.withOpacity(accentOpacity),
                blurRadius: 20,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Left accent stripe
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [colorScheme.primary, colorScheme.tertiary],
                      ),
                    ),
                  ),
                ),
                // Admin Actions Menu
                if (widget.isAdmin)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        size: 20,
                        color: colorScheme.onSurface.withOpacity(0.4),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      onSelected: (value) async {
                        final outcomes = widget.outcomes
                            .map((e) => {'description': e})
                            .toList();

                        if (value == 'promptV2') {
                          await AdminCopyButton.copyPrompt(
                            context,
                            gradeName: widget.gradeName,
                            lessonName: widget.lessonName,
                            unitTitle: widget.unitTitle,
                            topicTitle: widget.topicTitle,
                            outcomes: outcomes,
                            promptType: AdminPromptType.contentV2,
                          );
                        } else if (value == 'promptQuestions') {
                          await AdminCopyButton.copyPrompt(
                            context,
                            gradeName: widget.gradeName,
                            lessonName: widget.lessonName,
                            unitTitle: widget.unitTitle,
                            topicTitle: widget.topicTitle,
                            outcomes: outcomes,
                            promptType: AdminPromptType.questions,
                          );
                        } else if (value == 'addContent') {
                          widget.onOpenAdmin();
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'promptV2',
                          child: ListTile(
                            leading: Icon(Icons.data_object_rounded, size: 18),
                            title: Text('İçerik Promptu V2', style: TextStyle(fontSize: 13)),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'promptQuestions',
                          child: ListTile(
                            leading: Icon(Icons.quiz_outlined, size: 18),
                            title: Text('Soru Promptu', style: TextStyle(fontSize: 13)),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'addContent',
                          child: ListTile(
                            leading: Icon(Icons.admin_panel_settings_rounded, size: 18, color: Colors.blue),
                            title: Text(
                              'Yönetici İçerik Ekle',
                              style: TextStyle(fontSize: 13, color: Colors.blue, fontWeight: FontWeight.bold),
                            ),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Unit badge
                      if (widget.unitTitle.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withOpacity(
                              0.6,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.unitTitle,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.primary,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Topic title
                      Text(
                        widget.topicTitle.isNotEmpty
                            ? widget.topicTitle
                            : 'Konu',
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          height: 1.3,
                        ),
                      ),

                      // Outcomes
                      if (widget.outcomes.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        ...widget.outcomes
                            .map(
                              (o) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 5),
                                      child: Container(
                                        width: 5,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary
                                              .withOpacity(0.55),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        o,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          height: 1.5,
                                          color: colorScheme.onSurface
                                              .withOpacity(0.68),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      ],



                      // Footer CTA
                      const SizedBox(height: 16),
                      if (isPublished) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _GameLikeButton(
                                label: 'Ders İçeriği',
                                icon: Icons.menu_book_rounded,
                                onTap: widget.onShowContent,
                                gradientColors: const [Color(0xFF6366F1), Color(0xFF4F46E5)],
                                shadowColor: const Color(0xFF4F46E5),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _GameLikeButton(
                                label: 'Testi Başlat',
                                icon: Icons.play_arrow_rounded,
                                onTap: widget.onStartQuestions,
                                gradientColors: const [Color(0xFFFF8A65), Color(0xFFFF5722)],
                                shadowColor: const Color(0xFFFF5722),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline_rounded, size: 16, color: colorScheme.onSurfaceVariant),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Bu konu için V11 içerikleri henüz eklenmemiş.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: widget.onOpenClassic,
                            icon: const Icon(Icons.history_rounded, size: 18),
                            label: const Text('Klasik Versiyonu Aç'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
                            ),
                          ),
                        ),
                      ],
                    ],
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

class _GameLikeButton extends StatelessWidget {
  const _GameLikeButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.gradientColors,
    required this.shadowColor,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final List<Color> gradientColors;
  final Color shadowColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        boxShadow: [
          BoxShadow(color: shadowColor.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
