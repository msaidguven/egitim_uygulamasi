import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'lesson_viewer.dart' as viewer;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const LessonApp());
}

class LessonApp extends StatelessWidget {
  const LessonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lesson Preview V11',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3B82F6)),
        useMaterial3: true,
      ),
      home: const LessonPage(),
    );
  }
}

class LessonPage extends StatelessWidget {
  final int? topicId;
  final bool useAssetFallback;
  final List<int>? outcomeIds;

  const LessonPage({
    super.key,
    this.topicId,
    this.useAssetFallback = true,
    this.outcomeIds,
  });

  static const String _lessonAssetPath =
      'lib/screens/lesson_content/lesson_v11/lesson_module.json';

  @override
  Widget build(BuildContext context) {
    return viewer.LessonPage(
      topicId: topicId,
      outcomeIds: outcomeIds,
      assetPath: useAssetFallback ? _lessonAssetPath : null,
    );
  }
}
