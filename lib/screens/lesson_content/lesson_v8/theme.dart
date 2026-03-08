import 'package:flutter/material.dart';

// ─── THEME V4 — "QUEST MODE — BRIGHT" ────────────────────────────────────────
// Sınıf ortamında okunabilir: koyu değil, orta-açık tonda,
// turuncu/yeşil/mavi cıvıl renkler, beyaz üzerine koyu yazı

class AppTheme {
  // ── Zemin & Yüzeyler ──────────────────────────────────────────────────────
  static const Color bg      = Color(0xFF1A1A2E); // derin lacivert (çok koyu değil)
  static const Color surface = Color(0xFF22223B); // yüzey
  static const Color card    = Color(0xFF2D2D4E); // kart
  static const Color border  = Color(0xFF3D3D6B); // çerçeve
  static const Color muted   = Color(0xFF6B6B9A); // soluk
  static const Color subtle  = Color(0xFF9090BB); // orta

  // ── Metin (dark alan için) ─────────────────────────────────────────────────
  static const Color textBody  = Color(0xFFF0F0FF);
  static const Color textMuted = Color(0xFFAAAAAA);

  // ── İçerik kutuları — açık, güneşte okunabilir ────────────────────────────
  static const Color cBg        = Color(0xFFFFFFFF); // saf beyaz
  static const Color cBgBlue    = Color(0xFFE3F2FD); // açık mavi
  static const Color cBgGreen   = Color(0xFFE8F5E9); // açık yeşil
  static const Color cBgOrange  = Color(0xFFFFF3E0); // açık turuncu
  static const Color cBgPurple  = Color(0xFFF3E5F5); // açık mor
  static const Color cBgTeal    = Color(0xFFE0F7FA); // açık teal
  static const Color cBgYellow  = Color(0xFFFFFDE7); // açık sarı
  static const Color cBgPink    = Color(0xFFFCE4EC); // açık pembe
  static const Color cText      = Color(0xFF1A1A2E); // koyu lacivert — siyaha yakın
  static const Color cTextMid   = Color(0xFF2D3561); // orta koyu
  static const Color cTextSoft  = Color(0xFF4A5080); // biraz yumuşak

  // ── Ana renk ──────────────────────────────────────────────────────────────
  static const Color primary     = Color(0xFF5B4FE8);
  static const Color primaryLt   = Color(0xFFEDE9FF);
  static const Color primaryGlow = Color(0xFF7C6FFF);

  // ── Step renkleri (canlı ama sınıfta görünür) ────────────────────────────
  // intro — gökyüzü mavisi
  static const Color intro    = Color(0xFF0288D1);
  static const Color introDk  = Color(0xFF01579B);
  static const Color introLt  = Color(0xFFE3F2FD);
  static const Color introBdr = Color(0xFF4FC3F7);

  // concept — canlı yeşil
  static const Color concept    = Color(0xFF00897B);
  static const Color conceptDk  = Color(0xFF00695C);
  static const Color conceptLt  = Color(0xFFE0F7FA);
  static const Color conceptBdr = Color(0xFF4DB6AC);

  // scenario — canlı turuncu
  static const Color scenario    = Color(0xFFE65100);
  static const Color scenarioDk  = Color(0xFFBF360C);
  static const Color scenarioLt  = Color(0xFFFFF3E0);
  static const Color scenarioBdr = Color(0xFFFF8A65);

  // game — limon yeşil → koyu yeşile
  static const Color game    = Color(0xFF558B2F);
  static const Color gameDk  = Color(0xFF33691E);
  static const Color gameLt  = Color(0xFFF9FBE7);
  static const Color gameBdr = Color(0xFF9CCC65);

  // word — sıcak pembe
  static const Color word    = Color(0xFFC2185B);
  static const Color wordDk  = Color(0xFF880E4F);
  static const Color wordLt  = Color(0xFFFCE4EC);
  static const Color wordBdr = Color(0xFFF48FB1);

  // risk — altın turuncu
  static const Color risk    = Color(0xFFF57F17);
  static const Color riskDk  = Color(0xFFE65100);
  static const Color riskLt  = Color(0xFFFFFDE7);
  static const Color riskBdr = Color(0xFFFFCC02);

