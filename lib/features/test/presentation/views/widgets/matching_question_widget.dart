import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:egitim_uygulamasi/features/test/data/models/test_question.dart';
import 'package:egitim_uygulamasi/models/question_model.dart';
import 'package:egitim_uygulamasi/widgets/question_text.dart';

class MatchingQuestionWidget extends StatefulWidget {
  final TestQuestion testQuestion;
  final ValueChanged<dynamic> onAnswered;

  const MatchingQuestionWidget({
    super.key,
    required this.testQuestion,
    required this.onAnswered,
  });

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
    leftTexts = question.matchingPairs?.map((p) => p.leftText).toList() ?? [];
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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 16.0),
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
                onAcceptWithDetails: (details) {
                  if (isChecked) return;
                  // DÜZELTME: details.data ile asıl veriye erişiyoruz
                  final data = details.data;
                  setState(() {
                    final existingEntry = userMatches.entries.firstWhereOrNull(
                      (entry) => entry.value?.id == data.id,
                    );
                    if (existingEntry != null) {
                      userMatches.remove(existingEntry.key);
                    }
                    userMatches[leftText] = data;
                    widget.onAnswered(
                      Map<String, MatchingPair?>.from(userMatches),
                    );
                  });
                },
                builder: (context, candidateData, rejectedData) {
                  return matchedPair != null
                      ? Draggable<MatchingPair>(
                          data: matchedPair,
                          onDragStarted: () => _startDragBack(leftText),
                          onDragEnd: _endDragBack,
                          onDraggableCanceled: (_, __) => _cancelDragBack(),
                          feedback: Material(
                            color: Colors.transparent,
                            child: _buildDraggingFeedback(
                              matchedPair.rightText,
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.3,
                            child: _buildMatchContainer(
                              index: index,
                              leftText: leftText,
                              matchedPair: matchedPair,
                              isDraggingBack: true,
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
                              ),
                            ),
                          ),
                        )
                      : _buildMatchContainer(
                          index: index,
                          leftText: leftText,
                          matchedPair: null,
                        );
                },
              ),
            );
          }),
          const SizedBox(height: 10),
          if (!isChecked) _buildOptionsPool(),
          if (userMatches.length == leftTexts.length && !isChecked)
            _buildCompletionStatus(),
        ],
      ),
    );
  }

  // ... (Geri kalan kod aynı)

  Widget _buildMatchContainer({
    required int index,
    required String leftText,
    required MatchingPair? matchedPair,
    bool isDraggingBack = false,
  }) {
    final isChecked = widget.testQuestion.isChecked;

    // Doğruluk Kontrolü
    bool isCorrectMatch = false;
    if (matchedPair != null) {
      final originalPair = widget.testQuestion.question.matchingPairs
          ?.firstWhereOrNull((p) => p.leftText == leftText);
      isCorrectMatch = originalPair?.rightText == matchedPair.rightText;
    }

    // Stil Belirleme
    Color rowBorderColor = Colors.grey.shade300;
    Color rightBoxBgColor = Colors.grey.shade100;
    Color rightBoxBorderColor = Colors.grey.shade300;
    Color textColor = Colors.grey.shade600;

    if (matchedPair != null) {
      if (isChecked) {
        // Kontrol edildikten sonra (Yeşil / Kırmızı)
        rightBoxBgColor = isCorrectMatch
            ? Colors.green.shade50
            : Colors.red.shade50;
        rightBoxBorderColor = isCorrectMatch ? Colors.green : Colors.red;
        textColor = isCorrectMatch
            ? Colors.green.shade900
            : Colors.red.shade900;
        rowBorderColor = rightBoxBorderColor.withOpacity(0.5);
      } else {
        // Yerleştirilmiş ama henüz kontrol edilmemiş (Mavi)
        rightBoxBgColor = Colors.blue.shade50;
        rightBoxBorderColor = Colors.blue;
        textColor = Colors.blue.shade900;
      }
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sol Bölüm
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: rowBorderColor),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(10),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 11,
                    backgroundColor: isChecked && matchedPair != null
                        ? rightBoxBorderColor
                        : Theme.of(context).primaryColor,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: QuestionText(text: leftText, fontSize: 14)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 1),
          // Sağ Bölüm (Eşleşme Alanı)
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: rightBoxBgColor,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(10),
                ),
                border: Border.all(
                  color: rightBoxBorderColor,
                  width: matchedPair != null ? 1.5 : 1.0,
                ),
              ),
              alignment: Alignment.center,
              child: (matchedPair != null && !isDraggingBack)
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isChecked
                              ? (isCorrectMatch
                                    ? Icons.check_circle
                                    : Icons.cancel)
                              : Icons.check_circle,
                          size: 14,
                          color: rightBoxBorderColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: QuestionText(
                            text: matchedPair.rightText,
                            fontSize: 13,
                            textColor: textColor,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      "Buraya bırakın",
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 11,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsPool() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seçenekleri eşleştirin:',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: shuffledRightPairs
                .where((p) => !userMatches.values.contains(p))
                .map(
                  (pair) => Draggable<MatchingPair>(
                    data: pair,
                    feedback: Material(
                      color: Colors.transparent,
                      child: _buildDraggingFeedback(pair.rightText),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.3,
                      child: _buildPoolItem(pair.rightText, isDragging: true),
                    ),
                    child: _buildPoolItem(pair.rightText),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPoolItem(String text, {bool isDragging = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDragging ? Colors.grey.shade200 : Colors.amber.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDragging ? Colors.grey.shade400 : Colors.amber.shade400,
        ),
      ),
      child: QuestionText(
        text: text,
        fontSize: 13,
        textColor: isDragging ? Colors.grey.shade700 : Colors.amber.shade900,
      ),
    );
  }

  Widget _buildDraggingFeedback(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  Widget _buildCompletionStatus() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 20),
          SizedBox(width: 8),
          Text(
            'Eşleştirme Tamamlandı',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
