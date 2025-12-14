// lib/widgets/common/content_renderer.dart

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

/// A centralized widget for rendering content strings.
///
/// This widget uses the `flutter_html` package to parse and render HTML
/// content. It can handle various HTML tags like headings, paragraphs, and lists.
/// It is designed to be easily swappable with other renderers in the future
/// without requiring changes to the widgets that use it.
class ContentRenderer extends StatelessWidget {
  final String content;
  final Map<String, Style>? style;

  const ContentRenderer({super.key, required this.content, this.style});

  @override
  Widget build(BuildContext context) {
    // Html widget parses the given 'data' string and builds
    // a widget tree that displays the formatted HTML content.
    return Html(data: content, style: style ?? {});
  }
}
