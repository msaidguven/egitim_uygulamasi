// lib/widgets/topic_sections/explanation_section.dart

import 'package:egitim_uygulamasi/models/topic_content.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:egitim_uygulamasi/widgets/common/content_renderer.dart';
import 'package:flutter/material.dart';

/// **Explanation Section:** Standard text with a bold title.
class ExplanationSection extends StatelessWidget {
  final TopicContent content;
  const ExplanationSection({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final titleTextStyle = theme.textTheme.titleMedium;
    final bodyTextStyle = theme.textTheme.bodyMedium;

    // Define a style for the title to appear as a bold subtitle.
    // This will apply to heading tags (like ##) or plain text in the title.
    final titleStyle = {
      "p": Style(
        fontSize: FontSize(titleTextStyle?.fontSize ?? 16.0),
        fontWeight: FontWeight.bold,
      ),
      "h2": Style(
        fontSize: FontSize(titleTextStyle?.fontSize ?? 16.0),
        fontWeight: FontWeight.bold,
      ),
    };

    // Define a style for the main content with proper line height.
    final contentStyle = {
      "p": Style(
        fontSize: FontSize(bodyTextStyle?.fontSize ?? 14.0),
        lineHeight: LineHeight.em(1.5),
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (content.title != null && content.title!.isNotEmpty) ...[
          ContentRenderer(content: content.title!, style: titleStyle),
          const SizedBox(height: 8.0), // Add spacing between title and content
        ],
        ContentRenderer(content: content.content, style: contentStyle),
      ],
    );
  }
}
