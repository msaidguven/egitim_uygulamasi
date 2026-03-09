import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'theme.dart';
import 'models.dart';
import 'lesson_data.dart';

// ─── SCREENS V4 — QUEST MODE BRIGHT ──────────────────────────────────────────
// Tüm metin boyutları AppFS ile — A+/A- çalışır
// Kart içleri açık (cBg*) arka plan — sınıfta okunabilir
// Sabit yükseklik yok — overflow imkansız

// ─── YARDIMCI: cevap seçeneği ─────────────────────────────────────────────────
Widget _answerOption({
  required BuildContext ctx,
  required String label,
  required String text,
  required bool answered,
  required bool isCorrect,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  final tc = TC.of(ctx);
  Color bg = tc.card;
  Color border = tc.border;
  Color textCol = tc.textBody;

  if (answered && isCorrect) {
    bg = tc.greenLt;
    border = tc.green;
    textCol = tc.green;
  }
  if (answered && isSelected && !isCorrect) {
    bg = tc.redLt;
    border = tc.red;
    textCol = tc.red;
  }

  return GestureDetector(
    onTap: answered ? null : onTap,
    child: AnimatedBuilder(
      animation: fontSizeNotifier,
      builder: (_, __) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: border,
            width: answered && (isCorrect || isSelected) ? 2 : 1.5,
          ),
          boxShadow: answered && (isCorrect || isSelected)
              ? [
                  BoxShadow(
                    color: border.withValues(alpha: 0.35),
                    blurRadius: 12,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: answered && (isCorrect || isSelected)
                    ? border
                    : tc.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: answered && (isCorrect || isSelected)
                      ? border
                      : tc.border,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                answered && isCorrect
                    ? '✓'
                    : answered && isSelected
                    ? '✗'
                    : label,
                style: TextStyle(
                  color: answered && (isCorrect || isSelected)
                      ? Colors.white
                      : tc.textMuted,
                  fontSize: AppFS.label,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: textCol,
                  fontSize: AppFS.body,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ─── YARDIMCI: feedback kutusu ────────────────────────────────────────────────
Widget _feedbackBox(BuildContext ctx, String text, {bool isGood = true}) {
  final tc = TC.of(ctx);
  return AnimatedBuilder(
    animation: fontSizeNotifier,
    builder: (_, __) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isGood ? tc.greenLt : tc.redLt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isGood ? tc.greenBdr : tc.redBdr, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isGood ? '💡 ' : '⚠️ ', style: const TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isGood ? tc.green : tc.red,
                fontSize: AppFS.labelLg,
                height: 1.55,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ─── YARDIMCI: içerik kutusu ─────────────────────────────────────────────────
Widget _contentBox({
  required Widget child,
  required Color bgColor,
  required Color borderColor,
}) => Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: bgColor,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: borderColor.withValues(alpha: 0.5), width: 2),
    boxShadow: [
      BoxShadow(color: borderColor.withValues(alpha: 0.15), blurRadius: 12),
    ],
  ),
  child: child,
);

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
      begin: 0.88,
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
    final tc = TC.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: AnimatedBuilder(
        animation: fontSizeNotifier,
        builder: (_, __) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF01579B), Color(0xFF0288D1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.intro.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ScaleTransition(
                    scale: _pulse,
                    child: const Text('🚀', style: TextStyle(fontSize: 64)),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: AppFS.titleLg,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '🎮  GÖREV BAŞLIYOR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: AppFS.small,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (widget.content.isNotEmpty) ...[
              _contentBox(
                bgColor: tc.cBgBlue,
                borderColor: AppTheme.intro,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppTheme.intro,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            '💡',
                            style: TextStyle(fontSize: 15),
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
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.content,
                      style: TextStyle(
                        color: tc.cText,
                        fontSize: AppFS.body,
                        height: 1.75,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: tc.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: tc.border),
              ),
              child: Row(
                children: [
                  const Text('🕹️', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Her adımda görevleri tamamla, XP kazan!',
                      style: TextStyle(
                        color: tc.textMuted,
                        fontSize: AppFS.label,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            PrimaryButton(
              label: '▶  GÖREVE BAŞLA',
              onPressed: widget.onComplete,
              gradient: AppTheme.introGrad,
            ),
          ],
        ),
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
  final String notebookDefinition;
  final List<String> notebookItems;
  final List<NotebookSectionData> notebookSections;
  const ConceptCardsScreen({
    super.key,
    required this.items,
    required this.title,
    required this.onComplete,
    this.notebookDefinition = '',
    this.notebookItems = const [],
    this.notebookSections = const [],
  });

  @override
  State<ConceptCardsScreen> createState() => _ConceptCardsState();
}

class _ConceptCardsState extends State<ConceptCardsScreen> {
  bool _showNotebookPage = false;

  @override
  Widget build(BuildContext context) {
    final tc = TC.of(context);
    final hasNotebook =
        widget.notebookDefinition.isNotEmpty ||
        widget.notebookItems.isNotEmpty ||
        widget.notebookSections.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: AnimatedBuilder(
        animation: fontSizeNotifier,
        builder: (_, __) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StepHeader(
              emoji: '📚',
              label: 'KAVRAMLAR',
              title: widget.title,
              color: AppTheme.concept,
              colorLt: AppTheme.conceptLt,
            ),
            const SizedBox(height: 6),
            Text(
              _showNotebookPage
                  ? 'Simdi bu bilgileri duzenli sekilde defterine gecirebilirsin.'
                  : 'Once kavram notlarini oku, sonra ayri sayfada deftere yaz bolumune gec.',
              style: TextStyle(
                color: tc.textMuted,
                fontSize: AppFS.body,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final slide = Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(position: slide, child: child),
                );
              },
              child: _showNotebookPage
                  ? Column(
                      key: const ValueKey('notebook_page'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _NotebookSection(
                          definition: widget.notebookDefinition,
                          items: widget.notebookItems,
                          sections: widget.notebookSections,
                        ),
                        const SizedBox(height: 18),
                      ],
                    )
                  : Column(
                      key: const ValueKey('concept_notes_page'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.items.isNotEmpty)
                          _ConceptNotesSheet(items: widget.items),
                        if (widget.items.isNotEmpty) const SizedBox(height: 18),
                      ],
                    ),
            ),

            if (hasNotebook && !_showNotebookPage)
              PrimaryButton(
                label: 'İLERİ  →  DEFTERE YAZ',
                onPressed: () => setState(() => _showNotebookPage = true),
                color: AppTheme.concept,
              )
            else if (hasNotebook && _showNotebookPage)
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: '←  KAVRAM NOTLARI',
                      onPressed: () =>
                          setState(() => _showNotebookPage = false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      label: '✅  DEFTERE GECIRDIM',
                      onPressed: widget.onComplete,
                      color: AppTheme.concept,
                    ),
                  ),
                ],
              )
            else
              PrimaryButton(
                label: '✅  DEVAM ET',
                onPressed: widget.onComplete,
                color: AppTheme.concept,
              ),
          ],
        ),
      ),
    );
  }
}

