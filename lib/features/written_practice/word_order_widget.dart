import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'written_practice_models.dart';
import 'written_practice_providers.dart';

/// Masaüstü ve web'de normal Draggable (mouse),
/// mobilde LongPressDraggable kullanır.
bool get _isDesktopOrWeb {
  if (kIsWeb) return true;
  try {
    return Platform.isLinux || Platform.isMacOS || Platform.isWindows;
  } catch (_) {
    return false;
  }
}

class WordOrderWidget extends ConsumerWidget {
  final QuestionAttempt attempt;
  const WordOrderWidget({super.key, required this.attempt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(writtenSessionProvider.notifier);
    final theme = Theme.of(context);
    final isAnswered = attempt.status != AnswerStatus.unanswered;

    final placed = attempt.placedWords;
    final allWords = attempt.shuffledWords;
    final bankWords = _remainingBankWords(allWords, placed);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Hint section ─────────────────────────────────────────────────
        _HintSection(attempt: attempt, isAnswered: isAnswered),
        const SizedBox(height: 20),

        // ── Answer area label ────────────────────────────────────────────
        Text(
          'Cevabını oluştur:',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),

        // ── Answer area ──────────────────────────────────────────────────
        _AnswerArea(
          placedWords: placed,
          status: attempt.status,
          isAnswered: isAnswered,
          onRemove: (i) => notifier.removeWord(i),
          onReorder: (from, to) => notifier.reorderWord(from, to),
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

        // ── Confirm button ────────────────────────────────────────────────
        if (!isAnswered)
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: attempt.isComplete ? notifier.confirmAnswer : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Cevabı Kontrol Et',
                  style: TextStyle(fontSize: 16)),
            ),
          ),

