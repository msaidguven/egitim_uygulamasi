import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// THEME V5 ─ DARK (🌙 Quest Mode) + LIGHT (☀️ Cıvıl Sınıf Modu)
//
// Kullanım:
//   final tc = TC.of(context);   // build() içinde
//   tc.card, tc.textBody, tc.cBgBlue ...
//
// Accent renkler (her iki temada aynı):
//   AppTheme.intro, AppTheme.concept, AppTheme.quiz ...
// ═══════════════════════════════════════════════════════════════════════════════

// ─── TEMA BİLDİRİMCİSİ ────────────────────────────────────────────────────────
class ThemeNotifier extends ChangeNotifier {
  bool _dark = false;
  bool get isDark => _dark;
  void toggle() {
    _dark = !_dark;
    notifyListeners();
  }
}

final themeNotifier = ThemeNotifier();

// ─── FONT BOYUTU ───────────────────────────────────────────────────────────────
class FontSizeNotifier extends ChangeNotifier {
  double _scale = 1.0;
  static const double _minScale = 0.7;
  static const double _maxScale = 5.0;
  double get scale => _scale;
  void increase() {
    if (_scale < _maxScale) {
      _scale = (_scale + 0.15).clamp(_minScale, _maxScale);
      notifyListeners();
    }
  }

  void decrease() {
    if (_scale > _minScale) {
      _scale = (_scale - 0.15).clamp(_minScale, _maxScale);
      notifyListeners();
    }
  }

  bool get canIncrease => _scale < _maxScale;
  bool get canDecrease => _scale > _minScale;
}

final fontSizeNotifier = FontSizeNotifier();

class AppFS {
  static double get body => 15 * fontSizeNotifier.scale;
  static double get bodyLg => 17 * fontSizeNotifier.scale;
  static double get label => 12 * fontSizeNotifier.scale;
  static double get labelLg => 13 * fontSizeNotifier.scale;
  static double get title => 20 * fontSizeNotifier.scale;
  static double get titleLg => 24 * fontSizeNotifier.scale;
  static double get small => 11 * fontSizeNotifier.scale;
  static double get btn => 15 * fontSizeNotifier.scale;
  static double get chip => 11 * fontSizeNotifier.scale;
}

// ─── TC ─ TEMA RENK TOKENLERİ (context tabanlı) ───────────────────────────────
// screens.dart + main.dart:  final tc = TC.of(context);
class TC {
  final bool isDark;
  const TC._(this.isDark);
  factory TC.of(BuildContext context) => TC._(themeNotifier.isDark);

