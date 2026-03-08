import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'common/lesson_step_card.dart';

class WordSelector extends StatefulWidget {
  final Map<String, dynamic> step;
  final bool isActive;
  final VoidCallback onComplete;

  const WordSelector({
    super.key,
    required this.step,
    required this.isActive,
    required this.onComplete,
  });

  @override
  State<WordSelector> createState() => _WordSelectorState();
}

class _WordSelectorState extends State<WordSelector> {
  String? selectedWord;

  @override
  Widget build(BuildContext context) {
    final question = widget.step['question']?.toString() ?? '';
    final displayQuestion = question.replaceFirst(
      '[ ]',
      selectedWord ?? '_______',
    );
    final options =
        (widget.step['options'] as List?)?.map((e) => e.toString()).toList() ??
        const <String>[];
    final correct = widget.step['correct']?.toString();

    return LessonStepCard(
      badge: widget.step['badge']?.toString() ?? 'Kelime Secimi',
      title: widget.step['title']?.toString(),
      helperText: widget.step['helper']?.toString(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              displayQuestion,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
          if (widget.isActive) ...[
            const SizedBox(height: 20),
            const Text(
              'Kelimeyi Sec:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: options.map((word) {
                final isCorrect = word == correct;
                return ChoiceChip(
                  label: Text(word),
                  selected: selectedWord == word,
                  onSelected: (selected) {
                    if (!selected) return;
                    setState(() {
                      selectedWord = word;
                    });
                    if (isCorrect) {
                      Future.delayed(
                        const Duration(milliseconds: 600),
                        widget.onComplete,
                      );
                    }
                  },
                  selectedColor: isCorrect ? Colors.green : Colors.red,
                  labelStyle: TextStyle(
                    color: selectedWord == word ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
            ),
            if (widget.step['hint'] != null &&
                selectedWord != null &&
                selectedWord != correct)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Ipucu: ${widget.step['hint']}',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}
