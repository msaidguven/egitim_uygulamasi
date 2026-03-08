import 'package:flutter/material.dart';

// ─── THEME V3 — "QUEST MODE" ──────────────────────────────────────────────────
// Dark zemin + neon renkler + oyun havası

class AppTheme {
  // ── Zemin & Yüzeyler ────────────────────────────────────────────────────────
  static const Color bg = Color(0xFF0D0D1A);
  static const Color surface = Color(0xFF13132A);
  static const Color card = Color(0xFF1C1C3A);
  static const Color cardHi = Color(0xFF252550);
  static const Color border = Color(0xFF2E2E5A);
  static const Color muted = Color(0xFF4A4A7A);
  static const Color subtle = Color(0xFF7070AA);

  // ── Metin ───────────────────────────────────────────────────────────────────
  static const Color textBody = Color(0xFFEEEEFF);
  static const Color textMuted = Color(0xFF9090C0);

  // ── Ana Renk ─────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryLt = Color(0xFF1A0A3D);
  static const Color primaryGlow = Color(0xFFA855F7);

  // ── Step Neon Renkleri ────────────────────────────────────────────────────────
  static const Color intro = Color(0xFF00D4FF);
  static const Color introDk = Color(0xFF001C2E);
  static const Color introBdr = Color(0xFF0066AA);

  static const Color concept = Color(0xFF00FF88);
  static const Color conceptDk = Color(0xFF001A10);
  static const Color conceptBdr = Color(0xFF006640);

  static const Color scenario = Color(0xFFFF6B35);
  static const Color scenarioDk = Color(0xFF2A0F00);
  static const Color scenarioBdr = Color(0xFF8B3010);

  static const Color game = Color(0xFFCCFF00);
  static const Color gameDk = Color(0xFF1A2200);
  static const Color gameBdr = Color(0xFF557700);

  static const Color word = Color(0xFFFF2D78);
  static const Color wordDk = Color(0xFF2A0018);
  static const Color wordBdr = Color(0xFF8B0040);

  static const Color risk = Color(0xFFFFBB00);
  static const Color riskDk = Color(0xFF2A1E00);
  static const Color riskBdr = Color(0xFF8B6000);

  static const Color quiz = Color(0xFFBF5FFF);
  static const Color quizDk = Color(0xFF1A0030);
  static const Color quizBdr = Color(0xFF6B1AAA);

  static const Color reflect = Color(0xFF00E5CC);
  static const Color reflectDk = Color(0xFF001C18);
  static const Color reflectBdr = Color(0xFF007A6A);

  static const Color cert = Color(0xFFFFD700);
  static const Color certDk = Color(0xFF2A2000);
  static const Color certBdr = Color(0xFF8B7200);

  // ── İçerik Kartı Arka Planları (açık, okunabilir) ───────────────────────────
  // Koyu dark tema içinde metin okumak zorunda kalınan yerler için
  // hafif renkli, yazılar koyu siyah üzerine gelecek şekilde
  static const Color contentBg = Color(0xFFF0F4FF); // hafif mavi-gri
  static const Color contentBgBlue = Color(0xFFE8F4FD); // açık mavi
  static const Color contentBgGreen = Color(0xFFE8F8F0); // açık yeşil
  static const Color contentBgAmber = Color(0xFFFFF8E8); // açık sarı
  static const Color contentBgPurple = Color(0xFFF3EEFF); // açık mor
  static const Color contentBgTeal = Color(0xFFE8FAFA); // açık teal
  static const Color contentText = Color(
    0xFF1A1A2E,
  ); // koyu lacivert — okunabilir
  static const Color contentTextMid = Color(0xFF2D3561); // orta koyu
  static const Color contentTextSoft = Color(
    0xFF4A5080,
  ); // biraz yumuşak ama hâlâ okunabilir

  // ── Durum Renkleri ───────────────────────────────────────────────────────────
  static const Color green = Color(0xFF00FF88);
  static const Color greenDk = Color(0xFF001A10);
  static const Color greenBdr = Color(0xFF00AA55);
  static const Color red = Color(0xFFFF3366);
  static const Color redDk = Color(0xFF2A0012);
  static const Color redBdr = Color(0xFFAA1133);
  static const Color amber = Color(0xFFFFBB00);