  // ── Zemin & Yüzey ────────────────────────────────────────────────────────
  Color get bg => isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F8FF);
  Color get surface =>
      isDark ? const Color(0xFF22223B) : const Color(0xFFFFFFFF);
  Color get card => isDark ? const Color(0xFF2D2D4E) : const Color(0xFFFFFFFF);
  Color get border =>
      isDark ? const Color(0xFF3D3D6B) : const Color(0xFFCDD5F0);
  Color get muted => isDark ? const Color(0xFF6B6B9A) : const Color(0xFF9090BB);
  Color get subtle =>
      isDark ? const Color(0xFF9090BB) : const Color(0xFF6B6B9A);

  // ── Metin ────────────────────────────────────────────────────────────────
  Color get textBody =>
      isDark ? const Color(0xFFF0F0FF) : const Color(0xFF1A1A2E);
  Color get textMuted =>
      isDark ? const Color(0xFFAAAAAA) : const Color(0xFF5A5A80);

  // ── İçerik kutuları ───────────────────────────────────────────────────────
  // Dark: koyu pastel  /  Light: parlak cıvıl renkler
  Color get cBg => isDark ? const Color(0xFF252545) : const Color(0xFFFFFFFF);
  Color get cBgBlue =>
      isDark ? const Color(0xFF0D1E30) : const Color(0xFFD6EEFF);
  Color get cBgGreen =>
      isDark ? const Color(0xFF0A2012) : const Color(0xFFCCF5DD);
  Color get cBgOrange =>
      isDark ? const Color(0xFF2A1400) : const Color(0xFFFFE8CC);
  Color get cBgPurple =>
      isDark ? const Color(0xFF1C0A35) : const Color(0xFFEBDEFF);
  Color get cBgTeal =>
      isDark ? const Color(0xFF002825) : const Color(0xFFCCF2EE);
  Color get cBgYellow =>
      isDark ? const Color(0xFF221800) : const Color(0xFFFFF4CC);
  Color get cBgPink =>
      isDark ? const Color(0xFF280010) : const Color(0xFFFFD6E8);

  // ── İçerik kutusu metin ───────────────────────────────────────────────────
  Color get cText => isDark ? const Color(0xFFF0F0FF) : const Color(0xFF1A1A2E);
  Color get cTextMid =>
      isDark ? const Color(0xFFCCCCEE) : const Color(0xFF2D3561);
  Color get cTextSoft =>
      isDark ? const Color(0xFF9090BB) : const Color(0xFF4A5080);

  // ── Durum ─────────────────────────────────────────────────────────────────
  Color get green => isDark ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32);
  Color get greenLt =>
      isDark ? const Color(0xFF0D200D) : const Color(0xFFCCF5DD);
  Color get greenBdr => const Color(0xFF81C784);
  Color get red => isDark ? const Color(0xFFEF5350) : const Color(0xFFC62828);
  Color get redLt => isDark ? const Color(0xFF200808) : const Color(0xFFFFD6D6);
  Color get redBdr => const Color(0xFFEF9A9A);

  // ── Light temada sayfa arka planı (adım tipine göre cıvıl gradyan) ────────
  Decoration pageDecoration(String stepType) {
    if (isDark) return const BoxDecoration(color: Color(0xFF1A1A2E));
    final colors = switch (stepType) {
      'intro' => [const Color(0xFFD6EEFF), const Color(0xFFCCF5DD)],
      'concept_cards' => [const Color(0xFFCCF5DD), const Color(0xFFCCF2EE)],
      'risk_analysis' => [const Color(0xFFFFF4CC), const Color(0xFFFFE8CC)],
      'scenario_choice' => [const Color(0xFFFFE8CC), const Color(0xFFFFD6E8)],
      'role_play' => [const Color(0xFFFFE0CC), const Color(0xFFEBDEFF)],
      'mini_game' => [const Color(0xFFD6F5CC), const Color(0xFFF0FFD6)],
      'word_bank' => [const Color(0xFFFFD6E8), const Color(0xFFEBDEFF)],
      'quiz' => [const Color(0xFFEBDEFF), const Color(0xFFD6EEFF)],
      'critical_thinking' => [const Color(0xFFEBDEFF), const Color(0xFFD6EEFF)],
      'reflection' => [const Color(0xFFCCF2EE), const Color(0xFFD6EEFF)],
      'summary' => [const Color(0xFFD6EEFF), const Color(0xFFEBDEFF)],
      'certificate' => [const Color(0xFFFFF4CC), const Color(0xFFFFE8CC)],
      _ => [const Color(0xFFD6EEFF), const Color(0xFFCCF5DD)],
    };
    return BoxDecoration(
      gradient: LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }
}

