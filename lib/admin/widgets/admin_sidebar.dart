// lib/admin/widgets/admin_sidebar.dart

import 'package:flutter/material.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      labelType: NavigationRailLabelType.all,
      leading: const Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0),
        child: Icon(Icons.admin_panel_settings, size: 32),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.book_outlined),
          selectedIcon: Icon(Icons.book),
          label: Text('Lessons'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.view_list_outlined),
          selectedIcon: Icon(Icons.view_list),
          label: Text('Units'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.topic_outlined),
          selectedIcon: Icon(Icons.topic),
          label: Text('Topics'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.check_circle_outline),
          selectedIcon: Icon(Icons.check_circle),
          label: Text('Outcomes'),
        ),
      ],
    );
  }
}
