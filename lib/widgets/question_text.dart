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

  static final RegExp _fractionRegex =
  RegExp(r'\b\d{1,3}\/\d{1,3}\b');

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
    final fractionWidth = fontSize * (0.72 + (maxDigits * 0.34));
    final numDenSize = fontSize * 0.62;
    final lineThickness = (fontSize * 0.06).clamp(1.2, 2.2);
    final baselineY = fontSize * 0.78;
    final totalHeight = fontSize * 1.42;

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
              bottom: totalHeight - baselineY + 2,
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
            Positioned(
              left: 0,
              right: 0,
              top: baselineY - (lineThickness / 2),
              child: Container(
                height: lineThickness,
                color: fractionColor.withValues(alpha: 0.9),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: baselineY + 2,
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
        ),
      ),
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