  // quiz — mor
  static const Color quiz    = Color(0xFF6A1B9A);
  static const Color quizDk  = Color(0xFF4A148C);
  static const Color quizLt  = Color(0xFFF3E5F5);
  static const Color quizBdr = Color(0xFFCE93D8);

  // reflect — teal
  static const Color reflect    = Color(0xFF00796B);
  static const Color reflectDk  = Color(0xFF004D40);
  static const Color reflectLt  = Color(0xFFE0F7FA);
  static const Color reflectBdr = Color(0xFF4DB6AC);

  // cert — altın
  static const Color cert    = Color(0xFFF9A825);
  static const Color certDk  = Color(0xFFF57F17);
  static const Color certLt  = Color(0xFFFFFDE7);
  static const Color certBdr = Color(0xFFFFD54F);

  // ── Durum renkleri ─────────────────────────────────────────────────────────
  static const Color green    = Color(0xFF2E7D32);
  static const Color greenLt  = Color(0xFFE8F5E9);
  static const Color greenBdr = Color(0xFF81C784);
  static const Color red      = Color(0xFFC62828);
  static const Color redLt    = Color(0xFFFFEBEE);
  static const Color redBdr   = Color(0xFFEF9A9A);
  static const Color amber    = Color(0xFFF9A825);

  // ── Gradyanlar ─────────────────────────────────────────────────────────────
  static const LinearGradient primaryGrad = LinearGradient(
    colors: [Color(0xFF5B4FE8), Color(0xFF9C6FFF)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient certGrad = LinearGradient(
    colors: [Color(0xFFF9A825), Color(0xFFFF6F00)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient introGrad = LinearGradient(
    colors: [Color(0xFF0288D1), Color(0xFF01579B)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient gameGrad = LinearGradient(
    colors: [Color(0xFF558B2F), Color(0xFF00897B)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient wordGrad = LinearGradient(
    colors: [Color(0xFFC2185B), Color(0xFF6A1B9A)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  static ThemeData get theme => ThemeData(
    scaffoldBackgroundColor: bg,
    fontFamily: 'Nunito',
    colorScheme: const ColorScheme.dark(surface: surface, primary: primary),
    textTheme: const TextTheme(
      headlineLarge:  TextStyle(color: textBody, fontWeight: FontWeight.w800, fontSize: 22),
      headlineMedium: TextStyle(color: textBody, fontWeight: FontWeight.w800, fontSize: 18),
      bodyMedium: TextStyle(color: textMuted, fontSize: 14, height: 1.7),
      bodySmall:  TextStyle(color: subtle,    fontSize: 12),
    ),
  );
}

// ─── FONT BOYUTU SİSTEMİ ─────────────────────────────────────────────────────
class FontSizeNotifier extends ChangeNotifier {
  double _scale = 1.0;
  double get scale => _scale;

  void increase() {
    if (_scale < 1.5) { _scale = (_scale + 0.15).clamp(0.7, 1.5); notifyListeners(); }
  }
  void decrease() {
    if (_scale > 0.7) { _scale = (_scale - 0.15).clamp(0.7, 1.5); notifyListeners(); }
  }
  bool get canIncrease => _scale < 1.5;
  bool get canDecrease => _scale > 0.7;
}

final fontSizeNotifier = FontSizeNotifier();

// Kullanım: AppFS.body, AppFS.title vb.
class AppFS {
  static double get body    => 15 * fontSizeNotifier.scale;
  static double get bodyLg  => 17 * fontSizeNotifier.scale;
  static double get label   => 12 * fontSizeNotifier.scale;
  static double get labelLg => 13 * fontSizeNotifier.scale;
  static double get title   => 20 * fontSizeNotifier.scale;
  static double get titleLg => 24 * fontSizeNotifier.scale;
  static double get small   => 11 * fontSizeNotifier.scale;
  static double get btn     => 15 * fontSizeNotifier.scale;
  static double get chip    => 11 * fontSizeNotifier.scale;
}

// ─── SHARED WIDGETS ───────────────────────────────────────────────────────────

/// Gölgeli kart — hem dark hem light bg için
class AppCard extends StatelessWidget {
  final Widget child;
  final Color? background;
  final Color? borderColor;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final double? radius;
  final bool glowing;

  const AppCard({
    super.key, required this.child,
    this.background, this.borderColor, this.padding,
    this.onTap, this.radius, this.glowing = false,
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
            ? [BoxShadow(color: col.withValues(alpha: 0.4), blurRadius: 16, spreadRadius: 1)]
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))],
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
  const PillBadge({super.key, required this.text, required this.bg, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: bg, borderRadius: BorderRadius.circular(99),
      border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
    ),
    child: AnimatedBuilder(
      animation: fontSizeNotifier,
      builder: (_, __) => Text(text, style: TextStyle(color: color, fontSize: AppFS.chip, fontWeight: FontWeight.w800)),
    ),
  );
}

/// Büyük buton — AppFS.btn ile yazı büyür
class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final Color? color;
  final LinearGradient? gradient;
  const PrimaryButton({super.key, required this.label, required this.onPressed, this.color, this.gradient});

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100), lowerBound: 0, upperBound: 1);
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final col = widget.color ?? AppTheme.primary;
    final grad = widget.gradient ??
        (widget.color != null
            ? LinearGradient(colors: [col, HSLColor.fromColor(col).withLightness((HSLColor.fromColor(col).lightness + 0.1).clamp(0, 1)).toColor()])
            : AppTheme.primaryGrad);

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onPressed(); },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_scale, fontSizeNotifier]),
        builder: (_, __) => Transform.scale(
          scale: _scale.value,
          child: SizedBox(
            width: double.infinity,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: grad, borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: col.withValues(alpha: 0.45), blurRadius: 16, offset: const Offset(0, 4))],
                border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
              ),
              alignment: Alignment.center,
              child: Text(widget.label, style: TextStyle(
                color: Colors.white, fontSize: AppFS.btn, fontWeight: FontWeight.w800, letterSpacing: 0.3,
              )),
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
  const SecondaryButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: fontSizeNotifier,
    builder: (_, __) => SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.subtle,
          side: const BorderSide(color: AppTheme.border, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(label, style: TextStyle(fontSize: AppFS.btn, fontWeight: FontWeight.w700)),
      ),
    ),
  );
}

