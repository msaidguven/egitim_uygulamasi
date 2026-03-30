import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'written_practice_models.dart';
import 'written_practice_providers.dart';
import 'word_order_widget.dart';
import 'written_result_screen.dart';

class WrittenSessionScreen extends ConsumerWidget {
  const WrittenSessionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(writtenSessionProvider);
    if (session == null) return const SizedBox.shrink();

    final attempt = session.current;
    final theme = Theme.of(context);
    final isCorrect = attempt.status == AnswerStatus.correct;
    final textScale = ref.watch(writtenPracticeTextScaleProvider);
    final textScaleNotifier = ref.read(
      writtenPracticeTextScaleProvider.notifier,
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      drawer: const _TopicFilterDrawer(),
      appBar: AppBar(
        title: Text(
          'Yazılı Pratiği', // More descriptive
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => _confirmExit(context, ref),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${session.currentIndex + 1} / ${session.totalQuestions}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Progress bar ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Soru ${session.currentIndex + 1} / ${session.totalQuestions}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (session.currentIndex + 1) / session.totalQuestions,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),

          if (session.hasPrevious || isCorrect)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Row(
                children: [
                  if (session.hasPrevious)
                    OutlinedButton.icon(
                      onPressed: () => ref
                          .read(writtenSessionProvider.notifier)
                          .previousQuestion(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Önceki Soru'),
                    ),
                  const Spacer(),
                  if (isCorrect && !session.isLast)
                    FilledButton.icon(
                      onPressed: () => _onNext(context, ref, session),
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Sonraki Soru'),
                    ),
                ],
              ),
            ),

          // ── Question + word order ─────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Question Card ───────────────────────────────────────
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header: Badges & Hint Button
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 12, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _MetaBadges(attempt: attempt),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _TextScaleButton(
                                    label: 'A-',
                                    tooltip: 'Yazıyı küçült',
                                    onPressed: textScale <= 0.85
                                        ? null
                                        : textScaleNotifier.decrease,
                                  ),
                                  const SizedBox(width: 8),
                                  _TextScaleButton(
                                    label: 'A+',
                                    tooltip: 'Yazıyı büyüt',
                                    onPressed: textScale >= 4.0
                                        ? null
                                        : textScaleNotifier.increase,
                                  ),
                                  const SizedBox(width: 8),
                                  _HintToggleButton(attempt: attempt),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Question Text
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontSize: 22 * textScale,
                                    height: 1.4,
                                    fontWeight: FontWeight.w800,
                                    color: theme.colorScheme.onSurface,
                                    letterSpacing: -0.2,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '${session.currentIndex + 1}) ',
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    TextSpan(
                                      text: attempt.question.questionText,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Revealed Hints (Subtle)
                        if (attempt.revealedHintCount > 0)
                          _RevealedHintsList(attempt: attempt),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Word order widget
                  WordOrderWidget(
                    attempt: attempt,
                    textScale: textScale,
                    onRetry: () => ref
                        .read(writtenSessionProvider.notifier)
                        .retryCurrentQuestion(),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom next button ────────────────────────────────────────
          if (isCorrect && session.isLast)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: FilledButton.icon(
                  onPressed: () => _onNext(context, ref, session),
                  icon: Icon(Icons.flag_rounded),
                  label: Text(
                    'Sonuçları Gör',
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
        ],
      ),
    );
  }

  void _onNext(BuildContext context, WidgetRef ref, WrittenSession session) {
    if (session.isLast) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => WrittenResultScreen(session: session),
        ),
      );
    } else {
      ref.read(writtenSessionProvider.notifier).nextQuestion();
    }
  }

  Future<void> _confirmExit(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Çıkmak istiyor musun?'),
        content: const Text('İlerleme kaybolacak. Devam etmek istiyor musun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hayır'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Evet, çık'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      ref.read(writtenSessionProvider.notifier).reset();
      Navigator.of(context).pop();
    }
  }
}

class _TextScaleButton extends StatelessWidget {
  final String label;
  final String tooltip;
  final VoidCallback? onPressed;

