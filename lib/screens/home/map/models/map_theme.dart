import 'package:flutter/material.dart';

enum MapThemeStyle { atlas, modern, minimal }

extension MapThemeStyleX on MapThemeStyle {
  String get label {
    switch (this) {
      case MapThemeStyle.atlas:
        return 'Atlas';
      case MapThemeStyle.modern:
        return 'Modern';
      case MapThemeStyle.minimal:
        return 'Minimal';
    }
  }

  List<Color> get backgroundGradient {
    switch (this) {
      case MapThemeStyle.atlas:
        return const [Color(0xFFF8F4E8), Color(0xFFF0E7D6), Color(0xFFE8DDC8)];
      case MapThemeStyle.modern:
        return const [Color(0xFFEFF6FF), Color(0xFFE2ECFF), Color(0xFFDDE7F8)];
      case MapThemeStyle.minimal:
        return const [Color(0xFFF8FAFC), Color(0xFFF1F5F9), Color(0xFFE2E8F0)];
    }
  }

  Color get contour {
    switch (this) {
      case MapThemeStyle.atlas:
        return const Color(0xFFA89472);
      case MapThemeStyle.modern:
        return const Color(0xFF8FA6CC);
      case MapThemeStyle.minimal:
        return const Color(0xFF94A3B8);
    }
  }

  Color get routeBase {
    switch (this) {
      case MapThemeStyle.atlas:
        return const Color(0xFF7C6A4F);
      case MapThemeStyle.modern:
        return const Color(0xFF64748B);
      case MapThemeStyle.minimal:
        return const Color(0xFF475569);
    }
  }
}
