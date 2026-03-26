// bu sayfa matematik sorualrını güzelleştiren fonsiyondur

import 'package:flutter/material.dart';

class QuestionText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color textColor;
  final Color fractionColor;
  final bool enableFractions;
  final bool useBaselineFractionLayout;

  const QuestionText({
    super.key,
    required this.text,
    this.fontSize = 18,
    this.textColor = Colors.black,
    this.fractionColor = Colors.blue,
    this.enableFractions = true,
    this.useBaselineFractionLayout = false,
  });

  static final RegExp _fractionRegex = RegExp(
    r'\b(?!7\/24\b)\d{1,3}\/\d{1,3}\b',
  );

  String _decodeHtmlEntities(String input) {
    var output = input;
    for (var i = 0; i < 2; i++) {
      output = output
          .replaceAll('&amp;', '&')
          .replaceAll('&gt;', '>')
          .replaceAll('&lt;', '<')
          .replaceAll('&quot;', '"')
          .replaceAll('&#39;', "'")
          .replaceAll('&nbsp;', ' ');
    }
    return output;
  }

  Widget _fractionLegacy(String value) {
    final parts = value.split('/');
    final numerator = parts[0];
    final denominator = parts[1];
    final maxDigits = numerator.length > denominator.length
        ? numerator.length
        : denominator.length;
    final fractionWidth = fontSize * (0.64 + (maxDigits * 0.28));
    final numDenSize = fontSize * 0.7;
    final lineThickness = (fontSize * 0.06).clamp(1.2, 2.2);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: fractionWidth,
          child: Text(
            numerator,
            textAlign: TextAlign.center,
            softWrap: false,
            maxLines: 1,
            overflow: TextOverflow.visible,
            style: TextStyle(
              fontSize: numDenSize,
              color: fractionColor,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ),
        Container(
          width: fractionWidth,
          height: lineThickness,
          color: fractionColor.withValues(alpha: 0.9),
        ),
        SizedBox(
          width: fractionWidth,
          child: Text(
            denominator,
            textAlign: TextAlign.center,
            softWrap: false,
            maxLines: 1,
            overflow: TextOverflow.visible,
            style: TextStyle(
              fontSize: numDenSize,
              color: fractionColor,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _fractionBaseline(String value) {
    final parts = value.split('/');
    final numerator = parts[0];
    final denominator = parts[1];
    final maxDigits = numerator.length > denominator.length
        ? numerator.length
        : denominator.length;
    final fractionWidth = fontSize * (0.76 + (maxDigits * 0.34));
    final numDenSize = fontSize * 0.66;
    final lineThickness = (fontSize * 0.055).clamp(1.1, 2.1);
    final baselineY = fontSize * 1.00;
    final totalHeight = fontSize * 1.32;
    final lineY = fontSize * 0.52;
    final textGap = fontSize * 0.02;

    return Baseline(
      baseline: baselineY,
      baselineType: TextBaseline.alphabetic,
      child: SizedBox(
        width: fractionWidth,
        height: totalHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: totalHeight - lineY + textGap,
              child: Text(
                numerator,
                textAlign: TextAlign.center,
                softWrap: false,
                maxLines: 1,
                overflow: TextOverflow.visible,
                style: TextStyle(
                  fontSize: numDenSize,
                  color: fractionColor,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: lineY - (lineThickness / 2),
              child: Container(
                height: lineThickness,
                color: fractionColor.withValues(alpha: 0.9),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: lineY + textGap,
              child: Text(
                denominator,
                textAlign: TextAlign.center,
                softWrap: false,
                maxLines: 1,
                overflow: TextOverflow.visible,
                style: TextStyle(
                  fontSize: numDenSize,
                  color: fractionColor,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<InlineSpan> _parse(String input) {
    final normalizedInput = _decodeHtmlEntities(input);
    if (!enableFractions) {
      return [TextSpan(text: normalizedInput)];
    }

    final matches = _fractionRegex.allMatches(normalizedInput);
    int last = 0;
    final spans = <InlineSpan>[];

    for (final m in matches) {
      if (m.start > last) {
        spans.add(
          TextSpan(
            text: normalizedInput.substring(last, m.start),
            style: TextStyle(color: textColor),
          ),
        );
      }

      spans.add(
        WidgetSpan(
          alignment: useBaselineFractionLayout
              ? PlaceholderAlignment.baseline
              : PlaceholderAlignment.middle,
          baseline: useBaselineFractionLayout ? TextBaseline.alphabetic : null,
          child: useBaselineFractionLayout
              ? _fractionBaseline(m.group(0)!)
              : _fractionLegacy(m.group(0)!),
        ),
      );

      last = m.end;
    }

    if (last < normalizedInput.length) {
      spans.add(
        TextSpan(
          text: normalizedInput.substring(last),
          style: TextStyle(color: textColor),
        ),
      );
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    return RichText(
      textScaler: textScaler,
      text: TextSpan(
        style: TextStyle(fontSize: fontSize, color: textColor),
        children: _parse(text),
      ),
    );
  }
}
