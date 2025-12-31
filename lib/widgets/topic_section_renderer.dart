import 'package:flutter/material.dart';
import 'package:egitim_uygulamasi/models/topic_content.dart';

class TopicSectionRenderer extends StatelessWidget {
  final TopicContent topicContent;

  const TopicSectionRenderer({super.key, required this.topicContent});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row for badge and title
            Row(
              children: [
                Expanded(
                  child: Text(
                    topicContent.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // Rendered content
            ..._buildContentWidgets(context, topicContent.content),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTypeBadge(BuildContext context, String sectionType) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).primaryColor, width: 1),
      ),
      child: Text(
        sectionType.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  List<Widget> _buildContentWidgets(BuildContext context, String content) {
    final List<Widget> widgets = [];
    if (content.trim().isEmpty) {
      return widgets;
    }

    // Replace @@ with a unique paragraph separator to split by it.
    final paragraphs = content.replaceAll('@@', '\n<PARAGRAPH_BREAK>\n').split('<PARAGRAPH_BREAK>');

    for (var paragraph in paragraphs) {
      final lines = paragraph.trim().split('\n');
      for (final line in lines) {
        final trimmedLine = line.trim();
        if (trimmedLine.isEmpty) continue;

        if (trimmedLine.startsWith('## ')) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
              child: Text(
                trimmedLine.substring(3),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          );
        } else if (trimmedLine.startsWith('* ')) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 2.0, bottom: 2.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(child: _buildRichText(context, trimmedLine.substring(2))),
                ],
              ),
            ),
          );
        } else {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _buildRichText(context, trimmedLine),
            )
          );
        }
      }
    }

    return widgets;
  }
  
  // Basic RichText parser for **bold** and __underline__
  Widget _buildRichText(BuildContext context, String text) {
    final List<TextSpan> spans = [];
    final RegExp exp = RegExp(r'(\**.*?\**|__.*?__)');
    final matches = exp.allMatches(text);

    int lastMatchEnd = 0;

    for (final Match match in matches) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start)));
      }

      final String matchText = match.group(0)!;
      if (matchText.startsWith('**')) {
        spans.add(TextSpan(
          text: matchText.substring(2, matchText.length - 2),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ));
      } else if (matchText.startsWith('__')) {
        spans.add(TextSpan(
          text: matchText.substring(2, matchText.length - 2),
          style: const TextStyle(decoration: TextDecoration.underline),
        ));
      }
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd)));
    }

    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16, height: 1.5),
        children: spans,
      ),
    );
  }
}