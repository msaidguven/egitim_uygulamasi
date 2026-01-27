// lib/widgets/topic_sections/summary_section.dart

import 'package:egitim_uygulamasi/models/topic_content.dart';
import 'package:egitim_uygulamasi/widgets/common/content_renderer.dart';
import 'package:flutter/material.dart';

/// **Summary Section:** A bordered box to wrap up key points.
class SummarySection extends StatelessWidget {
  final TopicContent content;
  const SummarySection({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = Colors.orange.shade700;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // The main content container
        Container(
          margin: const EdgeInsets.only(top: 12.0), // Space for the label
          padding: const EdgeInsets.fromLTRB(
            16.0,
            24.0,
            16.0,
            16.0,
          ), // Top padding for content
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: accentColor.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (content.title.isNotEmpty) ...[
                Text(
                  content.title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
              ],
              ContentRenderer(content: content.content),
            ],
          ),
        ),
        // The "Özet" label positioned over the top border
        Positioned(
          top: 0,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Text(
              'ÖZET',
              style: theme.textTheme.bodySmall?.copyWith(
                color: accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
