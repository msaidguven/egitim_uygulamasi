import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'written_practice_models.dart';
import 'written_practice_providers.dart';

class WrittenExamplesScreen extends ConsumerStatefulWidget {
  const WrittenExamplesScreen({super.key});

  @override
  ConsumerState<WrittenExamplesScreen> createState() =>
      _WrittenExamplesScreenState();
}

class _WrittenExamplesScreenState extends ConsumerState<WrittenExamplesScreen> {
  final _queryController = TextEditingController();
  String _query = '';
  bool _showSearchBar = false;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(writtenSessionProvider);
    final textScale = ref.watch(writtenPracticeTextScaleProvider);
    final textScaleNotifier = ref.read(
      writtenPracticeTextScaleProvider.notifier,
    );
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Örnek Sorular',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Ara',
            onPressed: () {
              setState(() {
                _showSearchBar = !_showSearchBar;
                if (!_showSearchBar) {
                  _queryController.clear();
                  _query = '';
                }
              });
            },
            icon: Icon(
              _showSearchBar ? Icons.search_off_rounded : Icons.search_rounded,
            ),
          ),
          _ScaleButton(
            label: 'A-',
            tooltip: 'Yazıyı küçült',
            onPressed: textScale <= 0.85 ? null : textScaleNotifier.decrease,
          ),
          const SizedBox(width: 6),
          _ScaleButton(
            label: 'A+',
            tooltip: 'Yazıyı büyüt',
            onPressed: textScale >= 5.0 ? null : textScaleNotifier.increase,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: session == null || session.attempts.isEmpty
          ? const Center(child: Text('Listelenecek soru bulunamadı.'))
          : _buildContent(theme, textScale, session.attempts),
    );
  }

  Widget _buildContent(
    ThemeData theme,
    double textScale,
    List<QuestionAttempt> attempts,
  ) {
    final entries = <_ExampleEntry>[
      for (int index = 0; index < attempts.length; index++)
        _ExampleEntry.fromAttempt(index: index, attempt: attempts[index]),
    ];

    final filtered = entries.where((entry) {
      if (_query.trim().isEmpty) return true;
      final needle = _query.trim().toLowerCase();
      return entry.question.toLowerCase().contains(needle) ||
          entry.answer.toLowerCase().contains(needle);
    }).toList();

    return Column(
      children: [
        if (_showSearchBar)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: TextField(
              controller: _queryController,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Ara...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _queryController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close_rounded, size: 20),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                isDense: true,
              ),
            ),
          ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('Aramaya uygun soru bulunamadı.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, listIndex) {
                    final entry = filtered[listIndex];
                    final itemIndex = entry.index;

                    return Container(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: theme.colorScheme.primary,
                                child: Text(
                                  '${itemIndex + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  entry.question,
                                  style: TextStyle(
                                    fontSize: 17 * textScale,
                                    fontWeight: FontWeight.w700,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Spacer(),
                              IconButton(
                                tooltip: 'Soru + cevap kopyala',
                                onPressed: () => _copyToClipboard(
                                  context,
                                  '${itemIndex + 1}) ${entry.question}\nCevap: ${entry.answer}',
                                ),
                                icon: const Icon(Icons.copy_rounded),
                              ),
                            ],
                          ),
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: theme.colorScheme.secondaryContainer
                                  .withValues(alpha: 0.55),
                            ),
                            child: Text(
                              'Cevap: ${entry.answer}',
                              style: TextStyle(
                                fontSize: 16 * textScale,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _copyToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Soru panoya kopyalandı.')));
  }
}

class _ScaleButton extends StatelessWidget {
  final String label;
  final String tooltip;
  final VoidCallback? onPressed;

  const _ScaleButton({
    required this.label,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: TextButton(
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class _ExampleEntry {
  final int index;
  final String question;
  final String answer;

  const _ExampleEntry({
    required this.index,
    required this.question,
    required this.answer,
  });

  factory _ExampleEntry.fromAttempt({
    required int index,
    required QuestionAttempt attempt,
  }) {
    final question = attempt.question;
    final classical = question.classical;
    final modelAnswer = classical?.modelAnswer.trim() ?? '';
    final answer = modelAnswer.isEmpty
        ? (classical?.answerWords ?? const []).join(' ')
        : modelAnswer;

    return _ExampleEntry(
      index: index,
      question: question.questionText.toString(),
      answer: answer.toString(),
    );
  }
}
