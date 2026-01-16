import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:egitim_uygulamasi/features/test/data/models/test_question.dart';
import 'package:egitim_uygulamasi/models/question_blank_option.dart';

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

        questionWidgets.add(
          DragTarget<QuestionBlankOption>(
            builder: (context, candidateData, rejectedData) {
              return GestureDetector(
                onTap: droppedOption != null ? () => _removeFromBlank(blankIndex) : null,
                child: Container(
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
                  child: Center(
                    child: Text(
                      droppedOption?.optionText ?? '...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: droppedOption != null
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
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
                  child: Text(
                    'Seçenekleri boşluklara sürükleyin. Yerleştirilen seçeneğe tıklayarak kaldırabilirsiniz.',
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontSize: 14,
                    ),
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
                      feedback: Material(
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
                          child: Text(
                            option.optionText,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      childWhenDragging: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          option.optionText,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
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
                        child: Text(
                          option.optionText,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber.shade900,
                          ),
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
}