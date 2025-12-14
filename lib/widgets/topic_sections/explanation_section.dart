// lib/widgets/topic_sections/explanation_section.dart

import 'package:egitim_uygulamasi/models/topic_content.dart';
import 'package:egitim_uygulamasi/utils/html_style.dart';
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

    // Get the base styles and override the title style.
    final titleStyle = getBaseHtmlStyle(context)
      ..addAll({
        "p": Style(
          fontSize: FontSize(theme.textTheme.titleMedium?.fontSize ?? 16.0),
          fontWeight: FontWeight.bold,
        ),
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (content.title != null && content.title!.isNotEmpty) ...[
          ContentRenderer(content: content.title!, style: titleStyle),
          const SizedBox(height: 8.0), // Add spacing between title and content
        ],
        // Use the default style from ContentRenderer for the body
        ContentRenderer(content: content.content),
      ],
    );
  }
}
