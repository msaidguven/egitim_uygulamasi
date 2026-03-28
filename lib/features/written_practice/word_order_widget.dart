import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'written_practice_models.dart';
import 'written_practice_providers.dart';

class WordOrderWidget extends ConsumerWidget {
  final QuestionAttempt attempt;
  const WordOrderWidget({super.key, required this.attempt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(writtenSessionProvider.notifier);
    final theme = Theme.of(context);
    final isAnswered = attempt.status != AnswerStatus.unanswered;

    // Words still available in the bank
    final placed = attempt.placedWords;
    final allWords = attempt.shuffledWords;
    final bankWords = _remainingBankWords(allWords, placed);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Answer area ─────────────────────────────────────────────────
        Text(
          'Cevabını oluştur:',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        _AnswerArea(
          placedWords: placed,
          status: attempt.status,
          isAnswered: isAnswered,
          onRemove: (i) => notifier.removeWord(i),
        ),

        const SizedBox(height: 24),

        // ── Word bank ────────────────────────────────────────────────────
        Text(
          'Kelimeler:',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        _WordBank(
          words: bankWords,
          isAnswered: isAnswered,
          onTap: (word) => notifier.placeWord(word),
        ),

        const SizedBox(height: 28),

        // ── Confirm button ───────────────────────────────────────────────
        if (!isAnswered)
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: attempt.isComplete ? notifier.confirmAnswer : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cevabı Kontrol Et',
                  style: TextStyle(fontSize: 16)),
            ),
          ),

        // ── Feedback ─────────────────────────────────────────────────────
        if (isAnswered) _FeedbackBanner(attempt: attempt),
      ],
    );
  }

  /// Returns words still available: placed words are consumed one by one
  List<String> _remainingBankWords(
      List<String> shuffled, List<String> placed) {
    final pool = [...shuffled];
    for (final w in placed) {
      pool.remove(w);
    }
    return pool;
  }
}

// ── Answer area ─────────────────────────────────────────────────────────────

class _AnswerArea extends StatelessWidget {
  final List<String> placedWords;
  final AnswerStatus status;
  final bool isAnswered;
  final void Function(int index) onRemove;

  const _AnswerArea({
    required this.placedWords,
    required this.status,
    required this.isAnswered,
    required this.onRemove,
  });

  Color _borderColor(BuildContext context) {
    return switch (status) {
      AnswerStatus.correct => Colors.green.shade600,
      AnswerStatus.incorrect => Colors.red.shade400,
      AnswerStatus.unanswered => Theme.of(context).colorScheme.outlineVariant,
    };
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor(context), width: 1.8),
      ),
      child: placedWords.isEmpty
          ? Center(
              child: Text(
                'Aşağıdan kelimelere dokun',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int i = 0; i < placedWords.length; i++)
                  _PlacedWordChip(
                    word: placedWords[i],
                    index: i,
                    isAnswered: isAnswered,
                    status: status,
                    onRemove: onRemove,
                  ),
              ],
            ),
    );
  }
}

class _PlacedWordChip extends StatelessWidget {
  final String word;
  final int index;
  final bool isAnswered;
  final AnswerStatus status;
  final void Function(int) onRemove;

  const _PlacedWordChip({
    required this.word,
    required this.index,
    required this.isAnswered,
    required this.status,
    required this.onRemove,
  });

  Color _chipColor(BuildContext context) {
    if (!isAnswered) return Theme.of(context).colorScheme.primaryContainer;
    return switch (status) {
      AnswerStatus.correct => Colors.green.shade100,
      AnswerStatus.incorrect => Colors.red.shade100,
      _ => Theme.of(context).colorScheme.primaryContainer,
    };
  }

  Color _textColor(BuildContext context) {
    if (!isAnswered) return Theme.of(context).colorScheme.onPrimaryContainer;
    return switch (status) {
      AnswerStatus.correct => Colors.green.shade800,
      AnswerStatus.incorrect => Colors.red.shade800,
      _ => Theme.of(context).colorScheme.onPrimaryContainer,
    };
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isAnswered ? null : () => onRemove(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _chipColor(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          word,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textColor(context),
          ),
        ),
      ),
    );
  }
}

// ── Word bank ────────────────────────────────────────────────────────────────

class _WordBank extends StatelessWidget {
  final List<String> words;
  final bool isAnswered;
  final void Function(String) onTap;

  const _WordBank({
    required this.words,
    required this.isAnswered,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: words
          .map(
            (w) => GestureDetector(
              onTap: isAnswered ? null : () => onTap(w),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isAnswered ? 0.35 : 1.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.colorScheme.secondary.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    w,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ── Feedback banner ──────────────────────────────────────────────────────────

class _FeedbackBanner extends StatelessWidget {
  final QuestionAttempt attempt;
  const _FeedbackBanner({required this.attempt});

  @override
  Widget build(BuildContext context) {
    final isCorrect = attempt.status == AnswerStatus.correct;
    final modelAnswer = attempt.question.classical?.modelAnswer ?? '';
    final solution = attempt.question.solutionText;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect ? Colors.green.shade300 : Colors.red.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: isCorrect ? Colors.green.shade700 : Colors.red.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                isCorrect ? 'Doğru!' : 'Yanlış',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color:
                      isCorrect ? Colors.green.shade800 : Colors.red.shade700,
                ),
              ),
              if (isCorrect) ...[
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+${attempt.question.score} puan',
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (!isCorrect) ...[
            const SizedBox(height: 10),
            Text(
              'Doğru cevap:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              modelAnswer,
              style: TextStyle(
                fontSize: 14,
                color: Colors.red.shade900,
              ),
            ),
          ],
          if (solution != null) ...[
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 6),
            Text(
              '💡 Açıklama',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              solution,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