        // ── Feedback banner ───────────────────────────────────────────────
        if (isAnswered) _FeedbackBanner(attempt: attempt),
      ],
    );
  }

  List<String> _remainingBankWords(
      List<String> shuffled, List<String> placed) {
    final pool = [...shuffled];
    for (final w in placed) pool.remove(w);
    return pool;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HINT SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _HintSection extends ConsumerWidget {
  final QuestionAttempt attempt;
  final bool isAnswered;

  const _HintSection({required this.attempt, required this.isAnswered});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(writtenSessionProvider.notifier);
    final answerWords = attempt.question.classical?.answerWords ?? [];
    final revealed = attempt.revealedHintCount;
    final allRevealed = attempt.allHintsRevealed;

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header — tapping reveals next word
            InkWell(
              onTap: isAnswered || allRevealed ? null : notifier.useHint,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_rounded,
                        color: Colors.amber.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        revealed == 0
                            ? 'İpucuna bak'
                            : allRevealed
                                ? 'Tüm ipuçları açıldı'
                                : 'Sonraki kelimeyi gör  ($revealed / ${answerWords.length})',
                        style: TextStyle(
                          color: Colors.amber.shade800,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (!isAnswered && !allRevealed)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Tıkla',
                          style: TextStyle(
                            color: Colors.amber.shade900,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Revealed words row
            if (revealed > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (int i = 0; i < revealed; i++)
                      _HintWordChip(
                        word: answerWords[i],
                        index: i + 1,
                        isNew: i == revealed - 1,
                      ),
                    if (!allRevealed)
                      ...List.generate(
                        answerWords.length - revealed,
                        (_) => _HintPlaceholder(),
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

class _HintWordChip extends StatefulWidget {
  final String word;
  final int index;
  final bool isNew;
  const _HintWordChip(
      {required this.word, required this.index, required this.isNew});

  @override
  State<_HintWordChip> createState() => _HintWordChipState();
}

class _HintWordChipState extends State<_HintWordChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    widget.isNew ? _ctrl.forward() : (_ctrl.value = 1.0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.amber.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.shade400),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${widget.index}.',
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.amber.shade700,
                    fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            Text(widget.word,
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.amber.shade900,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _HintPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Center(
          child:
              Icon(Icons.more_horiz, size: 14, color: Colors.amber.shade400)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ANSWER AREA
// ─────────────────────────────────────────────────────────────────────────────

class _AnswerArea extends StatelessWidget {
  final List<String> placedWords;
  final AnswerStatus status;
  final bool isAnswered;
  final void Function(int) onRemove;
  final void Function(int, int) onReorder;

  const _AnswerArea({
    required this.placedWords,
    required this.status,
    required this.isAnswered,
    required this.onRemove,
    required this.onReorder,
  });

  Color _borderColor(BuildContext context) => switch (status) {
        AnswerStatus.correct => Colors.green.shade600,
        AnswerStatus.incorrect => Colors.red.shade400,
        AnswerStatus.unanswered =>
          Theme.of(context).colorScheme.outlineVariant,
      };

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
                    fontSize: 13),
              ),
            )
          : isAnswered
              ? Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (int i = 0; i < placedWords.length; i++)
                      _PlacedWordChip(
                        word: placedWords[i],
                        index: i,
                        isAnswered: true,
                        status: status,
                        onRemove: onRemove,
                      ),
                  ],
                )
              : _DraggableWrapWordList(
                  words: placedWords,
                  status: status,
                  onRemove: onRemove,
                  onReorder: onReorder,
                ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DRAGGABLE WRAP WORD LIST
// Kelimeleri yan yana (Wrap) gösterir. Uzun basınca sürükleme başlar,
// hedef konuma bırakınca notifier.reorderWord çağrılır.
// ─────────────────────────────────────────────────────────────────────────────

class _DraggableWrapWordList extends StatefulWidget {
  final List<String> words;
  final AnswerStatus status;
  final void Function(int) onRemove;
  final void Function(int, int) onReorder;

  const _DraggableWrapWordList({
    required this.words,
    required this.status,
    required this.onRemove,
    required this.onReorder,
  });

  @override
  State<_DraggableWrapWordList> createState() => _DraggableWrapWordListState();
}

class _DraggableWrapWordListState extends State<_DraggableWrapWordList> {
  int? _draggingIndex;
  int? _hoverIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(widget.words.length, (i) {
        final word = widget.words[i];
        final isDragging = _draggingIndex == i;
        final isHover = _hoverIndex == i && _draggingIndex != i;

        return DragTarget<int>(
          onWillAcceptWithDetails: (details) {
            if (details.data != i) {
              setState(() => _hoverIndex = i);
            }
            return details.data != i;
          },
          onLeave: (_) => setState(() => _hoverIndex = null),
          onAcceptWithDetails: (details) {
            setState(() {
              _hoverIndex = null;
              _draggingIndex = null;
            });
            widget.onReorder(details.data, i > details.data ? i + 1 : i);
          },
          builder: (context, candidateData, rejectedData) {
            final feedback = Material(
              color: Colors.transparent,
              child: Transform.scale(
                scale: 1.08,
                child: _PlacedWordChip(
                  word: word,
                  index: i,
                  isAnswered: false,
                  status: widget.status,
                  onRemove: (_) {},
                  isDragging: true,
                ),
              ),
            );

            final childWhenDragging = AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: 0.25,
              child: _PlacedWordChip(
                word: word,
                index: i,
                isAnswered: false,
                status: widget.status,
                onRemove: (_) {},
              ),
            );

            final innerChild = AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: isHover
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    )
                  : null,
              child: _PlacedWordChip(
                word: word,
                index: i,
                isAnswered: false,
                status: widget.status,
                onRemove: onRemove,
              ),
            );

            void onDragStarted() => setState(() => _draggingIndex = i);
            void onDragEnd(DraggableDetails _) => setState(() {
                  _draggingIndex = null;
                  _hoverIndex = null;
                });
            void onDraggableCanceled(Velocity _, Offset __) => setState(() {
                  _draggingIndex = null;
                  _hoverIndex = null;
                });

            // Masaüstü/web: normal mouse sürükleme
            // Mobil: uzun basarak sürükleme
            if (_isDesktopOrWeb) {
              return Draggable<int>(
                data: i,
                feedback: feedback,
                childWhenDragging: childWhenDragging,
                onDragStarted: onDragStarted,
                onDragEnd: onDragEnd,
                onDraggableCanceled: onDraggableCanceled,
                child: innerChild,
              );
            }
            return LongPressDraggable<int>(
              data: i,
              delay: const Duration(milliseconds: 200),
              feedback: feedback,
              childWhenDragging: childWhenDragging,
              onDragStarted: onDragStarted,
              onDragEnd: onDragEnd,
              onDraggableCanceled: onDraggableCanceled,
              child: innerChild,
            );
          },
        );
      }),
    );
  }

  void onRemove(int index) {
    widget.onRemove(index);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLACED WORD CHIP
// ─────────────────────────────────────────────────────────────────────────────

class _PlacedWordChip extends StatelessWidget {
  final String word;
  final int index;
  final bool isAnswered;
  final AnswerStatus status;
  final void Function(int) onRemove;
  final bool isDragging;

  const _PlacedWordChip({
    required this.word,
    required this.index,
    required this.isAnswered,
    required this.status,
    required this.onRemove,
    this.isDragging = false,
  });

  Color _chipColor(BuildContext context) {
    if (isDragging) {
      return Theme.of(context).colorScheme.primary.withOpacity(0.15);
    }
    if (!isAnswered) return Theme.of(context).colorScheme.primaryContainer;
    return switch (status) {
      AnswerStatus.correct => Colors.green.shade100,
      AnswerStatus.incorrect => Colors.red.shade100,
      _ => Theme.of(context).colorScheme.primaryContainer,
    };
  }

  Color _textColor(BuildContext context) {
    if (isDragging) return Theme.of(context).colorScheme.primary;
    if (!isAnswered)
      return Theme.of(context).colorScheme.onPrimaryContainer;
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
          boxShadow: isDragging
              ? [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isAnswered && !isDragging)
              Padding(
                padding: const EdgeInsets.only(right: 5),
                child: Icon(
                  Icons.drag_indicator_rounded,
                  size: 14,
                  color: _textColor(context).withOpacity(0.5),
                ),
              ),
            Text(word,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textColor(context))),
            if (!isAnswered && !isDragging) ...[
              const SizedBox(width: 6),
              Icon(Icons.close_rounded,
                  size: 14, color: _textColor(context).withOpacity(0.6)),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WORD BANK
// ─────────────────────────────────────────────────────────────────────────────

class _WordBank extends StatelessWidget {
  final List<String> words;
  final bool isAnswered;
  final void Function(String) onTap;

  const _WordBank(
      {required this.words, required this.isAnswered, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (words.isEmpty && !isAnswered) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Tüm kelimeler yerleştirildi ✓',
          style: TextStyle(
              color: theme.colorScheme.primary, fontWeight: FontWeight.w500),
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: words
          .map((w) => GestureDetector(
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
                          color:
                              theme.colorScheme.secondary.withOpacity(0.3)),
                    ),
                    child: Text(w,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSecondaryContainer)),
                  ),
                ),
              ))
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FEEDBACK BANNER
// ─────────────────────────────────────────────────────────────────────────────

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
            color: isCorrect ? Colors.green.shade300 : Colors.red.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                color: isCorrect
                    ? Colors.green.shade700
                    : Colors.red.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                isCorrect ? 'Doğru!' : 'Yanlış',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isCorrect
                        ? Colors.green.shade800
                        : Colors.red.shade700),
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
                  child: Text('+${attempt.question.score} puan',
                      style: TextStyle(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ),
              ],
            ],
          ),
          if (!isCorrect) ...[
            const SizedBox(height: 10),
            Text('Doğru cevap:',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(modelAnswer,
                style:
                    TextStyle(fontSize: 14, color: Colors.red.shade900)),
          ],
          if (solution != null) ...[
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 6),
            Text('💡 Açıklama',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700)),
            const SizedBox(height: 4),
            Text(solution,
                style:
                    TextStyle(fontSize: 13, color: Colors.grey.shade800)),
          ],
        ],
      ),
    );
  }
}