class _ConceptNotesSheet extends StatelessWidget {
  final List<ConceptItem> items;
  const _ConceptNotesSheet({required this.items});

  @override
  Widget build(BuildContext context) {
    final tc = TC.of(context);

    const Color nbYellow = Color(0xFFFFFDE7);
    const Color nbYellowDk = Color(0xFFFFF9C4);
    const Color nbBorder = Color(0xFFE6C200);
    const Color nbLine = Color(0xFFE8E0A0);
    const Color nbText = Color(0xFF3E2F00);
    const Color nbMuted = Color(0xFF6B5800);
    const Color nbAccent = Color(0xFFB8860B);

    return AnimatedBuilder(
      animation: fontSizeNotifier,
      builder: (_, __) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: tc.isDark ? const Color(0xFF2A2200) : nbYellow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: nbBorder, width: 2),
          boxShadow: [
            BoxShadow(
              color: nbBorder.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
              decoration: BoxDecoration(
                color: tc.isDark ? const Color(0xFF3A3000) : nbYellowDk,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                border: Border(bottom: BorderSide(color: nbBorder, width: 1.5)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: nbAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: nbAccent.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Text('✍️', style: TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'KAVRAM NOTLARI',
                        style: TextStyle(
                          color: nbAccent,
                          fontSize: AppFS.small,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4,
                        ),
                      ),
                      Text(
                        'Bu bolumdeki bilgileri sirayla defterine yazabilirsin',
                        style: TextStyle(
                          color: nbMuted,
                          fontSize: AppFS.small,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: CustomPaint(
                painter: _NotebookLinesPainter(
                  lineColor: tc.isDark
                      ? nbLine.withValues(alpha: 0.15)
                      : nbLine,
                  lineHeight: AppFS.bodyLg * 1.8 + 18,
                ),
                child: Column(
                  children: items.asMap().entries.map((entry) {
                    final item = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: nbAccent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${entry.key + 1}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: AppFS.small,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${item.icon} ',
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: TextStyle(
                                          color: tc.isDark
                                              ? const Color(0xFFFFF9C4)
                                              : nbText,
                                          fontSize: AppFS.bodyLg,
                                          fontWeight: FontWeight.w800,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.desc,
                                  style: TextStyle(
                                    color: tc.isDark
                                        ? const Color(0xFFFFF9C4)
                                        : nbText,
                                    fontSize: AppFS.body,
                                    fontWeight: FontWeight.w600,
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// DEFTER BÖLÜMÜ — concept_explanation sonunda gösterilir
// Çizgili arka plan, defter sarısı, tanım + özet maddeler
// ────────────────────────────────────────────────────────────────────────────
class _NotebookSection extends StatefulWidget {
  final String definition;
  final List<String> items;
  final List<NotebookSectionData> sections;
  const _NotebookSection({
    required this.definition,
    required this.items,
    this.sections = const [],
  });

  @override
  State<_NotebookSection> createState() => _NotebookSectionState();
}

class _NotebookSectionState extends State<_NotebookSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tc = TC.of(context);
    final sections = widget.sections.isNotEmpty
        ? widget.sections
        : [
            if (widget.items.isNotEmpty)
              NotebookSectionData(title: 'OZET NOTLAR', items: widget.items),
          ];
    final sectionPages = _buildSectionPages(sections);
    final currentPageIndex = sectionPages.isEmpty
        ? 0
        : (_pageIndex >= sectionPages.length
              ? sectionPages.length - 1
              : _pageIndex);
    final visibleSections = sectionPages.isEmpty
        ? sections
        : sectionPages[currentPageIndex];
    // Defter sarısı — her iki temada da okunabilir
    const Color nbYellow = Color(0xFFFFFDE7);
    const Color nbYellowDk = Color(0xFFFFF9C4);
    const Color nbBorder = Color(0xFFE6C200);
    const Color nbLine = Color(0xFFE8E0A0);
    const Color nbText = Color(0xFF3E2F00);
    const Color nbMuted = Color(0xFF6B5800);
    const Color nbAccent = Color(0xFFB8860B);

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: AnimatedBuilder(
          animation: fontSizeNotifier,
          builder: (_, __) => Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: tc.isDark ? const Color(0xFF2A2200) : nbYellow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: nbBorder, width: 2),
              boxShadow: [
                BoxShadow(
                  color: nbBorder.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Başlık bandı ─────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                  decoration: BoxDecoration(
                    color: tc.isDark ? const Color(0xFF3A3000) : nbYellowDk,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                    border: Border(
                      bottom: BorderSide(color: nbBorder, width: 1.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: nbAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: nbAccent.withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Text('📓', style: TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DEFTERE YAZ',
                            style: TextStyle(
                              color: nbAccent,
                              fontSize: AppFS.small,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── İçerik — çizgili arka plan ────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tanım kutusu
                      if (widget.definition.isNotEmpty) ...[
                        Text(
                          'TANIM',
                          style: TextStyle(
                            color: nbAccent,
                            fontSize: AppFS.small,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(
                              alpha: tc.isDark ? 0.06 : 0.7,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border(
                              left: BorderSide(color: nbAccent, width: 4),
                            ),
                          ),
                          child: Text(
                            widget.definition,
                            style: TextStyle(
                              color: tc.isDark
                                  ? const Color(0xFFFFF9C4)
                                  : nbText,
                              fontSize: AppFS.bodyLg,
                              fontWeight: FontWeight.w700,
                              height: 1.6,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      if (visibleSections.isNotEmpty)
                        ...visibleSections.asMap().entries.expand((entry) {
                          final sectionIndex = entry.key;
                          final section = entry.value;
                          return [
                            Text(
                              section.title.toUpperCase(),
                              style: TextStyle(
                                color: nbAccent,
                                fontSize: AppFS.small,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            CustomPaint(
                              painter: _NotebookLinesPainter(
                                lineColor: tc.isDark
                                    ? nbLine.withValues(alpha: 0.15)
                                    : nbLine,
                                lineHeight: AppFS.bodyLg * 1.65 + 12,
                              ),
                              child: Column(
                                children: section.items.asMap().entries.map((
                                  e,
                                ) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 26,
                                          height: 26,
                                          decoration: BoxDecoration(
                                            color: nbAccent,
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            '${e.key + 1}',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: AppFS.small,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            e.value,
                                            style: TextStyle(
                                              color: tc.isDark
                                                  ? const Color(0xFFFFF9C4)
                                                  : nbText,
                                              fontSize: AppFS.bodyLg,
                                              fontWeight: FontWeight.w600,
                                              height: 1.55,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            if ((section.note ?? '').trim().isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(
                                    alpha: tc.isDark ? 0.06 : 0.7,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: nbAccent.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Text(
                                  section.note!,
                                  style: TextStyle(
                                    color: tc.isDark
                                        ? const Color(0xFFFFF9C4)
                                        : nbMuted,
                                    fontSize: AppFS.labelLg,
                                    fontWeight: FontWeight.w600,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                            if (sectionIndex != visibleSections.length - 1)
                              const SizedBox(height: 20),
                          ];
                        }),

                      if (sectionPages.length > 1) ...[
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: nbAccent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: nbAccent.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                'Bolum ${currentPageIndex + 1}/${sectionPages.length}',
                                style: TextStyle(
                                  color: nbAccent,
                                  fontSize: AppFS.small,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Row(
                                children: List.generate(sectionPages.length, (
                                  i,
                                ) {
                                  final active = i == currentPageIndex;
                                  return Expanded(
                                    child: Container(
                                      height: 7,
                                      margin: EdgeInsets.only(
                                        right: i == sectionPages.length - 1
                                            ? 0
                                            : 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: active
                                            ? nbAccent
                                            : nbAccent.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: AnimatedOpacity(
                                opacity: currentPageIndex == 0 ? 0.55 : 1,
                                duration: const Duration(milliseconds: 180),
                                child: IgnorePointer(
                                  ignoring: currentPageIndex == 0,
                                  child: SecondaryButton(
                                    label: '←  ONCEKI BOLUM',
                                    onPressed: () =>
                                        setState(() => _pageIndex--),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AnimatedOpacity(
                                opacity:
                                    currentPageIndex == sectionPages.length - 1
                                    ? 0.55
                                    : 1,
                                duration: const Duration(milliseconds: 180),
                                child: IgnorePointer(
                                  ignoring:
                                      currentPageIndex ==
                                      sectionPages.length - 1,
                                  child: PrimaryButton(
                                    label: 'SONRAKI BOLUM  →',
                                    onPressed: () =>
                                        setState(() => _pageIndex++),
                                    color: nbAccent,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<List<NotebookSectionData>> _buildSectionPages(
    List<NotebookSectionData> sections,
  ) {
    if (sections.isEmpty) return const [];

    const int maxItemsPerPage = 6;
    const int maxSectionsPerPage = 2;
    final pages = <List<NotebookSectionData>>[];
    var currentPage = <NotebookSectionData>[];
    var currentItems = 0;

    for (final section in sections) {
      final sectionItems = section.items.length;
      final exceedsSectionLimit = currentPage.length >= maxSectionsPerPage;
      final exceedsItemLimit =
          currentPage.isNotEmpty &&
          currentItems + sectionItems > maxItemsPerPage;

      if (exceedsSectionLimit || exceedsItemLimit) {
        pages.add(currentPage);
        currentPage = <NotebookSectionData>[];
        currentItems = 0;
      }

      currentPage.add(section);
      currentItems += sectionItems;
    }

    if (currentPage.isNotEmpty) {
      pages.add(currentPage);
    }

    return pages;
  }
}

// Çizgili defter arka planı çizen painter
class _NotebookLinesPainter extends CustomPainter {
  final Color lineColor;
  final double lineHeight;
  const _NotebookLinesPainter({
    required this.lineColor,
    required this.lineHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    double y = lineHeight;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      y += lineHeight;
    }
  }

  @override
  bool shouldRepaint(_NotebookLinesPainter old) =>
      old.lineColor != lineColor || old.lineHeight != lineHeight;
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
  int _currentIndex = 0;
  final Set<int> _seen = {};

  @override
  void initState() {
    super.initState();
    if (widget.items.isNotEmpty) {
      _seen.add(0);
    }
  }

  Color _riskColor(String level) {
    final normalized = level
        .toLowerCase()
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ı', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g');
    if (normalized.contains('yuksek')) return const Color(0xFFE53935);
    if (normalized.contains('orta')) return const Color(0xFFFB8C00);
    if (normalized.contains('dusuk')) return const Color(0xFF43A047);
    return AppTheme.risk;
  }

  String _riskLabel(String level) {
    if (level.trim().isEmpty) return 'incele';
    return level;
  }

  @override
  Widget build(BuildContext context) {
    final tc = TC.of(context);
    final hasItems = widget.items.isNotEmpty;
    final item = hasItems ? widget.items[_currentIndex] : null;
    final isLast = !hasItems || _currentIndex == widget.items.length - 1;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: AnimatedBuilder(
        animation: fontSizeNotifier,
        builder: (_, __) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StepHeader(
              emoji: widget.icon,
              label: 'RİSK ANALİZİ',
              title: widget.title,
              color: AppTheme.risk,
              colorLt: AppTheme.riskLt,
            ),
            const SizedBox(height: 6),
            Text(
              'Yanilgi, nedeni ve duzeltme yolunu adim adim incele',
              style: TextStyle(color: tc.textMuted, fontSize: AppFS.label),
            ),
            const SizedBox(height: 14),
            if (hasItems) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: tc.cBgOrange,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppTheme.risk.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      'Risk ${_currentIndex + 1}/${widget.items.length}',
                      style: TextStyle(
                        color: AppTheme.risk,
                        fontSize: AppFS.small,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Row(
                      children: List.generate(widget.items.length, (index) {
                        final active = index == _currentIndex;
                        final seen = _seen.contains(index);
                        return Expanded(
                          child: Container(
                            height: 8,
                            margin: EdgeInsets.only(
                              right: index == widget.items.length - 1 ? 0 : 6,
                            ),
                            decoration: BoxDecoration(
                              color: active
                                  ? AppTheme.risk
                                  : seen
                                  ? AppTheme.risk.withValues(alpha: 0.35)
                                  : tc.surface,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final slide = Tween<Offset>(
                    begin: const Offset(0.08, 0),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: slide, child: child),
                  );
                },
                child: Container(
                  key: ValueKey(_currentIndex),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: tc.cBgOrange,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.risk, width: 1.8),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.risk.withValues(alpha: 0.22),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.risk,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${_currentIndex + 1}',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: AppFS.labelLg,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item!.misconception,
                              style: TextStyle(
                                color: tc.cText,
                                fontWeight: FontWeight.w800,
                                fontSize: AppFS.title,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _riskColor(
                                item.riskLevel,
                              ).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: _riskColor(
                                  item.riskLevel,
                                ).withValues(alpha: 0.35),
                              ),
                            ),
                            child: Text(
                              _riskLabel(item.riskLevel),
                              style: TextStyle(
                                color: _riskColor(item.riskLevel),
                                fontSize: AppFS.small,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (item.whyItHappens.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _RiskDetailCard(
                          icon: '🧠',
                          title: 'Neden boyle dusunuluyor?',
                          text: item.whyItHappens,
                          color: const Color(0xFFFFB300),
                        ),
                      ],
                      if (item.truth.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _RiskDetailCard(
                          icon: '✅',
                          title: 'Dogrusu ne?',
                          text: item.truth,
                          color: const Color(0xFF43A047),
                        ),
                      ],
                      if (item.fixTip.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _RiskDetailCard(
                          icon: '🛠️',
                          title: 'Nasil duzeltilir?',
                          text: item.fixTip,
                          color: const Color(0xFF1E88E5),
                        ),
                      ],
                      if (item.miniCheck.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _RiskDetailCard(
                          icon: '❓',
                          title: 'Mini kontrol',
                          text: item.miniCheck,
                          color: AppTheme.risk,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AnimatedOpacity(
                      opacity: _currentIndex == 0 ? 0.55 : 1,
                      duration: const Duration(milliseconds: 200),
                      child: IgnorePointer(
                        ignoring: _currentIndex == 0,
                        child: PrimaryButton(
                          label: '←  GERI',
                          onPressed: () => setState(() => _currentIndex--),
                          color: AppTheme.risk,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AnimatedOpacity(
                      opacity: isLast ? 0.55 : 1,
                      duration: const Duration(milliseconds: 200),
                      child: IgnorePointer(
                        ignoring: isLast,
                        child: PrimaryButton(
                          label: isLast ? 'SON RISKI GORDUM' : 'ILERI  →',
                          onPressed: () => setState(() {
                            _currentIndex++;
                            _seen.add(_currentIndex);
                          }),
                          color: AppTheme.risk,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
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
      ),
    );
  }
}

class _RiskDetailCard extends StatelessWidget {
  final String icon;
  final String title;
  final String text;
  final Color color;
  const _RiskDetailCard({
    required this.icon,
    required this.title,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tc = TC.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$icon ', style: const TextStyle(fontSize: 14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: AppFS.small,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: TextStyle(
                    color: tc.cTextMid,
                    fontSize: AppFS.labelLg,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 3 · SCENARIO CHOICE
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
    final tc = TC.of(context);
    final answered = _sel != null;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: AnimatedBuilder(
        animation: fontSizeNotifier,
        builder: (_, __) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StepHeader(
              emoji: '🎯',
              label: 'SENARYO',
              title: 'Ne yapardın?',
              color: AppTheme.scenario,
              colorLt: AppTheme.scenarioLt,
            ),
            const SizedBox(height: 14),

            _contentBox(
              bgColor: tc.cBgOrange,
              borderColor: AppTheme.scenario,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppTheme.scenario,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Text('📌', style: TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.context,
                      style: TextStyle(
                        color: tc.cText,
                        fontSize: AppFS.body,
                        height: 1.65,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            Text(
              widget.question,
              style: TextStyle(
                color: tc.textBody,
                fontSize: AppFS.bodyLg,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),

            ...widget.options.asMap().entries.map(
              (e) => _answerOption(
                ctx: context,
                label: _letters[e.key],
                text: e.value,
                answered: answered,
                isCorrect: e.key == widget.correct,
                isSelected: e.key == _sel,
                onTap: () => setState(() => _sel = e.key),
              ),
            ),

            if (answered) ...[
              const SizedBox(height: 4),
              _feedbackBox(
                context,
                (_sel != null &&
                        _sel! < widget.feedbacks.length &&
                        widget.feedbacks[_sel!].trim().isNotEmpty)
                    ? widget.feedbacks[_sel!]
                    : widget.explanation,
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                label: 'DEVAM  →',
                onPressed: widget.onComplete,
                color: AppTheme.scenario,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 4 · ROLE PLAY
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
  // _cols ve _lights build() içinde tc ile

  @override
  Widget build(BuildContext context) {
    final tc = TC.of(context);
    final _cols = [
      AppTheme.intro,
      AppTheme.scenario,
      AppTheme.concept,
      AppTheme.quiz,
    ];
    final _lights = [tc.cBgBlue, tc.cBgOrange, tc.cBgGreen, tc.cBgPurple];
    final done = _step >= widget.script.length;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: AnimatedBuilder(
        animation: fontSizeNotifier,
        builder: (_, __) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StepHeader(
              emoji: '🎭',
              label: 'ROL YAPMA',
              title: 'Canlandıralım!',
              color: AppTheme.scenario,
              colorLt: AppTheme.scenarioLt,
            ),
            const SizedBox(height: 14),
            ...widget.script.asMap().entries.map((e) {
              final i = e.key;
              final line = e.value;
              final visible = i <= _step;
              final col = _cols[i % _cols.length];
              final bg = _lights[i % _lights.length];
              return AnimatedOpacity(
                opacity: visible ? 1 : 0,
                duration: const Duration(milliseconds: 400),
                child: AnimatedSlide(
                  offset: visible ? Offset.zero : const Offset(0, 0.06),
                  duration: const Duration(milliseconds: 400),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: visible ? bg : tc.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: visible
                              ? col.withValues(alpha: 0.6)
                              : tc.border,
                          width: visible ? 2 : 1.5,
                        ),
                        boxShadow: visible
                            ? [
                                BoxShadow(
                                  color: col.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: col,
                              borderRadius: BorderRadius.circular(9),
                              boxShadow: [
                                BoxShadow(
                                  color: col.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: AppFS.labelLg,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
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
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  line['action'] ?? '',
                                  style: TextStyle(
                                    color: tc.cText,
                                    fontSize: AppFS.body,
                                    height: 1.5,
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
              );
            }),
            const SizedBox(height: 8),
            PrimaryButton(
              label: done ? 'HARİKA! DEVAM  →' : 'SONRAKİ SAHNE  →',
              onPressed: done
                  ? widget.onComplete
                  : () => setState(() => _step++),
              color: AppTheme.scenario,
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 5 · PERMISSION DETECTIVE (mini_game)
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
  int _qi = 0, _correct = 0;
  int? _sel;
  bool _answered = false, _done = false;
  static const _letters = ['A', 'B', 'C', 'D'];

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
    final tc = TC.of(context);
    if (_done) {
      final pct = widget.items.isEmpty ? 0.0 : _correct / widget.items.length;
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
        child: AnimatedBuilder(
          animation: fontSizeNotifier,
          builder: (_, __) => Column(
            children: [
              const SizedBox(height: 24),
              Text(
                pct == 1.0 ? '🎉' : '👍',
                style: const TextStyle(fontSize: 72),
              ),
              const SizedBox(height: 12),
              Text(
                '$_correct / ${widget.items.length} DOĞRU!',
                style: TextStyle(
                  color: AppTheme.game,
                  fontSize: AppFS.titleLg,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                pct == 1.0
                    ? 'MÜKEMMEL! Hepsini doğru yaptın! 🏆'
                    : 'İyi iş! Tekrar deneyerek gelişebilirsin.',
                style: TextStyle(color: tc.textMuted, fontSize: AppFS.body),
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
        ),
      );
    }

    final item = widget.items[_qi];
    final correctAns = (item['correct_answer'] ?? '').toString().trim();
    final feedback = (item['feedback'] ?? '').toString();
    final situation = (item['situation'] ?? '').toString();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: AnimatedBuilder(
        animation: fontSizeNotifier,
        builder: (_, __) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StepHeader(
              emoji: '🎮',
              label: 'MİNİ OYUN',
              title: widget.title,
              color: AppTheme.game,
              colorLt: AppTheme.gameLt,
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 7,
                        decoration: BoxDecoration(
                          color: tc.surface,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: _qi / widget.items.length,
                        child: Container(
                          height: 7,
                          decoration: BoxDecoration(
                            gradient: AppTheme.gameGrad,
                            borderRadius: BorderRadius.circular(99),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.game.withValues(alpha: 0.5),
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
                    fontSize: AppFS.labelLg,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            _contentBox(
              bgColor: tc.cBgGreen,
              borderColor: AppTheme.game,
              child: Text(
                situation,
                style: TextStyle(
                  color: tc.cText,
                  fontSize: AppFS.bodyLg,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 14),

            ...widget.answerOptions.asMap().entries.map((e) {
              final i = e.key;
              final opt = e.value;
              final isCorr = opt == correctAns;
              final isSel = i == _sel;
              return _answerOption(
                ctx: context,
                label: _letters[i < _letters.length ? i : 0],
                text: opt,
                answered: _answered,
                isCorrect: isCorr,
                isSelected: isSel,
                onTap: () => _choose(i),
              );
            }),

            if (_answered) ...[
              if (feedback.isNotEmpty) ...[
                _feedbackBox(context, feedback),
                const SizedBox(height: 14),
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
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 6 · SECURITY SCORE
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
    final tc = TC.of(context);
    final answered = _answers.length == widget.questions.length;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: AnimatedBuilder(
        animation: fontSizeNotifier,
        builder: (_, __) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StepHeader(
              emoji: '🛡️',
              label: 'GÜVENLİK SKORU',
              title: 'Ne Kadar Güvenlisin?',
              color: AppTheme.game,
              colorLt: AppTheme.gameLt,
            ),
            const SizedBox(height: 14),
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
                        ? tc.card
                        : ans
                        ? tc.greenLt
                        : tc.redLt,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: ans == null
                          ? tc.border
                          : ans
                          ? tc.green
                          : tc.red,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(q.icon, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          q.text,
                          style: TextStyle(
                            color: ans == null ? tc.textBody : tc.cText,
                            fontSize: AppFS.body,
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
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: AppTheme.gameGrad,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.game.withValues(alpha: 0.4),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Text('⚡', style: TextStyle(fontSize: 26)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GÜVENLİK SKORUM',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: AppFS.small,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          '$_score puan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: AppFS.titleLg,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
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
      ),
    );
  }
}

class _NeonYesNo extends StatelessWidget {
  final bool? value;
  final void Function(bool) onChanged;
  const _NeonYesNo({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final tc = TC.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _NBtn(
          label: 'EVET',
          selected: value == true,
          color: tc.green,
          onTap: () => onChanged(true),
        ),
        const SizedBox(width: 5),
        _NBtn(
          label: 'HAYIR',
          selected: value == false,
          color: tc.red,
          onTap: () => onChanged(false),
        ),
      ],
    );
  }
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
  Widget build(BuildContext context) {
    final tc = TC.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: fontSizeNotifier,
        builder: (_, __) => AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? color : tc.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? color : tc.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : tc.textMuted,
              fontSize: AppFS.small,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 7 · REFLECTION
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
    final tc = TC.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: AnimatedBuilder(
        animation: fontSizeNotifier,
        builder: (_, __) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StepHeader(
              emoji: '🌱',
              label: 'YANSITMA',
              title: widget.title,
              color: AppTheme.reflect,
              colorLt: AppTheme.reflectLt,
            ),
            if (widget.intro.isNotEmpty) ...[
              const SizedBox(height: 12),
              _contentBox(
                bgColor: tc.cBgTeal,
                borderColor: AppTheme.reflect,
                child: Text(
                  widget.intro,
                  style: TextStyle(
                    color: tc.cText,
                    fontSize: AppFS.body,
                    height: 1.65,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'KENDİNE SOR:',
              style: TextStyle(
                color: AppTheme.reflect,
                fontSize: AppFS.small,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
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
                      color: checked ? tc.cBgTeal : tc.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: checked ? AppTheme.reflect : tc.border,
                        width: checked ? 2 : 1.5,
                      ),
                      boxShadow: checked
                          ? [
                              BoxShadow(
                                color: AppTheme.reflect.withValues(alpha: 0.25),
                                blurRadius: 10,
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
                              color: checked ? AppTheme.reflect : tc.border,
                              width: 2,
                            ),
                          ),
                          child: checked
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 14,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            q,
                            style: TextStyle(
                              color: checked ? tc.cText : tc.textBody,
                              fontSize: AppFS.body,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
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
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tc.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: tc.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📝 '),
                    Expanded(
                      child: Text(
                        widget.note,
                        style: TextStyle(
                          color: tc.textMuted,
                          fontSize: AppFS.label,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'DEĞERLENDİRDİM  →',
              onPressed: widget.onComplete,
              color: AppTheme.reflect,
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 8 · WORD BANK
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
  late AnimationController _shakeCtrl;

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
    final tc = TC.of(context);
    final parts = widget.template.split(RegExp(r'_{3,}'));
    final widgets = <Widget>[];
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        widgets.add(
          AnimatedBuilder(
            animation: fontSizeNotifier,
            builder: (_, __) => Text(
              parts[i],
              style: TextStyle(
                color: tc.cText,
                fontSize: AppFS.body,
                height: 1.7,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }
      if (i < widget.blanks.length) {
        final word = _selected[i];
        final wrong = _wrongSlots.contains(i);
        widgets.add(
          AnimatedBuilder(
            animation: Listenable.merge([_shakeCtrl, fontSizeNotifier]),
            builder: (_, __) {
              final dx = wrong
                  ? math.sin(_shakeCtrl.value * math.pi * 8) * 5
                  : 0.0;
              return Transform.translate(
                offset: Offset(dx, 0),
                child: GestureDetector(
                  onTap: () => _removeWord(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 3,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: word == null
                          ? tc.cBgPink
                          : wrong
                          ? tc.redLt
                          : tc.greenLt,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: word == null
                            ? AppTheme.word
                            : wrong
                            ? tc.red
                            : tc.green,
                        width: 2,
                      ),
                      boxShadow: word != null
                          ? [
                              BoxShadow(
                                color: (wrong ? tc.red : tc.green).withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 8,
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
                            ? tc.red
                            : tc.green,
                        fontWeight: FontWeight.w800,
                        fontSize: AppFS.body,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final tc = TC.of(context);
    final allFilled = _selected.every((e) => e != null);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: AnimatedBuilder(
        animation: fontSizeNotifier,
        builder: (_, __) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StepHeader(
              emoji: '🧩',
              label: 'KELIME BANKASI',
              title: widget.title,
              color: AppTheme.word,
              colorLt: AppTheme.wordLt,
            ),
            if (widget.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                widget.description,
                style: TextStyle(
                  color: tc.textMuted,
                  fontSize: AppFS.label,
                  height: 1.6,
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Cümle şablonu
            _contentBox(
              bgColor: tc.cBgPink,
              borderColor: AppTheme.word,
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 4,
                children: _buildTemplateParts(),
              ),
            ),
            const SizedBox(height: 14),

            Text(
              '📦  KELIME HAVUZU',
              style: TextStyle(
                color: AppTheme.word,
                fontSize: AppFS.small,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: tc.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: tc.border),
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
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.wordLt,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.word.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.word.withValues(alpha: 0.2),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Text(
                            word,
                            style: TextStyle(
                              color: AppTheme.word,
                              fontWeight: FontWeight.w700,
                              fontSize: AppFS.body,
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
              _feedbackBox(
                context,
                'Hatalı boşluğa dokun, kelimeyi geri gönder!',
                isGood: false,
              ),
            ],
            const SizedBox(height: 18),

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
                  color: tc.greenLt,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: tc.greenBdr, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: tc.green.withValues(alpha: 0.3),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Text('🎉 ', style: TextStyle(fontSize: 20)),
                    Expanded(
                      child: Text(
                        'MÜKEMMEL! Tüm boşlukları doğru doldurdun.',
                        style: TextStyle(
                          color: tc.green,
                          fontWeight: FontWeight.w800,
                          fontSize: AppFS.body,
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
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 9 · CRITICAL THINKING
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
    final tc = TC.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: AnimatedBuilder(
        animation: fontSizeNotifier,
        builder: (_, __) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StepHeader(
              emoji: '🧠',
              label: 'KRİTİK DÜŞÜNME',
              title: widget.title,
              color: AppTheme.quiz,
              colorLt: AppTheme.quizLt,
            ),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: tc.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: tc.border),
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
            const SizedBox(height: 14),

            if (_tab == 0)
              ..._buildList(widget.prompts, AppTheme.quiz, tc.cBgPurple, '❓')
            else if (_tab == 1)
              ..._buildList(widget.hints, AppTheme.concept, tc.cBgGreen, '💡')
            else
              ..._buildList(
                widget.discussion,
                AppTheme.scenario,
                tc.cBgOrange,
                '💬',
              ),

            if (widget.tasks.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                '📋 GÖREVLER',
                style: TextStyle(
                  color: AppTheme.quiz,
                  fontSize: AppFS.small,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              ...widget.tasks.map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: tc.cBgPurple,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.quizBdr),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.quiz, width: 2),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            t,
                            style: TextStyle(
                              color: tc.cText,
                              fontSize: AppFS.body,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'DÜŞÜNDÜM  →',
              onPressed: widget.onComplete,
              color: AppTheme.quiz,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildList(
    List<String> items,
    Color color,
    Color bg,
    String icon,
  ) {
    final tc = TC.of(context);
    return items
        .map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: color.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(icon, style: const TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        color: tc.cText,
                        fontSize: AppFS.body,
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
  Widget build(BuildContext context) {
    final tc = TC.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedBuilder(
          animation: fontSizeNotifier,
          builder: (_, __) => AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: active ? color : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 10,
                      ),
                    ]
                  : [],
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : tc.textMuted,
                fontSize: AppFS.small,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 10 · INFOGRAPHIC (summary)
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
  // _cols/_bgs build() içinde

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

  @override
  Widget build(BuildContext context) {
    final tc = TC.of(context);
    final cols = [
      AppTheme.primaryGlow,
      AppTheme.intro,
      AppTheme.concept,
      AppTheme.scenario,
      AppTheme.quiz,
      AppTheme.reflect,
    ];
    final bgs = [
      tc.cBgBlue,
      tc.cBgGreen,
      tc.cBgOrange,
      tc.cBgPurple,
      tc.cBgYellow,
      tc.cBgTeal,
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: AnimatedBuilder(
        animation: fontSizeNotifier,
        builder: (_, __) => Column(
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
              const SizedBox(height: 10),
              Text(
                widget.description,
                style: TextStyle(
                  color: tc.textMuted,
                  fontSize: AppFS.body,
                  height: 1.6,
                ),
              ),
            ],
            const SizedBox(height: 16),
            ...widget.points.asMap().entries.map((e) {
              final visible = e.key <= _vis;
              final col = cols[e.key % cols.length];
              final bg = bgs[e.key % bgs.length];
              return AnimatedOpacity(
                opacity: visible ? 1 : 0,
                duration: const Duration(milliseconds: 350),
                child: AnimatedSlide(
                  offset: visible ? Offset.zero : const Offset(-0.04, 0),
                  duration: const Duration(milliseconds: 350),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: col.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: col.withValues(alpha: 0.15),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: col,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${e.key + 1}',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: AppFS.labelLg,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              e.value,
                              style: TextStyle(
                                color: tc.cText,
                                fontSize: AppFS.body,
                                fontWeight: FontWeight.w700,
                                height: 1.4,
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
            const SizedBox(height: 18),
            PrimaryButton(label: 'ANLADIM  →', onPressed: widget.onComplete),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 11 · MULTI QUIZ
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
    final tc = TC.of(context);
    if (_done) {
      final pct = widget.questions.isEmpty
          ? 0.0
          : _score / widget.questions.length;
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
        child: AnimatedBuilder(
          animation: fontSizeNotifier,
          builder: (_, __) => Column(
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
              const SizedBox(height: 10),
              Text(
                '$_score / ${widget.questions.length}',
                style: TextStyle(
                  color: AppTheme.quiz,
                  fontSize: AppFS.titleLg * 1.4,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                pct == 1.0
                    ? 'MÜKEMMEL! Tüm soruları doğru! 🏆'
                    : pct >= 0.7
                    ? 'Harika iş! Çok yaklaştın!'
                    : 'Tekrar deneyerek gelişebilirsin.',
                style: TextStyle(color: tc.textMuted, fontSize: AppFS.body),
                textAlign: TextAlign.center,
              ),
              if (pct == 1.0) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.certLt,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.certBdr),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.cert.withValues(alpha: 0.3),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🏅 ', style: TextStyle(fontSize: 20)),
                      Flexible(
                        child: Text(
                          '"BİLGİ USTASI" ROZETİ KAZANDIN!',
                          style: TextStyle(
                            color: AppTheme.certDk,
                            fontWeight: FontWeight.w800,
                            fontSize: AppFS.body,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 22),
              PrimaryButton(
                label: 'DEVAM  →',
                onPressed: widget.onComplete,
                color: AppTheme.quiz,
              ),
            ],
          ),
        ),
      );
    }

    final q = widget.questions[_qi];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: AnimatedBuilder(
        animation: fontSizeNotifier,
        builder: (_, __) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: StepHeader(
                    emoji: '❓',
                    label: 'SORU ${_qi + 1}/${widget.questions.length}',
                    title: '',
                    color: AppTheme.quiz,
                    colorLt: AppTheme.quizLt,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: tc.greenLt,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: tc.greenBdr),
                  ),
                  child: Text(
                    '$_score ✓',
                    style: TextStyle(
                      color: tc.green,
                      fontWeight: FontWeight.w800,
                      fontSize: AppFS.labelLg,
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
                    color: tc.surface,
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
                          color: AppTheme.quiz.withValues(alpha: 0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _contentBox(
              bgColor: tc.cBgPurple,
              borderColor: AppTheme.quiz,
              child: Text(
                q.q,
                style: TextStyle(
                  color: tc.cText,
                  fontSize: AppFS.bodyLg,
                  fontWeight: FontWeight.w800,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 14),

            ...q.opts.asMap().entries.map(
              (e) => _answerOption(
                ctx: context,
                label: _letters[e.key < _letters.length ? e.key : 0],
                text: e.value,
                answered: _answered,
                isCorrect: e.key == q.ans,
                isSelected: e.key == _sel,
                onTap: () => _choose(e.key),
              ),
            ),

            if (_answered) ...[
              _feedbackBox(context, q.exp),
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
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 12 · MYTH BUSTERS
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
    final tc = TC.of(context);
    final done = _revealed.length == widget.myths.length;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: AnimatedBuilder(
        animation: fontSizeNotifier,
        builder: (_, __) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StepHeader(
              emoji: '🔬',
              label: 'EFSANE Mİ?',
              title: 'Yanılgıları Kır!',
              color: AppTheme.risk,
              colorLt: AppTheme.riskLt,
            ),
            const SizedBox(height: 14),
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
                      color: rev ? tc.greenLt : tc.cBgOrange,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: rev ? tc.greenBdr : AppTheme.riskBdr,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (rev ? tc.green : AppTheme.risk).withValues(
                            alpha: 0.2,
                          ),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              myth.icon,
                              style: const TextStyle(fontSize: 22),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: rev ? tc.green : AppTheme.risk,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                rev ? '✅ GERÇEK' : '❓ YANILGI',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: AppFS.small,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          myth.myth,
                          style: TextStyle(
                            color: rev ? tc.cTextSoft : tc.cText,
                            fontSize: AppFS.body,
                            fontWeight: FontWeight.w700,
                            decoration: rev ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        if (rev) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(10),
                              border: Border(
                                left: BorderSide(color: tc.green, width: 3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '✅ ${myth.truth}',
                                  style: TextStyle(
                                    color: tc.green,
                                    fontSize: AppFS.body,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '📌 ${myth.example}',
                                  style: TextStyle(
                                    color: tc.cTextMid,
                                    fontSize: AppFS.label,
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
                              fontSize: AppFS.small,
                              fontWeight: FontWeight.w600,
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
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 13 · CERTIFICATE
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
      begin: 0.95,
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
    final tc = TC.of(context);
    final _tcols = [
      AppTheme.concept,
      AppTheme.intro,
      AppTheme.game,
      AppTheme.quiz,
      AppTheme.word,
      AppTheme.scenario,
      AppTheme.reflect,
    ];
    final _tbgs = [
      tc.cBgGreen,
      tc.cBgBlue,
      tc.cBgYellow,
      tc.cBgPurple,
      tc.cBgPink,
      tc.cBgOrange,
      tc.cBgTeal,
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: AnimatedBuilder(
        animation: fontSizeNotifier,
        builder: (_, __) => Column(
          children: [
            ScaleTransition(
              scale: _pulse,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  gradient: AppTheme.certGrad,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.cert.withValues(alpha: 0.45),
                      blurRadius: 28,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text('🏆', style: TextStyle(fontSize: 64)),
                    const SizedBox(height: 12),
                    Text(
                      widget.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: AppFS.titleLg,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.message,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: AppFS.body,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('⚡', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            '${widget.xp} XP KAZANDIN!',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: AppFS.body,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'NELER ÖĞRENDİN:',
                style: TextStyle(
                  color: tc.subtle,
                  fontSize: AppFS.small,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 10),

            ...widget.takeaways.asMap().entries.map((e) {
              final visible = e.key <= _vis;
              final col = _tcols[e.key % _tcols.length];
              final bg = _tbgs[e.key % _tbgs.length];
              return AnimatedOpacity(
                opacity: visible ? 1 : 0,
                duration: const Duration(milliseconds: 400),
                child: AnimatedSlide(
                  offset: visible ? Offset.zero : const Offset(-0.04, 0),
                  duration: const Duration(milliseconds: 400),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: col.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: col,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              e.value,
                              style: TextStyle(
                                color: tc.cText,
                                fontSize: AppFS.body,
                                fontWeight: FontWeight.w700,
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

            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: tc.cBgPurple,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.quizBdr),
              ),
              child: Row(
                children: [
                  const Text('🌟 ', style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Text(
                      'Öğrendiklerini arkadaşlarınla paylaş!',
                      style: TextStyle(
                        color: AppTheme.quiz,
                        fontSize: AppFS.body,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SecondaryButton(
              label: '🔄  TEKRAR AL',
              onPressed: widget.onRestart,
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// STUBS — case swipe, digital footprint, analysis, keywords, progress tracker
// ────────────────────────────────────────────────────────────────────────────
class CaseSwipeScreen extends StatelessWidget {
  final List<CaseStudy> cases;
  final VoidCallback onComplete;
  const CaseSwipeScreen({
    super.key,
    required this.cases,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      children: [
        const SizedBox(height: 20),
        PrimaryButton(label: 'DEVAM  →', onPressed: onComplete),
      ],
    ),
  );
}

class DigitalFootprintScreen extends StatelessWidget {
  final List<TimelineItem> timeline;
  final VoidCallback onComplete;
  const DigitalFootprintScreen({
    super.key,
    required this.timeline,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      children: [
        const SizedBox(height: 20),
        PrimaryButton(label: 'DEVAM  →', onPressed: onComplete),
      ],
    ),
  );
}

class AnalysisScreen extends StatelessWidget {
  final List<AnalysisItem> items;
  final VoidCallback onComplete;
  const AnalysisScreen({
    super.key,
    required this.items,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      children: [
        const SizedBox(height: 20),
        PrimaryButton(label: 'DEVAM  →', onPressed: onComplete),
      ],
    ),
  );
}

class KeywordsScreen extends StatelessWidget {
  final VoidCallback onComplete;
  final List<KeywordItem> items;
  final String title;
  final String description;
  const KeywordsScreen({
    super.key,
    required this.onComplete,
    required this.items,
    this.title = 'Anahtar Kavramlar',
    this.description = '',
  });

  @override
  Widget build(BuildContext context) {
    final tc = TC.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: AnimatedBuilder(
        animation: fontSizeNotifier,
        builder: (_, __) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StepHeader(
              emoji: '🗝️',
              label: 'ANAHTAR KAVRAMLAR',
              title: title,
              color: AppTheme.word,
              colorLt: AppTheme.wordLt,
            ),
            const SizedBox(height: 8),
            Text(
              description.isNotEmpty
                  ? description
                  : 'Bu derste sik karsilasacagin temel kavramlari once tanimak isini kolaylastirir.',
              style: TextStyle(
                color: tc.textMuted,
                fontSize: AppFS.body,
                fontWeight: FontWeight.w600,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 16),
            ...items.asMap().entries.map((entry) {
              final item = entry.value;
              final showDef = item.def.trim().isNotEmpty;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: tc.cBgPurple,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.word.withValues(alpha: 0.35),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.word.withValues(alpha: 0.16),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppTheme.word,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${entry.key + 1}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: AppFS.small,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.term,
                              style: TextStyle(
                                color: tc.cText,
                                fontSize: AppFS.bodyLg,
                                fontWeight: FontWeight.w800,
                                height: 1.35,
                              ),
                            ),
                            if (showDef) ...[
                              const SizedBox(height: 4),
                              Text(
                                item.def,
                                style: TextStyle(
                                  color: tc.cTextMid,
                                  fontSize: AppFS.body,
                                  fontWeight: FontWeight.w600,
                                  height: 1.55,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            PrimaryButton(label: 'DEVAM  →', onPressed: onComplete),
          ],
        ),
      ),
    );
  }
}

class ProgressTrackerScreen extends StatelessWidget {
  final VoidCallback onComplete;
  const ProgressTrackerScreen({super.key, required this.onComplete});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      children: [
        const SizedBox(height: 20),
        PrimaryButton(label: 'DEVAM  →', onPressed: onComplete),
      ],
    ),
  );
}
