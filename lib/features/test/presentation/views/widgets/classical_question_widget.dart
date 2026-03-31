// lib/features/test/presentation/views/widgets/classical_question_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:egitim_uygulamasi/features/test/data/models/test_question.dart';

/// Masaüstü/web → normal Draggable, mobil → LongPressDraggable
bool get _isDesktopOrWeb {
  if (kIsWeb) return true;
  try {
    return Platform.isLinux || Platform.isMacOS || Platform.isWindows;
  } catch (_) {
    return false;
  }
}

/// Test feature içinde kullanılan klasik (word-order) soru widget'ı.
///
/// [testQuestion] içindeki kelimeler karıştırılarak
/// kelime bankası olarak gösterilir.
/// Kullanıcı sıraladıktan sonra [onAnswered] ile `List<String>` döner.
/// [onAnswered] null'a çağrılırsa cevap iptal edilmiş demektir.
class ClassicalQuestionWidget extends StatefulWidget {
  final TestQuestion testQuestion;
  final ValueChanged<dynamic> onAnswered;

  const ClassicalQuestionWidget({
    super.key,
    required this.testQuestion,
    required this.onAnswered,
  });

  @override
  State<ClassicalQuestionWidget> createState() =>
      _ClassicalQuestionWidgetState();
}

class _ClassicalQuestionWidgetState extends State<ClassicalQuestionWidget> {
  /// Kelime öbeklerinden oluşan banka (henüz yerleştirilmemiş)
  late List<String> _bank;
  /// Kelime öbeklerinden oluşan cevap alanı
  late List<String> _placed;

  bool get _isChecked => widget.testQuestion.isChecked;
  bool get _isCorrect => widget.testQuestion.isCorrect;

  /// Orijinal (sıralı) kelimeleri karıştırır.
  List<String> _buildBank() {
    final list = List<String>.from(widget.testQuestion.question.answerWords);
    list.shuffle();
    return list;
  }

  @override
  void initState() {
    super.initState();
    _placed = [];

    // Eğer daha önce bir cevap var ise (resume) geri yükle
    final prev = widget.testQuestion.userAnswer;
    if (prev is List && prev.isNotEmpty) {
      _placed = List<String>.from(prev);
    }

    // Bank: tüm kelime setinden _placed'dekileri birer birer çıkar
    final allWords = _buildBank();
    _bank = List<String>.from(allWords);
    for (final chunk in _placed) {
      _bank.remove(chunk); // ilk eşleşeni kaldırır
    }
  }

  @override
  void didUpdateWidget(ClassicalQuestionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Soru değiştiğinde durumu sıfırla
    if (oldWidget.testQuestion.question.id !=
        widget.testQuestion.question.id) {
      _bank = _buildBank();
      _placed = [];
    }
  }

  void _placeWord(String chunk) {
    if (_isChecked) return;
    setState(() {
      _bank.remove(chunk);
      _placed.add(chunk);
    });
    _notifyAnswer();
  }

  void _removeWord(int index) {
    if (_isChecked) return;
    setState(() {
      _bank.add(_placed[index]);
      _placed.removeAt(index);
    });
    _notifyAnswer();
  }

  void _reorderWord(int from, int to) {
    if (_isChecked) return;
    setState(() {
      final chunk = _placed.removeAt(from);
      final insertAt = to > from ? to - 1 : to;
      _placed.insert(insertAt.clamp(0, _placed.length), chunk);
    });
    _notifyAnswer();
  }

