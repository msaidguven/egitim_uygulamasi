import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'written_practice_models.dart';
import 'written_practice_providers.dart';
import 'written_session_screen.dart';

class WrittenPracticeHomeScreen extends ConsumerStatefulWidget {
  static const routeName = '/written-practice';

  const WrittenPracticeHomeScreen({super.key});

  @override
  ConsumerState<WrittenPracticeHomeScreen> createState() =>
      _WrittenPracticeHomeScreenState();
}

class _WrittenPracticeHomeScreenState
    extends ConsumerState<WrittenPracticeHomeScreen> {
  int? _expandedUnitId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subjects = ref.watch(subjectsProvider);
    final selectedSubject = ref.watch(selectedSubjectProvider);
    final selectedTopicIds = ref.watch(selectedTopicIdsProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Yazılıya Çalış'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
      ),
      body: Column(
        children: [
          // ── Subject selector ──────────────────────────────────────────
          subjects.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Hata: $e'),
            data: (list) => _SubjectChips(
              subjects: list,
              selected: selectedSubject,
              onSelect: (s) {
                ref.read(selectedSubjectProvider.notifier).state = s;
                ref.read(selectedTopicIdsProvider.notifier).state = {};
                setState(() => _expandedUnitId = null);
              },
            ),
          ),

          // ── Unit > Topic tree ─────────────────────────────────────────
          Expanded(
            child: selectedSubject == null
                ? _EmptyHint(
                    icon: Icons.school_outlined,
                    text: 'Önce bir ders seç',
                  )
                : _UnitTopicTree(
                    subject: selectedSubject,
                    selectedTopicIds: selectedTopicIds,
                    expandedUnitId: _expandedUnitId,
                    onExpandUnit: (id) => setState(() => _expandedUnitId = id),
                    onToggleTopic: (topicId) {
                      final current = ref.read(selectedTopicIdsProvider);
                      final updated = {...current};
                      if (updated.contains(topicId)) {
                        updated.remove(topicId);
                      } else {
                        updated.add(topicId);
                      }
                      ref.read(selectedTopicIdsProvider.notifier).state =
                          updated;
                    },
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

// ── Subject chips ────────────────────────────────────────────────────────────

class _SubjectChips extends StatelessWidget {
  final List<Subject> subjects;
  final Subject? selected;
  final void Function(Subject) onSelect;

  const _SubjectChips({
    required this.subjects,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: subjects.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final s = subjects[i];
          final isSelected = selected?.id == s.id;
          return ChoiceChip(
            label: Text(s.title),
            selected: isSelected,
            onSelected: (_) => onSelect(s),
          );
        },
      ),
    );
  }
}

// ── Unit > Topic tree ────────────────────────────────────────────────────────

class _UnitTopicTree extends ConsumerWidget {
  final Subject subject;
  final Set<int> selectedTopicIds;
  final int? expandedUnitId;
  final void Function(int?) onExpandUnit;
  final void Function(int) onToggleTopic;

  const _UnitTopicTree({
    required this.subject,
    required this.selectedTopicIds,
    required this.expandedUnitId,
    required this.onExpandUnit,
    required this.onToggleTopic,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitsAsync = ref.watch(unitsProvider(subject.id));

    return unitsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Hata: $e')),
      data: (units) => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: units.length,
        itemBuilder: (_, i) => _UnitTile(
          unit: units[i],
          isExpanded: expandedUnitId == units[i].id,
          selectedTopicIds: selectedTopicIds,
          onExpand: () =>
              onExpandUnit(expandedUnitId == units[i].id ? null : units[i].id),
          onToggleTopic: onToggleTopic,
        ),
      ),
    );
  }
}

class _UnitTile extends ConsumerWidget {
  final Unit unit;
  final bool isExpanded;
  final Set<int> selectedTopicIds;
  final VoidCallback onExpand;
  final void Function(int) onToggleTopic;

  const _UnitTile({
    required this.unit,
    required this.isExpanded,
    required this.selectedTopicIds,
    required this.onExpand,
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
          // Unit header
          ListTile(
            title: Text(
              unit.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: Icon(
              isExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
            ),
            onTap: onExpand,
          ),

          // Topics
          if (isExpanded)
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
