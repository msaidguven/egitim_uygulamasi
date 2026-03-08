import 'package:flutter/material.dart';
import 'package:egitim_uygulamasi/models/lesson_step_model.dart';

class QuizWidget extends StatefulWidget {
  final LessonStepModel step;
  final VoidCallback onCompleted;
  final bool isCompleted;

  const QuizWidget({
    super.key,
    required this.step,
    required this.onCompleted,
    required this.isCompleted,
  });

  @override
  State<QuizWidget> createState() => _QuizWidgetState();
}

class _QuizWidgetState extends State<QuizWidget> {
  int _index = 0;
  int? _selected;
  bool _checked = false;
  int _correctCount = 0;
  bool _finished = false;

  @override
  Widget build(BuildContext context) {
    final questions = (widget.step.content['questions'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();

    if (questions.isEmpty) return const SizedBox.shrink();

    if (_finished && !widget.isCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onCompleted());
    }

    if (_finished) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('Score: $_correctCount/${questions.length}'),
                const SizedBox(height: 10),
                FilledButton(onPressed: widget.onCompleted, child: const Text('Continue')),
              ]),
            ),
          ),
        ),
      );
    }

    final q = questions[_index];
    final options = (q['options'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => e.toString())
        .toList();
    final answer = (q['answer'] as num?)?.toInt() ?? -1;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.step.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: (_index + 1) / questions.length),
        const SizedBox(height: 12),
        Text((q['question'] ?? '').toString()),
        const SizedBox(height: 12),
        ...List.generate(options.length, (i) {
          Color side = Colors.grey.shade300;
          if (_checked && i == answer) side = Colors.green;
          if (_checked && i == _selected && i != answer) side = Colors.red;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              onPressed: _checked ? null : () => setState(() => _selected = i),
              style: OutlinedButton.styleFrom(side: BorderSide(color: side, width: 1.4)),
              child: Align(alignment: Alignment.centerLeft, child: Text(options[i])),
            ),
          );
        }),
        const SizedBox(height: 8),
        if (!_checked)
          FilledButton(
            onPressed: _selected == null
                ? null
                : () {
                    setState(() {
                      _checked = true;
                      if (_selected == answer) _correctCount++;
                    });
                  },
            child: const Text('Check'),
          ),
        if (_checked) ...[
          if ((q['explanation'] ?? '').toString().isNotEmpty)
            Card(child: Padding(padding: const EdgeInsets.all(10), child: Text((q['explanation'] ?? '').toString()))),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () {
              if (_index < questions.length - 1) {
                setState(() {
                  _index++;
                  _selected = null;
                  _checked = false;
                });
              } else {
                setState(() => _finished = true);
              }
            },
            child: Text(_index < questions.length - 1 ? 'Next Question' : 'Finish Quiz'),
          ),
        ],
      ]),
    );
  }
}
