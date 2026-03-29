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
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(selectedLessonIdProvider.notifier).state =
          widget.initialLessonId;
      ref.read(selectedGradeIdProvider.notifier).state = widget.initialGradeId;
      ref.read(selectedTopicIdsProvider.notifier).state = {};
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unitsAsync = ref.watch(lessonUnitsProvider);
    final selectedLessonId = ref.watch(selectedLessonIdProvider);
    final selectedTopicIds = ref.watch(selectedTopicIdsProvider);
    final lessonTitle = (widget.initialLessonName ?? '').trim();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          lessonTitle.isEmpty
              ? 'Yazılıya Çalış'
              : 'Yazılıya Çalış • $lessonTitle',
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
      ),
      body: Column(
        children: [
          Expanded(
            child: selectedLessonId == null
                ? _EmptyHint(
                    icon: Icons.school_outlined,
                    text:
                        'Ders bilgisi gelmedi. Bu ekrana haftalık ders içinden geçin.',
                  )
                : unitsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Hata: $e')),
                    data: (units) => units.isEmpty
                        ? const _EmptyHint(
                            icon: Icons.list_alt_rounded,
                            text: 'Bu ders için ünite bulunamadı.',
                          )
                        : _UnitTopicTree(
                            units: units,
                            selectedTopicIds: selectedTopicIds,
                            onToggleTopic: (topicId) {
                              final current = ref.read(
                                selectedTopicIdsProvider,
                              );
                              final updated = {...current};
                              if (updated.contains(topicId)) {
                                updated.remove(topicId);
                              } else {
                                updated.add(topicId);
                              }
                              ref
                                      .read(selectedTopicIdsProvider.notifier)
                                      .state =
                                  updated;
                            },
                          ),
                  ),
          ),
        ],
      ),

      // ── Start button ────────────────────────────────────────────────
      bottomNavigationBar: selectedTopicIds.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: FilledButton.icon(
                  onPressed: () => _startSession(context, selectedTopicIds),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    '${selectedTopicIds.length} konu ile başla',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _startSession(BuildContext context, Set<int> topicIds) async {
    await ref
        .read(writtenSessionProvider.notifier)
        .startSession(topicIds.toList());

    if (!mounted) return;
    final session = ref.read(writtenSessionProvider);
    if (session == null || session.totalQuestions == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seçilen konularda soru bulunamadı.')),
      );
      return;
    }

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const WrittenSessionScreen()));
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

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                unit.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
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
                      const Divider(height: 1),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(topic.title, style: theme.textTheme.bodyMedium),
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
