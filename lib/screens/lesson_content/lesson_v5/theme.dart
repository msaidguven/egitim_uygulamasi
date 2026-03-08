import 'package:flutter/material.dart';

// ─── THEME ────────────────────────────────────────────────────────────────────

class AppTheme {
  // Colors
  static const Color bg = Color(0xFF020817);
  static const Color surface = Color(0xFF0F172A);
  static const Color card = Color(0xFF1E293B);
  static const Color border = Color(0xFF334155);
  static const Color muted = Color(0xFF475569);
  static const Color subtle = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textBody = Color(0xFFE2E8F0);
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLt = Color(0xFFA78BFA);
  static const Color green = Color(0xFF22C55E);
  static const Color greenDark = Color(0xFF0D2D0D);
  static const Color greenBdr = Color(0xFF166534);
  static const Color red = Color(0xFFEF4444);
  static const Color redDark = Color(0xFF2D0D0D);
  static const Color redBdr = Color(0xFF7F1D1D);
  static const Color amber = Color(0xFFFBBF24);
  static const Color amberDark = Color(0xFF2D1F0F);
  static const Color orange = Color(0xFFFB923C);
  static const Color blue = Color(0xFF3B82F6);
  static const Color blueDark = Color(0xFF1E3A5F);
  static const Color teal = Color(0xFF14B8A6);
  static const Color indigo = Color(0xFF312E81);

  // Gradients
  static const LinearGradient primaryGrad = LinearGradient(
    colors: [primary, primaryLt],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient bgGrad = LinearGradient(
    colors: [surface, bg],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get theme => ThemeData(
    scaffoldBackgroundColor: bg,
    fontFamily: 'Roboto',
    colorScheme: const ColorScheme.dark(surface: surface, primary: primary),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: textBody,
        fontWeight: FontWeight.w800,
        fontSize: 22,
      ),
      headlineMedium: TextStyle(
        color: textBody,
        fontWeight: FontWeight.w800,
        fontSize: 18,
      ),
      bodyMedium: TextStyle(color: textMuted, fontSize: 14, height: 1.7),
      bodySmall: TextStyle(color: subtle, fontSize: 12),
    ),
  );
}

// ─── SHARED WIDGETS ───────────────────────────────────────────────────────────

class AppCard extends StatelessWidget {
  final Widget child;
  final Color? background;
  final Color? borderColor;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  const AppCard({
    super.key,
    required this.child,
    this.background,
    this.borderColor,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget w = Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background ?? AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor ?? AppTheme.border),
      ),
      child: child,
    );
    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: w);
    }
    return w;
  }
}

class PillBadge extends StatelessWidget {
  final String text;
  final Color bg, color;
  const PillBadge({
    super.key,
    required this.text,
    required this.bg,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGrad,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
  );
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.subtle,
        side: const BorderSide(color: AppTheme.border),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

class SectionLabel extends StatelessWidget {
  final String text, emoji;
  final Color bg, color;
  const SectionLabel({
    super.key,
    required this.text,
    required this.emoji,
    required this.bg,
    required this.color,
  });

  @override
  Widget build(BuildContext context) =>
      PillBadge(text: '$emoji $text', bg: bg, color: color);
}

class CheckBox extends StatelessWidget {
  final bool checked;
  final VoidCallback onTap;
  const CheckBox({super.key, required this.checked, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: checked ? AppTheme.green : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: checked ? AppTheme.green : AppTheme.muted,
          width: 2,
        ),
      ),
      child: checked
          ? const Icon(Icons.check, color: Colors.white, size: 14)
          : null,
    ),
  );
}

// Progress bar pill
class XpChip extends StatelessWidget {
  final int xp;
  const XpChip({super.key, required this.xp});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: AppTheme.card,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('⚡', style: TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(
          '$xp',
          style: const TextStyle(
            color: AppTheme.amber,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ],
    ),
  );
}
