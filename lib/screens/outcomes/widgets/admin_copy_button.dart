import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum AdminPromptType { content, contentV0, questions }

class AdminCopyButton extends StatelessWidget {
  final String gradeName;
  final String lessonName;
  final String unitTitle;
  final String topicTitle;
  final List<Map<String, dynamic>> outcomes;
  final AdminPromptType promptType;

  static const String _contentPromptAssetPath =
      'assets/prompts/lesson_content_prompt_v1.md';
  static const String _contentPromptV0AssetPath =
      'assets/prompts/lesson_content_prompt_v0.md';
  static const String _questionsPromptAssetPath =
      'assets/prompts/lesson_questions_prompt_v1.md';

  const AdminCopyButton({
    super.key,
    required this.gradeName,
    required this.lessonName,
    required this.unitTitle,
    required this.topicTitle,
    required this.outcomes,
    this.promptType = AdminPromptType.content,
  });

  static Future<String> buildPrompt({
    required String gradeName,
    required String lessonName,
    required String unitTitle,
    required String topicTitle,
    required List<Map<String, dynamic>> outcomes,
    required AdminPromptType promptType,
  }) async {
    final outcomesBuffer = StringBuffer();
    if (outcomes.isEmpty) {
      outcomesBuffer.writeln('(Kazanım bulunamadı)');
    } else {
      for (final outcome in outcomes) {
        final description = (outcome['description'] as String? ?? '').trim();
        if (description.isNotEmpty) {
          outcomesBuffer.writeln('- $description');
        }
      }
    }

    if (promptType == AdminPromptType.content ||
        promptType == AdminPromptType.contentV0) {
      return _buildContentPrompt(
        gradeName: gradeName,
        lessonName: lessonName,
        unitTitle: unitTitle,
        topicTitle: topicTitle,
        outcomesText: outcomesBuffer.toString(),
        assetPath: promptType == AdminPromptType.contentV0
            ? _contentPromptV0AssetPath
            : _contentPromptAssetPath,
      );
    }
    return _buildQuestionsPrompt(
      gradeName: gradeName,
      lessonName: lessonName,
      unitTitle: unitTitle,
      topicTitle: topicTitle,
      outcomesText: outcomesBuffer.toString(),
    );
  }

  static Future<void> copyPrompt(
    BuildContext context, {
    required String gradeName,
    required String lessonName,
    required String unitTitle,
    required String topicTitle,
    required List<Map<String, dynamic>> outcomes,
    required AdminPromptType promptType,
  }) async {
    final prompt = await buildPrompt(
      gradeName: gradeName,
      lessonName: lessonName,
      unitTitle: unitTitle,
      topicTitle: topicTitle,
      outcomes: outcomes,
      promptType: promptType,
    );

    try {
      await Clipboard.setData(ClipboardData(text: prompt));
      if (context.mounted) {
        String message;
        switch (promptType) {
          case AdminPromptType.content:
            message = 'İçerik bilgileri kopyalandı';
            break;
          case AdminPromptType.contentV0:
            message = 'İçerik promptu V0 kopyalandı';
            break;
          case AdminPromptType.questions:
            message = 'Soru hazırlama promptu kopyalandı';
            break;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Kopyalama hatası: $e')));
      }
    }
  }

  Future<void> _copyToClipboard(BuildContext context) {
    return copyPrompt(
      context,
      gradeName: gradeName,
      lessonName: lessonName,
      unitTitle: unitTitle,
      topicTitle: topicTitle,
      outcomes: outcomes,
      promptType: promptType,
    );
  }

  static Future<String> _buildContentPrompt({
    required String gradeName,
    required String lessonName,
    required String unitTitle,
    required String topicTitle,
    required String outcomesText,
    required String assetPath,
  }) async {
    final template = await rootBundle.loadString(assetPath);
    return template
        .replaceAll('{grade}', gradeName)
        .replaceAll('{subject}', lessonName)
        .replaceAll('{unit}', unitTitle)
        .replaceAll('{topic}', topicTitle)
        .replaceAll('{learning_outcomes}', outcomesText.trimRight());
  }

  static Future<String> _buildQuestionsPrompt({
    required String gradeName,
    required String lessonName,
    required String unitTitle,
    required String topicTitle,
    required String outcomesText,
  }) async {
    final template = await rootBundle.loadString(_questionsPromptAssetPath);
    return template
        .replaceAll('{grade}', gradeName)
        .replaceAll('{subject}', lessonName)
        .replaceAll('{unit}', unitTitle)
        .replaceAll('{topic}', topicTitle)
        .replaceAll('{learning_outcomes}', outcomesText.trimRight());
  }

  @override
  Widget build(BuildContext context) {
    IconData icon;
    String label;

    switch (promptType) {
      case AdminPromptType.content:
        icon = Icons.copy_rounded;
        label = 'İçerik Promptu';
        break;
      case AdminPromptType.contentV0:
        icon = Icons.copy_all_rounded;
        label = 'İçerik Promptu V0';
        break;
      case AdminPromptType.questions:
        icon = Icons.quiz_outlined;
        label = 'AI Questions Prompt';
        break;
    }

    return OutlinedButton.icon(
      onPressed: () => _copyToClipboard(context),
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF2F6FE4),
        side: const BorderSide(color: Color(0xFFC8DBFF)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
