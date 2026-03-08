import 'package:flutter/material.dart';
import './widgets/lesson_engine.dart';

class LessonPage extends StatelessWidget {
  final String lessonKey;
  final String pageTitle;

  const LessonPage({
    super.key,
    this.lessonKey = 'lesson_tam_golge',
    this.pageTitle = 'Ders Onizleme',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF4F46E5),
        title: Text(
          pageTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: LessonEngine(lessonKey: lessonKey),
    );
  }
}
