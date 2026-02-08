import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:egitim_uygulamasi/features/test/data/models/test_question.dart';
import 'package:egitim_uygulamasi/models/question_blank_option.dart';
import 'package:egitim_uygulamasi/widgets/question_text.dart';

class FillBlankWidget extends StatefulWidget {
  final TestQuestion testQuestion;
  final ValueChanged<dynamic> onAnswered;

  const FillBlankWidget({super.key, required this.testQuestion, required this.onAnswered});

  @override
  _FillBlankWidgetState createState() => _FillBlankWidgetState();
}

class _FillBlankWidgetState extends State<FillBlankWidget> {
  late Map<int, QuestionBlankOption?> _droppedAnswers;
  late List<QuestionBlankOption> _availableOptions;
  int? _draggingBlankIndex;
  QuestionBlankOption? _draggingBackOption;

  @override
  void initState() {
    super.initState();
    final question = widget.testQuestion.question;
    final int blankCount = '______'.allMatches(question.text).length;
    _droppedAnswers = {for (var i = 0; i < blankCount; i++) i: null};
    _availableOptions = List.from(widget.testQuestion.shuffledBlankOptions);
  }

  void _onDrop(int blankIndex, QuestionBlankOption option) {
    if (widget.testQuestion.isChecked) return;
    setState(() {
      final previousEntry = _droppedAnswers.entries
          .firstWhereOrNull((entry) => entry.value?.id == option.id);
      if (previousEntry != null) _droppedAnswers[previousEntry.key] = null;

      final existingOption = _droppedAnswers[blankIndex];
      if (existingOption != null) _availableOptions.add(existingOption);

      _droppedAnswers[blankIndex] = option;
      _availableOptions.removeWhere((opt) => opt.id == option.id);
      widget.onAnswered(Map<int, QuestionBlankOption?>.from(_droppedAnswers));
    });
  }

  void _removeFromBlank(int blankIndex) {
    if (widget.testQuestion.isChecked) return;
    setState(() {
      final removedOption = _droppedAnswers[blankIndex];
      if (removedOption != null) {
        _availableOptions.add(removedOption);
        _droppedAnswers[blankIndex] = null;
        widget.onAnswered(Map<int, QuestionBlankOption?>.from(_droppedAnswers));
      }
    });
  }

  void _startDragBack(int blankIndex) {
    if (widget.testQuestion.isChecked) return;
    setState(() {
      _draggingBlankIndex = blankIndex;
      _draggingBackOption = _droppedAnswers[blankIndex];
    });
  }

  void _endDragBack(DraggableDetails details) {
    if (_draggingBackOption != null && _draggingBlankIndex != null) {
      _removeFromBlank(_draggingBlankIndex!);
    }
    setState(() {
      _draggingBlankIndex = null;
      _draggingBackOption = null;
    });
  }

