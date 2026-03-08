import 'package:flutter/material.dart';

// ─── THEME V2 — "Akıllı Defter" ───────────────────────────────────────────────
// Canlı & renkli, 11-15 yaş, beyaz zemin, her step tipi kendi rengi

class AppTheme {
  // ── Zemin & Yüzeyler ────────────────────────────────────────────────────────
  static const Color bg       = Color(0xFFF8F7F4);   // krem beyaz
  static const Color surface  = Color(0xFFFFFFFF);
  static const Color card     = Color(0xFFFFFFFF);
  static const Color border   = Color(0xFFE8E4DC);
  static const Color muted    = Color(0xFFB8B0A4);
  static const Color subtle   = Color(0xFF8C8478);

  // ── Metin ───────────────────────────────────────────────────────────────────
  static const Color textBody = Color(0xFF1A1714);
  static const Color textMuted= Color(0xFF5C5752);

  // ── Ana Renk — Mor/İndigo ────────────────────────────────────────────────────
  static const Color primary  = Color(0xFF6C47FF);
  static const Color primaryLt= Color(0xFFEDE8FF);
  static const Color primaryMd= Color(0xFFBBA9FF);

  // ── Step Renkleri ────────────────────────────────────────────────────────────
  static const Color intro    = Color(0xFF6C47FF);  // mor — giriş
  static const Color introLt  = Color(0xFFEDE8FF);
  static const Color concept  = Color(0xFF0EA5E9);  // mavi — kavram
  static const Color conceptLt= Color(0xFFE0F2FE);
  static const Color scenario = Color(0xFFF97316);  // turuncu — senaryo
  static const Color scenarioLt=Color(0xFFFFF0E6);
  static const Color game     = Color(0xFF10B981);  // yeşil — oyun
  static const Color gameLt   = Color(0xFFD1FAE5);
  static const Color word     = Color(0xFFEC4899);  // pembe — kelime
  static const Color wordLt   = Color(0xFFFCE7F3);
  static const Color risk     = Color(0xFFF59E0B);  // amber — risk
  static const Color riskLt   = Color(0xFFFEF3C7);
  static const Color quiz     = Color(0xFF8B5CF6);  // mor-violet — quiz
  static const Color quizLt   = Color(0xFFEDE9FE);
  static const Color reflect  = Color(0xFF14B8A6);  // teal — yansıma
  static const Color reflectLt= Color(0xFFCCFBF1);
  static const Color cert     = Color(0xFFF59E0B);  // altın — sertifika
  static const Color certLt   = Color(0xFFFEF9C3);

  // ── Durum Renkleri ───────────────────────────────────────────────────────────
  static const Color green    = Color(0xFF16A34A);
  static const Color greenLt  = Color(0xFFDCFCE7);
  static const Color greenMd  = Color(0xFF86EFAC);
  static const Color red      = Color(0xFFDC2626);
  static const Color redLt    = Color(0xFFFEE2E2);
  static const Color amber    = Color(0xFFD97706);
  static const Color amberLt  = Color(0xFFFEF3C7);

  // ── Gradyanlar ──────────────────────────────────────────────────────────────
  static const LinearGradient primaryGrad = LinearGradient(
    colors: [Color(0xFF6C47FF), Color(0xFFA78BFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient headerGrad = LinearGradient(
    colors: [Color(0xFF6C47FF), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient certGrad = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get theme => ThemeData(
    scaffoldBackgroundColor: bg,
    fontFamily: 'Nunito',
    colorScheme: const ColorScheme.light(
      surface: surface,
      primary: primary,
    ),
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
  final double? radius;

  const AppCard({
    super.key,
    required this.child,
    this.background,
    this.borderColor,
    this.padding,
    this.onTap,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    Widget w = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background ?? AppTheme.card,
        borderRadius: BorderRadius.circular(radius ?? 16),
        border: Border.all(
          color: borderColor ?? AppTheme.border,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color? color;
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: Container(
      decoration: BoxDecoration(
        gradient: color != null
            ? LinearGradient(colors: [color!, color!])
            : AppTheme.primaryGrad,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: (color ?? AppTheme.primary).withValues(alpha: 0.3),
            blurRadius: 16,
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
            fontWeight: FontWeight.w800,
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
        side: const BorderSide(color: AppTheme.border, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
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
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: checked ? AppTheme.green : Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: checked ? AppTheme.green : AppTheme.border,
          width: 2,
        ),
      ),
      child: checked
          ? const Icon(Icons.check, color: Colors.white, size: 15)
          : null,
    ),
  );
}

class XpChip extends StatelessWidget {
  final int xp;
  const XpChip({super.key, required this.xp});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      gradient: AppTheme.certGrad,
      borderRadius: BorderRadius.circular(99),
      boxShadow: [
        BoxShadow(
          color: AppTheme.amber.withValues(alpha: 0.3),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('⚡', style: TextStyle(fontSize: 13)),
        const SizedBox(width: 4),
        Text(
          '$xp',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ],
    ),
  );
}

// ─── STEP HEADER ─────────────────────────────────────────────────────────────
// Her screen'in üstünde emoji + başlık + renk bandı

class StepHeader extends StatelessWidget {
  final String emoji, label, title;
  final Color color, colorLt;
  const StepHeader({
    super.key,
    required this.emoji,
    required this.label,
    required this.title,
    required this.color,
    required this.colorLt,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: colorLt,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          '$emoji $label',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const SizedBox(height: 10),
      Text(
        title,
        style: TextStyle(
          color: AppTheme.textBody,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          height: 1.3,
        ),
      ),
    ],
  );
}
