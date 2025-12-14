// lib/widgets/topic_sections/activity_section.dart

import 'package:egitim_uygulamasi/widgets/common/content_renderer.dart';
import 'package:flutter/material.dart';

/// 'activity' tipi için özel widget.
class ActivitySection extends StatelessWidget {
  final String? content;
  final String? title;
  const ActivitySection({super.key, this.content, this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const accentColor = Colors.deepPurple;

    return Card(
      elevation: 1,
      shadowColor: accentColor.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: accentColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit_note_outlined, color: accentColor.shade700),
                const SizedBox(width: 8),
                Text(
                  'Etkinlik',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: accentColor.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (title != null && title!.isNotEmpty) ...[
              Text(title!, style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
            ],
            ContentRenderer(content: content ?? ''),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implement activity interaction logic.
                },
                child: const Text('Etkinliği Başlat'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
