// lib/widgets/common/content_renderer.dart

import 'package:flutter/material.dart';

/// A centralized widget for rendering custom-formatted plain text content.
///
/// This widget parses a string and builds a rich layout based on simple rules:
/// - Lines starting with `## ` are treated as sub-headings.
/// - Lines starting with `* ` are treated as bullet points.
/// - Text wrapped in `**...**` is rendered as bold.
/// - Text wrapped in `_..._` is rendered as italic.
/// - Text wrapped in `__...__` is rendered as underlined.
/// - Empty lines are converted into vertical spacing.
/// - Other lines are rendered as standard text paragraphs.
///
/// This renderer does NOT use HTML or Markdown.
class ContentRenderer extends StatelessWidget {
  final String content;

  const ContentRenderer({super.key, required this.content});

  /// Parses a line of text and returns a list of [TextSpan]s with appropriate styling.
  List<TextSpan> _parseSpans(String text, TextStyle baseStyle) {
    final List<TextSpan> spans = [];
    // Regex to find **bold**, _italic_, or __underlined__ text
    final regex = RegExp(r'(\*\*.*?\*\*|__.*?__|_.*?_)');

    final matches = regex.allMatches(text);

    if (matches.isEmpty) {
      return [TextSpan(text: text, style: baseStyle)];
    }

    int lastMatchEnd = 0;
    for (final match in matches) {
      // Add text before the match
      if (match.start > lastMatchEnd) {
        spans.add(
            TextSpan(text: text.substring(lastMatchEnd, match.start), style: baseStyle));
      }

      // Add the matched text with styling
      final matchedText = match.group(0)!;
      TextStyle style = baseStyle;
      String innerText = '';

      if (matchedText.startsWith('**') && matchedText.endsWith('**')) {
        style = style.copyWith(fontWeight: FontWeight.bold);
        innerText = matchedText.substring(2, matchedText.length - 2);
      } else if (matchedText.startsWith('__') && matchedText.endsWith('__')) {
        style = style.copyWith(decoration: TextDecoration.underline);
        innerText = matchedText.substring(2, matchedText.length - 2);
      } else if (matchedText.startsWith('_') && matchedText.endsWith('_')) {
        style = style.copyWith(fontStyle: FontStyle.italic);
        innerText = matchedText.substring(1, matchedText.length - 1);
      }
      spans.add(TextSpan(text: innerText, style: style));
      lastMatchEnd = match.end;
    }

    // Add any remaining text after the last match
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd), style: baseStyle));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    // Get the default text style from the current theme to ensure correct color.
    final defaultStyle = DefaultTextStyle.of(context).style;
    // Create a base style by overriding properties on the default style.
    final baseStyle = defaultStyle.copyWith(fontSize: 16, height: 1.5);
    final subHeaderStyle = baseStyle.copyWith(
        fontSize: 20, fontWeight: FontWeight.bold, height: 1.8);

    // Pre-process the content to handle custom paragraph breaks.
    final processedContent = content.replaceAll('@@', '\n\n');

    final lines = processedContent.split('\n');
    final List<Widget> children = [];

    for (final line in lines) {
      if (line.trim().isEmpty) {
        children.add(const SizedBox(height: 8.0));
      } else if (line.startsWith('## ')) {
        children.add(Text(
          line.substring(3), // Remove '## '
          style: subHeaderStyle,
        ));
      } else {
        // Handle bullet points and regular paragraphs
        final isBullet = line.startsWith('* ');
        final text = isBullet ? line.substring(2) : line;

        final textSpans = _parseSpans(text, baseStyle);

        final richText = RichText(
          text: TextSpan(
            style: baseStyle,
            children: textSpans,
          ),
        );

        if (isBullet) {
          children.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4.0), // Align bullet
                  child: Text('• ', style: baseStyle),
                ),
                Expanded(child: richText),
              ],
            ),
          );
        } else {
          children.add(richText);
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