  void _cancelDragBack() {
    setState(() {
      _draggingBlankIndex = null;
      _draggingBackOption = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.testQuestion.question;
    final isChecked = widget.testQuestion.isChecked;
    final isCorrect = widget.testQuestion.isCorrect;

    final questionParts = question.text.split('______');
    List<Widget> questionWidgets = [];

    for (int i = 0; i < questionParts.length; i++) {
      questionWidgets.add(Text(
        questionParts[i],
        style: const TextStyle(fontSize: 18, height: 1.6),
      ));

      if (i < questionParts.length - 1) {
        final blankIndex = i;
        final droppedOption = _droppedAnswers[blankIndex];
        Color borderColor = Colors.grey.shade400;
        Color bgColor = Colors.white;

        if (isChecked) {
          borderColor = isCorrect ? Colors.green.shade600 : Colors.red.shade600;
          bgColor = isCorrect ? Colors.green.shade50 : Colors.red.shade50;
        } else if (droppedOption != null) {
          borderColor = Theme.of(context).primaryColor;
          bgColor = Theme.of(context).primaryColor.withOpacity(0.05);
        }

        final isDraggingBack = _draggingBlankIndex == blankIndex;

        questionWidgets.add(
          DragTarget<QuestionBlankOption>(
            builder: (context, candidateData, rejectedData) {
              return droppedOption != null
                  ? Draggable<QuestionBlankOption>(
                data: droppedOption,
                onDragStarted: () => _startDragBack(blankIndex),
                onDragEnd: _endDragBack,
                onDraggableCanceled: (_, __) => _cancelDragBack(),
                feedback: Material(
                  color: Colors.transparent,
                  child: _buildDraggingFeedback(droppedOption.optionText),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.3,
                  child: _buildBlankContainer(
                    context,
                    borderColor: Colors.grey.shade300,
                    bgColor: Colors.grey.shade100,
                    text: droppedOption.optionText,
                  ),
                ),
                child: GestureDetector(
                  onTap: () => _removeFromBlank(blankIndex),
                  child: Opacity(
                    opacity: isDraggingBack ? 0.5 : 1.0,
                    child: _buildBlankContainer(
                      context,
                      borderColor: borderColor,
                      bgColor: bgColor,
                      text: droppedOption.optionText,
                      isMatched: true,
                    ),
                  ),
                ),
              )
                  : DragTarget<QuestionBlankOption>(
                builder: (context, candidateData, rejectedData) {
                  return _buildBlankContainer(
                    context,
                    borderColor: borderColor,
                    bgColor: bgColor,
                    text: '...',
                  );
                },
                onAcceptWithDetails: (details) => _onDrop(blankIndex, details.data),
              );
            },
            onAcceptWithDetails: (details) => _onDrop(blankIndex, details.data),
          ),
        );
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 2,
              runSpacing: 12,
              children: questionWidgets,
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoPanel(),
          const SizedBox(height: 20),
          if (!isChecked) _buildOptionsPool(),
          if (isChecked) _buildCheckStatus(isCorrect),
        ],
      ),
    );
  }

  Widget _buildBlankContainer(
      BuildContext context, {
        required Color borderColor,
        required Color bgColor,
        required String text,
        bool isMatched = false,
      }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 75), // Başlangıç genişliği artırıldı
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isMatched && !widget.testQuestion.isChecked) ...[
            Icon(Icons.unfold_more, size: 14, color: Theme.of(context).primaryColor.withOpacity(0.5)),
            const SizedBox(width: 4),
          ],
          // Metin render işlemi
          text == '...'
              ? Text('...', style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold, fontSize: 18))
              : QuestionText(
            text: text,
            fontSize: 16,
            textColor: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsPool() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: _availableOptions.map((option) {
          return Draggable<QuestionBlankOption>(
            data: option,
            feedback: Material(
              color: Colors.transparent,
              child: _buildDraggingFeedback(option.optionText),
            ),
            childWhenDragging: Opacity(
                opacity: 0.3,
                child: _buildPoolItem(option.optionText, isDragging: true)
            ),
            child: _buildPoolItem(option.optionText),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPoolItem(String text, {bool isDragging = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDragging ? Colors.grey.shade200 : Colors.amber.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDragging ? Colors.grey.shade400 : Colors.amber.shade400),
      ),
      child: QuestionText(
        text: text,
        fontSize: 15,
        textColor: isDragging ? Colors.grey.shade700 : Colors.amber.shade900,
      ),
    );
  }

  Widget _buildDraggingFeedback(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
      ),
      child: QuestionText(
        text: text,
        fontSize: 16,
        textColor: Colors.white,
      ),
    );
  }

  Widget _buildInfoPanel() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Doğru seçenekleri boşluklara taşıyın.',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckStatus(bool isCorrect) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isCorrect ? Colors.green.shade200 : Colors.red.shade200),
      ),
      child: Center(
        child: Text(
          isCorrect ? 'Tebrikler, doğru!' : 'Cevap yanlış, tekrar deneyin.',
          style: TextStyle(color: isCorrect ? Colors.green.shade800 : Colors.red.shade800, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
