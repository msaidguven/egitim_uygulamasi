// lib/utils/html_style.dart

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

/// Returns a base style map for the flutter_html widget,
/// derived from the application's current theme.
Map<String, Style> getBaseHtmlStyle(BuildContext context) {
  final theme = Theme.of(context);
  final textTheme = theme.textTheme;

  return {
    // Default paragraph style
    "p": Style(
      fontSize: FontSize(textTheme.bodyMedium?.fontSize ?? 14.0),
      lineHeight: LineHeight.em(1.5),
    ),
    "body": Style(
      margin: Margins.zero, // Remove default margins from Html widget
    ),

    // Heading styles
    "h1": Style(
      fontSize: FontSize(textTheme.headlineLarge?.fontSize ?? 32.0),
      fontWeight: FontWeight.bold,
    ),
    "h2": Style(
      fontSize: FontSize(textTheme.headlineMedium?.fontSize ?? 28.0),
      fontWeight: FontWeight.bold,
      margin: Margins.only(top: 16, bottom: 8),
    ),
    "h3": Style(
      fontSize: FontSize(textTheme.headlineSmall?.fontSize ?? 24.0),
      fontWeight: FontWeight.bold,
      margin: Margins.only(top: 12, bottom: 6),
    ),

    // List styles
    "li": Style(
      fontSize: FontSize(textTheme.bodyMedium?.fontSize ?? 14.0),
      lineHeight: LineHeight.em(1.5),
    ),

    // Link style
    "a": Style(
      color: theme.colorScheme.primary,
      textDecoration: TextDecoration.underline,
    ),

    // Table styles
    "table": Style(
      backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.2),
      border: Border.all(color: theme.dividerColor),
    ),
    "tr": Style(
      border: Border(bottom: BorderSide(color: theme.dividerColor)),
    ),
    "th": Style(
      padding: HtmlPaddings.all(8),
      backgroundColor: theme.colorScheme.surfaceVariant,
      fontWeight: FontWeight.bold,
      textAlign: TextAlign.center,
    ),
    "td": Style(
      padding: HtmlPaddings.all(8),
      textAlign: TextAlign.left,
      // Ensure table cells have a consistent line height with paragraphs
      lineHeight: LineHeight.em(1.5),
    ),
  };
}
