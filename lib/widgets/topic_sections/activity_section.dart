// lib/widgets/topic_sections/activity_section.dart

import 'package:egitim_uygulamasi/models/topic_content.dart';
import 'package:egitim_uygulamasi/widgets/common/content_renderer.dart';
import 'package:flutter/material.dart';

/// 'Etkinlik' türündeki içerikleri sade ve şık bir kart içinde gösteren widget.
class ActivitySection extends StatelessWidget {
  final TopicContent content;
  const ActivitySection({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor =
        theme.colorScheme.secondary; // Etkinlikler için ikincil renk

    return Card(
      elevation: 1.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: accentColor.withOpacity(0.5), width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık Bölümü
          Container(
            width: double.infinity,
            color: accentColor.withOpacity(0.08),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Row(
              children: [
                Icon(Icons.edit_note_rounded, color: accentColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    content.title ?? 'Etkinlik',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // İçerik Bölümü
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
            child: ContentRenderer(content: content.content),
          ),
        ],
      ),
    );
  }
}
