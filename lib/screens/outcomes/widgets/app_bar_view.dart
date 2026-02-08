import 'package:flutter/material.dart';

class AppleStyleAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color backgroundColor;
  final List<Widget>? actions;

  const AppleStyleAppBar({
    required this.title,
    required this.backgroundColor,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
      ),
      backgroundColor: backgroundColor,
      foregroundColor: Colors.black,
      elevation: 0,
      centerTitle: false,
      actions: actions,
      scrolledUnderElevation: 1,
      surfaceTintColor: Colors.transparent,
      shape: const Border(
        bottom: BorderSide(color: Color(0xFFE5E5EA), width: 0.5),
      ),
    );
  }
}
