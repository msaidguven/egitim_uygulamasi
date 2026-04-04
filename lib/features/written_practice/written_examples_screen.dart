import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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
  bool _isDownloadingPdf = false;

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
          const SizedBox(width: 12),
          _ScaleButton(
            label: 'A+',
            tooltip: 'Yazıyı büyüt',
            onPressed: textScale >= 5.0 ? null : textScaleNotifier.increase,
          ),
          const SizedBox(width: 20),
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: _isDownloadingPdf
                  ? null
                  : () => _downloadQuestionsAsPdf(context, entries),
              icon: _isDownloadingPdf
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_rounded),
              label: Text(
                _isDownloadingPdf
                    ? 'PDF hazırlanıyor...'
                    : 'Soruları PDF olarak indir',
              ),
            ),
          ),
        ),
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
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.6,
                    ),
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
              ),
            ),
          ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('Aramaya uygun soru bulunamadı.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
                  physics: const BouncingScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 24),
                  itemBuilder: (context, listIndex) {
                    final entry = filtered[listIndex];
                    final itemIndex = entry.index;

                    return Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.shadow.withValues(
                              alpha: 0.05,
                            ),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.4,
                          ),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            theme.colorScheme.primary,
                                            theme.colorScheme.primary
                                                .withValues(alpha: 0.85),
                                          ],
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: theme.colorScheme.primary
                                                .withValues(alpha: 0.25),
                                            blurRadius: 10,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        'SORU ${itemIndex + 1}',
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                          color: theme.colorScheme.onPrimary,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.0,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Material(
                                      color: theme
                                          .colorScheme
                                          .surfaceContainerHighest
                                          .withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(12),
                                      child: IconButton(
                                        tooltip: 'Panoya Kopyala',
                                        onPressed: () => _copyToClipboard(
                                          context,
                                          '${itemIndex + 1}) ${entry.question}\nCevap: ${entry.answer}',
                                        ),
                                        icon: Icon(
                                          Icons.content_copy_rounded,
                                          size: 20,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  '${itemIndex + 1}) ${entry.question}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontSize: 20 * textScale,
                                    fontWeight: FontWeight.w800,
                                    height: 1.5,
                                    color: theme.colorScheme.onSurface,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.1,
                                ),
                              ),
                            ),
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  VerticalDivider(
                                    color: theme.colorScheme.primary,
                                    thickness: 4,
                                    width: 4,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'DOĞRU CEVAP',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          entry.answer,
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                            fontSize: 18 * textScale,
                                            fontWeight: FontWeight.w700,
                                            height: 1.6,
                                            color: theme
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.lightbulb_rounded,
                                    size: 24 * textScale,
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                ],
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
    ScaffoldMessenger.of(context).showSnackBar(
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

  Future<void> _downloadQuestionsAsPdf(
    BuildContext context,
    List<_ExampleEntry> entries,
  ) async {
    if (entries.isEmpty || _isDownloadingPdf) return;

    setState(() => _isDownloadingPdf = true);

    try {
      final doc = pw.Document();
      final baseFont = await PdfGoogleFonts.notoSansRegular();
      final boldFont = await PdfGoogleFonts.notoSansBold();
      final symbolFont = await PdfGoogleFonts.notoSansSymbols2Regular();

      doc.addPage(
        pw.MultiPage(
          theme: pw.ThemeData.withFont(
            base: baseFont,
            bold: boldFont,
            fontFallback: [symbolFont, baseFont],
          ),
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (pdfContext) => [
            pw.Text(
              'Yazili Calisma - Ornek Sorular',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Toplam soru: ${entries.length}',
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 18),
            for (final entry in entries)
              pw.Container(
                width: double.infinity,
                margin: const pw.EdgeInsets.only(bottom: 12),
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Soru ${entry.index + 1}',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      '${entry.index + 1}) ${entry.question}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Cevap',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green800,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(entry.answer, style: const pw.TextStyle(fontSize: 12)),
                  ],
                ),
              ),
          ],
        ),
      );

      final now = DateTime.now();
      final filename =
          'ornek_sorular_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.pdf';

      await Printing.sharePdf(bytes: await doc.save(), filename: filename);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sorular PDF olarak hazırlandı.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF oluşturulamadı: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isDownloadingPdf = false);
      }
    }
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
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(
                color: isEnabled
                    ? theme.colorScheme.outlineVariant
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              label,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 20,
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
