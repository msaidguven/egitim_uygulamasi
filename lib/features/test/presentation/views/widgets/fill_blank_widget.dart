import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:egitim_uygulamasi/features/test/data/models/test_question.dart';
import 'package:egitim_uygulamasi/models/question_blank_option.dart';
import 'package:egitim_uygulamasi/widgets/question_text.dart';

class FillBlankWidget extends StatefulWidget {
  final TestQuestion testQuestion;
  final ValueChanged<dynamic> onAnswered;

  const FillBlankWidget({required this.testQuestion, required this.onAnswered});

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
    _availableOptions = List.from(question.blankOptions);
  }

  void _onDrop(int blankIndex, QuestionBlankOption option) {
    if (widget.testQuestion.isChecked) return;
    setState(() {
      final previousEntry = _droppedAnswers.entries.firstWhereOrNull((entry) => entry.value?.id == option.id);
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
        style: const TextStyle(fontSize: 18),
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
          bgColor = Theme.of(context).primaryColor.withOpacity(0.1);
        }

        // Sürüklenen boşluk için şeffaf görünüm
        final isDraggingBack = _draggingBlankIndex == blankIndex;
        final opacity = isDraggingBack ? 0.5 : 1.0;

        questionWidgets.add(
          DragTarget<QuestionBlankOption>(
            builder: (context, candidateData, rejectedData) {
              return droppedOption != null
                  ? Draggable<QuestionBlankOption>(
                data: droppedOption,
                onDragStarted: () => _startDragBack(blankIndex),
                onDragEnd: _endDragBack,
                onDraggableCanceled: (velocity, offset) => _cancelDragBack(),
                feedback: Material(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade400, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      droppedOption.optionText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.3,
                  child: _buildBlankContainer(
                    context,
                    borderColor: Colors.grey.shade400,
                    bgColor: Colors.grey.shade200,
                    text: droppedOption.optionText,
                  ),
                ),
                child: GestureDetector(
                  onTap: () => _removeFromBlank(blankIndex),
                  child: Opacity(
                    opacity: opacity,
                    child: _buildBlankContainer(
                      context,
                      borderColor: borderColor,
                      bgColor: bgColor,
                      text: droppedOption.optionText,
                      showRemoveIcon: true,
                    ),
                  ),
                ),
              )
                  : DragTarget<QuestionBlankOption>(
                builder: (context, candidateData, rejectedData) {
                  return GestureDetector(
                    onTap: droppedOption != null ? () => _removeFromBlank(blankIndex) : null,
                    child: _buildBlankContainer(
                      context,
                      borderColor: borderColor,
                      bgColor: bgColor,
                      text: '...',
                    ),
                  );
                },
                onAccept: (option) => _onDrop(blankIndex, option),
              );
            },
            onAccept: (option) => _onDrop(blankIndex, option),
          ),
        );
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Wrap(
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: questionWidgets,
            ),
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seçenekleri boşluklara sürükleyin.',
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Yerleştirilen seçeneğe tıklayarak veya tutup sürükleyerek kaldırabilirsiniz.',
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          if (!isChecked && _availableOptions.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kullanılabilir Seçenekler:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10.0,
                  runSpacing: 10.0,
                  children: _availableOptions.map((option) {
                    return Draggable<QuestionBlankOption>(
                      data: option,

                      // ================= FEEDBACK (sürüklerken görünen)
                      feedback: Material(
                        color: Colors.transparent,
                        child: Align(
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.amber.shade400),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: QuestionText(
                              text: option.optionText,
                              fontSize: 16,
                              textColor: Colors.amber.shade900,
                              fractionColor: Colors.amber.shade900,
                              //enableFractions: question.unit.isMath,
                            ),
                          ),
                        ),
                      ),

                      // ================= SÜRÜKLENİRKEN YERİ BOŞ KALSIN
                      childWhenDragging: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: QuestionText(
                          text: option.optionText,
                          fontSize: 16,
                          textColor: Colors.grey.shade600,
                          fractionColor: Colors.grey.shade600,
                          //enableFractions: question.unit.isMath,
                        ),
                      ),

                      // ================= NORMAL HAL
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amber.shade400),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 3,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: QuestionText(
                          text: option.optionText,
                          fontSize: 16,
                          textColor: Colors.amber.shade900,
                          fractionColor: Colors.amber.shade900,
                          //enableFractions: question.unit.isMath,
                        ),
                      ),
                    );

                  }).toList(),
                ),
              ],
            ),

          if (!isChecked && _availableOptions.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Center(
                child: Text(
                  'Tüm seçenekler kullanıldı!',
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBlankContainer(
      BuildContext context, {
        required Color borderColor,
        required Color bgColor,
        required String text,
        bool showRemoveIcon = false,
      }) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(
          color: borderColor,
          width: 2.5,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showRemoveIcon && !widget.testQuestion.isChecked)
            Icon(
              Icons.drag_handle,
              size: 16,
              color: Theme.of(context).primaryColor.withOpacity(0.7),
            ),
          if (showRemoveIcon && !widget.testQuestion.isChecked)
            const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: text != '...'
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (showRemoveIcon && !widget.testQuestion.isChecked)
            const SizedBox(width: 6),
          if (showRemoveIcon && !widget.testQuestion.isChecked)
            Icon(
              Icons.touch_app,
              size: 14,
              color: Theme.of(context).primaryColor.withOpacity(0.7),
            ),
        ],
      ),
    );
  }
}