// ─── AppTheme ─ MEVCUT KOD UYUMU (accent renkler değişmiyor) ─────────────────
class AppTheme {
  static const Color bg = Color(0xFF1A1A2E);
  static const Color surface = Color(0xFF22223B);
  static const Color card = Color(0xFF2D2D4E);
  static const Color border = Color(0xFF3D3D6B);
  static const Color muted = Color(0xFF6B6B9A);
  static const Color subtle = Color(0xFF9090BB);
  static const Color textBody = Color(0xFFF0F0FF);
  static const Color textMuted = Color(0xFFAAAAAA);
  static const Color cBg = Color(0xFFFFFFFF);
  static const Color cBgBlue = Color(0xFFE3F2FD);
  static const Color cBgGreen = Color(0xFFE8F5E9);
  static const Color cBgOrange = Color(0xFFFFF3E0);
  static const Color cBgPurple = Color(0xFFF3E5F5);
  static const Color cBgTeal = Color(0xFFE0F7FA);
  static const Color cBgYellow = Color(0xFFFFFDE7);
  static const Color cBgPink = Color(0xFFFCE4EC);
  static const Color cText = Color(0xFF1A1A2E);
  static const Color cTextMid = Color(0xFF2D3561);
  static const Color cTextSoft = Color(0xFF4A5080);
  static const Color primary = Color(0xFF5B4FE8);
  static const Color primaryLt = Color(0xFFEDE9FF);
  static const Color primaryGlow = Color(0xFF7C6FFF);
  // ── Accent renkler (her iki temada aynı) ─────────────────────────────────
  static const Color intro = Color(0xFF0288D1);
  static const Color introDk = Color(0xFF01579B);
  static const Color introLt = Color(0xFFD6EEFF);
  static const Color introBdr = Color(0xFF4FC3F7);
  static const Color concept = Color(0xFF00897B);
  static const Color conceptDk = Color(0xFF00695C);
  static const Color conceptLt = Color(0xFFCCF2EE);
  static const Color conceptBdr = Color(0xFF4DB6AC);
  static const Color scenario = Color(0xFFE65100);
  static const Color scenarioDk = Color(0xFFBF360C);
  static const Color scenarioLt = Color(0xFFFFE8CC);
  static const Color scenarioBdr = Color(0xFFFF8A65);
  static const Color game = Color(0xFF558B2F);
  static const Color gameDk = Color(0xFF33691E);
  static const Color gameLt = Color(0xFFD6F5CC);
  static const Color gameBdr = Color(0xFF9CCC65);
  static const Color word = Color(0xFFC2185B);
  static const Color wordDk = Color(0xFF880E4F);
  static const Color wordLt = Color(0xFFFFD6E8);
  static const Color wordBdr = Color(0xFFF48FB1);
  static const Color risk = Color(0xFFF57F17);
  static const Color riskDk = Color(0xFFE65100);
  static const Color riskLt = Color(0xFFFFF4CC);
  static const Color riskBdr = Color(0xFFFFCC02);
  static const Color quiz = Color(0xFF6A1B9A);
  static const Color quizDk = Color(0xFF4A148C);
  static const Color quizLt = Color(0xFFEBDEFF);
  static const Color quizBdr = Color(0xFFCE93D8);
  static const Color reflect = Color(0xFF00796B);
  static const Color reflectDk = Color(0xFF004D40);
  static const Color reflectLt = Color(0xFFCCF2EE);
  static const Color reflectBdr = Color(0xFF4DB6AC);
  static const Color cert = Color(0xFFF9A825);
  static const Color certDk = Color(0xFFF57F17);
  static const Color certLt = Color(0xFFFFF4CC);
  static const Color certBdr = Color(0xFFFFD54F);
  static const Color green = Color(0xFF2E7D32);
  static const Color greenLt = Color(0xFFCCF5DD);
  static const Color greenBdr = Color(0xFF81C784);
  static const Color red = Color(0xFFC62828);
  static const Color redLt = Color(0xFFFFD6D6);
  static const Color redBdr = Color(0xFFEF9A9A);
  static const Color amber = Color(0xFFF9A825);
  static const LinearGradient primaryGrad = LinearGradient(
    colors: [Color(0xFF5B4FE8), Color(0xFF9C6FFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient certGrad = LinearGradient(
    colors: [Color(0xFFF9A825), Color(0xFFFF6F00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient introGrad = LinearGradient(
    colors: [Color(0xFF0288D1), Color(0xFF01579B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient gameGrad = LinearGradient(
    colors: [Color(0xFF558B2F), Color(0xFF00897B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient wordGrad = LinearGradient(
    colors: [Color(0xFFC2185B), Color(0xFF6A1B9A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get theme => _build(true);
  static ThemeData get lightTheme => _build(false);
  static ThemeData _build(bool dark) => ThemeData(
    scaffoldBackgroundColor: dark ? bg : const Color(0xFFF5F8FF),
    fontFamily: 'Nunito',
    colorScheme: dark
        ? const ColorScheme.dark(surface: surface, primary: primary)
        : ColorScheme.light(surface: Colors.white, primary: primary),
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        color: dark ? textBody : const Color(0xFF1A1A2E),
        fontWeight: FontWeight.w800,
        fontSize: 22,
      ),
      headlineMedium: TextStyle(
        color: dark ? textBody : const Color(0xFF1A1A2E),
        fontWeight: FontWeight.w800,
        fontSize: 18,
      ),
      bodyMedium: TextStyle(
        color: dark ? textMuted : const Color(0xFF5A5A80),
        fontSize: 14,
        height: 1.7,
      ),
      bodySmall: TextStyle(
        color: dark ? subtle : const Color(0xFF6B6B9A),
        fontSize: 12,
      ),
    ),
  );
}

// ─── SHARED WIDGETS ───────────────────────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final Color? background, borderColor;
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
    final tc = TC.of(context);
    final col = borderColor ?? tc.border;
    Widget w = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background ?? tc.card,
        borderRadius: BorderRadius.circular(radius ?? 16),
        border: Border.all(color: col, width: 1.5),
        boxShadow: glowing
            ? [
                BoxShadow(
                  color: col.withValues(alpha: 0.4),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
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
      border: Border.all(color: color.withValues(alpha: 0.5)),
    ),
    child: AnimatedBuilder(
      animation: fontSizeNotifier,
      builder: (_, __) => Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: AppFS.chip,
          fontWeight: FontWeight.w800,
        ),
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
      lowerBound: 0,
      upperBound: 1,
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
                        (HSLColor.fromColor(col).lightness + 0.1).clamp(0, 1),
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
        animation: Listenable.merge([_scale, fontSizeNotifier]),
        builder: (_, __) => Transform.scale(
          scale: _scale.value,
          child: SizedBox(
            width: double.infinity,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: grad,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: col.withValues(alpha: 0.45),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                widget.label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: AppFS.btn,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
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
  Widget build(BuildContext context) {
    final tc = TC.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([fontSizeNotifier, themeNotifier]),
      builder: (_, __) => SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: tc.subtle,
            side: BorderSide(color: tc.border, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: AppFS.btn, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
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
        gradient: AppTheme.certGrad,
        borderRadius: BorderRadius.circular(99),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cert.withValues(alpha: 0.5),
            blurRadius: 12,
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⚡', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            '$xp XP',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: AppFS.chip,
            ),
          ),
        ],
      ),
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
  Widget build(BuildContext context) {
    final tc = TC.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([fontSizeNotifier, themeNotifier]),
      builder: (_, __) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorLt,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 8),
              ],
            ),
            child: Text(
              '$emoji  $label',
              style: TextStyle(
                color: color,
                fontSize: AppFS.small,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: tc.textBody,
              fontSize: AppFS.title,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class NeonDivider extends StatelessWidget {
  final Color color;
  const NeonDivider({super.key, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    height: 2,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.transparent, color, color, Colors.transparent],
      ),
      borderRadius: BorderRadius.circular(99),
      boxShadow: [
        BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6),
      ],
    ),
  );
}

class CheckBox extends StatelessWidget {
  final bool checked;
  final VoidCallback onTap;
  const CheckBox({super.key, required this.checked, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final tc = TC.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: checked ? tc.green : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: checked ? tc.green : tc.border, width: 2),
          boxShadow: checked
              ? [
                  BoxShadow(
                    color: tc.green.withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ]
              : [],
        ),
        child: checked
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : null,
      ),
    );
  }
}
