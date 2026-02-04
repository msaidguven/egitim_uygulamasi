import 'package:flutter/foundation.dart';
import '../models/topic_content.dart';

class TopicContentParser {
  List<TopicContent> parse(String rawContent) {
    final List<TopicContent> sections = [];
    if (rawContent.trim().isEmpty) {
      return sections;
    }

    final sectionBlocks = rawContent.split(RegExp(r'\n---\n?'));
    int order = 0;

    for (final block in sectionBlocks) {
      if (block.trim().isEmpty) continue;

      final lines = block.split('\n');
      // Must have title and content marker. At least 2 lines.
      if (lines.length < 2) continue;

      try {
        String title = lines[0].trim();
        if (title.startsWith('[') && title.endsWith(']')) {
          title = title.substring(1, title.length - 1);
        } else {
          continue; // Malformed title, skip this block
        }

        if (lines[1].trim().toLowerCase() != 'content:') {
          continue; // Malformed content marker, skip this block
        }

        final content = lines.sublist(2).join('\n');

        sections.add(
          TopicContent(
              title: title,
              content: content,
              order: order),
        );
        order++;
      } catch (e) {
        // In case of any other error during processing of a block,
        // print it and continue to the next block.
        debugPrint('Error parsing content block: $e');
      }
    }

    return sections;
  }
}