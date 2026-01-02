// lib/admin/pages/admin_layout.dart

import 'package:egitim_uygulamasi/admin/admin_router.dart';
import 'package:egitim_uygulamasi/admin/widgets/admin_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminLayout extends StatefulWidget {
  final Widget child;

  const AdminLayout({super.key, required this.child});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(AdminRoutes.curriculum);
        break;
      case 1:
        context.go(AdminRoutes.lessons);
        break;
      case 2:
        context.go(AdminRoutes.units);
        break;
      case 3:
        context.go(AdminRoutes.topics);
        break;
      case 4:
        context.go(AdminRoutes.outcomes);
        break;
      case 5:
        context.go(AdminRoutes.smartContentAddition);
        break;
      case 6: // New case for Smart Question Addition
        context.go(AdminRoutes.smartQuestionAddition);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    int selectedIndex = 0;
    if (location.startsWith(AdminRoutes.curriculum)) {
      selectedIndex = 0;
    } else if (location.startsWith(AdminRoutes.lessons)) {
      selectedIndex = 1;
    } else if (location.startsWith(AdminRoutes.units)) {
      selectedIndex = 2;
    } else if (location.startsWith(AdminRoutes.topics)) {
      selectedIndex = 3;
    } else if (location.startsWith(AdminRoutes.outcomes)) {
      selectedIndex = 4;
    } else if (location.startsWith(AdminRoutes.smartContentAddition)) {
      selectedIndex = 5;
    } else if (location.startsWith(AdminRoutes.smartQuestionAddition)) { // New else if for Smart Question Addition
      selectedIndex = 6;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: Row(
        children: [
          AdminSidebar(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) => _onItemTapped(index, context),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}
