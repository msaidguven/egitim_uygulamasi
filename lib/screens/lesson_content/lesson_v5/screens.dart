import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'theme.dart';
import 'models.dart';
import 'lesson_data.dart';

// ─── STEP SCREENS ─────────────────────────────────────────────────────────────
// Each screen receives [onComplete] callback and calls it when the user finishes.

// ────────────────────────────────────────────────────────────────────────────
// 0 · INTRO
// ────────────────────────────────────────────────────────────────────────────
class IntroScreen extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback onComplete;
  const IntroScreen({
    super.key,
    required this.onComplete,
    this.title = 'Dijital Dünyada Yapay Zekâ 🚀',
    this.content =
        'Telefonumuzdaki yüz tanıma sistemi, video önerileri yapan uygulamalar ya da sesli asistanlar… Hepsi yapay zekâ kullanır.',
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                const Text('🚀', style: TextStyle(fontSize: 72)),
                const SizedBox(height: 12),
                ShaderMask(
                  shaderCallback: (b) => AppTheme.primaryGrad.createShader(b),
                  child: const Text(
                    'Ders Başlıyor 🚀',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            content,
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 14,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 20),
          AppCard(
            background: AppTheme.blueDark,
            borderColor: AppTheme.blue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡', style: TextStyle(fontSize: 24)),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF93C5FD),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Hazırsan başlayalım!',
                  style: TextStyle(color: Color(0xFF60A5FA), fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(label: 'Başlayalım →', onPressed: onComplete),
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

  @override
  Widget build(BuildContext context) {
    final done = _seen.length == widget.items.length;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PillBadge(
            text: '📚 Kavramlar',
            bg: AppTheme.indigo,
            color: Color(0xFFA5B4FC),
          ),
          const SizedBox(height: 10),
          Text(
            widget.title,
            style: const TextStyle(
              color: AppTheme.textBody,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Her karta dokun! 👇',
            style: TextStyle(color: AppTheme.subtle, fontSize: 12),
          ),
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 260,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.95,
            ),
            itemCount: widget.items.length,
            itemBuilder: (_, i) {
              final item = widget.items[i];
              final active = _seen.contains(i);
              return GestureDetector(
                onTap: () => setState(() => _seen.add(i)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: active
                        ? const LinearGradient(
                            colors: [AppTheme.blueDark, AppTheme.bg],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: active ? null : AppTheme.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: active ? AppTheme.primary : AppTheme.border,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.icon, style: const TextStyle(fontSize: 32)),
                      const SizedBox(height: 8),
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: AppTheme.textBody,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (active) ...[
                        Text(
                          item.desc,
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                        if (item.example != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Örnek: ${item.example}',
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ] else
                        const Text(
                          'Dokunmak için tıkla',
                          style: TextStyle(color: AppTheme.muted, fontSize: 11),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (done) ...[
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Hepsini öğrendim! ✅',
              onPressed: widget.onComplete,
            ),
          ],
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 2 · INFO LIST
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
          PillBadge(
            text: '${widget.icon} Liste',
            bg: const Color(0xFF1C1917),
            color: widget.color,
          ),
          const SizedBox(height: 10),
          Text(
            widget.title,
            style: const TextStyle(
              color: AppTheme.textBody,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
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
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: open ? AppTheme.card : AppTheme.bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: open ? widget.color : const Color(0xFF1E293B),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            (i + 1).toString().padLeft(2, '0'),
                            style: TextStyle(
                              color: widget.color,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.text,
                              style: const TextStyle(
                                color: AppTheme.textBody,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Icon(
                            open
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: AppTheme.muted,
                            size: 20,
                          ),
                        ],
                      ),
                      if (open) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.bg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border(
                              left: BorderSide(color: widget.color, width: 3),
                            ),
                          ),
                          child: Text(
                            '💬 ${item.example}',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
          Opacity(
            opacity: _seen.length == widget.items.length ? 1 : 0.45,
            child: IgnorePointer(
              ignoring: _seen.length != widget.items.length,
              child: PrimaryButton(
                label: 'Anladım →',
                onPressed: widget.onComplete,
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
    final last = _idx == widget.cases.length - 1;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PillBadge(
            text: '📰 Vaka',
            bg: AppTheme.blueDark,
            color: Color(0xFF60A5FA),
          ),
          const SizedBox(height: 10),
          const Text(
            'Gerçek Hayattan Örnekler',
            style: TextStyle(
              color: AppTheme.textBody,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Kaydır ve öğren →',
            style: TextStyle(color: AppTheme.subtle, fontSize: 12),
          ),
          const SizedBox(height: 16),
          AppCard(
            background: AppTheme.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.emoji, style: const TextStyle(fontSize: 44)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    PillBadge(
                      text: c.where,
                      bg: AppTheme.blueDark,
                      color: const Color(0xFF60A5FA),
                    ),
                    Text(
                      c.title,
                      style: const TextStyle(
                        color: AppTheme.textBody,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  c.desc,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1D4ED8)),
                  ),
                  child: Text(
                    '💡 Ders: ${c.lesson}',
                    style: const TextStyle(
                      color: Color(0xFF93C5FD),
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1F0F),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.greenBdr),
                  ),
                  child: Text(
                    '✅ Ne yapmalısın? ${c.action}',
                    style: const TextStyle(
                      color: Color(0xFF86EFAC),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: List.generate(
                  widget.cases.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 6),
                    width: i == _idx ? 22 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == _idx ? AppTheme.primary : AppTheme.border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
              last
                  ? SizedBox(
                      width: 110,
                      child: PrimaryButton(
                        label: 'Devam →',
                        onPressed: widget.onComplete,
                      ),
                    )
                  : ElevatedButton(
                      onPressed: () => setState(() => _idx++),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Sonraki →',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 4 · DIGITAL FOOTPRINT
// ────────────────────────────────────────────────────────────────────────────
class DigitalFootprintScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final List<TimelineItem> timeline;
  const DigitalFootprintScreen({
    super.key,
    required this.onComplete,
    this.timeline = defaultTimeline,
  });

  @override
  State<DigitalFootprintScreen> createState() => _DigitalFootprintState();
}

class _DigitalFootprintState extends State<DigitalFootprintScreen> {
  int? _active;
  final Set<int> _seen = {};

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PillBadge(
            text: '👣 Ayak İzi',
            bg: AppTheme.bg,
            color: AppTheme.primaryLt,
          ),
          const SizedBox(height: 10),
          const Text(
            'Dijital Ayak İzini Keşfet 👣',
            style: TextStyle(
              color: AppTheme.textBody,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Bir günde ne kadar iz bırakıyorsun? Her saate dokun!',
            style: TextStyle(color: AppTheme.subtle, fontSize: 12),
          ),
          const SizedBox(height: 20),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(width: 2, height: 16, color: AppTheme.primary),
                    ...List.generate(
                      widget.timeline.length,
                      (i) => Column(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.bg, width: 2),
                            ),
                          ),
                          if (i < widget.timeline.length - 1)
                            Container(
                              width: 2,
                              height: _active == i ? 120 : 80,
                              color: AppTheme.primary,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      ...widget.timeline.asMap().entries.map((e) {
                        final i = e.key;
                        final item = e.value;
                        final active = _active == i;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _active = active ? null : i;
                              _seen.add(i);
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: active
                                    ? AppTheme.blueDark
                                    : AppTheme.card,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: active
                                      ? AppTheme.primary
                                      : AppTheme.border,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        item.time,
                                        style: const TextStyle(
                                          color: AppTheme.primary,
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 10,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        item.icon,
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.app,
                                              style: const TextStyle(
                                                color: AppTheme.textBody,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              item.label,
                                              style: const TextStyle(
                                                color: AppTheme.muted,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        active
                                            ? Icons.keyboard_arrow_up
                                            : Icons.keyboard_arrow_down,
                                        color: AppTheme.muted,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                  if (active) ...[
                                    const SizedBox(height: 10),
                                    const Divider(color: AppTheme.border),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Toplanan veriler:',
                                      style: TextStyle(
                                        color: AppTheme.subtle,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: item.data
                                          .map(
                                            (d) => PillBadge(
                                              text: '🔍 $d',
                                              bg: AppTheme.blueDark,
                                              color: const Color(0xFF93C5FD),
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
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppCard(
            background: const Color(0xFF2D0D0D),
            borderColor: const Color(0xFF991B1B),
            child: Text(
              '⚠️ Bu uygulamaların kaç tanesinin konum, mikrofon veya kamerana erişimi var?',
              style: const TextStyle(
                color: Color(0xFFFCA5A5),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Opacity(
            opacity: _seen.length == widget.timeline.length ? 1 : 0.45,
            child: IgnorePointer(
              ignoring: _seen.length != widget.timeline.length,
              child: PrimaryButton(
                label: 'Anladım →',
                onPressed: widget.onComplete,
              ),
            ),
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
    required this.onComplete,
    required this.questions,
  });

  @override
  State<SecurityScoreScreen> createState() => _SecurityScoreState();
}

class _SecurityScoreState extends State<SecurityScoreScreen> {
  final Map<int, bool> _ans = {};

  @override
  Widget build(BuildContext context) {
    final done = _ans.length == widget.questions.length;
    final score = widget.questions.asMap().entries.fold(
      0,
      (acc, e) => acc + ((_ans[e.key] ?? false) ? e.value.points : 0),
    );
    final max = widget.questions.fold(0, (acc, q) => acc + q.points);
    final pct = done ? score / max : 0.0;
    final emoji = score >= 60
        ? '🦸'
        : score >= 35
        ? '🛡️'
        : '🐣';
    final title = score >= 60
        ? 'Süper Güvenlik Ustası!'
        : score >= 35
        ? 'İyi Güvenlik Uygulayıcısı'
        : 'Güvenlik Çaylağı';
    final color = score >= 60
        ? const Color(0xFF34D399)
        : score >= 35
        ? AppTheme.amber
        : const Color(0xFFF87171);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PillBadge(
            text: '🔢 Skor',
            bg: AppTheme.bg,
            color: AppTheme.primaryLt,
          ),
          const SizedBox(height: 10),
          const Text(
            'Yapay Zekâ Güvenlik Skorun',
            style: TextStyle(
              color: AppTheme.textBody,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Aşağıdaki soruları cevapla ve güvenlik skorunu hesapla!',
            style: TextStyle(color: AppTheme.subtle, fontSize: 12),
          ),
          const SizedBox(height: 18),
          ...widget.questions.asMap().entries.map((e) {
            final i = e.key;
            final q = e.value;
            final checked = _ans[i] ?? false;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => setState(() => _ans[i] = !checked),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: checked ? AppTheme.greenDark : AppTheme.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: checked ? AppTheme.green : AppTheme.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      CheckBox(
                        checked: checked,
                        onTap: () => setState(() => _ans[i] = !checked),
                      ),
                      const SizedBox(width: 10),
                      Text(q.icon, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          q.text,
                          style: const TextStyle(
                            color: AppTheme.textBody,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        '+${q.points}',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (done) ...[
            const SizedBox(height: 20),
            AppCard(
              background: AppTheme.bg,
              borderColor: color,
              child: Column(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 48)),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$score/$max puan',
                    style: const TextStyle(
                      color: AppTheme.subtle,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 8,
                      backgroundColor: AppTheme.card,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(label: 'Devam →', onPressed: widget.onComplete),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 6 · ROLE PLAY
// ────────────────────────────────────────────────────────────────────────────
class RolePlayScreen extends StatefulWidget {
  final List<Map<String, String>> script;
  final VoidCallback onComplete;
  const RolePlayScreen({
    super.key,
    required this.onComplete,
    required this.script,
  });

  @override
  State<RolePlayScreen> createState() => _RolePlayState();
}

class _RolePlayState extends State<RolePlayScreen> {
  int _step = 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PillBadge(
            text: '🎭 Rol Yapma',
            bg: AppTheme.blueDark,
            color: Color(0xFF60A5FA),
          ),
          const SizedBox(height: 10),
          const Text(
            'Canlandırma',
            style: TextStyle(
              color: AppTheme.textBody,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          ...widget.script.asMap().entries.map((e) {
            final i = e.key;
            final item = e.value;
            if (i > _step) return const SizedBox.shrink();

            final isMe = i % 2 == 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: isMe
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe) ...[
                    const CircleAvatar(child: Text('A')),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isMe ? AppTheme.primary : AppTheme.card,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['role'] ?? '',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isMe ? Colors.white70 : AppTheme.textMuted,
                            ),
                          ),
                          Text(
                            item['action'] ?? '',
                            style: TextStyle(
                              color: isMe ? Colors.white : AppTheme.textBody,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 8),
                    const CircleAvatar(
                      backgroundColor: AppTheme.primary,
                      child: Text('B', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ],
              ),
            );
          }),
          const SizedBox(height: 20),
          if (_step < widget.script.length - 1)
            PrimaryButton(
              label: 'Devam Et',
              onPressed: () => setState(() => _step++),
            )
          else
            PrimaryButton(label: 'Tamamla ✅', onPressed: widget.onComplete),
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
  final List<String> feedbacks;
  final List<String> options;
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
          const PillBadge(
            text: '📱 Senaryo',
            bg: Color(0xFF1C1917),
            color: Color(0xFFFB923C),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Text(
              '📌 ${widget.context}',
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.question,
            style: const TextStyle(
              color: AppTheme.textBody,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ...widget.options.asMap().entries.map((e) {
            final i = e.key;
            final opt = e.value;
            final isCorr = i == widget.correct;
            final isSel = i == _sel;
            Color bg = AppTheme.card,
                border = AppTheme.border,
                txtColor = AppTheme.textBody;
            Color circleBg = AppTheme.border;
            if (answered && isCorr) {
              bg = AppTheme.greenDark;
              border = AppTheme.green;
              txtColor = const Color(0xFF86EFAC);
              circleBg = AppTheme.green;
            }
            if (answered && isSel && !isCorr) {
              bg = AppTheme.redDark;
              border = AppTheme.red;
              txtColor = const Color(0xFFFCA5A5);
              circleBg = AppTheme.red;
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
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: circleBg,
                        radius: 13,
                        child: Text(
                          answered && isCorr
                              ? '✓'
                              : answered && isSel
                              ? '✗'
                              : _letters[i],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          opt,
                          style: TextStyle(color: txtColor, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (answered) ...[
            AppCard(
              background: const Color(0xFF0F1F0F),
              borderColor: AppTheme.greenBdr,
              child: Text(
                '💡 ${(_sel != null && _sel! < widget.feedbacks.length && widget.feedbacks[_sel!].trim().isNotEmpty) ? widget.feedbacks[_sel!] : widget.explanation}',
                style: const TextStyle(
                  color: Color(0xFF86EFAC),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(label: 'Devam →', onPressed: widget.onComplete),
          ],
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 8 · PERMISSION DETECTIVE
// ────────────────────────────────────────────────────────────────────────────
class PermissionDetectiveScreen extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final List<String> answerOptions;
  final String title;
  final String description;
  final VoidCallback onComplete;
  const PermissionDetectiveScreen({
    super.key,
    required this.onComplete,
    required this.items,
    this.answerOptions = const [],
    this.title = 'Mini Oyun',
    this.description = 'Aşağıdaki durumları değerlendir.',
  });

  @override
  State<PermissionDetectiveScreen> createState() => _PermissionDetectiveState();
}

class _PermissionDetectiveState extends State<PermissionDetectiveScreen> {
  final Map<int, String> _ans = {};
  bool _showResult = false;

  @override
  Widget build(BuildContext context) {
    final allDone = _ans.length == widget.items.length;
    final answerOptions = widget.answerOptions.isNotEmpty
        ? widget.answerOptions
        : widget.items
              .map((e) => (e['correct_answer'] ?? '').toString().trim())
              .where((e) => e.isNotEmpty)
              .toSet()
              .toList();
    int correctCount = 0;
    for (int i = 0; i < widget.items.length; i++) {
      if (_ans[i] == widget.items[i]['correct_answer']) correctCount++;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PillBadge(
            text: '🕵️ Dedektif',
            bg: Color(0xFF1C1917),
            color: AppTheme.amber,
          ),
          const SizedBox(height: 10),
          Text(
            widget.title,
            style: TextStyle(
              color: AppTheme.textBody,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.description,
            style: TextStyle(color: AppTheme.subtle, fontSize: 12),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Row(
              children: [
                const Text('🎮', style: TextStyle(fontSize: 36)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Durum Analizi',
                      style: TextStyle(
                        color: AppTheme.textBody,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Text(
                      '💡 Doğru cevabı seç',
                      style: TextStyle(color: AppTheme.subtle, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...widget.items.asMap().entries.map((e) {
            final i = e.key;
            final item = e.value;
            final ans = _ans[i];
            final correctVal = item['correct_answer'];
            final isCorrect = ans == correctVal;

            Color border = AppTheme.border;
            if (ans != null) {
              border = isCorrect ? AppTheme.green : AppTheme.red;
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('❓', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item['situation'] ?? '',
                            style: const TextStyle(
                              color: AppTheme.textBody,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (ans == null)
                      Wrap(
                        spacing: 8,
                        children: answerOptions
                            .map(
                              (option) => _ToggleBtn(
                                label: option,
                                active: false,
                                activeColor: AppTheme.primary,
                                onTap: () => setState(() => _ans[i] = option),
                              ),
                            )
                            .toList(),
                      ),
                    if (ans != null) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 30),
                        child: Text(
                          '${isCorrect ? "✅ " : "❌ "}${item['feedback'] ?? (isCorrect ? "Doğru!" : "Yanlış, tekrar düşün.")}',
                          style: TextStyle(
                            color: isCorrect
                                ? const Color(0xFF86EFAC)
                                : const Color(0xFFFCA5A5),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
          if (allDone && !_showResult)
            PrimaryButton(
              label: 'Sonuçları Gör!',
              onPressed: () => setState(() => _showResult = true),
            ),
          if (_showResult) ...[
            const SizedBox(height: 16),
            AppCard(
              background: AppTheme.bg,
              borderColor: AppTheme.primary,
              child: Column(
                children: [
                  Text(
                    correctCount == widget.items.length
                        ? '🏆'
                        : correctCount >= (widget.items.length / 2)
                        ? '🎯'
                        : '📚',
                    style: const TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$correctCount/${widget.items.length} Doğru',
                    style: const TextStyle(
                      color: AppTheme.textBody,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    correctCount == widget.items.length
                        ? 'Mükemmel! Gerçek bir güvenlik uzmanısın!'
                        : 'İyi iş! Açıklamaları gözden geçir.',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(label: 'Devam →', onPressed: widget.onComplete),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;
  const _ToggleBtn({
    required this.label,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? activeColor : AppTheme.border,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : AppTheme.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

// ────────────────────────────────────────────────────────────────────────────
// 9 · ANALYSIS
// ────────────────────────────────────────────────────────────────────────────
class AnalysisScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final List<AnalysisItem> items;
  const AnalysisScreen({
    super.key,
    required this.onComplete,
    this.items = defaultAnalysisItems,
  });

  @override
  State<AnalysisScreen> createState() => _AnalysisState();
}

class _AnalysisState extends State<AnalysisScreen> {
  final Set<int> _seen = {};

  @override
  Widget build(BuildContext context) {
    final done = _seen.length == widget.items.length;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PillBadge(
            text: '🔬 Analiz',
            bg: AppTheme.bg,
            color: AppTheme.primaryLt,
          ),
          const SizedBox(height: 10),
          const Text(
            'Analiz ve Derinleştirme',
            style: TextStyle(
              color: AppTheme.textBody,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Güvenli bir yapay zekâ sistemi şunları sağlamalıdır:',
            style: TextStyle(color: AppTheme.subtle, fontSize: 12),
          ),
          const SizedBox(height: 18),
          ...widget.items.asMap().entries.map((e) {
            final i = e.key;
            final item = e.value;
            final seen = _seen.contains(i);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => setState(() => _seen.add(i)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: seen ? AppTheme.card : AppTheme.bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: seen ? AppTheme.primary : const Color(0xFF1E293B),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.icon, style: const TextStyle(fontSize: 22)),
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
                            if (seen) ...[
                              const SizedBox(height: 5),
                              Text(
                                item.explanation,
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 13,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (done) ...[
            const SizedBox(height: 4),
            PrimaryButton(
              label: 'Harika! Devam →',
              onPressed: widget.onComplete,
            ),
          ],
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 10 · MYTH BUSTERS
// ────────────────────────────────────────────────────────────────────────────
class MythBustersScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final List<MythItem> myths;
  const MythBustersScreen({
    super.key,
    required this.onComplete,
    this.myths = defaultMyths,
  });

  @override
  State<MythBustersScreen> createState() => _MythBustersState();
}

class _MythBustersState extends State<MythBustersScreen> {
  final Set<int> _flipped = {};

  @override
  Widget build(BuildContext context) {
    final done = _flipped.length == widget.myths.length;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PillBadge(
            text: '💥 Efsane Kırıcı',
            bg: Color(0xFF2D1F0F),
            color: Color(0xFFFB923C),
          ),
          const SizedBox(height: 10),
          const Text(
            'Kavram Yanılgıları 💥',
            style: TextStyle(
              color: AppTheme.textBody,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Efsaneye dokun, gerçeği öğren!',
            style: TextStyle(color: AppTheme.subtle, fontSize: 12),
          ),
          const SizedBox(height: 20),
          ...widget.myths.asMap().entries.map((e) {
            final i = e.key;
            final item = e.value;
            final flipped = _flipped.contains(i);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => setState(() => _flipped.add(i)),
                child: AnimatedCrossFade(
                  duration: const Duration(milliseconds: 300),
                  crossFadeState: flipped
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: AppCard(
                    background: const Color(0xFF2D1F0F),
                    borderColor: const Color(0xFF92400E),
                    child: Row(
                      children: [
                        Text(item.icon, style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'EFSANE',
                                style: TextStyle(
                                  color: Color(0xFFFB923C),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '"${item.myth}"',
                                style: const TextStyle(
                                  color: Color(0xFFFDE68A),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Text('👆', style: TextStyle(fontSize: 18)),
                      ],
                    ),
                  ),
                  secondChild: AppCard(
                    background: AppTheme.greenDark,
                    borderColor: AppTheme.greenBdr,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '✅ GERÇEK',
                          style: TextStyle(
                            color: AppTheme.green,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          item.truth,
                          style: const TextStyle(
                            color: Color(0xFF86EFAC),
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Divider(color: AppTheme.greenBdr),
                        const SizedBox(height: 8),
                        Text(
                          'Örnek: ${item.example}',
                          style: const TextStyle(
                            color: AppTheme.subtle,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          if (done) ...[
            const SizedBox(height: 4),
            PrimaryButton(
              label: 'Harika! Devam →',
              onPressed: widget.onComplete,
            ),
          ],
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 11 · REFLECTION
// ────────────────────────────────────────────────────────────────────────────
class ReflectionScreen extends StatefulWidget {
  final List<String> questions;
  final String title;
  final String intro;
  final String note;
  final VoidCallback onComplete;
  const ReflectionScreen({
    super.key,
    required this.onComplete,
    required this.questions,
    this.title = 'Kendini Değerlendir',
    this.intro = 'Aşağıdaki maddeleri düşün ve tamamladıklarını işaretle.',
    this.note =
        'Öğrendiklerini kendi cümlelerinle tekrar etmek kalıcılığı artırır.',
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
          const PillBadge(
            text: '🔎 Etkinlik',
            bg: Color(0xFF1C1917),
            color: Color(0xFFF59E0B),
          ),
          const SizedBox(height: 10),
          Text(
            widget.title,
            style: TextStyle(
              color: AppTheme.textBody,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.intro,
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          ...widget.questions.asMap().entries.map((e) {
            final i = e.key;
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
                    color: checked ? AppTheme.greenDark : AppTheme.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: checked ? AppTheme.green : AppTheme.border,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: CheckBox(
                          checked: checked,
                          onTap: () => setState(
                            () =>
                                checked ? _checked.remove(i) : _checked.add(i),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.questions[i],
                          style: const TextStyle(
                            color: AppTheme.textBody,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          AppCard(
            background: AppTheme.blueDark,
            borderColor: AppTheme.blue,
            child: Text(
              '📌 ${widget.note}',
              style: TextStyle(
                color: Color(0xFF93C5FD),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Opacity(
            opacity: _checked.length == widget.questions.length ? 1 : 0.45,
            child: IgnorePointer(
              ignoring: _checked.length != widget.questions.length,
              child: PrimaryButton(
                label: 'Tamamladım →',
                onPressed: widget.onComplete,
              ),
            ),
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
  final String title;
  final String description;
  final String template;
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
      if ((_selected[i] ?? '').trim() !=
          widget.blanks[i].correctAnswer.trim()) {
        wrong.add(i);
      }
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
    final parts = widget.template.split('___');
    final widgets = <Widget>[];
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        widgets.add(
          Text(
            parts[i],
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 14,
              height: 1.6,
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
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: word == null
                      ? AppTheme.card
                      : wrong
                      ? AppTheme.redDark
                      : AppTheme.greenDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: word == null
                        ? AppTheme.border
                        : wrong
                        ? AppTheme.red
                        : AppTheme.green,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  word ?? 'boşluk ${i + 1}',
                  style: TextStyle(
                    color: wrong ? const Color(0xFFFCA5A5) : AppTheme.textBody,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
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
          const PillBadge(
            text: '🧩 Kelime Bankası',
            bg: AppTheme.bg,
            color: AppTheme.primaryLt,
          ),
          const SizedBox(height: 10),
          Text(
            widget.title,
            style: const TextStyle(
              color: AppTheme.textBody,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.description,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 18),
          AppCard(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 8,
              children: _buildTemplateParts(),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Kelime havuzu',
            style: TextStyle(
              color: AppTheme.subtle,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          AppCard(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _bank
                  .map(
                    (word) => GestureDetector(
                      onTap: () => _pickWord(word),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.blueDark,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.primary),
                        ),
                        child: Text(
                          word,
                          style: const TextStyle(
                            color: AppTheme.textBody,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          if (_wrongSlots.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Hatalı boşluğa dokunup kelimeyi geri gönder, sonra yeniden seç.',
              style: TextStyle(color: Color(0xFFFCA5A5), fontSize: 12),
            ),
          ],
          const SizedBox(height: 20),
          if (!_solved)
            Opacity(
              opacity: allFilled ? 1 : 0.45,
              child: IgnorePointer(
                ignoring: !allFilled,
                child: PrimaryButton(
                  label: 'Kontrol Et',
                  onPressed: _checkAnswer,
                ),
              ),
            )
          else ...[
            AppCard(
              background: AppTheme.greenDark,
              borderColor: AppTheme.green,
              child: const Text(
                '✅ Tüm boşlukları doğru doldurdun.',
                style: TextStyle(color: Color(0xFF86EFAC), fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            PrimaryButton(label: 'Devam →', onPressed: widget.onComplete),
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
  final List<String> prompts;
  final List<String> hints;
  final List<String> discussion;
  final List<String> tasks;
  final String title;
  final VoidCallback onComplete;
  const CriticalThinkingScreen({
    super.key,
    required this.onComplete,
    required this.prompts,
    this.hints = defaultCriticalHints,
    this.discussion = defaultCriticalDiscussion,
    this.tasks = const [],
    this.title = 'Kritik Düşünme Sorusu',
  });

  @override
  State<CriticalThinkingScreen> createState() => _CriticalThinkingState();
}

class _CriticalThinkingState extends State<CriticalThinkingScreen>
    with SingleTickerProviderStateMixin {
  bool _show = false;
  final Set<int> _checkedTasks = {};
  final List<String> _target = const [
    'veri',
    'şeffaflık',
    'karşılaştır',
    'kontrol',
  ];
  late List<String?> _slots;
  late List<String> _bank;
  final Set<int> _wrongSlots = {};
  bool _solved = false;
  late final AnimationController _shakeCtrl;

  @override
  void initState() {
    super.initState();
    _slots = List<String?>.filled(_target.length, null);
    _bank = <String>[..._target, 'rastgele', 'hemen', 'gerekmez', 'güvenme']
      ..shuffle();
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
    final empty = _slots.indexWhere((e) => e == null);
    if (empty == -1) return;
    setState(() {
      _slots[empty] = word;
      _bank.remove(word);
      _wrongSlots.remove(empty);
    });
  }

  void _removeFromSlot(int i) {
    final w = _slots[i];
    if (w == null) return;
    if (_solved) return;
    setState(() {
      _slots[i] = null;
      _bank.add(w);
      _wrongSlots.remove(i);
    });
  }

  void _checkAnswer() {
    final wrong = <int>{};
    for (int i = 0; i < _target.length; i++) {
      if (_slots[i] != _target[i]) wrong.add(i);
    }
    if (wrong.isEmpty) {
      setState(() {
        _wrongSlots.clear();
        _solved = true;
      });
      return;
    }
    setState(
      () => _wrongSlots
        ..clear()
        ..addAll(wrong),
    );
    _shakeCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final allSlotsFilled = _slots.every((e) => e != null);
    final hasTasks = widget.tasks.isNotEmpty;
    final allTasksDone = _checkedTasks.length == widget.tasks.length;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PillBadge(
            text: '🧠 Kritik Düşünme',
            bg: AppTheme.bg,
            color: Color(0xFF34D399),
          ),
          const SizedBox(height: 10),
          Text(
            '${widget.title} 🧠',
            style: TextStyle(
              color: AppTheme.textBody,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            background: AppTheme.card,
            borderColor: const Color(0xFF4F46E5),
            child: Text(
              widget.prompts.isNotEmpty ? widget.prompts.first : 'Düşünelim...',
              style: const TextStyle(
                color: AppTheme.textBody,
                fontSize: 14,
                height: 1.7,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (!_show)
            SecondaryButton(
              label: '💡 İpuçlarını Gör',
              onPressed: () => setState(() => _show = true),
            )
          else ...[
            const Text(
              'DÜŞÜNME İPUÇLARI',
              style: TextStyle(
                color: AppTheme.subtle,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            ...widget.hints.map(
              (h) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  child: Row(
                    children: [
                      const Text(
                        '?',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          h,
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'TARTIŞMA NOKTALARI',
              style: TextStyle(
                color: AppTheme.subtle,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            ...widget.discussion.map(
              (d) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  background: const Color(0xFF0F1F0F),
                  borderColor: AppTheme.greenBdr,
                  child: Row(
                    children: [
                      const Text('→', style: TextStyle(color: AppTheme.green)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          d,
                          style: const TextStyle(
                            color: Color(0xFF86EFAC),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (hasTasks) ...[
              const Text(
                'Tamamlamak için aşağıdaki görevlere dokun:',
                style: TextStyle(color: AppTheme.subtle, fontSize: 12),
              ),
              const SizedBox(height: 10),
              ...widget.tasks.asMap().entries.map((entry) {
                final i = entry.key;
                final checked = _checkedTasks.contains(i);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      checked ? _checkedTasks.remove(i) : _checkedTasks.add(i);
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: checked ? AppTheme.greenDark : AppTheme.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: checked ? AppTheme.green : AppTheme.border,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CheckBox(
                            checked: checked,
                            onTap: () => setState(() {
                              checked
                                  ? _checkedTasks.remove(i)
                                  : _checkedTasks.add(i);
                            }),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: const TextStyle(
                                color: AppTheme.textBody,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ] else ...[
              const Text(
                'Kelime Bankasından seç ve boşlukları doldur:',
                style: TextStyle(color: AppTheme.subtle, fontSize: 12),
              ),
              const SizedBox(height: 10),
              AppCard(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _bank
                      .map(
                        (w) => GestureDetector(
                          onTap: () => _pickWord(w),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.blueDark,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.primary),
                            ),
                            child: Text(
                              w,
                              style: const TextStyle(
                                color: AppTheme.textBody,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                background: AppTheme.bg,
                borderColor: AppTheme.border,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Şablon:',
                      style: TextStyle(
                        color: AppTheme.textBody,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Yapay zekâ kararını değerlendirirken önce ____ sonra ____ gerekir.',
                      style: TextStyle(color: AppTheme.textMuted, height: 1.5),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ayrıca önerileri ____ ve sonrasında ____ etmeliyim.',
                      style: TextStyle(color: AppTheme.textMuted, height: 1.5),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(_slots.length, (i) {
                        final word = _slots[i];
                        final wrong = _wrongSlots.contains(i);
                        return AnimatedBuilder(
                          animation: _shakeCtrl,
                          builder: (_, child) {
                            final dx = wrong
                                ? math.sin(_shakeCtrl.value * math.pi * 8) * 5
                                : 0.0;
                            return Transform.translate(
                              offset: Offset(dx, 0),
                              child: child,
                            );
                          },
                          child: GestureDetector(
                            onTap: wrong ? () => _removeFromSlot(i) : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: word == null
                                    ? AppTheme.card
                                    : wrong
                                    ? AppTheme.redDark
                                    : AppTheme.greenDark,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: word == null
                                      ? AppTheme.border
                                      : wrong
                                      ? AppTheme.red
                                      : AppTheme.green,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                word ?? 'boşluk ${i + 1}',
                                style: TextStyle(
                                  color: wrong
                                      ? const Color(0xFFFCA5A5)
                                      : AppTheme.textBody,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    if (_wrongSlots.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Hatalı olan kırmızı kutuya tıklayıp kelimeyi geri gönder, yeniden seç.',
                        style: TextStyle(
                          color: Color(0xFFFCA5A5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (!(hasTasks ? allTasksDone : _solved))
              Opacity(
                opacity: hasTasks
                    ? (allTasksDone ? 1 : 0.45)
                    : (allSlotsFilled ? 1 : 0.45),
                child: IgnorePointer(
                  ignoring: hasTasks ? !allTasksDone : !allSlotsFilled,
                  child: PrimaryButton(
                    label: hasTasks ? 'Tamamladım' : 'Kontrol Et',
                    onPressed: hasTasks ? widget.onComplete : _checkAnswer,
                  ),
                ),
              )
            else ...[
              AppCard(
                background: AppTheme.greenDark,
                borderColor: AppTheme.green,
                child: const Text(
                  '✅ Harika! Değerlendirme adımını doğru tamamladın.',
                  style: TextStyle(color: Color(0xFF86EFAC), fontSize: 13),
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Düşündüm, devam →',
                onPressed: widget.onComplete,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 13 · INFOGRAPHIC
// ────────────────────────────────────────────────────────────────────────────
class InfographicScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final List<String> points;
  final List<FirewallLayer> layers;
  final String title;
  final String description;
  const InfographicScreen({
    super.key,
    required this.onComplete,
    this.points = const [],
    this.layers = defaultFirewallLayers,
    this.title = 'Ders Özeti',
    this.description = '',
  });

  @override
  State<InfographicScreen> createState() => _InfographicScreenState();
}

class _InfographicScreenState extends State<InfographicScreen> {
  final Set<int> _opened = {};

  Color _hexColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final layers = widget.points.isNotEmpty
        ? widget.points
              .asMap()
              .entries
              .map(
                (entry) => FirewallLayer(
                  name: 'Ozet ${entry.key + 1}',
                  color: const [
                    '#ef4444',
                    '#14b8a6',
                    '#3b82f6',
                    '#8b5cf6',
                  ][entry.key % 4],
                  items: [entry.value],
                ),
              )
              .toList()
        : widget.layers;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PillBadge(
            text: '🏰 Güvenlik Duvarı',
            bg: AppTheme.bg,
            color: Color(0xFF60A5FA),
          ),
          const SizedBox(height: 10),
          Text(
            widget.title,
            style: TextStyle(
              color: AppTheme.textBody,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.description.trim().isNotEmpty
                ? widget.description
                : widget.points.isNotEmpty
                ? 'Bu dersin ana noktalarını özet halinde incele.'
                : 'Bu bölümde katmanları inceleyerek ilerle.',
            style: const TextStyle(color: AppTheme.subtle, fontSize: 12),
          ),
          const SizedBox(height: 20),
          ...layers.asMap().entries.map((entry) {
            final i = entry.key;
            final layer = entry.value;
            final c = _hexColor(layer.color);
            final opened = _opened.contains(i);
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: () => setState(() {
                  if (opened) {
                    _opened.remove(i);
                  } else {
                    _opened.add(i);
                  }
                }),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: c, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: c,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    layer.name,
                                    style: TextStyle(
                                      color: c,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Icon(
                                  opened
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  color: c,
                                ),
                              ],
                            ),
                            if (opened) ...[
                              const SizedBox(height: 12),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithMaxCrossAxisExtent(
                                      maxCrossAxisExtent: 260,
                                      childAspectRatio: 3.2,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                    ),
                                itemCount: layer.items.length,
                                itemBuilder: (_, idx) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.card,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    layer.items[idx],
                                    style: const TextStyle(
                                      color: AppTheme.textBody,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          Opacity(
            opacity: _opened.length == layers.length ? 1 : 0.45,
            child: IgnorePointer(
              ignoring: _opened.length != layers.length,
              child: PrimaryButton(
                label: 'Anladım →',
                onPressed: widget.onComplete,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 14 · MULTI QUIZ
// ────────────────────────────────────────────────────────────────────────────
class MultiQuizScreen extends StatefulWidget {
  final List<QuizQuestion> questions;
  final VoidCallback onComplete;
  final void Function(String badgeId) onBadge;
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
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
        child: Column(
          children: [
            Text(
              _score == widget.questions.length
                  ? '🌟'
                  : _score >= (widget.questions.length * 0.7).ceil()
                  ? '🎯'
                  : '📚',
              style: const TextStyle(fontSize: 56),
            ),
            const SizedBox(height: 12),
            const Text(
              'Quiz Tamamlandı!',
              style: TextStyle(
                color: AppTheme.textBody,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_score/${widget.questions.length}',
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w800,
                fontSize: 32,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _score == widget.questions.length
                  ? 'Mükemmel! Tüm soruları doğru yanıtladın! 🏆'
                  : 'İyi iş! Tekrar deneyerek daha yüksek skor alabilirsin.',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            if (_score == widget.questions.length) ...[
              const SizedBox(height: 16),
              AppCard(
                background: AppTheme.greenDark,
                borderColor: AppTheme.green,
                child: const Text(
                  '🦉 "Güvenlik Ustası" rozeti kazandın!',
                  style: TextStyle(color: Color(0xFF86EFAC), fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 24),
            PrimaryButton(label: 'Devam →', onPressed: widget.onComplete),
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
              PillBadge(
                text: '❓ ${_qi + 1}/${widget.questions.length}',
                bg: AppTheme.indigo,
                color: const Color(0xFFA5B4FC),
              ),
              Text(
                '$_score ✓',
                style: const TextStyle(
                  color: AppTheme.green,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: _qi / widget.questions.length,
              minHeight: 4,
              backgroundColor: AppTheme.card,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            q.q,
            style: const TextStyle(
              color: AppTheme.textBody,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ...q.opts.asMap().entries.map((e) {
            final i = e.key;
            final isCorr = i == q.ans, isSel = i == _sel;
            Color bg = AppTheme.card,
                border = AppTheme.border,
                txtColor = AppTheme.textBody;
            Color circleBg = AppTheme.border;
            if (_answered && isCorr) {
              bg = AppTheme.greenDark;
              border = AppTheme.green;
              txtColor = const Color(0xFF86EFAC);
              circleBg = AppTheme.green;
            }
            if (_answered && isSel && !isCorr) {
              bg = AppTheme.redDark;
              border = AppTheme.red;
              txtColor = const Color(0xFFFCA5A5);
              circleBg = AppTheme.red;
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
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: circleBg,
                        radius: 13,
                        child: Text(
                          _answered && isCorr
                              ? '✓'
                              : _answered && isSel
                              ? '✗'
                              : _letters[i],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          e.value,
                          style: TextStyle(color: txtColor, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (_answered) ...[
            AppCard(
              background: const Color(0xFF0F1F0F),
              borderColor: AppTheme.greenBdr,
              child: Text(
                '💡 ${q.exp}',
                style: const TextStyle(
                  color: Color(0xFF86EFAC),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: _qi < widget.questions.length - 1
                  ? 'Sonraki Soru →'
                  : 'Sonuçları Gör →',
              onPressed: _next,
            ),
          ],
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 15 · KEYWORDS
// ────────────────────────────────────────────────────────────────────────────
class KeywordsScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final List<KeywordItem> items;
  const KeywordsScreen({
    super.key,
    required this.onComplete,
    this.items = defaultKeywords,
  });

  @override
  State<KeywordsScreen> createState() => _KeywordsState();
}

class _KeywordsState extends State<KeywordsScreen> {
  final Set<int> _opened = {};

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PillBadge(
            text: '📖 Sözlük',
            bg: AppTheme.bg,
            color: AppTheme.primaryLt,
          ),
          const SizedBox(height: 10),
          const Text(
            'Anahtar Kavramlar 📖',
            style: TextStyle(
              color: AppTheme.textBody,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Her kavrama dokun! 👇',
            style: TextStyle(color: AppTheme.subtle, fontSize: 12),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 260,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.25,
            ),
            itemCount: widget.items.length,
            itemBuilder: (_, i) {
              final open = _opened.contains(i);
              return GestureDetector(
                onTap: () => setState(() {
                  if (open) {
                    _opened.remove(i);
                  } else {
                    _opened.add(i);
                  }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: open ? AppTheme.blueDark : AppTheme.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: open ? AppTheme.primary : AppTheme.border,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.items[i].term,
                        style: const TextStyle(
                          color: AppTheme.primaryLt,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      if (open) ...[
                        const SizedBox(height: 6),
                        Text(
                          widget.items[i].def,
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Opacity(
            opacity: _opened.length == widget.items.length ? 1 : 0.45,
            child: IgnorePointer(
              ignoring: _opened.length != widget.items.length,
              child: PrimaryButton(
                label: 'Devam →',
                onPressed: widget.onComplete,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 16 · PROGRESS TRACKER / BADGES
// ────────────────────────────────────────────────────────────────────────────
class ProgressTrackerScreen extends StatelessWidget {
  final Set<String> earnedBadges;
  final List<BadgeItem> badges;
  final VoidCallback onComplete;
  const ProgressTrackerScreen({
    super.key,
    required this.earnedBadges,
    required this.onComplete,
    this.badges = defaultBadges,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PillBadge(
            text: '🏅 Rozetler',
            bg: Color(0xFF1C1917),
            color: AppTheme.amber,
          ),
          const SizedBox(height: 10),
          const Text(
            'Başarı Rozetlerin 🏅',
            style: TextStyle(
              color: AppTheme.textBody,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          ...badges.map((b) {
            final earned = earnedBadges.contains(b.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AnimatedOpacity(
                opacity: earned ? 1.0 : 0.4,
                duration: const Duration(milliseconds: 300),
                child: AppCard(
                  background: earned ? AppTheme.greenDark : AppTheme.bg,
                  borderColor: earned
                      ? AppTheme.green
                      : const Color(0xFF1E293B),
                  child: Row(
                    children: [
                      Text(b.icon, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.name,
                              style: TextStyle(
                                color: earned
                                    ? const Color(0xFF86EFAC)
                                    : AppTheme.subtle,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              b.condition,
                              style: const TextStyle(
                                color: AppTheme.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (earned)
                        const Text('✅', style: TextStyle(fontSize: 20)),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
          PrimaryButton(label: 'Son adım →', onPressed: onComplete),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 17 · CERTIFICATE
// ────────────────────────────────────────────────────────────────────────────
class CertificateScreen extends StatefulWidget {
  final int xp;
  final VoidCallback onRestart;
  final String title;
  final String message;
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

class _CertificateState extends State<CertificateScreen> {
  int _vis = -1;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), _tick);
  }

  void _tick() {
    if (!mounted) return;
    if (_vis < widget.takeaways.length - 1) {
      setState(() => _vis++);
      Future.delayed(const Duration(milliseconds: 400), _tick);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: Column(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 12),
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [AppTheme.amber, Color(0xFFF59E0B)],
            ).createShader(b),
            child: Text(
              widget.title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.message,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGrad,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⚡', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  '${widget.xp} XP Kazandın!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Align(
            alignment: Alignment.centerLeft,
            child: const Text(
              'UNUTMA:',
              style: TextStyle(
                color: AppTheme.subtle,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...widget.takeaways.asMap().entries.map((e) {
            final visible = e.key <= _vis;
            return AnimatedOpacity(
              opacity: visible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 400),
              child: AnimatedSlide(
                offset: visible ? Offset.zero : const Offset(-0.1, 0),
                duration: const Duration(milliseconds: 400),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    background: visible ? AppTheme.greenDark : AppTheme.bg,
                    borderColor: visible
                        ? AppTheme.green
                        : const Color(0xFF1E293B),
                    child: Row(
                      children: [
                        const Text(
                          '✓',
                          style: TextStyle(color: AppTheme.green, fontSize: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            e.value,
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
            );
          }),
          const SizedBox(height: 20),
          AppCard(
            background: AppTheme.blueDark,
            borderColor: AppTheme.primary,
            child: const Text(
              '🌟 Ailenle bugün öğrendiklerini paylaş!\nTelefonunun gizlilik ayarlarını birlikte kontrol edin.',
              style: TextStyle(
                color: Color(0xFFA5B4FC),
                fontSize: 14,
                height: 1.7,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          SecondaryButton(label: '🔄 Tekrar Al', onPressed: widget.onRestart),
        ],
      ),
    );
  }
}