class SectionLabel extends StatelessWidget {
  final String text, emoji;
  final Color bg, color;
  const SectionLabel({super.key, required this.text, required this.emoji, required this.bg, required this.color});

  @override
  Widget build(BuildContext context) => PillBadge(text: '$emoji $text', bg: bg, color: color);
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
      width: 26, height: 26,
      decoration: BoxDecoration(
        color: checked ? AppTheme.green : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: checked ? AppTheme.green : AppTheme.border, width: 2),
        boxShadow: checked ? [BoxShadow(color: AppTheme.green.withValues(alpha: 0.4), blurRadius: 8)] : [],
      ),
      child: checked ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
    ),
  );
}

class XpChip extends StatelessWidget {
  final int xp;
  const XpChip({super.key, required this.xp});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: fontSizeNotifier,
    builder: (_, __) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: AppTheme.certGrad, borderRadius: BorderRadius.circular(99),
        boxShadow: [BoxShadow(color: AppTheme.cert.withValues(alpha: 0.5), blurRadius: 12)],
        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Text('⚡', style: TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Text('$xp XP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: AppFS.chip)),
      ]),
    ),
  );
}

class StepHeader extends StatelessWidget {
  final String emoji, label, title;
  final Color color, colorLt;

  const StepHeader({super.key, required this.emoji, required this.label, required this.title, required this.color, required this.colorLt});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: fontSizeNotifier,
    builder: (_, __) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colorLt, borderRadius: BorderRadius.circular(99),
            border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 8)],
          ),
          child: Text('$emoji  $label', style: TextStyle(color: color, fontSize: AppFS.small, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(height: 10),
        Text(title, style: TextStyle(color: AppTheme.textBody, fontSize: AppFS.title, fontWeight: FontWeight.w800, height: 1.3)),
      ],
    ),
  );
}

class NeonDivider extends StatelessWidget {
  final Color color;
  const NeonDivider({super.key, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    height: 2,
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [Colors.transparent, color, color, Colors.transparent]),
      borderRadius: BorderRadius.circular(99),
      boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6)],
    ),
  );
}
