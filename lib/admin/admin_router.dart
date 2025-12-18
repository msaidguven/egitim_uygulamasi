// lib/admin/admin_router.dart

import 'package:egitim_uygulamasi/admin/pages/admin_layout.dart';
import 'package:egitim_uygulamasi/admin/pages/lessons/lesson_list_page.dart';
import 'package:egitim_uygulamasi/admin/pages/outcomes/outcome_list_page.dart';
import 'package:egitim_uygulamasi/admin/pages/units/unit_list_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminRoutes {
  static const String lessons = '/admin/lessons';
  static const String units = '/admin/units';
  // Yeni rotalar
  static const String topics = '/admin/topics';
  static const String outcomes = '/admin/outcomes';
}

final adminRoutes = ShellRoute(
  builder: (context, state, child) {
    return AdminLayout(child: child);
  },
  routes: [
    GoRoute(
      path: AdminRoutes.lessons,
      builder: (context, state) => const LessonListPage(),
    ),
    GoRoute(
      path: AdminRoutes.units,
      builder: (context, state) => const UnitListPage(),
    ),
    // Henüz sayfası oluşturulmadığı için Topics rotasını yorum satırı yapalım.
    // GoRoute(
    //   path: AdminRoutes.topics,
    //   builder: (context, state) => const TopicListPage(),
    // ),
    GoRoute(
      path: AdminRoutes.outcomes,
      builder: (context, state) => const OutcomeListPage(),
    ),
  ],
);
