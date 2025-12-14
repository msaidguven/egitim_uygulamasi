// lib/widgets/topic_section_renderer.dart

import 'package:egitim_uygulamasi/models/topic_content.dart';
import 'package:egitim_uygulamasi/widgets/topic_sections/activity_section.dart';
import 'package:egitim_uygulamasi/widgets/topic_sections/example_section.dart';
import 'package:egitim_uygulamasi/widgets/topic_sections/explanation_section.dart';
import 'package:egitim_uygulamasi/widgets/topic_sections/intro_section.dart';
import 'package:egitim_uygulamasi/widgets/topic_sections/summary_section.dart';
import 'package:flutter/material.dart';

/// Returns a specific widget based on the `sectionType` of the [TopicContent].
///
/// This function acts as a widget factory, mapping a data type to a UI component.
Widget buildTopicSection(TopicContent item) {
  switch (item.sectionType) {
    case 'intro':
      return IntroSection(content: item);
    case 'explanation':
      return ExplanationSection(content: item);
    case 'example':
      return ExampleSection(content: item);
    case 'summary':
      return SummarySection(content: item);
    case 'activity':
      return ActivitySection(content: item);
    default:
      // A fallback widget for any unknown or unhandled section types.
      return ExplanationSection(content: item);
  }
}
