// lib/widgets/topic_section_renderer.dart

import 'package:egitim_uygulamasi/models/topic_content.dart';
import 'package:egitim_uygulamasi/widgets/topic_sections/activity_section.dart';
import 'package:egitim_uygulamasi/widgets/topic_sections/example_section.dart';
import 'package:egitim_uygulamasi/widgets/topic_sections/explanation_section.dart';
import 'package:egitim_uygulamasi/widgets/topic_sections/intro_section.dart';
import 'package:egitim_uygulamasi/widgets/topic_sections/summary_section.dart';
import 'package:flutter/material.dart';
import 'package:egitim_uygulamasi/widgets/common/content_renderer.dart';

/// Returns a specific widget based on the `sectionType` of the [TopicContent].
///
/// This function acts as a widget factory, mapping a data type to a UI component.
Widget buildTopicSection(TopicContent item) {
  Widget sectionWidget;
  switch (item.sectionType) {
    case 'intro':
      sectionWidget = IntroSection(content: item.content, title: item.title);
      break;
    case 'explanation':
      sectionWidget = ExplanationSection(
        title: item.title,
        content: item.content,
      );
      break;
    case 'example':
      sectionWidget = ExampleSection(title: item.title, content: item.content);
      break;
    case 'summary':
      sectionWidget = SummarySection(title: item.title, content: item.content);
      break;
    case 'activity':
      sectionWidget = ActivitySection(title: item.title, content: item.content);
      break;
    default:
      // A fallback widget for any unknown or unhandled section types.
      sectionWidget = ExplanationSection(
        title: item.title,
        content: item.content,
      );
      break;
  }

  // Eğer section 'intro' ise ve 'displayWeek' varsa, bir rozet ekle.
  if (item.sectionType == 'intro' && item.displayWeek != null) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.teal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ContentRenderer(
            content: 'HAFTA ${item.displayWeek}',
            // Note: Specific styling from Text is now handled by ContentRenderer's theme usage.
          ),
        ),
        const SizedBox(height: 16),
        sectionWidget,
      ],
    );
  }

  return sectionWidget;
}
