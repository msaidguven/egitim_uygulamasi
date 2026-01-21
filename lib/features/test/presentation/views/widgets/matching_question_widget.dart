import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:egitim_uygulamasi/features/test/data/models/test_question.dart';
import 'package:egitim_uygulamasi/models/question_model.dart';

class MatchingQuestionWidget extends StatefulWidget {
  final TestQuestion testQuestion;
  final ValueChanged<dynamic> onAnswered;

  const MatchingQuestionWidget({required this.testQuestion, required this.onAnswered});

  @override
  _MatchingQuestionWidgetState createState() => _MatchingQuestionWidgetState();
}

class _MatchingQuestionWidgetState extends State<MatchingQuestionWidget> {
  late List<String> leftTexts;
  late List<MatchingPair> shuffledRightPairs;
  late Map<String, MatchingPair?> userMatches;
  String? _draggingLeftText;
  MatchingPair? _draggingBackPair;

  @override
  void initState() {
    super.initState();
    final question = widget.testQuestion.question;
    leftTexts = question.matchingPairs?.map((p) => p.left_text).toList() ?? [];
    shuffledRightPairs = List.from(question.matchingPairs ?? [])..shuffle();
    userMatches = {};
  }

  void _removeMatch(String leftText) {
    if (widget.testQuestion.isChecked) return;
    setState(() {
      final removedPair = userMatches[leftText];
      if (removedPair != null) {
        userMatches.remove(leftText);
        widget.onAnswered(Map<String, MatchingPair?>.from(userMatches));
      }
    });
  }

  void _startDragBack(String leftText) {
    if (widget.testQuestion.isChecked) return;
    setState(() {
      _draggingLeftText = leftText;
      _draggingBackPair = userMatches[leftText];
    });
  }

  void _endDragBack(DraggableDetails details) {
    if (_draggingBackPair != null && _draggingLeftText != null) {
      _removeMatch(_draggingLeftText!);
    }
    setState(() {
      _draggingLeftText = null;
      _draggingBackPair = null;
    });
  }

  void _cancelDragBack() {
    setState(() {
      _draggingLeftText = null;
      _draggingBackPair = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isChecked = widget.testQuestion.isChecked;
    final screenWidth = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...List.generate(leftTexts.length, (index) {
            final leftText = leftTexts[index];
            final matchedPair = userMatches[leftText];
            final isDraggingBack = _draggingLeftText == leftText;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: DragTarget<MatchingPair>(
                builder: (context, candidateData, rejectedData) {
                  return matchedPair != null
                      ? Draggable<MatchingPair>(
                    data: matchedPair,
                    onDragStarted: () => _startDragBack(leftText),
                    onDragEnd: _endDragBack,
                    onDraggableCanceled: (velocity, offset) => _cancelDragBack(),
                    feedback: Material(
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: screenWidth * 0.8,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade400, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          matchedPair.right_text,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.3,
                      child: _buildMatchContainer(
                        index: index,
                        leftText: leftText,
                        matchedPair: matchedPair,
                        isDraggingBack: true,
                        screenWidth: screenWidth,
                      ),
                    ),
                    child: GestureDetector(
                      onTap: () => _removeMatch(leftText),
                      child: Opacity(
                        opacity: isDraggingBack ? 0.5 : 1.0,
                        child: _buildMatchContainer(
                          index: index,
                          leftText: leftText,
                          matchedPair: matchedPair,
                          screenWidth: screenWidth,
                        ),
                      ),
                    ),
                  )
                      : DragTarget<MatchingPair>(
                    builder: (context, candidateData, rejectedData) {
                      return _buildMatchContainer(
                        index: index,
                        leftText: leftText,
                        matchedPair: null,
                        screenWidth: screenWidth,
                      );
                    },
                    onAccept: (data) {
                      if (isChecked) return;
                      setState(() {
                        final existingEntry = userMatches.entries
                            .firstWhereOrNull((entry) => entry.value?.right_text == data.right_text);
                        if (existingEntry != null) {
                          userMatches.remove(existingEntry.key);
                        }

                        userMatches[leftText] = data;
                        widget.onAnswered(Map<String, MatchingPair?>.from(userMatches));
                      });
                    },
                  );
                },
                onAccept: (data) {
                  if (isChecked) return;
                  setState(() {
                    final existingEntry = userMatches.entries
                        .firstWhereOrNull((entry) => entry.value?.right_text == data.right_text);
                    if (existingEntry != null) {
                      userMatches.remove(existingEntry.key);
                    }

                    userMatches[leftText] = data;
                    widget.onAnswered(Map<String, MatchingPair?>.from(userMatches));
                  });
                },
              ),
            );
          }),

          if (!isChecked) ...[
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                'Kullanılabilir Seçenekler:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      'Aşağıdaki seçenekleri yukarıdaki kutulara sürükleyin:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: shuffledRightPairs
                        .where((p) => !userMatches.values.contains(p))
                        .map((pair) {
                      return Draggable<MatchingPair>(
                        data: pair,
                        feedback: Material(
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: screenWidth * 0.8,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.amber.shade400, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              pair.right_text,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        childWhenDragging: Container(
                          constraints: BoxConstraints(
                            maxWidth: screenWidth * 0.8,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            pair.right_text,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: screenWidth * 0.8,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.amber.shade400),
                          ),
                          child: Text(
                            pair.right_text,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber.shade900,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],

          if (userMatches.length == leftTexts.length && !isChecked)
            Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700, size: 24),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Tüm eşleştirmeler tamamlandı!',
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMatchContainer({
    required int index,
    required String leftText,
    required MatchingPair? matchedPair,
    required double screenWidth,
    bool isDraggingBack = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  leftText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: matchedPair != null
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : Colors.grey.shade100,
            border: Border.all(
              color: matchedPair != null
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade400,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (matchedPair != null && !widget.testQuestion.isChecked)
                Icon(
                  Icons.drag_handle,
                  color: Theme.of(context).primaryColor.withOpacity(0.7),
                  size: 18,
                ),
              if (matchedPair != null && !widget.testQuestion.isChecked)
                const SizedBox(width: 8),

              if (matchedPair != null && !isDraggingBack)
                Icon(
                  Icons.check_circle_outline,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
              if (matchedPair != null && !isDraggingBack)
                const SizedBox(width: 8),

              Expanded(
                child: Text(
                  matchedPair?.right_text ?? 'Seçenek sürükleyin...',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: matchedPair != null
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade600,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              if (matchedPair != null && !widget.testQuestion.isChecked)
                const SizedBox(width: 8),
              if (matchedPair != null && !widget.testQuestion.isChecked)
                Icon(
                  Icons.touch_app,
                  size: 16,
                  color: Theme.of(context).primaryColor.withOpacity(0.7),
                ),
            ],
          ),
        ),
      ],
    );
  }
}