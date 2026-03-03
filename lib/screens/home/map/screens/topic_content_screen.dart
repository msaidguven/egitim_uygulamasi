import 'package:egitim_uygulamasi/screens/weekly_outcomes_screen.dart';
import 'package:flutter/material.dart';

class TopicContentScreen extends StatelessWidget {
  const TopicContentScreen({
    super.key,
    required this.topicId,
    required this.topicTitle,
  });

  final int topicId;
  final String topicTitle;

  @override
  Widget build(BuildContext context) {
    return WeeklyOutcomesScreen(
      topicId: topicId,
      topicTitle: topicTitle,
    );
  }
}