  const _TextScaleButton({
    required this.label,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: tooltip,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 36),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _TopicFilterDrawer extends ConsumerWidget {
  const _TopicFilterDrawer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final unitsAsync = ref.watch(lessonUnitsProvider);
    final selectedTopicIds = ref.watch(selectedTopicIdsProvider);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.tune_rounded, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ünite ve Konular',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${selectedTopicIds.length} konu seçili',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            Expanded(
              child: unitsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Hata: $e')),
                data: (units) => units.isEmpty
                    ? const Center(child: Text('Ünite bulunamadı.'))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                        itemCount: units.length,
                        itemBuilder: (_, i) {
                          return _DrawerUnitTile(
                            unit: units[i],
                            selectedTopicIds: selectedTopicIds,
                          );
                        },
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: FilledButton.icon(
                onPressed: selectedTopicIds.isEmpty
                    ? null
                    : () => _restartSession(context, ref, selectedTopicIds),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Seçili konularla yeniden başlat'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _restartSession(
    BuildContext context,
    WidgetRef ref,
    Set<int> selectedTopicIds,
  ) async {
    Navigator.of(context).pop();
    await ref
        .read(writtenSessionProvider.notifier)
        .startSession(selectedTopicIds.toList());

    if (!context.mounted) return;
    final session = ref.read(writtenSessionProvider);
    if (session == null || session.totalQuestions == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seçilen konularda soru bulunamadı.')),
      );
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Oturum yeniden başlatıldı.')));
  }
}

class _DrawerUnitTile extends ConsumerWidget {
  final Unit unit;
  final Set<int> selectedTopicIds;

  const _DrawerUnitTile({required this.unit, required this.selectedTopicIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsAsync = ref.watch(topicsProvider(unit.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(unit.title),
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        children: [
          topicsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(12),
              child: LinearProgressIndicator(),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(12),
              child: Text('Hata: $e'),
            ),
            data: (topics) => topics.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Bu ünitede konu yok.'),
                  )
                : Column(
                    children: topics
                        .map(
                          (topic) => _DrawerTopicTile(
                            topic: topic,
                            isSelected: selectedTopicIds.contains(topic.id),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DrawerTopicTile extends ConsumerWidget {
  final Topic topic;
  final bool isSelected;

  const _DrawerTopicTile({required this.topic, required this.isSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CheckboxListTile(
      dense: true,
      value: isSelected,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      title: Text(topic.title, style: const TextStyle(fontSize: 14)),
      onChanged: (_) {
        final current = ref.read(selectedTopicIdsProvider);
        final updated = {...current};
        if (updated.contains(topic.id)) {
          updated.remove(topic.id);
        } else {
          updated.add(topic.id);
        }
        ref.read(selectedTopicIdsProvider.notifier).state = updated;
      },
    );
  }
}

// ── Hint Display Widgets ──────────────────────────────────────────────

class _HintToggleButton extends ConsumerWidget {
  final QuestionAttempt attempt;
  const _HintToggleButton({required this.attempt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(writtenSessionProvider.notifier);
    final isAnswered = attempt.status != AnswerStatus.unanswered;
    final allRevealed = attempt.allHintsRevealed;

    if (isAnswered) return const SizedBox.shrink();

    return TextButton.icon(
      onPressed: allRevealed ? null : notifier.useHint,
      style: TextButton.styleFrom(
        foregroundColor: Colors.amber.shade800,
        backgroundColor: Colors.amber.shade50,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(
        allRevealed ? Icons.lightbulb_outline_rounded : Icons.lightbulb_rounded,
        size: 18,
      ),
      label: Text(
        allRevealed ? 'İpuçları Açık' : 'İpucu Gör',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}

class _RevealedHintsList extends StatelessWidget {
  final QuestionAttempt attempt;
  const _RevealedHintsList({required this.attempt});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final answerWords = attempt.question.classical?.answerWords ?? [];
    final revealed = attempt.revealedHintCount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 24),
          Row(
            children: [
              Text(
                'İpucu: ',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.amber.shade900,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(revealed, (i) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.amber.shade300,
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        answerWords[i],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Meta badges (difficulty + score) ────────────────────────────────────────

class _MetaBadges extends StatelessWidget {
  final QuestionAttempt attempt;
  const _MetaBadges({required this.attempt});

  @override
  Widget build(BuildContext context) {
    final q = attempt.question;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Badge(
          icon: Icons.signal_cellular_alt_rounded,
          label: _difficultyLabel(q.difficulty),
          color: _difficultyColor(q.difficulty),
        ),
        const SizedBox(width: 8),
        _Badge(
          icon: Icons.stars_rounded,
          label: '${q.score} p',
          color: Colors
              .blue
              .shade600, // Changed from amber to distinguish from hints
        ),
      ],
    );
  }

  String _difficultyLabel(int d) => switch (d) {
    1 => 'Kolay',
    2 => 'Orta',
    3 => 'Zor',
    4 => 'Çok Zor',
    _ => 'Uzman',
  };

  Color _difficultyColor(int d) => switch (d) {
    1 => Colors.teal.shade600,
    2 => Colors.orange.shade600,
    3 => Colors.pink.shade500,
    _ => Colors.deepPurple.shade600,
  };
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Badge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
