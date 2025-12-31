// lib/widgets/topic_sections/explanation_section.dart

import 'package:egitim_uygulamasi/models/topic_content.dart';
import 'package:egitim_uygulamasi/widgets/common/content_renderer.dart';
import 'package:flutter/material.dart';

/// 'Açıklama' türündeki içerikleri sade ve şık bir kart içinde gösteren widget.
class ExplanationSection extends StatelessWidget {
  final TopicContent content;
  const ExplanationSection({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      // Kartın etrafında hafif bir gölge ve yuvarlak köşeler
      elevation: 1.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: Colors.grey.shade300, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias, // Köşelerin düzgün görünmesini sağlar
      margin: EdgeInsets.zero, // Üst widget'tan gelen boşlukları kullanır
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık Bölümü
          Container(
            width: double.infinity,
            color: theme.primaryColor.withOpacity(0.08),
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
