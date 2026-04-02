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
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surfaceContainerLow,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Örnek Sorular',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Çalışma Notları ve Örnekler',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Ara',
            style: IconButton.styleFrom(
              backgroundColor: _showSearchBar
                  ? theme.colorScheme.primaryContainer
                  : Colors.transparent,
            ),
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
          const SizedBox(width: 8),
          _ScaleButton(
            label: 'A-',
            tooltip: 'Yazıyı küçült',
            onPressed: textScale <= 0.85 ? null : textScaleNotifier.decrease,
          ),
          const SizedBox(width: 8),
          _ScaleButton(
            label: 'A+',
            tooltip: 'Yazıyı büyüt',
            onPressed: textScale >= 5.0 ? null : textScaleNotifier.increase,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: session == null || session.attempts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_edu_rounded,
                    size: 64,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Listelenecek soru bulunamadı.',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _queryController,
              onChanged: (value) => setState(() => _query = value),
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Sorularda veya cevaplarda ara...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _queryController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                filled: true,
                fillColor: theme.colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('Aramaya uygun soru bulunamadı.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  physics: const BouncingScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 20),
                  itemBuilder: (context, listIndex) {
                    final entry = filtered[listIndex];
                    final itemIndex = entry.index;

                    return Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.8,
                          ),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'SORU ${itemIndex + 1}',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: theme.colorScheme.onPrimary,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      tooltip: 'Kopyala',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => _copyToClipboard(
                                        context,
                                        '${itemIndex + 1}) ${entry.question}\nCevap: ${entry.answer}',
                                      ),
                                      icon: const Icon(
                                        Icons.content_copy_rounded,
                                        size: 18,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  entry.question,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontSize: 18 * textScale,
                                    fontWeight: FontWeight.w700,
                                    height: 1.4,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer
                                  .withValues(alpha: 0.25),
                              border: Border(
                                top: BorderSide(
                                  color: theme.colorScheme.outlineVariant
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 20 * textScale,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    entry.answer,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontSize: 17 * textScale,
                                      fontWeight: FontWeight.w600,
                                      height: 1.5,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
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
    ).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text('Soru ve cevap panoya kopyalandı.'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
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
    final theme = Theme.of(context);
    final isEnabled = onPressed != null;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: isEnabled
            ? theme.colorScheme.surfaceContainerHigh
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(
                color: isEnabled
                    ? theme.colorScheme.outlineVariant
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: isEnabled
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),
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

