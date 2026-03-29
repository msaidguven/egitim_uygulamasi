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
        // ── Answer area label ────────────────────────────────────────────
        Row(
          children: [
            Icon(Icons.edit_note_rounded, 
              size: 20, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              'Cevabını oluştur:',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Answer area ──────────────────────────────────────────────────
        _AnswerArea(
          placedWords: placed,
          status: attempt.status,
          isAnswered: isAnswered,
          onRemove: (i) => notifier.removeWord(i),
          onReorder: (from, to) => notifier.reorderWord(from, to),
        ),
        const SizedBox(height: 32),

        // ── Word bank ────────────────────────────────────────────────────
        Row(
          children: [
            Icon(Icons.widgets_outlined, 
              size: 18, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              'Kelimeler:',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _WordBank(
          words: bankWords,
          isAnswered: isAnswered,
          onTap: (word) => notifier.placeWord(word),
        ),
        const SizedBox(height: 32),

        // ── Confirm button ────────────────────────────────────────────────
        if (!isAnswered)
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: attempt.isComplete ? notifier.confirmAnswer : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Cevabı Kontrol Et',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ),
          ),

        // ── Feedback banner ───────────────────────────────────────────────
        if (isAnswered) 
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            child: _FeedbackBanner(attempt: attempt),
          ),
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
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 110),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _borderColor(context).withOpacity(0.4), 
          width: 2.5
        ),
        boxShadow: [
          BoxShadow(
            color: _borderColor(context).withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: placedWords.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app_outlined, 
                    size: 28, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3)),
                  const SizedBox(height: 10),
                  Text(
                    'Aşağıdan kelimelere dokunarak\ncümleyi oluşturmaya başla',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                        fontSize: 14,
                        height: 1.4,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )
          : isAnswered
              ? Wrap(
                  spacing: 12,
                  runSpacing: 12,
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
      spacing: 12,
      runSpacing: 12,
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
                scale: 1.1,
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
              opacity: 0.2,
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
                      borderRadius: BorderRadius.circular(16),
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
                onRemove: widget.onRemove,
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
      return Theme.of(context).colorScheme.primary.withOpacity(0.1);
    }
    if (!isAnswered) return Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7);
    return switch (status) {
      AnswerStatus.correct => Colors.green.shade100,
      AnswerStatus.incorrect => Colors.red.shade100,
      _ => Theme.of(context).colorScheme.primaryContainer,
    };
  }

  Color _textColor(BuildContext context) {
    if (isDragging) return Theme.of(context).colorScheme.primary;
    if (!isAnswered) return Theme.of(context).colorScheme.onPrimaryContainer;
    return switch (status) {
      AnswerStatus.correct => Colors.green.shade900,
      AnswerStatus.incorrect => Colors.red.shade900,
      _ => Theme.of(context).colorScheme.onPrimaryContainer,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: isAnswered ? null : () => onRemove(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _chipColor(context),
          borderRadius: BorderRadius.circular(14),
          boxShadow: isDragging
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  )
                ],
          border: Border.all(
            color: isDragging 
              ? theme.colorScheme.primary.withOpacity(0.4)
              : _textColor(context).withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isAnswered && !isDragging)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.drag_indicator_rounded,
                  size: 16,
                  color: _textColor(context).withOpacity(0.3),
                ),
              ),
            Text(word,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _textColor(context))),
            if (!isAnswered && !isDragging) ...[
              const SizedBox(width: 8),
              Icon(Icons.close_rounded,
                  size: 16, color: _textColor(context).withOpacity(0.35)),
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
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Text(
              'Tüm kelimeler yerleştirildi ✓',
              style: TextStyle(
                  color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: words
          .map((w) => GestureDetector(
                onTap: isAnswered ? null : () => onTap(w),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isAnswered ? 0.35 : 1.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: theme.colorScheme.outlineVariant.withOpacity(0.6),
                          width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(w,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface.withOpacity(0.9))),
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: isCorrect ? Colors.green.shade200 : Colors.red.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: (isCorrect ? Colors.green : Colors.red).withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isCorrect ? Colors.green.shade100 : Colors.red.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCorrect
                      ? Icons.check_circle_rounded
                      : Icons.error_rounded,
                  color: isCorrect
                      ? Colors.green.shade700
                      : Colors.red.shade600,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCorrect ? 'Mükemmel!' : 'Bir dahaki sefere...',
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: isCorrect
                              ? Colors.green.shade800
                              : Colors.red.shade800),
                    ),
                    Text(
                      isCorrect ? 'Tüm kelimeler doğru yerinde.' : 'Doğru dizilişi inceleyelim.',
                      style: TextStyle(
                          fontSize: 13,
                          color: isCorrect
                              ? Colors.green.shade700
                              : Colors.red.shade700),
                    ),
                  ],
                ),
              ),
              if (isCorrect) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade700,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 8)
                    ]
                  ),
                  child: Text('+${attempt.question.score}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14)),
                ),
              ],
            ],
          ),
          if (!isCorrect) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade100, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DOĞRU CEVAP',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  Text(modelAnswer,
                      style:
                          TextStyle(fontSize: 17, color: Colors.red.shade900, fontWeight: FontWeight.w800, height: 1.4)),
                ],
              ),
            ),
          ],
          if (solution != null) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded, size: 18, color: Colors.grey.shade700),
                const SizedBox(width: 8),
                Text('ÖĞRENME NOTU',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: Colors.grey.shade800)),
              ],
            ),
            const SizedBox(height: 10),
            Text(solution,
                style:
                    TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.6, fontWeight: FontWeight.w500)),
          ],
        ],
      ),
    );
  }
}
