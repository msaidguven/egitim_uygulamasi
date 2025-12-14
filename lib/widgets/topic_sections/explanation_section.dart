// lib/widgets/topic_sections/explanation_section.dart

import 'package:flutter/material.dart';

/// 'explanation' tipi için özel widget.
class ExplanationSection extends StatelessWidget {
  final String? content;
  final String? title;
  const ExplanationSection({super.key, this.content, this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasTitle = title != null && title!.isNotEmpty;
    final hasContent = content != null && content!.isNotEmpty;

    if (!hasTitle && !hasContent) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasTitle)
          Text(
            title!,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        if (hasTitle && hasContent) const SizedBox(height: 8.0),
        if (hasContent)
          Text(
            content!,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
      ],
    );
  }
}
