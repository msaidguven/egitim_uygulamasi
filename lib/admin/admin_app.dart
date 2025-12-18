import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'admin_router.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  // GoRouter yapılandırması
  static final _router = GoRouter(
    initialLocation: AdminRoutes.lessons, // Başlangıç rotası
    routes: [
      adminRoutes, // ShellRoute'u ana rotalara ekliyoruz
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Admin Panel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      routerConfig: _router,
    );
  }
}
