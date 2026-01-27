// lib/widgets/topic_sections/example_section.dart

import 'package:egitim_uygulamasi/models/topic_content.dart';
import 'package:egitim_uygulamasi/widgets/common/content_renderer.dart';
import 'package:flutter/material.dart';

/// **Example Section:** A card with an icon to denote an example.
class ExampleSection extends StatelessWidget {
  final TopicContent content;
  const ExampleSection({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = Colors.green;

    return Card(
      elevation: 0,
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
                Icon(Icons.lightbulb_outline, color: accentColor),
                const SizedBox(width: 8),
                if (content.title.isNotEmpty)
                  Expanded(
                    child: Text(
                      content.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ContentRenderer(content: content.content),
          ],
        ),
      ),
    );
  }
}
