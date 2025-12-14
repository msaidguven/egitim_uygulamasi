// lib/widgets/topic_sections/summary_section.dart

import 'package:flutter/material.dart';

/// 'summary' tipi için özel widget.
class SummarySection extends StatelessWidget {
  final String? content;
  final String? title;
  const SummarySection({super.key, this.content, this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const accentColor = Colors.orange;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.05),
        border: Border.all(color: accentColor.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline, color: accentColor.shade800),
              const SizedBox(width: 8),
              Text(
                'Özet',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: accentColor.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(content ?? '', style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