  // ── Gradyanlar ──────────────────────────────────────────────────────────────
  static const LinearGradient primaryGrad = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFFBF5FFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient certGrad = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFF9500)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient introGrad = LinearGradient(
    colors: [Color(0xFF00D4FF), Color(0xFF0066FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient gameGrad = LinearGradient(
    colors: [Color(0xFFCCFF00), Color(0xFF00FF88)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient wordGrad = LinearGradient(
    colors: [Color(0xFFFF2D78), Color(0xFFBF5FFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get theme => ThemeData(
    scaffoldBackgroundColor: bg,
    fontFamily: 'Nunito',
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

// ─── FONT BOYUTU SİSTEMİ ─────────────────────────────────────────────────────
// Header'daki A-/A+ butonları bu notifier'ı günceller.
// Tüm içerik metinleri AppFontSize.of(context) ile boyutunu alır.

class FontSizeNotifier extends ChangeNotifier {
  double _scale = 1.0; // 1.0 = normal, 1.2 = büyük, 1.4 = en büyük

  double get scale => _scale;

  void increase() {
    if (_scale < 1.5) {
      _scale = (_scale + 0.15).clamp(0.7, 1.5);
      notifyListeners();
    }
  }

  void decrease() {
    if (_scale > 0.7) {
      _scale = (_scale - 0.15).clamp(0.7, 1.5);
      notifyListeners();
    }
  }

  bool get canIncrease => _scale < 1.5;
  bool get canDecrease => _scale > 0.7;
}

// Uygulamanın herhangi bir yerinden erişilebilir global instance
final fontSizeNotifier = FontSizeNotifier();

// İçerik metinlerinde kullan: AppFS.body, AppFS.title vb.
// fontSizeNotifier.scale ile çarpılmış değerler döner.
class AppFS {
  static double get body => 15 * fontSizeNotifier.scale;
  static double get bodyLg => 17 * fontSizeNotifier.scale;
  static double get label => 12 * fontSizeNotifier.scale;
  static double get labelLg => 13 * fontSizeNotifier.scale;
  static double get title => 20 * fontSizeNotifier.scale;
  static double get titleLg => 24 * fontSizeNotifier.scale;
  static double get small => 11 * fontSizeNotifier.scale;
}

// ─── SHARED WIDGETS ───────────────────────────────────────────────────────────

class AppCard extends StatelessWidget {
  final Widget child;
  final Color? background;
  final Color? borderColor;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final double? radius;
  final bool glowing;

  const AppCard({
    super.key,
    required this.child,
    this.background,
    this.borderColor,
    this.padding,
    this.onTap,
    this.radius,
    this.glowing = false,
  });

  @override
  Widget build(BuildContext context) {
    final col = borderColor ?? AppTheme.border;
    Widget w = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background ?? AppTheme.card,
        borderRadius: BorderRadius.circular(radius ?? 16),
        border: Border.all(color: col, width: 1.5),
        boxShadow: glowing
            ? [
                BoxShadow(
                  color: col.withValues(alpha: 0.45),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: col.withValues(alpha: 0.15),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: child,
    );
    if (onTap != null) return GestureDetector(onTap: onTap, child: w);
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
      border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        shadows: [Shadow(color: color.withValues(alpha: 0.6), blurRadius: 6)],
      ),
    ),
  );
}

class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final Color? color;
  final LinearGradient? gradient;
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
    this.gradient,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final col = widget.color ?? AppTheme.primary;
    final grad =
        widget.gradient ??
        (widget.color != null
            ? LinearGradient(
                colors: [
                  col,
                  HSLColor.fromColor(col)
                      .withLightness(
                        (HSLColor.fromColor(col).lightness + 0.12).clamp(0, 1),
                      )
                      .toColor(),
                ],
              )
            : AppTheme.primaryGrad);

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: SizedBox(
          width: double.infinity,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: grad,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: col.withValues(alpha: 0.55),
                  blurRadius: 20,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: col.withValues(alpha: 0.2),
                  blurRadius: 40,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
              ),
            ),
          ),
        ),
      ),
    );
  }
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
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
        boxShadow: checked
            ? [
                BoxShadow(
                  color: AppTheme.green.withValues(alpha: 0.5),
                  blurRadius: 8,
                ),
              ]
            : [],
      ),
      child: checked
          ? const Icon(Icons.check, color: Colors.black, size: 15)
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
          color: AppTheme.cert.withValues(alpha: 0.6),
          blurRadius: 14,
          spreadRadius: 1,
        ),
      ],
      border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('⚡', style: TextStyle(fontSize: 13)),
        const SizedBox(width: 4),
        Text(
          '$xp XP',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 12,
            shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
          ),
        ),
      ],
    ),
  );
}

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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colorLt,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: color.withValues(alpha: 0.6), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Text(
          '$emoji  $label',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            shadows: [
              Shadow(color: color.withValues(alpha: 0.8), blurRadius: 6),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      Text(
        title,
        style: TextStyle(
          color: AppTheme.textBody,
          fontSize: 21,
          fontWeight: FontWeight.w800,
          height: 1.3,
          shadows: [
            Shadow(color: color.withValues(alpha: 0.3), blurRadius: 14),
          ],
        ),
      ),
    ],
  );
}

class NeonDivider extends StatelessWidget {
  final Color color;
  const NeonDivider({super.key, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    height: 1,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.transparent,
          color.withValues(alpha: 0.6),
          color,
          color.withValues(alpha: 0.6),
          Colors.transparent,
        ],
      ),
      boxShadow: [
        BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6),
      ],
    ),
  );
}

class PixelCounter extends StatelessWidget {
  final String value, label;
  final Color color;
  const PixelCounter({
    super.key,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: AppTheme.card,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      boxShadow: [
        BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 14),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 22,
            shadows: [Shadow(color: color, blurRadius: 10)],
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
