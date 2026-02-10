import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_table/flutter_html_table.dart';
import 'package:egitim_uygulamasi/models/topic_content.dart';
import 'package:egitim_uygulamasi/utils/html_style.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İçerik ID bulunamadı.')),
      );
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
          .eq('id', content.id);
      onContentUpdated?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İçerik güncellendi.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Güncelleme hatası: $e')),
      );
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
                      decoration: const InputDecoration(labelText: 'İçerik (HTML)'),
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
                  onPressed: isSaving ? null : () => Navigator.of(context).pop(),
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

  @override
  Widget build(BuildContext context) {
    final newStyle = Map<String, Style>.from(getBaseHtmlStyle(context));
    newStyle['body'] = Style(
      fontSize: FontSize(15),
      lineHeight: const LineHeight(1.6),
    );
    newStyle['h2'] = Style(
      color: Colors.red,
      fontSize: FontSize(20),
      fontWeight: FontWeight.w700,
      margin: Margins.symmetric(vertical: 12),
    );
    newStyle['h1'] = Style(
      color: Colors.red,
      fontSize: FontSize(22),
      fontWeight: FontWeight.w800,
      margin: Margins.symmetric(vertical: 14),
    );
    newStyle['h3'] = Style(
      color: Colors.red,
      fontSize: FontSize(18),
      fontWeight: FontWeight.w700,
      margin: Margins.symmetric(vertical: 10),
    );
    newStyle['strong'] = Style(
      color: Colors.red,
      fontWeight: FontWeight.w700,
    );

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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.article_rounded, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    content.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (isAdmin) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Düzenle',
                    onPressed: () => _showEditDialog(context),
                    icon: const Icon(Icons.edit, color: Colors.red),
                  ),
                  IconButton(
                    tooltip: content.isPublished == true
                        ? 'Yayından Al'
                        : 'Yayınla',
                    onPressed: content.isPublished == null
                        ? null
                        : () => _togglePublish(context),
                    icon: Icon(
                      content.isPublished == true
                          ? Icons.public
                          : Icons.public_off,
                      color: content.isPublished == true
                          ? Colors.green
                          : Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: Colors.grey.shade200),
            const SizedBox(height: 16),
            RepaintBoundary(
              child: Html(
                data: content.content,
                extensions: const [TableHtmlExtension()],
                style: newStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
