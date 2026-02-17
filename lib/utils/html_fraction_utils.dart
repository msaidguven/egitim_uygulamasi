import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

final RegExp _fractionRegex = RegExp(r'\b(\d{1,3}\/\d{1,3})\b');

String wrapFractionsForHtml(String html) {
  if (html.trim().isEmpty) return html;

  // Clean previously injected/escaped fraction tags if they exist in stored content.
  final sanitized = html
      .replaceAll(
        RegExp(r'<\s*/?\s*fraction\s*>', caseSensitive: false),
        '',
      )
      .replaceAll(
        RegExp(r'&lt;\s*/?\s*fraction\s*&gt;', caseSensitive: false),
        '',
      )
      .replaceAll(
        RegExp(r'&amp;lt;\s*/?\s*fraction\s*&amp;gt;', caseSensitive: false),
        '',
      );

  final fragment = html_parser.parseFragment(sanitized);

  void processNode(dom.Node node) {
    // Clone child list because we mutate the tree while iterating.
    final children = List<dom.Node>.from(node.nodes);
    for (final child in children) {
      if (child is dom.Element) {
        final tag = child.localName?.toLowerCase();
        // Do not transform code-like blocks.
        if (tag == 'pre' || tag == 'code' || tag == 'script' || tag == 'style') {
          continue;
        }
      }

      if (child is dom.Text) {
        final text = child.text;
        final matches = _fractionRegex.allMatches(text).toList();
        if (matches.isEmpty) continue;

        final replacementNodes = <dom.Node>[];
        var last = 0;
        for (final m in matches) {
          if (m.start > last) {
            replacementNodes.add(dom.Text(text.substring(last, m.start)));
          }
          final fraction = dom.Element.tag('fraction')..text = m.group(0)!;
          replacementNodes.add(fraction);
          last = m.end;
        }
        if (last < text.length) {
          replacementNodes.add(dom.Text(text.substring(last)));
        }

        final parent = child.parent;
        if (parent != null) {
          final idx = parent.nodes.indexOf(child);
          parent.nodes.removeAt(idx);
          parent.nodes.insertAll(idx, replacementNodes);
        }
      } else {
        processNode(child);
      }
    }
  }

  processNode(fragment);
  return fragment.outerHtml;
}
