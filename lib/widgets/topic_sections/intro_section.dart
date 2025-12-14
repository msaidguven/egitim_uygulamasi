// lib/widgets/topic_sections/intro_section.dart

import 'package:flutter/material.dart';

/// 'intro' tipi için özel widget.
class IntroSection extends StatelessWidget {
  final String? content;
  final String? title;
  const IntroSection({super.key, this.content, this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      content ?? '',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontStyle: FontStyle.italic,
        color: Colors.grey[700],
      ),
    );
  }
}