  void _notifyAnswer() {
    if (_placed.isEmpty) {
      widget.onAnswered(null);
    } else {
      widget.onAnswered(List<String>.from(_placed));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNarrow = MediaQuery.of(context).size.width < 700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Cevap alanı ──────────────────────────────────────────────────
        _AnswerArea(
          placedWords: _placed,
          isChecked: _isChecked,
          isCorrect: _isCorrect,
          isNarrow: isNarrow,
          onRemove: _removeWord,
          onReorder: _reorderWord,
        ),
        SizedBox(height: isNarrow ? 20 : 28),

        // ── Kelime bankası ───────────────────────────────────────────────
        if (!_isChecked || _bank.isNotEmpty) ...[
          Row(
            children: [
              Icon(
                Icons.widgets_outlined,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
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
            words: _bank,
            isChecked: _isChecked,
            onTap: _placeWord,
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ANSWER AREA
// ─────────────────────────────────────────────────────────────────────────────

class _AnswerArea extends StatelessWidget {
  final List<String> placedWords;
  final bool isChecked;
  final bool isCorrect;
  final bool isNarrow;
  final void Function(int) onRemove;
  final void Function(int, int) onReorder;

  const _AnswerArea({
    required this.placedWords,
    required this.isChecked,
    required this.isCorrect,
    required this.isNarrow,
    required this.onRemove,
    required this.onReorder,
  });

  Color _borderColor(BuildContext context) {
    if (!isChecked) return Theme.of(context).colorScheme.outlineVariant;
    return isCorrect ? Colors.green.shade500 : Colors.red.shade400;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 100),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isChecked
            ? (isCorrect
                  ? Colors.green.shade50
                  : Colors.red.shade50)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _borderColor(context).withOpacity(isChecked ? 0.6 : 0.35),
          width: isChecked ? 2.5 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _borderColor(context).withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: placedWords.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.touch_app_outlined,
                    size: 26,
                    color:
                        theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aşağıdan kelimelere dokunarak\ncümleyi oluşturmaya başla',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant
                          .withOpacity(0.55),
                      fontSize: isNarrow ? 13 : 14,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : isChecked
          ? Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (int i = 0; i < placedWords.length; i++)
                  _WordChip(
                    word: placedWords[i],
                    index: i,
                    isChecked: true,
                    isCorrect: isCorrect,
                    onRemove: onRemove,
                  ),
              ],
            )
          : _DraggableWordList(
              words: placedWords,
              onRemove: onRemove,
              onReorder: onReorder,
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DRAGGABLE WORD LIST (sürükle-bırak sıralama)
// ─────────────────────────────────────────────────────────────────────────────

class _DraggableWordList extends StatefulWidget {
  final List<String> words;
  final void Function(int) onRemove;
  final void Function(int, int) onReorder;

  const _DraggableWordList({
    required this.words,
    required this.onRemove,
    required this.onReorder,
  });

  @override
  State<_DraggableWordList> createState() => _DraggableWordListState();
}

class _DraggableWordListState extends State<_DraggableWordList> {
  int? _draggingIndex;
  int? _hoverIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(widget.words.length, (i) {
        final word = widget.words[i];
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
                child: _WordChip(
                  word: word,
                  index: i,
                  isChecked: false,
                  isCorrect: false,
                  onRemove: (_) {},
                  isDragging: true,
                ),
              ),
            );

            final childWhenDragging = AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: 0.2,
              child: _WordChip(
                word: word,
                index: i,
                isChecked: false,
                isCorrect: false,
                onRemove: (_) {},
              ),
            );

            final innerChild = AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: isHover
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    )
                  : null,
              child: _WordChip(
                word: word,
                index: i,
                isChecked: false,
                isCorrect: false,
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
// WORD CHIP (yerleştirilmiş kelime)
// ─────────────────────────────────────────────────────────────────────────────

class _WordChip extends StatelessWidget {
  final String word;
  final int index;
  final bool isChecked;
  final bool isCorrect;
  final void Function(int) onRemove;
  final bool isDragging;

  const _WordChip({
    required this.word,
    required this.index,
    required this.isChecked,
    required this.isCorrect,
    required this.onRemove,
    this.isDragging = false,
  });

  Color _bg(BuildContext context) {
    if (isDragging) {
      return Theme.of(context).colorScheme.primary.withOpacity(0.1);
    }
    if (!isChecked) {
      return Theme.of(context).colorScheme.primaryContainer.withOpacity(0.8);
    }
    return isCorrect ? Colors.green.shade100 : Colors.red.shade100;
  }

  Color _fg(BuildContext context) {
    if (isDragging) return Theme.of(context).colorScheme.primary;
    if (!isChecked) {
      return Theme.of(context).colorScheme.onPrimaryContainer;
    }
    return isCorrect ? Colors.green.shade900 : Colors.red.shade900;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: isChecked ? null : () => onRemove(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: _bg(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDragging
                ? theme.colorScheme.primary.withOpacity(0.4)
                : _fg(context).withOpacity(0.15),
            width: 1,
          ),
          boxShadow: isDragging
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isChecked && !isDragging)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.drag_indicator_rounded,
                  size: 15,
                  color: _fg(context).withOpacity(0.3),
                ),
              ),
            Text(
              word,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _fg(context),
              ),
            ),
            if (!isChecked && !isDragging) ...[
              const SizedBox(width: 7),
              Icon(
                Icons.close_rounded,
                size: 15,
                color: _fg(context).withOpacity(0.35),
              ),
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
  final bool isChecked;
  final void Function(String) onTap;

  const _WordBank({
    required this.words,
    required this.isChecked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (words.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Tüm kelimeler yerleştirildi ✓',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: words.map((w) {
        return GestureDetector(
          onTap: isChecked ? null : () => onTap(w),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isChecked ? 0.35 : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color:
                      theme.colorScheme.outlineVariant.withOpacity(0.55),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                w,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface.withOpacity(0.88),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
