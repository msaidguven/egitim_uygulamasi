// lib/widgets/topic_sections/activity_section.dart

import 'package:flutter_html/flutter_html.dart';
import 'package:egitim_uygulamasi/models/topic_content.dart';
import 'package:egitim_uygulamasi/widgets/common/content_renderer.dart';
import 'package:flutter/material.dart';

/// **Activity Section:** A task card with a call-to-action button.
class ActivitySection extends StatelessWidget {
  final TopicContent content;
  const ActivitySection({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.secondary;

    final titleTextStyle = theme.textTheme.titleMedium;
    final bodyTextStyle = theme.textTheme.bodyMedium;

    final titleStyle = {
      "p": Style(
        fontSize: FontSize(titleTextStyle?.fontSize ?? 16.0),
        fontWeight: FontWeight.bold,
        color: accentColor,
      ),
    };

    final contentStyle = {
      "p": Style(
        fontSize: FontSize(bodyTextStyle?.fontSize ?? 14.0),
        lineHeight: LineHeight.em(1.5),
      ),
    };

    return Card(
      elevation: 1,
      color: accentColor.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: accentColor.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit_note_rounded, color: accentColor),
                const SizedBox(width: 8),
                if (content.title != null && content.title!.isNotEmpty)
                  Expanded(
                    child: ContentRenderer(
                      content: content.title!,
                      style: titleStyle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ContentRenderer(content: content.content, style: contentStyle),
          ],
        ),
      ),
    );
  }
}
