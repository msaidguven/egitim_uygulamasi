import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_table/flutter_html_table.dart';
import 'package:html/dom.dart' as dom;
import 'package:egitim_uygulamasi/models/topic_content.dart';
import 'package:egitim_uygulamasi/utils/html_style.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:egitim_uygulamasi/widgets/question_text.dart';
import 'package:egitim_uygulamasi/utils/html_fraction_utils.dart';

enum _AdminMenuAction { update, publish, downloadPdf, copy, delete }

class TopicContentView extends StatelessWidget {
  final TopicContent content;
  final bool isAdmin;
  final VoidCallback? onContentUpdated;

  const TopicContentView({
    Key? key,
    required this.content,
    required this.isAdmin,
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
      final plainText = _stripHtml(content.content);
      final doc = pw.Document();
      final font = await PdfGoogleFonts.notoSansRegular();
      final boldFont = await PdfGoogleFonts.notoSansBold();

      doc.addPage(
        pw.MultiPage(
          build: (context) => [
            pw.Text(
              content.title,
              style: pw.TextStyle(font: boldFont, fontSize: 20),
            ),
            pw.SizedBox(height: 12),
            pw.Text(plainText, style: pw.TextStyle(font: font, fontSize: 12)),
          ],
        ),
      );

      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: '${content.title.trim().replaceAll(' ', '_')}.pdf',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF oluşturulamadı: $e')));
    }
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
                if (isAdmin)
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
                      const PopupMenuDivider(),
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
