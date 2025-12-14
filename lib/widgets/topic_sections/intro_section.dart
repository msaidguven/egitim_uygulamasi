// lib/widgets/topic_sections/intro_section.dart

import 'package:flutter_html/flutter_html.dart';
import 'package:egitim_uygulamasi/models/topic_content.dart';
import 'package:egitim_uygulamasi/widgets/common/content_renderer.dart';
import 'package:flutter/material.dart';

/// **Intro Section:** Highlighted container for introductions.
class IntroSection extends StatelessWidget {
  final TopicContent content;
  const IntroSection({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bodyLarge = theme.textTheme.bodyLarge;
    final headlineSmall = theme.textTheme.headlineSmall;
    final titleLarge = theme.textTheme.titleLarge;

    final introStyle = {
      // Larger typography for the main content
      "p": Style(
        fontSize: FontSize(bodyLarge?.fontSize ?? 16.0),
        lineHeight: LineHeight.em(1.5),
      ),
      // Style for headings (e.g., <h1>, <h2>) if used in the title
      "h1": Style(fontSize: FontSize(headlineSmall?.fontSize ?? 24.0)),
      "h2": Style(fontSize: FontSize(titleLarge?.fontSize ?? 22.0)),
    };

    return Card(
      elevation: 0,
      color: theme.colorScheme.primary.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (content.displayWeek != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ContentRenderer(
                  content: '<strong>HAFTA ${content.displayWeek}</strong>',
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (content.title != null && content.title!.isNotEmpty)
              ContentRenderer(content: content.title!, style: introStyle),
            ContentRenderer(content: content.content, style: introStyle),
          ],
        ),
      ),
    );
  }
}
