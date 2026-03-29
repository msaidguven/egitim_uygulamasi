import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'written_practice_models.dart';
import 'written_practice_providers.dart';
import 'written_session_screen.dart';

class WrittenPracticeHomeScreen extends ConsumerStatefulWidget {
  static const routeName = '/written-practice';
  final int? initialLessonId;
  final int? initialGradeId;
  final String? initialLessonName;

  const WrittenPracticeHomeScreen({
    super.key,
    this.initialLessonId,
    this.initialGradeId,
    this.initialLessonName,
  });

  @override
  ConsumerState<WrittenPracticeHomeScreen> createState() =>
      _WrittenPracticeHomeScreenState();
}

class _WrittenPracticeHomeScreenState
    extends ConsumerState<WrittenPracticeHomeScreen> {
  bool _isBootstrapping = true;
  String? _bootstrapError;

  @override
  void initState() {
    super.initState();
    Future.microtask(_bootstrapAndStartSession);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lessonTitle = (widget.initialLessonName ?? '').trim();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          lessonTitle.isEmpty
              ? 'Yazılıya Çalış'
              : 'Yazılıya Çalış • $lessonTitle',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: theme.colorScheme.surface,
      ),
      body: _isBootstrapping
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Sorular hazırlanıyor...'),
                ],
              ),
            )
          : _EmptyHint(
              icon: Icons.warning_amber_rounded,
              text: _bootstrapError ?? 'Oturum başlatılamadı.',
            ),
    );
  }

  Future<void> _bootstrapAndStartSession() async {
    ref.read(selectedLessonIdProvider.notifier).state = widget.initialLessonId;
    ref.read(selectedGradeIdProvider.notifier).state = widget.initialGradeId;
    ref.read(selectedTopicIdsProvider.notifier).state = {};

    if (widget.initialLessonId == null) {
      if (!mounted) return;
      setState(() {
        _isBootstrapping = false;
        _bootstrapError =
            'Ders bilgisi gelmedi. Bu ekrana haftalık ders içinden geçin.';
      });
      return;
    }

    try {
      final units = await ref.read(lessonUnitsProvider.future);
      final topicIds = <int>{};

      for (final unit in units) {
        final topics = await ref.read(topicsProvider(unit.id).future);
        for (final topic in topics) {
          topicIds.add(topic.id);
        }
      }

      if (topicIds.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isBootstrapping = false;
          _bootstrapError = 'Bu ders için konu bulunamadı.';
        });
        return;
      }

      ref.read(selectedTopicIdsProvider.notifier).state = topicIds;
      await _startSession(topicIds);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isBootstrapping = false;
        _bootstrapError = 'Veriler yüklenirken bir hata oluştu.';
      });
    }
  }

  Future<void> _startSession(Set<int> topicIds) async {
    await ref
        .read(writtenSessionProvider.notifier)
        .startSession(topicIds.toList());

    if (!mounted) return;
    final session = ref.read(writtenSessionProvider);
    if (session == null || session.totalQuestions == 0) {
      setState(() {
        _isBootstrapping = false;
        _bootstrapError = 'Seçilen konularda soru bulunamadı.';
      });
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const WrittenSessionScreen()),
    );
  }
}

// ── Unit > Topic tree ────────────────────────────────────────────────────────

class _UnitTopicTree extends ConsumerWidget {
  final List<Unit> units;
  final Set<int> selectedTopicIds;
  final void Function(int) onToggleTopic;

  const _UnitTopicTree({
    required this.units,
    required this.selectedTopicIds,
    required this.onToggleTopic,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: units.length,
      itemBuilder: (_, i) => _UnitTile(
        unit: units[i],
        selectedTopicIds: selectedTopicIds,
        onToggleTopic: onToggleTopic,
      ),
    );
  }
}

class _UnitTile extends ConsumerWidget {
  final Unit unit;
  final Set<int> selectedTopicIds;
  final void Function(int) onToggleTopic;

  const _UnitTile({
    required this.unit,
    required this.selectedTopicIds,
    required this.onToggleTopic,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final topicsAsync = ref.watch(topicsProvider(unit.id));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              child: Row(
                children: [
                  Icon(Icons.folder_open_rounded, 
                    size: 20, color: theme.colorScheme.primary.withOpacity(0.7)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      unit.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          topicsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Hata: $e'),
            ),
            data: (topics) => topics.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Bu ünitede konu yok.'),
                  )
                : Column(
                    children: [
                      ...topics.map(
                        (t) => _TopicCheckTile(
                          topic: t,
                          isSelected: selectedTopicIds.contains(t.id),
                          onToggle: () => onToggleTopic(t.id),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    ),
  );
  }
}

class _TopicCheckTile extends StatelessWidget {
  final Topic topic;
  final bool isSelected;
  final VoidCallback onToggle;

  const _TopicCheckTile({
    required this.topic,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.fastOutSlowIn,
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withOpacity(0.5),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: isSelected 
                  ? [BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2)
                    )]
                  : null,
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                topic.title, 
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty hint ───────────────────────────────────────────────────────────────

class _EmptyHint extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyHint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 56,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
