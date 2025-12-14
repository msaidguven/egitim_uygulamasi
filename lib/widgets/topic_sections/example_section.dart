// lib/widgets/topic_sections/example_section.dart

import 'package:egitim_uygulamasi/widgets/common/content_renderer.dart';
import 'package:flutter/material.dart';

/// 'example' tipi için özel widget.
class ExampleSection extends StatelessWidget {
  final String? content;
  final String? title;
  const ExampleSection({super.key, this.content, this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const accentColor = Colors.green;

    return Card(
      elevation: 0,
      color: accentColor.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: accentColor.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: accentColor.shade700),
                const SizedBox(width: 8),
                Text(
                  'Örnek',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: accentColor.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ContentRenderer(content: content ?? ''),
          ],
        ),
      ),
    );
  }
}
