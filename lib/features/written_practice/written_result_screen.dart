import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'written_practice_models.dart';
import 'written_practice_providers.dart';

class WrittenResultScreen extends ConsumerWidget {
  final WrittenSession session;
  const WrittenResultScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final correct = session.correctCount;
    final total = session.totalQuestions;
    final score = session.totalScore;
    final pct = total == 0 ? 0.0 : correct / total;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              // ── Trophy / emoji ─────────────────────────────────────
              Text(
                _emoji(pct),
                style: const TextStyle(fontSize: 72),
              ),
              const SizedBox(height: 16),
              Text(
                _headline(pct),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '$correct / $total soruyu doğru yaptın',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 32),

              // ── Stats row ──────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StatCard(
                    value: '$correct',
                    label: 'Doğru',
                    color: Colors.green.shade600,
                    icon: Icons.check_circle_rounded,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    value: '${session.incorrectCount}',
                    label: 'Yanlış',
                    color: Colors.red.shade500,
                    icon: Icons.cancel_rounded,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    value: '$score',
                    label: 'Puan',
                    color: Colors.amber.shade700,
                    icon: Icons.star_rounded,
                  ),
                ],
              ),

              const Spacer(),

              // ── Actions ────────────────────────────────────────────
              FilledButton.icon(
                onPressed: () {
                  ref.read(writtenSessionProvider.notifier).reset();
                  Navigator.of(context).popUntil((r) => r.isFirst);
                },
                icon: const Icon(Icons.home_rounded),
                label: const Text('Ana Sayfaya Dön'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(writtenSessionProvider.notifier).reset();
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Tekrar Çalış'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _emoji(double pct) {
    if (pct == 1.0) return '🏆';
    if (pct >= 0.7) return '🌟';
    if (pct >= 0.4) return '💪';
    return '📚';
  }

  String _headline(double pct) {
    if (pct == 1.0) return 'Mükemmel! Hepsini bildin!';
    if (pct >= 0.7) return 'Harika! Çok iyi gidiyorsun!';
    if (pct >= 0.4) return 'İyi! Biraz daha çalışalım.';
    return 'Tekrar çalışmaya devam et!';
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
