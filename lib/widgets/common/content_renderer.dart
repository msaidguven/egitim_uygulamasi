// lib/widgets/common/content_renderer.dart

import 'package:flutter/material.dart';

/// A centralized widget for rendering content strings.
///
/// This widget normalizes the input text by handling escaped newline characters
/// and renders it using a standard `Text` widget. It is designed to be
/// easily swappable with other renderers, such as a Markdown renderer,
/// in the future without requiring changes to the widgets that use it.
class ContentRenderer extends StatelessWidget {
  final String content;

  const ContentRenderer({super.key, required this.content});

  /// Normalizes the content text by replacing escaped newline characters with actual line breaks.
  String _formatContentText(String text) {
    return text.replaceAll(r'\n', '\n');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      _formatContentText(content),
      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
      softWrap: true,
    );
  }
}
