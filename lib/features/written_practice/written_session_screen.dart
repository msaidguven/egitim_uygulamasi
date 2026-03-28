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
    final isAnswered = attempt.status != AnswerStatus.unanswered;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          '${session.currentIndex + 1} / ${session.totalQuestions}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _confirmExit(context, ref),
        ),
      ),
      body: Column(
        children: [
          // ── Progress bar ──────────────────────────────────────────────
          LinearProgressIndicator(
            value: (session.currentIndex + 1) / session.totalQuestions,
            backgroundColor:
                theme.colorScheme.surfaceContainerHighest,
            minHeight: 4,
          ),

          // ── Question + word order ─────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Difficulty & score badge
                  _MetaBadges(attempt: attempt),
                  const SizedBox(height: 16),

                  // Question text
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer
                          .withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      attempt.question.questionText,
                      style: theme.textTheme.titleMedium?.copyWith(
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Word order widget
                  WordOrderWidget(attempt: attempt),
                ],
              ),
            ),
          ),

          // ── Bottom next button ────────────────────────────────────────
          if (isAnswered)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: FilledButton.icon(
                  onPressed: () => _onNext(context, ref, session),
                  icon: Icon(
                    session.isLast
                        ? Icons.flag_rounded
                        : Icons.arrow_forward_rounded,
                  ),
                  label: Text(
                    session.isLast ? 'Sonuçları Gör' : 'Sonraki Soru',
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

  void _onNext(
      BuildContext context, WidgetRef ref, WrittenSession session) {
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
        content:
            const Text('İlerleme kaybolacak. Devam etmek istiyor musun?'),
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

// ── Meta badges (difficulty + score) ────────────────────────────────────────

class _MetaBadges extends StatelessWidget {
  final QuestionAttempt attempt;
  const _MetaBadges({required this.attempt});

  @override
  Widget build(BuildContext context) {
    final q = attempt.question;
    return Row(
      children: [
        _Badge(
          icon: Icons.signal_cellular_alt_rounded,
          label: _difficultyLabel(q.difficulty),
          color: _difficultyColor(q.difficulty),
        ),
        const SizedBox(width: 8),
        _Badge(
          icon: Icons.star_rounded,
          label: '${q.score} puan',
          color: Colors.amber.shade700,
        ),
      ],
    );
  }

  String _difficultyLabel(int d) => switch (d) {
        1 => 'Kolay',
        2 => 'Orta',
        3 => 'Zor',
        4 => 'Çok Zor',
        _ => 'Uzmanlık',
      };

  Color _difficultyColor(int d) => switch (d) {
        1 => Colors.green.shade600,
        2 => Colors.orange.shade600,
        3 => Colors.red.shade500,
        _ => Colors.purple.shade600,
      };
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Badge(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
