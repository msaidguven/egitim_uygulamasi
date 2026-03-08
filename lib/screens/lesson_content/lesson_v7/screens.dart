import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'theme.dart';
import 'theme.dart' as lesson_theme;
import 'models.dart';
import 'lesson_data.dart';

final FontSizeNotifier _fontSizeNotifier = lesson_theme.fontSizeNotifier;
FontSizeNotifier get fontSizeNotifier => _fontSizeNotifier;

// ─── SCREENS V3 — QUEST MODE ──────────────────────────────────────────────────

// ────────────────────────────────────────────────────────────────────────────
// 0 · INTRO
// ────────────────────────────────────────────────────────────────────────────
class IntroScreen extends StatefulWidget {
  final String title, content;
  final VoidCallback onComplete;
  const IntroScreen({
    super.key,
    required this.onComplete,
    this.title = 'Ders Başlıyor',
    this.content = '',
  });

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero — neon glow banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppTheme.introDk,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.intro.withValues(alpha: 0.7),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.intro.withValues(alpha: 0.4),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: AppTheme.intro.withValues(alpha: 0.15),
                  blurRadius: 60,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: Column(
              children: [
                ScaleTransition(
                  scale: _pulse,
                  child: const Text('🚀', style: TextStyle(fontSize: 64)),
                ),
                const SizedBox(height: 16),
                ShaderMask(
                  shaderCallback: (b) => AppTheme.introGrad.createShader(b),
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.intro.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: AppTheme.intro.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '🎮  GÖREV BAŞLIYOR',
                    style: TextStyle(
                      color: AppTheme.intro,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      shadows: [Shadow(color: AppTheme.intro, blurRadius: 8)],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (widget.content.isNotEmpty) ...[
            AnimatedBuilder(
              animation: fontSizeNotifier,
              builder: (_, __) => Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.contentBgBlue,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.intro.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.intro.withValues(alpha: 0.1),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.introDk,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.intro.withValues(alpha: 0.5),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.intro.withValues(alpha: 0.3),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Text(
                            '💡',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'GÖREV BRİFİNGİ',
                          style: TextStyle(
                            color: AppTheme.intro,
                            fontWeight: FontWeight.w800,
                            fontSize: AppFS.small,
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(color: AppTheme.intro, blurRadius: 6),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      widget.content,
                      style: TextStyle(
                        color: AppTheme.contentText,
                        fontSize: AppFS.body,
                        height: 1.75,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Oyun ipucu şeridi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                const Text('🕹️', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Her adımda görevleri tamamla, XP kazan!',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          PrimaryButton(
            label: '▶  GÖREVE BAŞLA',
            onPressed: widget.onComplete,
            gradient: AppTheme.introGrad,
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 1 · CONCEPT CARDS
// ────────────────────────────────────────────────────────────────────────────
class ConceptCardsScreen extends StatefulWidget {
  final List<ConceptItem> items;
  final String title;
  final VoidCallback onComplete;
  const ConceptCardsScreen({
    super.key,
    required this.items,
    required this.title,
    required this.onComplete,
  });

  @override
  State<ConceptCardsScreen> createState() => _ConceptCardsState();
}

class _ConceptCardsState extends State<ConceptCardsScreen> {
  final Set<int> _seen = {};

  static const _neonColors = [
    AppTheme.concept,
    AppTheme.intro,
    AppTheme.quiz,
    AppTheme.word,
    AppTheme.scenario,
    AppTheme.reflect,
  ];
  static const _neonDarks = [
    AppTheme.conceptDk,
    AppTheme.introDk,
    AppTheme.quizDk,
    AppTheme.wordDk,
    AppTheme.scenarioDk,
    AppTheme.reflectDk,
  ];

  @override
  Widget build(BuildContext context) {
    final done = _seen.length == widget.items.length;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StepHeader(
            emoji: '📚',
            label: 'KAVRAMLAR',
            title: widget.title,
            color: AppTheme.concept,
            colorLt: AppTheme.conceptDk,
          ),
          const SizedBox(height: 6),
          Text(
            'Her karta dokunarak kilidi aç! 🔓',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.88,
            ),
            itemCount: widget.items.length,
            itemBuilder: (_, i) {
              final item = widget.items[i];
              final active = _seen.contains(i);
              final col = _neonColors[i % _neonColors.length];
              // Açık arka planlar — kart açıldığında okunabilir
              final lightBgs = [
                AppTheme.contentBgGreen,
                AppTheme.contentBgBlue,
                AppTheme.contentBgPurple,
                AppTheme.contentBgAmber,
                AppTheme.contentBgBlue,
                AppTheme.contentBgTeal,
              ];
              final lightBg = lightBgs[i % lightBgs.length];
              return GestureDetector(
                onTap: () => setState(() => _seen.add(i)),
                child: AnimatedBuilder(
                  animation: fontSizeNotifier,
                  builder: (_, __) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: active ? lightBg : AppTheme.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: active ? col : AppTheme.border,
                        width: active ? 2 : 1.5,
                      ),
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: col.withValues(alpha: 0.45),
                                blurRadius: 20,
                                spreadRadius: 1,
                              ),
                              BoxShadow(
                                color: col.withValues(alpha: 0.15),
                                blurRadius: 40,
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!active)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: const Text(
                              '🔒',
                              style: TextStyle(fontSize: 20),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: col.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: col.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Text(
                              item.icon,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        const SizedBox(height: 10),
                        Text(
                          item.title,
                          style: TextStyle(
                            color: active
                                ? AppTheme.contentText
                                : AppTheme.textBody,
                            fontWeight: FontWeight.w800,
                            fontSize: AppFS.labelLg,
                            shadows: active
                                ? null
                                : [
                                    Shadow(
                                      color: col.withValues(alpha: 0.3),
                                      blurRadius: 4,
                                    ),
                                  ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (active)
                          Text(
                            item.desc,
                            style: TextStyle(
                              color: AppTheme.contentTextMid,
                              fontSize: AppFS.label,
                              height: 1.5,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        else
                          Text(
                            'Dokun & kilidi aç',
                            style: TextStyle(
                              color: AppTheme.muted,
                              fontSize: AppFS.small,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),

          // Progress bar neon
          Row(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: widget.items.isEmpty
                          ? 0
                          : _seen.length / widget.items.length,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.concept, AppTheme.intro],
                          ),
                          borderRadius: BorderRadius.circular(99),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.concept.withValues(alpha: 0.6),
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
                '${_seen.length}/${widget.items.length}',
                style: TextStyle(
                  color: AppTheme.concept,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  shadows: [Shadow(color: AppTheme.concept, blurRadius: 6)],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          AnimatedOpacity(
            opacity: done ? 1 : 0.35,
            duration: const Duration(milliseconds: 300),
            child: IgnorePointer(
              ignoring: !done,
              child: PrimaryButton(
                label: done ? '✅  TÜMÜNÜ AÇTIM!' : '🔒  Tüm kartları aç...',
                onPressed: widget.onComplete,
                color: AppTheme.concept,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 2 · INFO LIST (risk_analysis)
// ────────────────────────────────────────────────────────────────────────────
class InfoListScreen extends StatefulWidget {
  final List<InfoItem> items;
  final String title, icon;
  final Color color;
  final VoidCallback onComplete;
  const InfoListScreen({
    super.key,
    required this.items,
    required this.title,
    required this.icon,
    required this.color,
    required this.onComplete,
  });

  @override
  State<InfoListScreen> createState() => _InfoListState();
}

class _InfoListState extends State<InfoListScreen> {
  int? _open;
  final Set<int> _seen = {};

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StepHeader(
            emoji: widget.icon,
            label: 'RİSK ANALİZİ',
            title: widget.title,
            color: AppTheme.risk,
            colorLt: AppTheme.riskDk,
          ),
          const SizedBox(height: 6),
          Text(
            'Her tehlikeyi incele, XP kazan',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 16),

          ...widget.items.asMap().entries.map((e) {
            final i = e.key;
            final item = e.value;
            final open = _open == i;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => setState(() {
                  _open = open ? null : i;
                  _seen.add(i);
                }),
                child: AnimatedBuilder(
                  animation: fontSizeNotifier,
                  builder: (_, __) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: open ? AppTheme.contentBgAmber : AppTheme.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: open ? AppTheme.risk : AppTheme.border,
                        width: open ? 2 : 1.5,
                      ),
                      boxShadow: open
                          ? [
                              BoxShadow(
                                color: AppTheme.risk.withValues(alpha: 0.4),
                                blurRadius: 18,
                                spreadRadius: 1,
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: open ? AppTheme.risk : AppTheme.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: open ? AppTheme.risk : AppTheme.border,
                                ),
                                boxShadow: open
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.risk.withValues(
                                            alpha: 0.5,
                                          ),
                                          blurRadius: 10,
                                        ),
                                      ]
                                    : [],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  color: open
                                      ? Colors.black
                                      : AppTheme.textMuted,
                                  fontWeight: FontWeight.w800,
                                  fontSize: AppFS.labelLg,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.text,
                                style: TextStyle(
                                  color: open
                                      ? AppTheme.contentText
                                      : AppTheme.textBody,
                                  fontWeight: FontWeight.w700,
                                  fontSize: AppFS.body,
                                ),
                              ),
                            ),
                            Icon(
                              open
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: open ? AppTheme.risk : AppTheme.muted,
                              size: 22,
                            ),
                          ],
                        ),
                        if (open && item.example.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(10),
                              border: Border(
                                left: BorderSide(
                                  color: AppTheme.risk,
                                  width: 3,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Text('💬 '),
                                Expanded(
                                  child: Text(
                                    item.example,
                                    style: TextStyle(
                                      color: AppTheme.contentTextMid,
                                      fontSize: AppFS.labelLg,
                                      height: 1.55,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 6),
          AnimatedOpacity(
            opacity: _seen.length == widget.items.length ? 1 : 0.35,
            duration: const Duration(milliseconds: 300),
            child: IgnorePointer(
              ignoring: _seen.length != widget.items.length,
              child: PrimaryButton(
                label: 'ANLADIM  →',
                onPressed: widget.onComplete,
                color: AppTheme.risk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 3 · CASE SWIPE
// ────────────────────────────────────────────────────────────────────────────
class CaseSwipeScreen extends StatefulWidget {
  final List<CaseStudy> cases;
  final VoidCallback onComplete;
  const CaseSwipeScreen({
    super.key,
    required this.cases,
    required this.onComplete,
  });
  @override
  State<CaseSwipeScreen> createState() => _CaseSwipeState();
}

class _CaseSwipeState extends State<CaseSwipeScreen> {
  int _idx = 0;

  @override
  Widget build(BuildContext context) {
    final c = widget.cases[_idx];
    final isLast = _idx == widget.cases.length - 1;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StepHeader(
            emoji: '📰',
            label: 'ÖRNEK OLAY',
            title: 'Gerçek Hayattan',
            color: AppTheme.scenario,
            colorLt: AppTheme.scenarioDk,
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(
              widget.cases.length,
              (i) => Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 4),
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= _idx ? AppTheme.scenario : AppTheme.surface,
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: i <= _idx
                        ? [
                            BoxShadow(
                              color: AppTheme.scenario.withValues(alpha: 0.5),
                              blurRadius: 6,
                            ),
                          ]
                        : [],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.scenarioDk,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.scenario.withValues(alpha: 0.6),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.scenario.withValues(alpha: 0.3),
                  blurRadius: 24,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(c.emoji, style: const TextStyle(fontSize: 36)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.title,
                            style: const TextStyle(
                              color: AppTheme.textBody,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            c.where,
                            style: TextStyle(
                              color: AppTheme.scenario,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              shadows: [
                                Shadow(color: AppTheme.scenario, blurRadius: 4),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  c.desc,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 14),
                _NeonDetailRow(
                  icon: '💡',
                  label: 'Ders',
                  text: c.lesson,
                  color: AppTheme.scenario,
                ),
                const SizedBox(height: 8),
                _NeonDetailRow(
                  icon: '✅',
                  label: 'Yapılacak',
                  text: c.action,
                  color: AppTheme.concept,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: isLast ? 'DEVAM  →' : 'SONRAKİ ÖRNEK  →',
            onPressed: () =>
                isLast ? widget.onComplete() : setState(() => _idx++),
            color: AppTheme.scenario,
          ),
        ],
      ),
    );
  }
}

class _NeonDetailRow extends StatelessWidget {
  final String icon, label, text;
  final Color color;
  const _NeonDetailRow({
    required this.icon,
    required this.label,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(icon),
      const SizedBox(width: 6),
      Text(
        '$label: ',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 13,
          shadows: [Shadow(color: color, blurRadius: 4)],
        ),
      ),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ),
    ],
  );
}

// ────────────────────────────────────────────────────────────────────────────
// 4 · DIGITAL FOOTPRINT
// ────────────────────────────────────────────────────────────────────────────
class DigitalFootprintScreen extends StatefulWidget {
  final List<TimelineItem> timeline;
  final VoidCallback onComplete;
  const DigitalFootprintScreen({
    super.key,
    required this.timeline,
    required this.onComplete,
  });
  @override
  State<DigitalFootprintScreen> createState() => _DigitalFootprintState();
}

class _DigitalFootprintState extends State<DigitalFootprintScreen> {
  int? _open;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StepHeader(
            emoji: '👣',
            label: 'DİJİTAL AYAK İZİ',
            title: 'Bir Gün Boyunca Bıraktığın Veriler',
            color: AppTheme.intro,
            colorLt: AppTheme.introDk,
          ),
          const SizedBox(height: 16),
          ...widget.timeline.asMap().entries.map((e) {
            final i = e.key;
            final item = e.value;
            final open = _open == i;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => setState(() => _open = open ? null : i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: open ? AppTheme.introDk : AppTheme.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: open ? AppTheme.intro : AppTheme.border,
                      width: open ? 2 : 1.5,
                    ),
                    boxShadow: open
                        ? [
                            BoxShadow(
                              color: AppTheme.intro.withValues(alpha: 0.35),
                              blurRadius: 16,
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(item.icon, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.time} · ${item.label}',
                                  style: TextStyle(
                                    color: AppTheme.intro,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    shadows: [
                                      Shadow(
                                        color: AppTheme.intro,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  item.app,
                                  style: const TextStyle(
                                    color: AppTheme.textBody,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            open
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            color: open ? AppTheme.intro : AppTheme.muted,
                          ),
                        ],
                      ),
                      if (open) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: item.data
                              .map(
                                (d) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.intro.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(99),
                                    border: Border.all(
                                      color: AppTheme.intro.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.intro.withValues(
                                          alpha: 0.2,
                                        ),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '📌 $d',
                                    style: TextStyle(
                                      color: AppTheme.intro,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'DEVAM  →',
            onPressed: widget.onComplete,
            gradient: AppTheme.introGrad,
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 5 · SECURITY SCORE
// ────────────────────────────────────────────────────────────────────────────
class SecurityScoreScreen extends StatefulWidget {
  final List<ScoreQuestion> questions;
  final VoidCallback onComplete;
  const SecurityScoreScreen({
    super.key,
    required this.questions,
    required this.onComplete,
  });
  @override
  State<SecurityScoreScreen> createState() => _SecurityScoreState();
}

class _SecurityScoreState extends State<SecurityScoreScreen> {
  final Map<int, bool> _answers = {};

  int get _score =>
      _answers.values.where((v) => v).length *
      (widget.questions.isEmpty ? 0 : widget.questions.first.points);

  @override
  Widget build(BuildContext context) {
    final answered = _answers.length == widget.questions.length;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StepHeader(
            emoji: '🛡️',
            label: 'GÜVENLİK SKORU',
            title: 'Ne Kadar Güvenlisin?',
            color: AppTheme.game,
            colorLt: AppTheme.gameDk,
          ),
          const SizedBox(height: 16),
          ...widget.questions.asMap().entries.map((e) {
            final i = e.key;
            final q = e.value;
            final ans = _answers[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ans == null
                      ? AppTheme.card
                      : ans
                      ? AppTheme.greenDk
                      : AppTheme.redDk,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: ans == null
                        ? AppTheme.border
                        : ans
                        ? AppTheme.green
                        : AppTheme.red,
                    width: 1.5,
                  ),
                  boxShadow: ans != null
                      ? [
                          BoxShadow(
                            color: (ans ? AppTheme.green : AppTheme.red)
                                .withValues(alpha: 0.35),
                            blurRadius: 14,
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    Text(q.icon, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        q.text,
                        style: const TextStyle(
                          color: AppTheme.textBody,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _NeonYesNo(
                      value: ans,
                      onChanged: (v) => setState(() => _answers[i] = v),
                    ),
                  ],
                ),
              ),
            );
          }),
          if (answered) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.gameGrad,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.game.withValues(alpha: 0.5),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Text('⚡', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'GÜVENLİK SKORUM',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        '$_score puan',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          AnimatedOpacity(
            opacity: answered ? 1 : 0.35,
            duration: const Duration(milliseconds: 300),
            child: IgnorePointer(
              ignoring: !answered,
              child: PrimaryButton(
                label: 'SONUÇLARI GÖR  →',
                onPressed: widget.onComplete,
                color: AppTheme.game,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NeonYesNo extends StatelessWidget {
  final bool? value;
  final void Function(bool) onChanged;
  const _NeonYesNo({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _NBtn(
        label: 'EVET',
        selected: value == true,
        color: AppTheme.green,
        onTap: () => onChanged(true),
      ),
      const SizedBox(width: 6),
      _NBtn(
        label: 'HAYIR',
        selected: value == false,
        color: AppTheme.red,
        onTap: () => onChanged(false),
      ),
    ],
  );
}

class _NBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _NBtn({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? color : AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: selected ? color : AppTheme.border),
        boxShadow: selected
            ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10)]
            : [],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.black : AppTheme.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}

// ────────────────────────────────────────────────────────────────────────────
// 6 · ROLE PLAY
// ────────────────────────────────────────────────────────────────────────────
class RolePlayScreen extends StatefulWidget {
  final List<Map<String, String>> script;
  final VoidCallback onComplete;
  const RolePlayScreen({
    super.key,
    required this.script,
    required this.onComplete,
  });
  @override
  State<RolePlayScreen> createState() => _RolePlayState();
}

class _RolePlayState extends State<RolePlayScreen> {
  int _step = 0;
  static const _cols = [
    AppTheme.intro,
    AppTheme.scenario,
    AppTheme.concept,
    AppTheme.quiz,
  ];

  @override
  Widget build(BuildContext context) {
    final done = _step >= widget.script.length;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StepHeader(
            emoji: '🎭',
            label: 'ROL YAPMA',
            title: 'Canlandıralım!',
            color: AppTheme.scenario,
            colorLt: AppTheme.scenarioDk,
          ),
          const SizedBox(height: 16),
          ...widget.script.asMap().entries.map((e) {
            final i = e.key;
            final line = e.value;
            final visible = i <= _step;
            final col = _cols[i % _cols.length];
            return AnimatedOpacity(
              opacity: visible ? 1 : 0,
              duration: const Duration(milliseconds: 400),
              child: AnimatedSlide(
                offset: visible ? Offset.zero : const Offset(0, 0.08),
                duration: const Duration(milliseconds: 400),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AnimatedBuilder(
                    animation: fontSizeNotifier,
                    builder: (_, __) => Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: visible ? AppTheme.contentBgBlue : AppTheme.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: visible
                              ? col.withValues(alpha: 0.5)
                              : AppTheme.border,
                          width: visible ? 2 : 1.5,
                        ),
                        boxShadow: visible
                            ? [
                                BoxShadow(
                                  color: col.withValues(alpha: 0.25),
                                  blurRadius: 14,
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: col,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: col.withValues(alpha: 0.5),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w800,
                                fontSize: AppFS.labelLg,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  line['role'] ?? 'Rol',
                                  style: TextStyle(
                                    color: col,
                                    fontWeight: FontWeight.w800,
                                    fontSize: AppFS.small,
                                    shadows: [
                                      Shadow(color: col, blurRadius: 4),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  line['action'] ?? '',
                                  style: TextStyle(
                                    color: AppTheme.contentText,
                                    fontSize: AppFS.body,
                                    height: 1.55,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          PrimaryButton(
            label: done ? 'HARİKA! DEVAM  →' : 'SONRAKİ SAHNE  →',
            onPressed: done ? widget.onComplete : () => setState(() => _step++),
            color: AppTheme.scenario,
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 7 · SCENARIO CHOICE
// ────────────────────────────────────────────────────────────────────────────
class ScenarioChoiceScreen extends StatefulWidget {
  final String context, question, explanation;
  final List<String> feedbacks, options;
  final int correct;
  final VoidCallback onComplete;
  const ScenarioChoiceScreen({
    super.key,
    required this.context,
    required this.question,
    required this.options,
    required this.correct,
    required this.explanation,
    this.feedbacks = const [],
    required this.onComplete,
  });
  @override
  State<ScenarioChoiceScreen> createState() => _ScenarioChoiceState();
}

class _ScenarioChoiceState extends State<ScenarioChoiceScreen> {
  int? _sel;
  static const _letters = ['A', 'B', 'C', 'D'];

  @override
  Widget build(BuildContext context) {
    final answered = _sel != null;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StepHeader(
            emoji: '🎯',
            label: 'SENARYO',
            title: 'Ne yapardın?',
            color: AppTheme.scenario,
            colorLt: AppTheme.scenarioDk,
          ),
          const SizedBox(height: 16),

          // Senaryo kutusu
          AnimatedBuilder(
            animation: fontSizeNotifier,
            builder: (_, __) => Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.contentBgBlue,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.scenario.withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.scenario.withValues(alpha: 0.2),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.scenarioDk,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.scenario.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Text('📌', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.context,
                      style: TextStyle(
                        color: AppTheme.contentText,
                        fontSize: AppFS.body,
                        height: 1.65,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          Text(
            widget.question,
            style: TextStyle(
              color: AppTheme.textBody,
              fontSize: AppFS.bodyLg,
              fontWeight: FontWeight.w800,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),

          ...widget.options.asMap().entries.map((e) {
            final i = e.key;
            final opt = e.value;
            final isCorr = i == widget.correct;
            final isSel = i == _sel;
            Color bg = AppTheme.card;
            Color border = AppTheme.border;
            Color txtCol = AppTheme.textBody;
            Color circleCol = AppTheme.surface;

            if (answered && isCorr) {
              bg = AppTheme.greenDk;
              border = AppTheme.green;
              txtCol = AppTheme.green;
              circleCol = AppTheme.green;
            }
            if (answered && isSel && !isCorr) {
              bg = AppTheme.redDk;
              border = AppTheme.red;
              txtCol = AppTheme.red;
              circleCol = AppTheme.red;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => answered ? null : setState(() => _sel = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: border, width: 1.5),
                    boxShadow: answered && (isCorr || isSel)
                        ? [
                            BoxShadow(
                              color: border.withValues(alpha: 0.4),
                              blurRadius: 14,
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: circleCol,
                        radius: 14,
                        child: Text(
                          answered && isCorr
                              ? '✓'
                              : answered && isSel
                              ? '✗'
                              : _letters[i],
                          style: TextStyle(
                            color: answered && (isCorr || isSel)
                                ? Colors.black
                                : AppTheme.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          opt,
                          style: TextStyle(
                            color: txtCol,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            shadows: answered && (isCorr || isSel)
                                ? [Shadow(color: txtCol, blurRadius: 6)]
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          if (answered) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.greenDk,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.greenBdr, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.green.withValues(alpha: 0.3),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡 '),
                  Expanded(
                    child: Text(
                      (_sel != null &&
                              _sel! < widget.feedbacks.length &&
                              widget.feedbacks[_sel!].trim().isNotEmpty)
                          ? widget.feedbacks[_sel!]
                          : widget.explanation,
                      style: TextStyle(
                        color: AppTheme.concept,
                        fontSize: 13,
                        height: 1.5,
                        shadows: [
                          Shadow(color: AppTheme.concept, blurRadius: 4),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'DEVAM  →',
              onPressed: widget.onComplete,
              color: AppTheme.scenario,
            ),
          ],
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 8 · PERMISSION DETECTIVE (mini_game)
// ────────────────────────────────────────────────────────────────────────────
class PermissionDetectiveScreen extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final List<String> answerOptions;
  final String title, description;
  final VoidCallback onComplete;
  const PermissionDetectiveScreen({
    super.key,
    required this.items,
    required this.answerOptions,
    required this.title,
    required this.description,
    required this.onComplete,
  });
  @override
  State<PermissionDetectiveScreen> createState() => _PermissionDetectiveState();
}

class _PermissionDetectiveState extends State<PermissionDetectiveScreen> {
  int _qi = 0;
  int? _sel;
  bool _answered = false;
  int _correct = 0;
  bool _done = false;

  void _choose(int i) {
    if (_answered) return;
    final correctAns = (widget.items[_qi]['correct_answer'] ?? '')
        .toString()
        .trim();
    setState(() {
      _sel = i;
      _answered = true;
      if (widget.answerOptions[i] == correctAns) _correct++;
    });
  }

  void _next() {
    if (_qi < widget.items.length - 1) {
      setState(() {
        _qi++;
        _sel = null;
        _answered = false;
      });
    } else {
      setState(() => _done = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done) {
      final pct = widget.items.isEmpty ? 0.0 : _correct / widget.items.length;
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              pct == 1.0 ? '🎉' : '👍',
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 12),
            ShaderMask(
              shaderCallback: (b) => AppTheme.gameGrad.createShader(b),
              child: Text(
                '$_correct/${widget.items.length} DOĞRU!',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 32,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              pct == 1.0
                  ? 'MÜKEMMEL! Hepsini doğru yaptın! 🏆'
                  : 'İyi iş! Tekrar deneyerek gelişebilirsin.',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'DEVAM  →',
              onPressed: widget.onComplete,
              gradient: AppTheme.gameGrad,
            ),
          ],
        ),
      );
    }

    final item = widget.items[_qi];
    final correctAns = (item['correct_answer'] ?? '').toString().trim();
    final feedback = (item['feedback'] ?? '').toString();
    final situation = (item['situation'] ?? '').toString();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StepHeader(
            emoji: '🎮',
            label: 'MİNİ OYUN',
            title: widget.title,
            color: AppTheme.game,
            colorLt: AppTheme.gameDk,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: _qi / widget.items.length,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: AppTheme.gameGrad,
                          borderRadius: BorderRadius.circular(99),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.game.withValues(alpha: 0.6),
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
                '${_qi + 1}/${widget.items.length}',
                style: TextStyle(
                  color: AppTheme.game,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  shadows: [Shadow(color: AppTheme.game, blurRadius: 6)],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          AnimatedBuilder(
            animation: fontSizeNotifier,
            builder: (_, __) => Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.contentBgGreen,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.game.withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.game.withValues(alpha: 0.2),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Text(
                situation,
                style: TextStyle(
                  color: AppTheme.contentText,
                  fontSize: AppFS.bodyLg,
                  fontWeight: FontWeight.w700,
                  height: 1.55,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          ...widget.answerOptions.asMap().entries.map((e) {
            final i = e.key;
            final opt = e.value;
            final isCorr = opt == correctAns;
            final isSel = i == _sel;
            Color bg = AppTheme.card;
            Color border = AppTheme.border;

            if (_answered && isCorr) {
              bg = AppTheme.greenDk;
              border = AppTheme.green;
            }
            if (_answered && isSel && !isCorr) {
              bg = AppTheme.redDk;
              border = AppTheme.red;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => _choose(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: border, width: 1.5),
                    boxShadow: _answered && (isCorr || isSel)
                        ? [
                            BoxShadow(
                              color: border.withValues(alpha: 0.4),
                              blurRadius: 14,
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      if (_answered && isCorr)
                        const Text('✅ ', style: TextStyle(fontSize: 16))
                      else if (_answered && isSel && !isCorr)
                        const Text('❌ ', style: TextStyle(fontSize: 16))
                      else
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.border),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            String.fromCharCode(65 + i),
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          opt,
                          style: TextStyle(
                            color: _answered && isCorr
                                ? AppTheme.green
                                : _answered && isSel
                                ? AppTheme.red
                                : AppTheme.textBody,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            shadows: _answered && (isCorr || isSel)
                                ? [Shadow(color: border, blurRadius: 6)]
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          if (_answered) ...[
            if (feedback.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.greenDk,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.greenBdr),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.green.withValues(alpha: 0.25),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Text(
                  '💡 $feedback',
                  style: TextStyle(
                    color: AppTheme.concept,
                    fontSize: 13,
                    height: 1.5,
                    shadows: [Shadow(color: AppTheme.concept, blurRadius: 4)],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            PrimaryButton(
              label: _qi < widget.items.length - 1
                  ? 'SONRAKİ  →'
                  : 'SONUÇLARI GÖR  →',
              onPressed: _next,
              gradient: AppTheme.gameGrad,
            ),
          ],
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 9 · ANALYSIS
// ────────────────────────────────────────────────────────────────────────────
class AnalysisScreen extends StatefulWidget {
  final List<AnalysisItem> items;
  final VoidCallback onComplete;
  const AnalysisScreen({
    super.key,
    required this.items,
    required this.onComplete,
  });
  @override
  State<AnalysisScreen> createState() => _AnalysisState();
}

class _AnalysisState extends State<AnalysisScreen> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StepHeader(
            emoji: '🔍',
            label: 'ANALİZ',
            title: 'Analiz Yöntemleri',
            color: AppTheme.intro,
            colorLt: AppTheme.introDk,
          ),
          const SizedBox(height: 16),
          ...widget.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.introDk,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.introBdr),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.intro.withValues(alpha: 0.25),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Text(
                        item.icon,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              color: AppTheme.textBody,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.explanation,
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'DEVAM  →',
            onPressed: widget.onComplete,
            gradient: AppTheme.introGrad,
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 10 · MYTH BUSTERS
// ────────────────────────────────────────────────────────────────────────────
class MythBustersScreen extends StatefulWidget {
  final List<MythItem> myths;
  final VoidCallback onComplete;
  const MythBustersScreen({
    super.key,
    required this.myths,
    required this.onComplete,
  });
  @override
  State<MythBustersScreen> createState() => _MythBustersState();
}

class _MythBustersState extends State<MythBustersScreen> {
  final Set<int> _revealed = {};

  @override
  Widget build(BuildContext context) {
    final done = _revealed.length == widget.myths.length;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StepHeader(
            emoji: '🔬',
            label: 'EFSANE Mİ, GERÇEK Mİ?',
            title: 'Yanılgıları Kır!',
            color: AppTheme.risk,
            colorLt: AppTheme.riskDk,
          ),
          const SizedBox(height: 16),
          ...widget.myths.asMap().entries.map((e) {
            final i = e.key;
            final myth = e.value;
            final rev = _revealed.contains(i);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => setState(() => _revealed.add(i)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: rev ? AppTheme.greenDk : AppTheme.riskDk,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: rev ? AppTheme.greenBdr : AppTheme.riskBdr,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (rev ? AppTheme.green : AppTheme.risk)
                            .withValues(alpha: 0.3),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(myth.icon, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: rev ? AppTheme.green : AppTheme.risk,
                              borderRadius: BorderRadius.circular(99),
                              boxShadow: [
                                BoxShadow(
                                  color: (rev ? AppTheme.green : AppTheme.risk)
                                      .withValues(alpha: 0.5),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Text(
                              rev ? '✅ GERÇEK' : '❓ YANILGI',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        myth.myth,
                        style: TextStyle(
                          color: rev ? AppTheme.textMuted : AppTheme.textBody,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          decoration: rev ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (rev) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.card,
                            borderRadius: BorderRadius.circular(10),
                            border: Border(
                              left: BorderSide(color: AppTheme.green, width: 3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '✅ ${myth.truth}',
                                style: TextStyle(
                                  color: AppTheme.green,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  shadows: [
                                    Shadow(
                                      color: AppTheme.green,
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '📌 ${myth.example}',
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else
                        Text(
                          'Doğrusunu görmek için dokun 👆',
                          style: TextStyle(
                            color: AppTheme.risk,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(color: AppTheme.risk, blurRadius: 4),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          AnimatedOpacity(
            opacity: done ? 1 : 0.35,
            duration: const Duration(milliseconds: 300),
            child: IgnorePointer(
              ignoring: !done,
              child: PrimaryButton(
                label: 'EFSANELERİ YIKTIM!  →',
                onPressed: widget.onComplete,
                gradient: AppTheme.gameGrad,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 11 · REFLECTION
// ────────────────────────────────────────────────────────────────────────────
class ReflectionScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final List<String> questions;
  final String title, intro, note;
  const ReflectionScreen({
    super.key,
    required this.onComplete,
    required this.questions,
    this.title = 'Düşün & Değerlendir',
    this.intro = '',
    this.note = '',
  });
  @override
  State<ReflectionScreen> createState() => _ReflectionState();
}

class _ReflectionState extends State<ReflectionScreen> {
  final Set<int> _checked = {};

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StepHeader(
            emoji: '🌱',
            label: 'YANSITMA',
            title: widget.title,
            color: AppTheme.reflect,
            colorLt: AppTheme.reflectDk,
          ),
          if (widget.intro.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.reflectDk,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.reflectBdr, width: 1.5),
              ),
              child: Text(
                widget.intro,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          Text(
            'KENDİNE SOR:',
            style: TextStyle(
              color: AppTheme.reflect,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              shadows: [Shadow(color: AppTheme.reflect, blurRadius: 6)],
            ),
          ),
          const SizedBox(height: 10),
          ...widget.questions.asMap().entries.map((e) {
            final i = e.key;
            final q = e.value;
            final checked = _checked.contains(i);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => setState(
                  () => checked ? _checked.remove(i) : _checked.add(i),
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: checked ? AppTheme.reflectDk : AppTheme.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: checked ? AppTheme.reflect : AppTheme.border,
                      width: checked ? 2 : 1.5,
                    ),
                    boxShadow: checked
                        ? [
                            BoxShadow(
                              color: AppTheme.reflect.withValues(alpha: 0.35),
                              blurRadius: 14,
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: checked
                              ? AppTheme.reflect
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: checked ? AppTheme.reflect : AppTheme.border,
                            width: 2,
                          ),
                          boxShadow: checked
                              ? [
                                  BoxShadow(
                                    color: AppTheme.reflect.withValues(
                                      alpha: 0.5,
                                    ),
                                    blurRadius: 8,
                                  ),
                                ]
                              : [],
                        ),
                        child: checked
                            ? const Icon(
                                Icons.check,
                                color: Colors.black,
                                size: 14,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          q,
                          style: TextStyle(
                            color: checked
                                ? AppTheme.reflect
                                : AppTheme.textBody,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                            shadows: checked
                                ? [
                                    Shadow(
                                      color: AppTheme.reflect,
                                      blurRadius: 4,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (widget.note.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  const Text('📝 '),
                  Expanded(
                    child: Text(
                      widget.note,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'DEĞERLENDİRDİM  →',
            onPressed: widget.onComplete,
            color: AppTheme.reflect,
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 12 · WORD BANK
// ────────────────────────────────────────────────────────────────────────────
class WordBankScreen extends StatefulWidget {
  final String title, description, template;
  final List<String> words;
  final List<WordBankBlank> blanks;
  final VoidCallback onComplete;
  const WordBankScreen({
    super.key,
    required this.title,
    required this.description,
    required this.template,
    required this.words,
    required this.blanks,
    required this.onComplete,
  });
  @override
  State<WordBankScreen> createState() => _WordBankScreenState();
}

class _WordBankScreenState extends State<WordBankScreen>
    with SingleTickerProviderStateMixin {
  late List<String?> _selected;
  late List<String> _bank;
  final Set<int> _wrongSlots = {};
  bool _solved = false;
  late final AnimationController _shakeCtrl;

  @override
  void initState() {
    super.initState();
    _selected = List<String?>.filled(widget.blanks.length, null);
    _bank = [...widget.words];
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _pickWord(String word) {
    if (_solved) return;
    final empty = _selected.indexWhere((e) => e == null);
    if (empty == -1) return;
    setState(() {
      _selected[empty] = word;
      _bank.remove(word);
      _wrongSlots.remove(empty);
    });
  }

  void _removeWord(int index) {
    if (_solved) return;
    final word = _selected[index];
    if (word == null) return;
    setState(() {
      _selected[index] = null;
      _bank.add(word);
      _wrongSlots.remove(index);
    });
  }

  void _checkAnswer() {
    final wrong = <int>{};
    for (var i = 0; i < widget.blanks.length; i++) {
      if ((_selected[i] ?? '').trim() != widget.blanks[i].correctAnswer.trim())
        wrong.add(i);
    }
    if (wrong.isEmpty) {
      setState(() {
        _wrongSlots.clear();
        _solved = true;
      });
      return;
    }
    setState(() {
      _wrongSlots
        ..clear()
        ..addAll(wrong);
    });
    _shakeCtrl.forward(from: 0);
  }

  List<Widget> _buildTemplateParts() {
    final parts = widget.template.split(RegExp(r'_{3,}'));
    final widgets = <Widget>[];
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        widgets.add(
          Text(
            parts[i],
            style: const TextStyle(
              color: AppTheme.textBody,
              fontSize: 14,
              height: 1.7,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }
      if (i < widget.blanks.length) {
        final word = _selected[i];
        final wrong = _wrongSlots.contains(i);
        widgets.add(
          AnimatedBuilder(
            animation: _shakeCtrl,
            builder: (_, child) {
              final dx = wrong
                  ? math.sin(_shakeCtrl.value * math.pi * 8) * 5
                  : 0.0;
              return Transform.translate(offset: Offset(dx, 0), child: child);
            },
            child: GestureDetector(
              onTap: () => _removeWord(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: word == null
                      ? AppTheme.surface
                      : wrong
                      ? AppTheme.redDk
                      : AppTheme.greenDk,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: word == null
                        ? AppTheme.word
                        : wrong
                        ? AppTheme.red
                        : AppTheme.green,
                    width: 2,
                  ),
                  boxShadow: word != null
                      ? [
                          BoxShadow(
                            color: (wrong ? AppTheme.red : AppTheme.green)
                                .withValues(alpha: 0.4),
                            blurRadius: 10,
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  word ?? '  ${i + 1}  ',
                  style: TextStyle(
                    color: word == null
                        ? AppTheme.word
                        : wrong
                        ? AppTheme.red
                        : AppTheme.green,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    shadows: word != null
                        ? [
                            Shadow(
                              color: (wrong ? AppTheme.red : AppTheme.green),
                              blurRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final allFilled = _selected.every((e) => e != null);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StepHeader(
            emoji: '🧩',
            label: 'KELIME BANKASI',
            title: widget.title,
            color: AppTheme.word,
            colorLt: AppTheme.wordDk,
          ),
          if (widget.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              widget.description,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ],
          const SizedBox(height: 18),

          // Cümle şablonu
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.wordDk,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.word.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.word.withValues(alpha: 0.2),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 8,
              children: _buildTemplateParts(),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              const Text('📦 '),
              Text(
                'KELIME HAVUZU',
                style: TextStyle(
                  color: AppTheme.word,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  shadows: [Shadow(color: AppTheme.word, blurRadius: 6)],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _bank
                  .map(
                    (word) => GestureDetector(
                      onTap: () => _pickWord(word),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.wordDk,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.word.withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.word.withValues(alpha: 0.3),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Text(
                          word,
                          style: TextStyle(
                            color: AppTheme.word,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            shadows: [
                              Shadow(color: AppTheme.word, blurRadius: 4),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          if (_wrongSlots.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.redDk,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.redBdr),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.red.withValues(alpha: 0.3),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Text('⚠️ '),
                  Expanded(
                    child: Text(
                      'Hatalı boşluğa dokun, kelimeyi geri gönder!',
                      style: TextStyle(
                        color: AppTheme.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),

          if (!_solved)
            AnimatedOpacity(
              opacity: allFilled ? 1 : 0.35,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: !allFilled,
                child: PrimaryButton(
                  label: allFilled
                      ? '✅  KONTROL ET'
                      : '🔒  Tüm boşlukları doldur...',
                  onPressed: _checkAnswer,
                  gradient: AppTheme.wordGrad,
                ),
              ),
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.greenDk,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.greenBdr),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.green.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Text('🎉 ', style: TextStyle(fontSize: 20)),
                  Expanded(
                    child: Text(
                      'MÜKEMMEL! Tüm boşlukları doğru doldurdun.',
                      style: TextStyle(
                        color: AppTheme.green,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'DEVAM  →',
              onPressed: widget.onComplete,
              gradient: AppTheme.wordGrad,
            ),
          ],
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 13 · CRITICAL THINKING
// ────────────────────────────────────────────────────────────────────────────
class CriticalThinkingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final List<String> prompts, hints, discussion, tasks;
  final String title;
  const CriticalThinkingScreen({
    super.key,
    required this.onComplete,
    required this.prompts,
    required this.title,
    this.hints = defaultCriticalHints,
    this.discussion = defaultCriticalDiscussion,
    this.tasks = const [],
  });
  @override
  State<CriticalThinkingScreen> createState() => _CriticalThinkingState();
}

class _CriticalThinkingState extends State<CriticalThinkingScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StepHeader(
            emoji: '🧠',
            label: 'KRİTİK DÜŞÜNME',
            title: widget.title,
            color: AppTheme.quiz,
            colorLt: AppTheme.quizDk,
          ),
          const SizedBox(height: 16),

          // Neon tab bar
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                _NeonTab(
                  label: '❓ Sorular',
                  active: _tab == 0,
                  onTap: () => setState(() => _tab = 0),
                  color: AppTheme.quiz,
                ),
                _NeonTab(
                  label: '💡 İpuçları',
                  active: _tab == 1,
                  onTap: () => setState(() => _tab = 1),
                  color: AppTheme.concept,
                ),
                _NeonTab(
                  label: '💬 Tartışma',
                  active: _tab == 2,
                  onTap: () => setState(() => _tab = 2),
                  color: AppTheme.scenario,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_tab == 0)
            ..._buildNeonList(widget.prompts, AppTheme.quiz, '❓')
          else if (_tab == 1)
            ..._buildNeonList(widget.hints, AppTheme.concept, '💡')
          else
            ..._buildNeonList(widget.discussion, AppTheme.scenario, '💬'),

          if (widget.tasks.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              '📋 GÖREVLER',
              style: TextStyle(
                color: AppTheme.quiz,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                shadows: [Shadow(color: AppTheme.quiz, blurRadius: 6)],
              ),
            ),
            const SizedBox(height: 8),
            ...widget.tasks.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppTheme.quizDk,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.quizBdr),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          t,
                          style: const TextStyle(
                            color: AppTheme.textBody,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'DÜŞÜNDÜM  →',
            onPressed: widget.onComplete,
            color: AppTheme.quiz,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildNeonList(List<String> items, Color color, String icon) {
    return items
        .asMap()
        .entries
        .map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: color.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(icon, style: const TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      e.value,
                      style: TextStyle(
                        color: AppTheme.textBody,
                        fontSize: 13,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .toList();
  }
}

class _NeonTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color color;
  const _NeonTab({
    required this.label,
    required this.active,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: active ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: active
              ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10)]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.black : AppTheme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ),
  );
}

// ────────────────────────────────────────────────────────────────────────────
// 14 · INFOGRAPHIC (summary)
// ────────────────────────────────────────────────────────────────────────────
class InfographicScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final List<String> points;
  final String title, description;
  const InfographicScreen({
    super.key,
    required this.onComplete,
    required this.points,
    this.title = 'Ders Özeti',
    this.description = '',
  });
  @override
  State<InfographicScreen> createState() => _InfographicScreenState();
}

class _InfographicScreenState extends State<InfographicScreen> {
  int _vis = -1;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 200), _tick);
  }

  void _tick() {
    if (!mounted) return;
    if (_vis < widget.points.length - 1) {
      setState(() => _vis++);
      Future.delayed(const Duration(milliseconds: 280), _tick);
    }
  }

  static const _cols = [
    AppTheme.intro,
    AppTheme.concept,
    AppTheme.game,
    AppTheme.scenario,
    AppTheme.word,
    AppTheme.risk,
    AppTheme.quiz,
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StepHeader(
            emoji: '📋',
            label: 'ÖZET',
            title: widget.title,
            color: AppTheme.primaryGlow,
            colorLt: AppTheme.primaryLt,
          ),
          if (widget.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            AnimatedBuilder(
              animation: fontSizeNotifier,
              builder: (_, __) => Text(
                widget.description,
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: AppFS.body,
                  height: 1.6,
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          ...widget.points.asMap().entries.map((e) {
            final visible = e.key <= _vis;
            final col = _cols[e.key % _cols.length];
            return AnimatedOpacity(
              opacity: visible ? 1 : 0,
              duration: const Duration(milliseconds: 350),
              child: AnimatedSlide(
                offset: visible ? Offset.zero : const Offset(-0.05, 0),
                duration: const Duration(milliseconds: 350),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AnimatedBuilder(
                    animation: fontSizeNotifier,
                    builder: (_, __) => Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.contentBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: col.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: col.withValues(alpha: 0.2),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: col.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: col.withValues(alpha: 0.6),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: col.withValues(alpha: 0.35),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${e.key + 1}',
                              style: TextStyle(
                                color: col,
                                fontWeight: FontWeight.w800,
                                fontSize: AppFS.labelLg,
                                shadows: [Shadow(color: col, blurRadius: 6)],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              e.value,
                              style: TextStyle(
                                color: AppTheme.contentText,
                                fontSize: AppFS.body,
                                fontWeight: FontWeight.w700,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          PrimaryButton(label: 'ANLADIM  →', onPressed: widget.onComplete),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 15 · MULTI QUIZ
// ────────────────────────────────────────────────────────────────────────────
class MultiQuizScreen extends StatefulWidget {
  final List<QuizQuestion> questions;
  final VoidCallback onComplete;
  final void Function(String) onBadge;
  const MultiQuizScreen({
    super.key,
    required this.questions,
    required this.onComplete,
    required this.onBadge,
  });
  @override
  State<MultiQuizScreen> createState() => _MultiQuizState();
}

class _MultiQuizState extends State<MultiQuizScreen> {
  int _qi = 0, _score = 0;
  int? _sel;
  bool _answered = false, _done = false;
  static const _letters = ['A', 'B', 'C', 'D'];

  void _choose(int i) {
    if (_answered) return;
    setState(() {
      _sel = i;
      _answered = true;
      if (i == widget.questions[_qi].ans) _score++;
    });
  }

  void _next() {
    if (_qi < widget.questions.length - 1) {
      setState(() {
        _qi++;
        _sel = null;
        _answered = false;
      });
    } else {
      if (_score == widget.questions.length) widget.onBadge('security_master');
      setState(() => _done = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done) {
      final pct = widget.questions.isEmpty
          ? 0.0
          : _score / widget.questions.length;
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              pct == 1.0
                  ? '🌟'
                  : pct >= 0.7
                  ? '🎯'
                  : '📚',
              style: const TextStyle(fontSize: 72),
            ),
            const SizedBox(height: 12),
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [AppTheme.quiz, AppTheme.intro],
              ).createShader(b),
              child: Text(
                '$_score / ${widget.questions.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 40,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              pct == 1.0
                  ? 'MÜKEMMEL! Tüm soruları doğru! 🏆'
                  : pct >= 0.7
                  ? 'Harika iş! Çok yaklaştın!'
                  : 'Tekrar deneyerek gelişebilirsin.',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            if (pct == 1.0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.certDk,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.certBdr),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.cert.withValues(alpha: 0.4),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🏅 ', style: TextStyle(fontSize: 20)),
                    Text(
                      '"BİLGİ USTASI" ROZETİ KAZANDIN!',
                      style: TextStyle(
                        color: AppTheme.cert,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'DEVAM  →',
              onPressed: widget.onComplete,
              color: AppTheme.quiz,
            ),
          ],
        ),
      );
    }

    final q = widget.questions[_qi];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StepHeader(
                emoji: '❓',
                label: 'SORU ${_qi + 1}/${widget.questions.length}',
                title: '',
                color: AppTheme.quiz,
                colorLt: AppTheme.quizDk,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.greenDk,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: AppTheme.greenBdr),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.green.withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Text(
                  '$_score ✓',
                  style: TextStyle(
                    color: AppTheme.green,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    shadows: [Shadow(color: AppTheme.green, blurRadius: 6)],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              FractionallySizedBox(
                widthFactor: _qi / widget.questions.length,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.quiz, AppTheme.intro],
                    ),
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.quiz.withValues(alpha: 0.6),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          AnimatedBuilder(
            animation: fontSizeNotifier,
            builder: (_, __) => Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.contentBgPurple,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.quiz.withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.quiz.withValues(alpha: 0.2),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Text(
                q.q,
                style: TextStyle(
                  color: AppTheme.contentText,
                  fontSize: AppFS.bodyLg,
                  fontWeight: FontWeight.w800,
                  height: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          ...q.opts.asMap().entries.map((e) {
            final i = e.key;
            final isCorr = i == q.ans;
            final isSel = i == _sel;
            Color bg = AppTheme.card;
            Color border = AppTheme.border;
            Color txtCol = AppTheme.textBody;
            if (_answered && isCorr) {
              bg = AppTheme.greenDk;
              border = AppTheme.green;
              txtCol = AppTheme.green;
            }
            if (_answered && isSel && !isCorr) {
              bg = AppTheme.redDk;
              border = AppTheme.red;
              txtCol = AppTheme.red;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => _choose(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: border, width: 1.5),
                    boxShadow: _answered && (isCorr || isSel)
                        ? [
                            BoxShadow(
                              color: border.withValues(alpha: 0.4),
                              blurRadius: 14,
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: _answered && (isCorr || isSel)
                            ? border
                            : AppTheme.surface,
                        radius: 14,
                        child: Text(
                          _answered && isCorr
                              ? '✓'
                              : _answered && isSel
                              ? '✗'
                              : _letters[i],
                          style: TextStyle(
                            color: _answered && (isCorr || isSel)
                                ? Colors.black
                                : AppTheme.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          e.value,
                          style: TextStyle(
                            color: txtCol,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            shadows: _answered && (isCorr || isSel)
                                ? [Shadow(color: txtCol, blurRadius: 6)]
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          if (_answered) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.greenDk,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.greenBdr),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.green.withValues(alpha: 0.25),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Text(
                '💡 ${q.exp}',
                style: TextStyle(
                  color: AppTheme.concept,
                  fontSize: 13,
                  height: 1.5,
                  shadows: [Shadow(color: AppTheme.concept, blurRadius: 4)],
                ),
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: _qi < widget.questions.length - 1
                  ? 'SONRAKİ SORU  →'
                  : 'SONUÇLARI GÖR  →',
              onPressed: _next,
              color: AppTheme.quiz,
            ),
          ],
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 16 · KEYWORDS
// ────────────────────────────────────────────────────────────────────────────
class KeywordsScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final List<KeywordItem> items;
  const KeywordsScreen({
    super.key,
    required this.onComplete,
    required this.items,
  });
  @override
  State<KeywordsScreen> createState() => _KeywordsState();
}

class _KeywordsState extends State<KeywordsScreen> {
  int? _open;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StepHeader(
            emoji: '📖',
            label: 'SÖZLÜK',
            title: 'Anahtar Kavramlar',
            color: AppTheme.intro,
            colorLt: AppTheme.introDk,
          ),
          const SizedBox(height: 16),
          ...widget.items.asMap().entries.map((e) {
            final i = e.key;
            final item = e.value;
            final open = _open == i;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => setState(() => _open = open ? null : i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: open ? AppTheme.introDk : AppTheme.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: open ? AppTheme.intro : AppTheme.border,
                      width: open ? 2 : 1.5,
                    ),
                    boxShadow: open
                        ? [
                            BoxShadow(
                              color: AppTheme.intro.withValues(alpha: 0.35),
                              blurRadius: 14,
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.term,
                              style: TextStyle(
                                color: open
                                    ? AppTheme.intro
                                    : AppTheme.textBody,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                shadows: open
                                    ? [
                                        Shadow(
                                          color: AppTheme.intro,
                                          blurRadius: 6,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ),
                          Icon(
                            open
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            color: open ? AppTheme.intro : AppTheme.muted,
                          ),
                        ],
                      ),
                      if (open) ...[
                        const SizedBox(height: 8),
                        Text(
                          item.def,
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'DEVAM  →',
            onPressed: widget.onComplete,
            gradient: AppTheme.introGrad,
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 17 · PROGRESS TRACKER (stub)
// ────────────────────────────────────────────────────────────────────────────
class ProgressTrackerScreen extends StatelessWidget {
  final VoidCallback onComplete;
  const ProgressTrackerScreen({super.key, required this.onComplete});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
    child: Column(
      children: [
        const StepHeader(
          emoji: '📊',
          label: 'İLERLEME',
          title: 'Harika Gidiyorsun!',
          color: AppTheme.game,
          colorLt: AppTheme.gameDk,
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'DEVAM  →',
          onPressed: onComplete,
          gradient: AppTheme.gameGrad,
        ),
      ],
    ),
  );
}

// ────────────────────────────────────────────────────────────────────────────
// 18 · CERTIFICATE
// ────────────────────────────────────────────────────────────────────────────
class CertificateScreen extends StatefulWidget {
  final int xp;
  final VoidCallback onRestart;
  final String title, message;
  final List<String> takeaways;
  const CertificateScreen({
    super.key,
    required this.xp,
    required this.onRestart,
    this.title = 'Tebrikler! 🎉',
    this.message = 'Tebrikler!',
    this.takeaways = defaultTakeaways,
  });
  @override
  State<CertificateScreen> createState() => _CertificateState();
}

class _CertificateState extends State<CertificateScreen>
    with TickerProviderStateMixin {
  int _vis = -1;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    Future.delayed(const Duration(milliseconds: 400), _tick);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _tick() {
    if (!mounted) return;
    if (_vis < widget.takeaways.length - 1) {
      setState(() => _vis++);
      Future.delayed(const Duration(milliseconds: 380), _tick);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: Column(
        children: [
          // Sertifika kartı — en gösterişli kısım
          ScaleTransition(
            scale: _pulse,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2A1500), Color(0xFF1A0A00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.cert.withValues(alpha: 0.8),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.cert.withValues(alpha: 0.55),
                    blurRadius: 40,
                    spreadRadius: 4,
                  ),
                  BoxShadow(
                    color: AppTheme.cert.withValues(alpha: 0.2),
                    blurRadius: 80,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 72)),
                  const SizedBox(height: 14),
                  ShaderMask(
                    shaderCallback: (b) => AppTheme.certGrad.createShader(b),
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.message,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppTheme.certGrad,
                      borderRadius: BorderRadius.circular(99),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.cert.withValues(alpha: 0.6),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('⚡', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.xp} XP KAZANDIN!',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'NELER ÖĞRENDİN:',
              style: TextStyle(
                color: AppTheme.muted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 12),

          ...widget.takeaways.asMap().entries.map((e) {
            final visible = e.key <= _vis;
            final col = [
              AppTheme.concept,
              AppTheme.intro,
              AppTheme.game,
              AppTheme.quiz,
              AppTheme.word,
              AppTheme.scenario,
              AppTheme.reflect,
            ][e.key % 7];
            return AnimatedOpacity(
              opacity: visible ? 1 : 0,
              duration: const Duration(milliseconds: 400),
              child: AnimatedSlide(
                offset: visible ? Offset.zero : const Offset(-0.05, 0),
                duration: const Duration(milliseconds: 400),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: col.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: col.withValues(alpha: 0.2),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: col,
                            borderRadius: BorderRadius.circular(7),
                            boxShadow: [
                              BoxShadow(
                                color: col.withValues(alpha: 0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.black,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            e.value,
                            style: const TextStyle(
                              color: AppTheme.textBody,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryLt,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppTheme.primaryGlow.withValues(alpha: 0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGlow.withValues(alpha: 0.2),
                  blurRadius: 16,
                ),
              ],
            ),
            child: const Row(
              children: [
                Text('🌟 ', style: TextStyle(fontSize: 18)),
                Expanded(
                  child: Text(
                    'Öğrendiklerini arkadaşlarınla paylaş!',
                    style: TextStyle(
                      color: AppTheme.primaryGlow,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SecondaryButton(label: '🔄  TEKRAR AL', onPressed: widget.onRestart),
        ],
      ),
    );
  }
}
