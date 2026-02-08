// bu sayfa matematik sorualrını güzelleştiren fonsiyondur

import 'package:flutter/material.dart';

class QuestionText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color textColor;
  final Color fractionColor;
  final bool enableFractions;

  const QuestionText({
    super.key,
    required this.text,
    this.fontSize = 18,
    this.textColor = Colors.black,
    this.fractionColor = Colors.blue,
    this.enableFractions = true,
  });

  static final RegExp _fractionRegex =
  RegExp(r'\b\d{1,3}\/\d{1,3}\b');

  Widget _fraction(String value) {
    final parts = value.split('/');
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          parts[0],
          style: TextStyle(
            fontSize: fontSize * 0.7,
            color: fractionColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        Container(
          width: fontSize * 0.8,
          height: 2,
          color: fractionColor.withOpacity(0.9),
        ),
        Text(
          parts[1],
          style: TextStyle(
            fontSize: fontSize * 0.7,
            color: fractionColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  List<InlineSpan> _parse(String input) {
    if (!enableFractions) {
      return [TextSpan(text: input)];
    }

    final matches = _fractionRegex.allMatches(input);
    int last = 0;
    final spans = <InlineSpan>[];

    for (final m in matches) {
      if (m.start > last) {
        spans.add(TextSpan(
          text: input.substring(last, m.start),
          style: TextStyle(color: textColor),
        ));
      }

      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: _fraction(m.group(0)!),
        ),
      );

      last = m.end;
    }

    if (last < input.length) {
      spans.add(TextSpan(
        text: input.substring(last),
        style: TextStyle(color: textColor),
      ));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScaleFactorOf(context);
    return RichText(
      textScaleFactor: scale,
      text: TextSpan(
        style: TextStyle(fontSize: fontSize, color: textColor),
        children: _parse(text),
      ),
    );
  }
}
