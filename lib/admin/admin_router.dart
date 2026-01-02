// lib/admin/admin_router.dart

import 'package:egitim_uygulamasi/admin/pages/admin_layout.dart';
import 'package:egitim_uygulamasi/admin/pages/curriculum/curriculum_page.dart';
import 'package:egitim_uygulamasi/admin/pages/lessons/lesson_list_page.dart';
import 'package:egitim_uygulamasi/admin/pages/topics/topic_list_page.dart';
import 'package:egitim_uygulamasi/admin/pages/outcomes/outcome_list_page.dart';
import 'package:egitim_uygulamasi/admin/pages/units/unit_list_page.dart';
import 'package:egitim_uygulamasi/admin/pages/smart_content_addition/smart_content_addition_page.dart';
import 'package:egitim_uygulamasi/admin/pages/smart_question_addition/smart_question_addition_page.dart'; // Add this
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminRoutes {
  static const String curriculum = '/admin/curriculum';
  static const String lessons = '/admin/lessons';
  static const String units = '/admin/units';
  static const String topics = '/admin/topics';
  static const String outcomes = '/admin/outcomes';
  static const String smartContentAddition = '/admin/smart-content-addition';
  static const String smartQuestionAddition = '/admin/smart-question-addition'; // Add this
}

final adminRoutes = ShellRoute(
  builder: (context, state, child) {
    return AdminLayout(child: child);
  },
  routes: [
    GoRoute(
      path: AdminRoutes.curriculum,
      builder: (context, state) {
        final String? gradeId = state.uri.queryParameters['gradeId'];
        final String? lessonId = state.uri.queryParameters['lessonId'];
        return CurriculumPage(
          gradeId: gradeId,
          lessonId: lessonId,
        );
      },
    ),
    GoRoute(
      path: AdminRoutes.lessons,
      builder: (context, state) => const LessonListPage(),
    ),
    GoRoute(
      path: AdminRoutes.units,
      builder: (context, state) => const UnitListPage(),
    ),
    GoRoute(
      path: AdminRoutes.topics,
      builder: (context, state) => const TopicListPage(),
    ),
    GoRoute(
      path: AdminRoutes.outcomes,
      builder: (context, state) => const OutcomeListPage(),
    ),
    GoRoute(
      path: AdminRoutes.smartContentAddition,
      builder: (context, state) => const SmartContentAdditionPage(),
    ),
    GoRoute(
      path: AdminRoutes.smartQuestionAddition, // Add this
      builder: (context, state) => const SmartQuestionAdditionPage(),
    ),
  ],
);
