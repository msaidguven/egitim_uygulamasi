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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withOpacity(0.05),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // ── Trophy / emoji ─────────────────────────────────────
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(_emoji(pct), style: const TextStyle(fontSize: 80)),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  _headline(pct),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$total soruda $correct doğru cevap',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // ── Stats row ──────────────────────────────────────────
                Row(
                  children: [
                    _StatCard(
                      value: '$correct',
                      label: 'Doğru',
                      color: Colors.teal.shade600,
                      icon: Icons.check_circle_rounded,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      value: '${session.incorrectCount}',
                      label: 'Yanlış',
                      color: Colors.pink.shade500,
                      icon: Icons.cancel_rounded,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      value: '$score',
                      label: 'Puan',
                      color: Colors.blue.shade600,
                      icon: Icons.stars_rounded,
                    ),
                  ],
                ),

                const Spacer(flex: 3),

                // ── Actions ────────────────────────────────────────────
                FilledButton.icon(
                  onPressed: () {
                    ref.read(writtenSessionProvider.notifier).reset();
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  },
                  icon: const Icon(Icons.home_rounded, size: 22),
                  label: const Text('Ana Sayfaya Dön'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(60),
                    backgroundColor: theme.colorScheme.primary,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    ref.read(writtenSessionProvider.notifier).reset();
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.replay_rounded, size: 22),
                  label: const Text('Tekrar Çalış'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(60),
                    side: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
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
    if (pct == 1.0) return 'Harika! Hepsini bildin!';
    if (pct >= 0.7) return 'Müthiş! Çok iyi gidiyorsun!';
    if (pct >= 0.4) return 'İyi! Biraz daha gayret.';
    return 'Pes etme, tekrar deneyelim!';
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
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.15), width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: -1,
              ),
            ),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
