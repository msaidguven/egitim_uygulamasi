import 'package:flutter/material.dart';
import 'theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SLIDE STEP SCREEN
// JSON'daki content.slides listesini birer birer sunum gibi gösterir.
// Her slide ayrı bir ekran — kullanıcı İLERİ butonuyla ilerler.
//
// Desteklenen slide type'ları:
//   hook | fact | analogy | example | key | bridge
// ─────────────────────────────────────────────────────────────────────────────

class SlideStepScreen extends StatefulWidget {
  final List<Map<String, String>> slides;
  final Color accentColor;
  final Color accentColorLt;
  final String stepLabel;
  final String stepEmoji;
  final String title;
  final VoidCallback onComplete;

  const SlideStepScreen({
    super.key,
    required this.slides,
    required this.accentColor,
    required this.accentColorLt,
    required this.stepLabel,
    required this.stepEmoji,
    required this.title,
    required this.onComplete,
  });

  @override
  State<SlideStepScreen> createState() => _SlideStepScreenState();
}

class _SlideStepScreenState extends State<SlideStepScreen>
    with TickerProviderStateMixin {
  int _current = 0;
  late AnimationController _fadeCtrl;
  late AnimationController _slideCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.06, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _fadeCtrl.forward();
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_current >= widget.slides.length - 1) {
      widget.onComplete();
      return;
    }
    _fadeCtrl.reset();
    _slideCtrl.reset();
    setState(() => _current++);
    _fadeCtrl.forward();
    _slideCtrl.forward();
  }

  _SlideConfig _configFor(String type) {
    switch (type) {
      case 'hook':
        return _SlideConfig(
          emoji: '🤔',
          label: 'MERAK',
          bgGetter: (tc) => tc.cBgYellow,
          borderColor: const Color(0xFFF9A825),
        );
      case 'fact':
        return _SlideConfig(
          emoji: '💡',
          label: 'BİLGİ',
          bgGetter: (tc) => tc.cBgBlue,
          borderColor: AppTheme.intro,
        );
      case 'analogy':
        return _SlideConfig(
          emoji: '🔗',
          label: 'ANALOJİ',
          bgGetter: (tc) => tc.cBgGreen,
          borderColor: AppTheme.concept,
        );
      case 'example':
        return _SlideConfig(
          emoji: '📌',
          label: 'ÖRNEK',
          bgGetter: (tc) => tc.cBgOrange,
          borderColor: AppTheme.scenario,
        );
      case 'key':
        return _SlideConfig(
          emoji: '🔑',
          label: 'ANAHTAR',
          bgGetter: (tc) => tc.cBgPurple,
          borderColor: AppTheme.quiz,
        );
      case 'bridge':
        return _SlideConfig(
          emoji: '➡️',
          label: 'SIRA SENİN',
          bgGetter: (tc) => tc.cBgTeal,
          borderColor: AppTheme.reflect,
        );
      default:
        return _SlideConfig(
          emoji: '📖',
          label: 'BİLGİ',
          bgGetter: (tc) => tc.cBgBlue,
          borderColor: AppTheme.intro,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = TC.of(context);
    final slides = widget.slides;

    if (slides.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: PrimaryButton(
            label: 'DEVAM  →',
            onPressed: widget.onComplete,
            color: widget.accentColor,
          ),
        ),
      );
    }

    final slide = slides[_current];
    final slideType = (slide['type'] ?? 'fact').toLowerCase();
    final slideText = slide['text'] ?? '';
    final config = _configFor(slideType);
    final isLast = _current == slides.length - 1;
    final progress = (_current + 1) / slides.length;

    return AnimatedBuilder(
      animation: fontSizeNotifier,
      builder: (_, __) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Başlık + progress bar ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StepHeader(
                  emoji: widget.stepEmoji,
                  label: widget.stepLabel,
                  title: widget.title,
                  color: widget.accentColor,
                  colorLt: widget.accentColorLt,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: tc.border,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: progress,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: 6,
                              decoration: BoxDecoration(
                                color: widget.accentColor,
                                borderRadius: BorderRadius.circular(99),
                                boxShadow: [
                                  BoxShadow(
                                    color: widget.accentColor
                                        .withValues(alpha: 0.5),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${_current + 1} / ${slides.length}',
                      style: TextStyle(
                        color: widget.accentColor,
                        fontSize: AppFS.labelLg,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Slide kartı ────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: _SlideCard(text: slideText, config: config),
                ),
              ),
            ),
          ),

          // ── Nokta göstergesi ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(slides.length, (i) {
                final active = i == _current;
                final done = i < _current;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: done
                        ? widget.accentColor.withValues(alpha: 0.4)
                        : active
                        ? widget.accentColor
                        : tc.border,
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: widget.accentColor.withValues(alpha: 0.5),
                              blurRadius: 8,
                            ),
                          ]
                        : [],
                  ),
                );
              }),
            ),
          ),

          // ── İleri butonu ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: PrimaryButton(
              label: isLast ? '✅  ANLADIM, DEVAM' : 'İLERİ  →',
              onPressed: _goNext,
              color: widget.accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Slide Kartı ──────────────────────────────────────────────────────────────
class _SlideCard extends StatelessWidget {
  final String text;
  final _SlideConfig config;

  const _SlideCard({required this.text, required this.config});

  @override
  Widget build(BuildContext context) {
    final tc = TC.of(context);
    final bg = config.bgGetter(tc);
    final border = config.borderColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border.withValues(alpha: 0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: border.withValues(alpha: 0.18),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Tip badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: border.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: border.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(config.emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  config.label,
                  style: TextStyle(
                    color: border,
                    fontSize: AppFS.small,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: tc.cText,
                fontSize: AppFS.bodyLg,
                fontWeight: FontWeight.w700,
                height: 1.65,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Config ───────────────────────────────────────────────────────────────────
class _SlideConfig {
  final String emoji;
  final String label;
  final Color Function(TC) bgGetter;
  final Color borderColor;

  const _SlideConfig({
    required this.emoji,
    required this.label,
    required this.bgGetter,
    required this.borderColor,
  });
}
