// lib/widgets/topic_sections/intro_section.dart

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

    return Card(
      elevation: 0,
      color: theme.colorScheme.primary.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (content.title != null && content.title.isNotEmpty) ...[
              Container(
                width: double.infinity,
                color: const Color(
                  0xFF4CAF50,
                ).withValues(alpha: 0.08), // yeşil pastel

                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Text(
                  content.title ?? 'Açıklama',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
              ),

              const SizedBox(height: 8),
            ],
            ContentRenderer(content: content.content),
          ],
        ),
      ),
    );
  }
}
