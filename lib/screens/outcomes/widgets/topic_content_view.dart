import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_table/flutter_html_table.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:egitim_uygulamasi/models/topic_content.dart';
import 'package:egitim_uygulamasi/utils/html_style.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:egitim_uygulamasi/widgets/question_text.dart';
import 'package:egitim_uygulamasi/utils/html_fraction_utils.dart';

enum _AdminMenuAction { update, publish, downloadPdf, copy, delete }

class TopicContentView extends StatelessWidget {
  final TopicContent content;
  final bool isAdmin;
  final bool canDownloadPdf;
  final String? gradeName;
  final String? lessonName;
  final String? unitTitle;
  final String? topicTitle;
  final VoidCallback? onContentUpdated;

  const TopicContentView({
    Key? key,
    required this.content,
    required this.isAdmin,
    this.canDownloadPdf = false,
    this.gradeName,
    this.lessonName,
    this.unitTitle,
    this.topicTitle,
    this.onContentUpdated,
  }) : super(key: key);

  Future<void> _updateContent({
    required BuildContext context,
    required String title,
    required String htmlContent,
    bool? isPublished,
  }) async {
    if (content.id == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('İçerik ID bulunamadı.')));
      return;
    }

    final updateData = <String, dynamic>{
      'title': title,
      'content': htmlContent,
    };
    if (isPublished != null) {
      updateData['is_published'] = isPublished;
    }

    try {
      await Supabase.instance.client
          .from('topic_contents')
          .update(updateData)
          .eq('id', content.id!);
      if (!context.mounted) return;
      onContentUpdated?.call();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('İçerik güncellendi.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Güncelleme hatası: $e')));
    }
  }

  Future<void> _showEditDialog(BuildContext context) async {
    final titleController = TextEditingController(text: content.title);
    final htmlController = TextEditingController(text: content.content);
    bool isSaving = false;
    bool? isPublished = content.isPublished;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('İçeriği Düzenle'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Başlık'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: htmlController,
                      decoration: const InputDecoration(
                        labelText: 'İçerik (HTML)',
                      ),
                      minLines: 6,
                      maxLines: 12,
                    ),
                    const SizedBox(height: 12),
                    if (isPublished != null)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Yayınlandı'),
                        value: isPublished!,
                        onChanged: (value) {
                          setState(() => isPublished = value);
                        },
                      )
                    else
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'is_published değeri gelmedi.',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          setState(() => isSaving = true);
                          await _updateContent(
                            context: context,
                            title: titleController.text.trim(),
                            htmlContent: htmlController.text,
                            isPublished: isPublished,
                          );
                          if (context.mounted) Navigator.of(context).pop();
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _togglePublish(BuildContext context) async {
    if (content.isPublished == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('is_published değeri gelmedi.')),
      );
      return;
    }
    await _updateContent(
      context: context,
      title: content.title,
      htmlContent: content.content,
      isPublished: !content.isPublished!,
    );
  }

  String _stripHtml(String value) {
    return value
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<void> _copyContent(BuildContext context) async {
    final plainText = _stripHtml(content.content);
    await Clipboard.setData(
      ClipboardData(text: '${content.title}\n\n$plainText'),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('İçerik panoya kopyalandı.')));
  }

  Future<void> _downloadContentAsPdf(BuildContext context) async {
    try {
      final pdfFilename = _buildPdfFilename(content.title);
      final printingInfo = await Printing.info();
      debugPrint(
        '[OutcomesPDF] start title="${content.title}" filename="$pdfFilename" '
        'canConvertHtml=${printingInfo.canConvertHtml} canShare=${printingInfo.canShare}',
      );

      if (printingInfo.canConvertHtml) {
        final logoDataUri = await _loadLogoDataUri();
        final convertedContentHtml = _prepareHtmlForPdf(content.content);
        final html = _buildPdfHtmlDocument(
          title: content.title,
          contentHtml: convertedContentHtml,
          logoDataUri: logoDataUri,
          gradeName: gradeName,
          lessonName: lessonName,
          unitTitle: unitTitle,
          topicTitle: topicTitle,
        );

        // ignore: deprecated_member_use
        final bytes = await Printing.convertHtml(
          html: html,
          baseUrl: 'https://derstakip.net/',
          format: PdfPageFormat.a4,
        );
        debugPrint(
          '[OutcomesPDF] convertHtml success bytes=${bytes.length} htmlLength=${html.length}',
        );

        await Printing.sharePdf(bytes: bytes, filename: pdfFilename);
        debugPrint('[OutcomesPDF] sharePdf success filename="$pdfFilename"');
        return;
      }

      final bodyWidgets = _buildFallbackPdfBodyWidgets(content.content);
      final doc = pw.Document();
      final font = await PdfGoogleFonts.notoSansRegular();
      final boldFont = await PdfGoogleFonts.notoSansBold();
      final symbolFont = await PdfGoogleFonts.notoSansSymbols2Regular();

      doc.addPage(
        pw.MultiPage(
          theme: pw.ThemeData.withFont(
            base: font,
            bold: boldFont,
            fontFallback: [symbolFont, font],
          ),
          header: (pdfContext) => pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.blue100),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Ders Takip',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.UrlLink(
                  destination: 'https://derstakip.net/',
                  child: pw.Text(
                    'derstakip.net',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.blue700),
                  ),
                ),
              ],
            ),
          ),
          footer: (pdfContext) => pw.Container(
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.blue100)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Sayfa ${pdfContext.pageNumber}/${pdfContext.pagesCount}',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
                pw.UrlLink(
                  destination: 'https://derstakip.net/',
                  child: pw.Text(
                    'Daha fazlasi: derstakip.net',
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.blue700),
                  ),
                ),
              ],
            ),
          ),
          build: (pdfContext) => [
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(10),
                border: pw.Border.all(color: PdfColors.blue100),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    content.title,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'Konu icerigi - Ders Takip',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.blue700,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            _buildPdfInfoCard(
              gradeName: gradeName,
              lessonName: lessonName,
              unitTitle: unitTitle,
              topicTitle: topicTitle,
            ),
            pw.SizedBox(height: 12),
            ...bodyWidgets,
          ],
        ),
      );

      await Printing.sharePdf(bytes: await doc.save(), filename: pdfFilename);
      debugPrint(
        '[OutcomesPDF] fallback sharePdf success filename="$pdfFilename"',
      );
    } catch (e, st) {
      _logPdfError('downloadContentAsPdf', e, st);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF oluşturulamadı: $e')));
    }
  }

  String _buildPdfFilename(String title) {
    final sanitized = title
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    final safe = sanitized.isEmpty ? 'icerik' : sanitized;
    return '$safe.pdf';
  }

  String _stripHtmlForPdfFallback(String value) {
    final withBreaks = value
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(
          RegExp(
            r'</(p|div|li|h1|h2|h3|h4|h5|h6|tr|table|ul|ol|section|article)>',
            caseSensitive: false,
          ),
          '\n',
        );

    final stripped = withBreaks.replaceAll(RegExp(r'<[^>]*>'), ' ');
    final decoded = html_parser.parseFragment(stripped).text ?? '';

    return decoded
        .replaceAll(RegExp(r'[ \t]+\n'), '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
        .trim();
  }

  List<pw.Widget> _buildFallbackPdfBodyWidgets(String rawHtml) {
    final wrapped = wrapFractionsForHtml(rawHtml);
    final fragment = html_parser.parseFragment(wrapped);
    final sections = fragment.querySelectorAll('section');
    final widgets = <pw.Widget>[];

    if (sections.isEmpty) {
      final plain = _stripHtmlForPdfFallback(rawHtml);
      widgets.addAll(
        _splitPdfTextIntoChunks(plain).map(
          (chunk) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Text(
              chunk,
              style: const pw.TextStyle(fontSize: 12, lineSpacing: 2),
            ),
          ),
        ),
      );
      return widgets;
    }

    for (var index = 0; index < sections.length; index++) {
      final section = sections[index];
      final h2 = section.children.where((e) => e.localName == 'h2');
      final sectionTitle = h2.isNotEmpty ? h2.first.text.trim() : 'Bilgi';

      final bodyHtml = section.innerHtml.replaceAll(
        RegExp(r'<h2[^>]*>.*?</h2>', caseSensitive: false, dotAll: true),
        '',
      );
      final sectionText = _stripHtmlForPdfFallback(bodyHtml);
      final chunks = _splitPdfTextIntoChunks(sectionText, maxChars: 700);

      widgets.add(
        pw.Container(
          width: double.infinity,
          margin: pw.EdgeInsets.only(top: index == 0 ? 0 : 10, bottom: 6),
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: PdfColors.grey300),
          ),
          child: pw.Text(
            sectionTitle,
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
        ),
      );

      if (chunks.isEmpty) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Text(
              '-',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
            ),
          ),
        );
        continue;
      }

      widgets.addAll(
        chunks.map(
          (chunk) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Text(
              chunk,
              style: const pw.TextStyle(fontSize: 12, lineSpacing: 2),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  List<String> _splitPdfTextIntoChunks(String text, {int maxChars = 500}) {
    if (text.trim().isEmpty) return const <String>[];

    final chunks = <String>[];
    var remaining = text.trim();

    while (remaining.length > maxChars) {
      var split = remaining.lastIndexOf('\n\n', maxChars);
      if (split < maxChars ~/ 3) {
        split = remaining.lastIndexOf('\n', maxChars);
      }
      if (split < maxChars ~/ 3) {
        split = remaining.lastIndexOf(' ', maxChars);
      }
      if (split <= 0) split = maxChars;

      final chunk = remaining.substring(0, split).trim();
      if (chunk.isNotEmpty) chunks.add(chunk);
      remaining = remaining.substring(split).trimLeft();
    }

    if (remaining.isNotEmpty) chunks.add(remaining);
    return chunks;
  }

  Future<String> _loadLogoDataUri() async {
    try {
      final bytes = await rootBundle.load('assets/images/app_logo.png');
      final base64 = base64Encode(bytes.buffer.asUint8List());
      return 'data:image/png;base64,$base64';
    } catch (e, st) {
      _logPdfError('loadLogoDataUri', e, st);
      return 'https://derstakip.net/app_logo.png';
    }
  }

  String _prepareHtmlForPdf(String rawHtml) {
    final wrapped = wrapFractionsForHtml(rawHtml);
    final fragment = html_parser.parseFragment(wrapped);
    final fractionNodes = fragment.querySelectorAll('fraction');

    for (final node in fractionNodes) {
      final text = node.text.trim();
      final parts = text.split('/');
      if (parts.length == 2) {
        final numerator = _escapeHtml(parts[0].trim());
        final denominator = _escapeHtml(parts[1].trim());
        final replacement = html_parser.parseFragment(
          '<span class="fraction"><sup>$numerator</sup>&frasl;<sub>$denominator</sub></span>',
        );
        final parent = node.parent;
        if (parent != null) {
          final index = parent.nodes.indexOf(node);
          parent.nodes.removeAt(index);
          parent.nodes.insertAll(index, replacement.nodes);
        }
      } else {
        final parent = node.parent;
        if (parent != null) {
          final index = parent.nodes.indexOf(node);
          parent.nodes.removeAt(index);
          parent.nodes.insert(index, dom.Text(text));
        }
      }
    }

    return fragment.outerHtml;
  }

  String _buildPdfHtmlDocument({
    required String title,
    required String contentHtml,
    required String logoDataUri,
    String? gradeName,
    String? lessonName,
    String? unitTitle,
    String? topicTitle,
  }) {
    final escapedTitle = _escapeHtml(title);
    final escapedGrade = _escapeHtml((gradeName ?? '').trim());
    final escapedLesson = _escapeHtml((lessonName ?? '').trim());
    final escapedUnit = _escapeHtml((unitTitle ?? '').trim());
    final escapedTopic = _escapeHtml((topicTitle ?? '').trim());

    return '''
<!DOCTYPE html>
<html lang="tr">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>$escapedTitle</title>
  <style>
    @page { size: A4; margin: 20mm 14mm; }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      color: #0f172a;
      font-family: "Segoe UI", Arial, sans-serif;
      background: #f8fafc;
      line-height: 1.6;
      font-size: 14px;
    }
    .brand {
      border: 1px solid #dbeafe;
      background: linear-gradient(135deg, #eff6ff 0%, #f8fbff 100%);
      border-radius: 14px;
      padding: 10px 12px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
    }
    .brand-left {
      display: flex;
      align-items: center;
      gap: 10px;
      min-width: 0;
    }
    .brand-logo {
      width: 34px;
      height: 34px;
      border-radius: 8px;
      object-fit: cover;
      border: 1px solid #cfe2ff;
      background: #fff;
    }
    .brand-title {
      font-size: 13px;
      font-weight: 700;
      color: #1d4ed8;
      margin: 0;
    }
    .brand-sub {
      font-size: 11px;
      color: #475569;
      margin: 0;
    }
    .brand-link {
      font-size: 11px;
      color: #1d4ed8;
      text-decoration: none;
      border: 1px solid #bfdbfe;
      background: #fff;
      border-radius: 999px;
      padding: 6px 10px;
      white-space: nowrap;
    }
    .paper {
      margin-top: 12px;
      margin-bottom: 12px;
      padding: 18px;
      border: 1px solid #e2e8f0;
      border-radius: 16px;
      background: #ffffff;
    }
    .meta-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 8px;
      margin-bottom: 12px;
    }
    .meta-item {
      border: 1px solid #dbe4f2;
      border-radius: 10px;
      background: #f8fbff;
      padding: 8px 10px;
    }
    .meta-label {
      font-size: 10px;
      text-transform: uppercase;
      letter-spacing: 0.3px;
      color: #64748b;
      margin: 0 0 3px 0;
      font-weight: 700;
    }
    .meta-value {
      font-size: 12px;
      color: #0f172a;
      margin: 0;
      font-weight: 700;
    }
    h1 {
      margin: 0 0 12px 0;
      font-size: 26px;
      line-height: 1.2;
      color: #0b3a78;
      letter-spacing: -0.4px;
    }
    h2, h3 {
      color: #0b3a78;
      margin-top: 18px;
      margin-bottom: 8px;
      line-height: 1.3;
    }
    p { margin: 0 0 10px 0; }
    ul, ol { margin: 0 0 12px 0; padding-left: 22px; }
    li { margin: 0 0 6px 0; }
    table {
      width: 100%;
      border-collapse: collapse;
      margin: 8px 0 14px 0;
      font-size: 12.5px;
    }
    th, td {
      border: 1px solid #d4dbe5;
      padding: 7px 8px;
      text-align: left;
      vertical-align: top;
    }
    th {
      background: #f1f5f9;
      color: #0f172a;
      font-weight: 700;
    }
    .fraction sup,
    .fraction sub {
      font-size: 0.85em;
      line-height: 0;
    }
    .fraction sup { vertical-align: 0.6em; }
    .fraction sub { vertical-align: -0.2em; }
  </style>
</head>
<body>
  <div class="brand">
    <div class="brand-left">
      <img class="brand-logo" src="$logoDataUri" alt="Ders Takip Logo" />
      <div>
        <p class="brand-title">Ders Takip</p>
        <p class="brand-sub">Konu Çıktısı ve İçerik Dökümü</p>
      </div>
    </div>
    <a class="brand-link" href="https://derstakip.net/">derstakip.net</a>
  </div>

  <main class="paper">
    <h1>$escapedTitle</h1>
    <div class="meta-grid">
      <div class="meta-item">
        <p class="meta-label">Sinif</p>
        <p class="meta-value">${escapedGrade.isEmpty ? '-' : escapedGrade}</p>
      </div>
      <div class="meta-item">
        <p class="meta-label">Ders</p>
        <p class="meta-value">${escapedLesson.isEmpty ? '-' : escapedLesson}</p>
      </div>
      <div class="meta-item">
        <p class="meta-label">Unite</p>
        <p class="meta-value">${escapedUnit.isEmpty ? '-' : escapedUnit}</p>
      </div>
      <div class="meta-item">
        <p class="meta-label">Konu</p>
        <p class="meta-value">${escapedTopic.isEmpty ? '-' : escapedTopic}</p>
      </div>
    </div>
    $contentHtml
  </main>

  <div class="brand">
    <div class="brand-left">
      <img class="brand-logo" src="$logoDataUri" alt="Ders Takip Logo" />
      <div>
        <p class="brand-title">Ders Takip</p>
        <p class="brand-sub">Daha fazla içerik için web sitemizi ziyaret edin.</p>
      </div>
    </div>
    <a class="brand-link" href="https://derstakip.net/">https://derstakip.net/</a>
  </div>
</body>
</html>
''';
  }

  String _escapeHtml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  pw.Widget _buildPdfInfoCard({
    String? gradeName,
    String? lessonName,
    String? unitTitle,
    String? topicTitle,
  }) {
    pw.Widget item(String label, String? value) {
      final safeValue = (value ?? '').trim().isEmpty ? '-' : value!.trim();
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: pw.BoxDecoration(
          color: PdfColors.blue50,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColors.blue100),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 9,
                color: PdfColors.blue700,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              safeValue,
              style: pw.TextStyle(
                fontSize: 11,
                color: PdfColors.blue900,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              item('Sinif', gradeName),
              pw.SizedBox(height: 6),
              item('Unite', unitTitle),
            ],
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              item('Ders', lessonName),
              pw.SizedBox(height: 6),
              item('Konu', topicTitle),
            ],
          ),
        ),
      ],
    );
  }

  void _logPdfError(String stage, Object error, StackTrace stackTrace) {
    final message = '[OutcomesPDF][$stage] $error';
    debugPrint(message);
    debugPrintStack(
      label: '[OutcomesPDF][$stage] stack',
      stackTrace: stackTrace,
    );
    developer.log(
      message,
      name: 'outcomes_pdf',
      error: error,
      stackTrace: stackTrace,
    );
  }

  Future<void> _deleteContent(BuildContext context) async {
    if (content.id == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('İçerik ID bulunamadı.')));
      return;
    }

    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('İçeriği Sil'),
          content: const Text(
            'Bu içerik silinecek. İlgili eşlemeler de kaldırılacak. Devam edilsin mi?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );

    if (approved != true) return;

    try {
      await Supabase.instance.client
          .from('topic_contents')
          .delete()
          .eq('id', content.id!);
      if (!context.mounted) return;
      onContentUpdated?.call();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('İçerik silindi.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Silme hatası: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine colors based on content type or use default red
    final accentColor = Colors.blue.shade700;

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent, // Cards handle their own background
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Topic Title Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        content.title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.blue.shade900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isAdmin || canDownloadPdf)
                  PopupMenuButton<_AdminMenuAction>(
                    tooltip: 'İçerik işlemleri',
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Icon(
                        Icons.more_horiz_rounded,
                        color: Colors.grey.shade700,
                        size: 20,
                      ),
                    ),
                    onSelected: (action) async {
                      switch (action) {
                        case _AdminMenuAction.update:
                          await _showEditDialog(context);
                          break;
                        case _AdminMenuAction.publish:
                          await _togglePublish(context);
                          break;
                        case _AdminMenuAction.downloadPdf:
                          await _downloadContentAsPdf(context);
                          break;
                        case _AdminMenuAction.copy:
                          await _copyContent(context);
                          break;
                        case _AdminMenuAction.delete:
                          await _deleteContent(context);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      if (isAdmin)
                        const PopupMenuItem<_AdminMenuAction>(
                          value: _AdminMenuAction.update,
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 8),
                              Text('İçeriği Güncelle'),
                            ],
                          ),
                        ),
                      if (isAdmin)
                        PopupMenuItem<_AdminMenuAction>(
                          value: _AdminMenuAction.publish,
                          enabled: content.isPublished != null,
                          child: Row(
                            children: [
                              Icon(
                                content.isPublished == true
                                    ? Icons.public
                                    : Icons.public_off,
                                size: 18,
                                color: content.isPublished == true
                                    ? Colors.green
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                content.isPublished == true
                                    ? 'Yayından Al'
                                    : 'Yayınla',
                              ),
                            ],
                          ),
                        ),
                      if (isAdmin || canDownloadPdf)
                        const PopupMenuItem<_AdminMenuAction>(
                          value: _AdminMenuAction.downloadPdf,
                          child: Row(
                            children: [
                              Icon(Icons.picture_as_pdf, size: 18),
                              SizedBox(width: 8),
                              Text('PDF Olarak İndir'),
                            ],
                          ),
                        ),
                      if (isAdmin)
                        const PopupMenuItem<_AdminMenuAction>(
                          value: _AdminMenuAction.copy,
                          child: Row(
                            children: [
                              Icon(Icons.copy, size: 18),
                              SizedBox(width: 8),
                              Text('İçeriği Kopyala'),
                            ],
                          ),
                        ),
                      if (isAdmin) const PopupMenuDivider(),
                      if (isAdmin)
                        const PopupMenuItem<_AdminMenuAction>(
                          value: _AdminMenuAction.delete,
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: Colors.red,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'İçeriği Sil',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),

          RepaintBoundary(
            child: Html(
              data: wrapFractionsForHtml(content.content),
              extensions: [
                const TableHtmlExtension(),
                TagExtension(
                  tagsToExtend: {"section"},
                  builder: (context) {
                    final element = context.node as dom.Element;
                    final h2Element = element.children.where(
                      (e) => e.localName == "h2",
                    );
                    final title = h2Element.isNotEmpty
                        ? h2Element.first.text.trim()
                        : "Bilgi";

                    return _PedagogicalCard(
                      title: title,
                      child: Html(
                        data: wrapFractionsForHtml(
                          element.innerHtml.replaceAll(
                            RegExp(r'<h2[^>]*>.*?</h2>', dotAll: true),
                            '',
                          ),
                        ),
                        extensions: [
                          const TableHtmlExtension(),
                          TagExtension(
                            tagsToExtend: {"fraction"},
                            builder: (ctx) => QuestionText(
                              text: ctx.innerHtml,
                              fontSize: 15.5,
                              useBaselineFractionLayout: true,
                            ),
                          ),
                        ],
                        style: {
                          ...getBaseHtmlStyle(context.buildContext!),
                          "p": Style(
                            fontSize: FontSize(15.5),
                            lineHeight: const LineHeight(1.6),
                            margin: Margins.only(bottom: 8),
                            color: Colors.grey.shade800,
                          ),
                          "li": Style(
                            fontSize: FontSize(15),
                            lineHeight: const LineHeight(1.5),
                            margin: Margins.only(bottom: 4),
                          ),
                        },
                      ),
                    );
                  },
                ),
                TagExtension(
                  tagsToExtend: {"fraction"},
                  builder: (ctx) => QuestionText(
                    text: ctx.innerHtml,
                    fontSize: 16,
                    useBaselineFractionLayout: true,
                  ),
                ),
              ],
              style: getBaseHtmlStyle(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _PedagogicalCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _PedagogicalCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final type = _getSectionType(title);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: type.color.withOpacity(0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: type.color.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: type.color.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: type.color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(type.icon, color: type.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: type.color.shade900,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: child,
          ),
        ],
      ),
    );
  }

  _SectionType _getSectionType(String title) {
    final t = title.toLowerCase();
    if (t.contains("giriş")) {
      return const _SectionType(Icons.auto_stories_rounded, Colors.indigo);
    }
    if (t.contains("bilgi")) {
      return const _SectionType(Icons.lightbulb_outline_rounded, Colors.blue);
    }
    if (t.contains("kavrama") || t.contains("açıklama")) {
      return const _SectionType(Icons.psychology_rounded, Colors.cyan);
    }
    if (t.contains("günlük hayat")) {
      return const _SectionType(Icons.eco_rounded, Colors.teal);
    }
    if (t.contains("uygulama")) {
      return const _SectionType(Icons.app_registration_rounded, Colors.orange);
    }
    if (t.contains("analiz") || t.contains("derinleştirme")) {
      return const _SectionType(Icons.insights_rounded, Colors.deepPurple);
    }
    if (t.contains("yanılgı")) {
      return const _SectionType(Icons.report_problem_rounded, Colors.red);
    }
    if (t.contains("etkinlik")) {
      return const _SectionType(Icons.extension_rounded, Colors.pink);
    }
    if (t.contains("düşünme")) {
      return const _SectionType(Icons.help_center_rounded, Colors.amber);
    }
    if (t.contains("özet")) {
      return const _SectionType(Icons.summarize_rounded, Colors.green);
    }
    if (t.contains("kavramlar")) {
      return const _SectionType(Icons.key_rounded, Colors.blueGrey);
    }
    if (t.contains("soru")) {
      return const _SectionType(Icons.quiz_rounded, Colors.indigo);
    }
    if (t.contains("cevap")) {
      return const _SectionType(Icons.checklist_rtl_rounded, Colors.teal);
    }
    return const _SectionType(Icons.article_rounded, Colors.blue);
  }
}

class _SectionType {
  final IconData icon;
  final MaterialColor color;
  const _SectionType(this.icon, this.color);
}

class AppleCollapsibleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const AppleCollapsibleCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Icon(icon, color: Colors.blue),
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: child,
          ),
        ],
      ),
    );
  }
}

class AppleOutcomeTile extends StatelessWidget {
  final String text;

  const AppleOutcomeTile({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: Colors.green.shade500,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
