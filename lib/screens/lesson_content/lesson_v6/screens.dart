import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'theme.dart';
import 'models.dart';
import 'lesson_data.dart';

// ─── STEP SCREENS V2 ──────────────────────────────────────────────────────────
// Tasarım: "Akıllı Defter" — beyaz zemin, canlı renk blokları, 11-15 yaş
// Her screen aynı constructor'ı korur — sadece UI değişti.

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
    this.title = 'Ders Başlıyor',
    this.content = '',
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGrad,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Text('🚀', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    '🎯 Ders Başlıyor',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // İçerik kartı
          if (content.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.introLt,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.intro.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.intro,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('💡', style: TextStyle(fontSize: 16)),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Bu derste ne öğreneceğiz?',
                        style: TextStyle(
                          color: AppTheme.intro,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    content,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 14,
                      height: 1.7,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),

          // İpucu şeridi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Row(
              children: [
                Text('👆', style: TextStyle(fontSize: 18)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Her adımda sorulara ve aktivitelere katılmayı unutma!',
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
            label: 'Hadi Başlayalım! 🚀',
            onPressed: onComplete,
            color: AppTheme.intro,
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

  static const _cardColors = [
    Color(0xFF6C47FF),
    Color(0xFF0EA5E9),
    Color(0xFF10B981),
    Color(0xFFF97316),
    Color(0xFFEC4899),
    Color(0xFF8B5CF6),
  ];
  static const _cardLt = [
    Color(0xFFEDE8FF),
    Color(0xFFE0F2FE),
    Color(0xFFD1FAE5),
    Color(0xFFFFF0E6),
    Color(0xFFFCE7F3),
    Color(0xFFEDE9FE),
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
            label: 'Kavramlar',
            title: widget.title,
            color: AppTheme.concept,
            colorLt: AppTheme.conceptLt,
          ),
          const SizedBox(height: 6),
          Text(
            'Her karta dokunarak öğren 👇',
            style: TextStyle(
              color: AppTheme.muted,
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
              childAspectRatio: 0.9,
            ),
            itemCount: widget.items.length,
            itemBuilder: (_, i) {
              final item = widget.items[i];
              final active = _seen.contains(i);
              final col = _cardColors[i % _cardColors.length];
              final lt = _cardLt[i % _cardLt.length];
              return GestureDetector(
                onTap: () => setState(() => _seen.add(i)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: active ? lt : AppTheme.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: active ? col : AppTheme.border,
                      width: active ? 2 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: active
                            ? col.withValues(alpha: 0.15)
                            : Colors.black.withValues(alpha: 0.04),
                        blurRadius: active ? 12 : 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: active ? col : AppTheme.bg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          item.icon,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.title,
                        style: TextStyle(
                          color: active ? col : AppTheme.textBody,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (active)
                        Text(
                          item.desc,
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        )
                      else
                        Text(
                          'Dokunmak için tıkla →',
                          style: TextStyle(color: AppTheme.muted, fontSize: 11),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          // İlerleme göstergesi
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: widget.items.isEmpty
                        ? 0
                        : _seen.length / widget.items.length,
                    minHeight: 6,
                    backgroundColor: AppTheme.border,
                    color: AppTheme.concept,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${_seen.length}/${widget.items.length}',
                style: TextStyle(
                  color: AppTheme.concept,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AnimatedOpacity(
            opacity: done ? 1 : 0.4,
            duration: const Duration(milliseconds: 300),
            child: IgnorePointer(
              ignoring: !done,
              child: PrimaryButton(
                label: done ? 'Hepsini öğrendim! ✅' : 'Tüm kartlara dokun...',
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
// 2 · INFO LIST (risk_analysis için)
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
            label: 'Dikkat Et',
            title: widget.title,
            color: AppTheme.risk,
            colorLt: AppTheme.riskLt,
          ),
          const SizedBox(height: 6),
          Text(
            'Her maddeye dokun, detayları gör',
            style: TextStyle(color: AppTheme.muted, fontSize: 12),
          ),
          const SizedBox(height: 18),
          ...widget.items.asMap().entries.map((e) {
            final i = e.key;
            final item = e.value;
            final open = _open == i;
            // Risk seviyesine göre renk
            final isHigh = item.example.toLowerCase().contains('yüksek');
            final riskColor = isHigh ? AppTheme.red : AppTheme.risk;
            final riskLt = isHigh ? AppTheme.redLt : AppTheme.riskLt;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => setState(() {
                  _open = open ? null : i;
                  _seen.add(i);
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: open ? riskLt : AppTheme.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: open ? riskColor : AppTheme.border,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
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
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: open ? riskColor : AppTheme.bg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              (i + 1).toString(),
                              style: TextStyle(
                                color: open ? Colors.white : AppTheme.muted,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.text,
                              style: TextStyle(
                                color: open ? riskColor : AppTheme.textBody,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Icon(
                            open
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: AppTheme.muted,
                            size: 22,
                          ),
                        ],
                      ),
                      if (open && item.example.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.card,
                            borderRadius: BorderRadius.circular(10),
                            border: Border(
                              left: BorderSide(color: riskColor, width: 3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Text('💬 '),
                              Expanded(
                                child: Text(
                                  item.example,
                                  style: const TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 13,
                                    height: 1.5,
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
            );
          }),
          const SizedBox(height: 4),
          AnimatedOpacity(
            opacity: _seen.length == widget.items.length ? 1 : 0.4,
            duration: const Duration(milliseconds: 300),
            child: IgnorePointer(
              ignoring: _seen.length != widget.items.length,
              child: PrimaryButton(
                label: 'Anladım →',
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
// 3 · CASE SWIPE (eski CaseSwipeScreen — kullanılmıyorsa boş bırakılabilir)
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
            label: 'Örnek Olay',
            title: 'Gerçek Hayattan Örnekler',
            color: AppTheme.scenario,
            colorLt: AppTheme.scenarioLt,
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(
              widget.cases.length,
              (i) => Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 4),
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= _idx ? AppTheme.scenario : AppTheme.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.scenarioLt,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.scenario.withValues(alpha: 0.3),
                width: 1.5,
              ),
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
                              fontWeight: FontWeight.w600,
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
                _DetailRow(icon: '💡', label: 'Ders', text: c.lesson),
                const SizedBox(height: 8),
                _DetailRow(icon: '✅', label: 'Yapılacak', text: c.action),
              ],
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: isLast ? 'Devam →' : 'Sonraki Örnek →',
            onPressed: () {
              if (isLast) {
                onComplete();
              } else {
                setState(() => _idx++);
              }
            },
            color: AppTheme.scenario,
          ),
        ],
      ),
    );
  }

  VoidCallback get onComplete => widget.onComplete;
}

class _DetailRow extends StatelessWidget {
  final String icon, label, text;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.text,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(icon, style: const TextStyle(fontSize: 14)),
      const SizedBox(width: 6),
      Text(
        '$label: ',
        style: const TextStyle(
          color: AppTheme.textBody,
          fontWeight: FontWeight.w700,
          fontSize: 13,
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
// 4 · DIGITAL FOOTPRINT (boş stub — kullanılmıyorsa)
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
            label: 'Dijital Ayak İzi',
            title: 'Bir Gün Boyunca Bıraktığın Veriler',
            color: AppTheme.concept,
            colorLt: AppTheme.conceptLt,
          ),
          const SizedBox(height: 16),
          ...widget.timeline.asMap().entries.map((e) {
            final i = e.key;
            final item = e.value;
            final open = _open == i;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                onTap: () => setState(() => _open = open ? null : i),
                background: open ? AppTheme.conceptLt : AppTheme.card,
                borderColor: open ? AppTheme.concept : AppTheme.border,
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
                                  color: AppTheme.concept,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
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
                          color: AppTheme.muted,
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
                                  color: AppTheme.concept.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(
                                    color: AppTheme.concept.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  '📌 $d',
                                  style: TextStyle(
                                    color: AppTheme.concept,
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
            );
          }),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Devam →',
            onPressed: widget.onComplete,
            color: AppTheme.concept,
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
      (widget.questions.isEmpty ? 0 : (widget.questions.first.points));

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
            label: 'Güvenlik Skoru',
            title: 'Ne Kadar Güvenlisin?',
            color: AppTheme.game,
            colorLt: AppTheme.gameLt,
          ),
          const SizedBox(height: 16),
          ...widget.questions.asMap().entries.map((e) {
            final i = e.key;
            final q = e.value;
            final ans = _answers[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                background: ans == null
                    ? AppTheme.card
                    : ans
                    ? AppTheme.greenLt
                    : AppTheme.redLt,
                borderColor: ans == null
                    ? AppTheme.border
                    : ans
                    ? AppTheme.green
                    : AppTheme.red,
                child: Row(
                  children: [
                    Text(q.icon, style: const TextStyle(fontSize: 24)),
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
                    _YesNoRow(
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
                gradient: AppTheme.primaryGrad,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Text('⚡', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Güvenlik Skorum',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$_score puan',
                        style: const TextStyle(
                          color: Colors.white,
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
          const SizedBox(height: 4),
          AnimatedOpacity(
            opacity: answered ? 1 : 0.4,
            duration: const Duration(milliseconds: 300),
            child: IgnorePointer(
              ignoring: !answered,
              child: PrimaryButton(
                label: 'Sonuçları Gör →',
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

class _YesNoRow extends StatelessWidget {
  final bool? value;
  final void Function(bool) onChanged;
  const _YesNoRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _Btn(
        label: 'Evet',
        selected: value == true,
        color: AppTheme.green,
        onTap: () => onChanged(true),
      ),
      const SizedBox(width: 6),
      _Btn(
        label: 'Hayır',
        selected: value == false,
        color: AppTheme.red,
        onTap: () => onChanged(false),
      ),
    ],
  );
}

class _Btn extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _Btn({
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
        color: selected ? color : AppTheme.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: selected ? color : AppTheme.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : AppTheme.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
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

  static const _roleColors = [
    AppTheme.intro,
    AppTheme.scenario,
    AppTheme.game,
    AppTheme.concept,
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
            label: 'Rol Yapma',
            title: 'Canlandıralım!',
            color: AppTheme.scenario,
            colorLt: AppTheme.scenarioLt,
          ),
          const SizedBox(height: 16),
          ...widget.script.asMap().entries.map((e) {
            final i = e.key;
            final line = e.value;
            final visible = i <= _step;
            final col = _roleColors[i % _roleColors.length];
            return AnimatedOpacity(
              opacity: visible ? 1 : 0,
              duration: const Duration(milliseconds: 400),
              child: AnimatedSlide(
                offset: visible ? Offset.zero : const Offset(0, 0.1),
                duration: const Duration(milliseconds: 400),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: visible
                          ? col.withValues(alpha: 0.08)
                          : AppTheme.bg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: visible
                            ? col.withValues(alpha: 0.3)
                            : AppTheme.border,
                      ),
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
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
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
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                line['action'] ?? '',
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 13,
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
            );
          }),
          const SizedBox(height: 8),
          if (!done)
            PrimaryButton(
              label: 'Sonraki →',
              onPressed: () => setState(() => _step++),
              color: AppTheme.scenario,
            )
          else
            PrimaryButton(
              label: 'Harika! Devam →',
              onPressed: widget.onComplete,
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
          StepHeader(
            emoji: '🎯',
            label: 'Senaryo',
            title: 'Ne yapardın?',
            color: AppTheme.scenario,
            colorLt: AppTheme.scenarioLt,
          ),
          const SizedBox(height: 16),

          // Senaryo kutusu
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.scenarioLt,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.scenario.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.scenario,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('📌', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.context,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          Text(
            widget.question,
            style: const TextStyle(
              color: AppTheme.textBody,
              fontSize: 17,
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
            Color txtColor = AppTheme.textBody;
            Color circleBg = AppTheme.bg;

            if (answered && isCorr) {
              bg = AppTheme.greenLt;
              border = AppTheme.green;
              txtColor = AppTheme.green;
              circleBg = AppTheme.green;
            }
            if (answered && isSel && !isCorr) {
              bg = AppTheme.redLt;
              border = AppTheme.red;
              txtColor = AppTheme.red;
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
                    border: Border.all(color: border, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: circleBg,
                        radius: 14,
                        child: Text(
                          answered && isCorr
                              ? '✓'
                              : answered && isSel
                              ? '✗'
                              : _letters[i],
                          style: TextStyle(
                            color: (answered && (isCorr || isSel))
                                ? Colors.white
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
                            color: txtColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
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
                color: AppTheme.greenLt,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.green.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡 ', style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Text(
                      (_sel != null &&
                              _sel! < widget.feedbacks.length &&
                              widget.feedbacks[_sel!].trim().isNotEmpty)
                          ? widget.feedbacks[_sel!]
                          : widget.explanation,
                      style: TextStyle(
                        color: AppTheme.green,
                        fontSize: 13,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Devam →',
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
    final item = widget.items[_qi];
    final correctAns = (item['correct_answer'] ?? '').toString().trim();
    final chosen = widget.answerOptions[i];
    setState(() {
      _sel = i;
      _answered = true;
      if (chosen == correctAns) _correct++;
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
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              _correct == widget.items.length ? '🎉' : '👍',
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 12),
            Text(
              '$_correct/${widget.items.length} Doğru!',
              style: const TextStyle(
                color: AppTheme.textBody,
                fontWeight: FontWeight.w800,
                fontSize: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _correct == widget.items.length
                  ? 'Mükemmel! Hepsini doğru yaptın!'
                  : 'İyi iş! Tekrar deneyerek gelişebilirsin.',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Devam →',
              onPressed: widget.onComplete,
              color: AppTheme.game,
            ),
          ],
        ),
      );
    }

    final item = widget.items[_qi];
    final situation = (item['situation'] ?? '').toString();
    final correctAns = (item['correct_answer'] ?? '').toString().trim();
    final feedback = (item['feedback'] ?? '').toString();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StepHeader(
            emoji: '🎮',
            label: 'Mini Oyun',
            title: widget.title,
            color: AppTheme.game,
            colorLt: AppTheme.gameLt,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: _qi / widget.items.length,
                    minHeight: 6,
                    backgroundColor: AppTheme.border,
                    color: AppTheme.game,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${_qi + 1}/${widget.items.length}',
                style: TextStyle(
                  color: AppTheme.game,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.gameLt,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.game.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Text(
              situation,
              style: const TextStyle(
                color: AppTheme.textBody,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.5,
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
              bg = AppTheme.greenLt;
              border = AppTheme.green;
            }
            if (_answered && isSel && !isCorr) {
              bg = AppTheme.redLt;
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
                            color: AppTheme.bg,
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
                  color: AppTheme.greenLt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.green.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  '💡 $feedback',
                  style: TextStyle(
                    color: AppTheme.green,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            PrimaryButton(
              label: _qi < widget.items.length - 1
                  ? 'Sonraki →'
                  : 'Sonuçları Gör →',
              onPressed: _next,
              color: AppTheme.game,
            ),
          ],
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 9 · ANALYSIS (stub)
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
            label: 'Analiz',
            title: 'Analiz Yöntemleri',
            color: AppTheme.concept,
            colorLt: AppTheme.conceptLt,
          ),
          const SizedBox(height: 16),
          ...widget.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.conceptLt,
                        borderRadius: BorderRadius.circular(10),
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
            label: 'Devam →',
            onPressed: widget.onComplete,
            color: AppTheme.concept,
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
            label: 'Efsane mi, Gerçek mi?',
            title: 'Yanılgıları Kır!',
            color: AppTheme.risk,
            colorLt: AppTheme.riskLt,
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
                    color: rev ? AppTheme.greenLt : AppTheme.riskLt,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: rev
                          ? AppTheme.green.withValues(alpha: 0.4)
                          : AppTheme.risk.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
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
                            ),
                            child: Text(
                              rev ? '✅ GERÇEK' : '❓ YANILGI',
                              style: const TextStyle(
                                color: Colors.white,
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
            opacity: done ? 1 : 0.4,
            duration: const Duration(milliseconds: 300),
            child: IgnorePointer(
              ignoring: !done,
              child: PrimaryButton(
                label: 'Efsaneleri Yıktım! →',
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
            label: 'Yansıtma',
            title: widget.title,
            color: AppTheme.reflect,
            colorLt: AppTheme.reflectLt,
          ),
          if (widget.intro.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.reflectLt,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.reflect.withValues(alpha: 0.3),
                ),
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
            'Kendine şunu sor:',
            style: TextStyle(
              color: AppTheme.reflect,
              fontSize: 12,
              fontWeight: FontWeight.w700,
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
                onTap: () => setState(() {
                  if (checked) {
                    _checked.remove(i);
                  } else {
                    _checked.add(i);
                  }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: checked ? AppTheme.reflectLt : AppTheme.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: checked ? AppTheme.reflect : AppTheme.border,
                      width: 1.5,
                    ),
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
                            color: checked
                                ? AppTheme.reflect
                                : AppTheme.textBody,
                            fontSize: 13,
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
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.bg,
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
            label: 'Değerlendirdim →',
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
                      ? AppTheme.bg
                      : wrong
                      ? AppTheme.redLt
                      : AppTheme.greenLt,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: word == null
                        ? AppTheme.word
                        : wrong
                        ? AppTheme.red
                        : AppTheme.green,
                    width: 2,
                  ),
                ),
                child: Text(
                  word ?? '  boşluk ${i + 1}  ',
                  style: TextStyle(
                    color: word == null
                        ? AppTheme.word
                        : wrong
                        ? AppTheme.red
                        : AppTheme.green,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
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
            label: 'Kelime Bankası',
            title: widget.title,
            color: AppTheme.word,
            colorLt: AppTheme.wordLt,
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
              color: AppTheme.wordLt,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.word.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 8,
              children: _buildTemplateParts(),
            ),
          ),
          const SizedBox(height: 16),

          // Kelime havuzu başlığı
          Row(
            children: [
              const Text('📦 ', style: TextStyle(fontSize: 14)),
              Text(
                'Kelime Havuzu',
                style: TextStyle(
                  color: AppTheme.word,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
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
                          color: AppTheme.wordLt,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.word.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.word.withValues(alpha: 0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          word,
                          style: TextStyle(
                            color: AppTheme.word,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
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
                color: AppTheme.redLt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.red.withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Text('⚠️ '),
                  Expanded(
                    child: Text(
                      'Hatalı boşluğa dokunup kelimeyi geri gönder, sonra yeniden seç.',
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
              opacity: allFilled ? 1 : 0.4,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: !allFilled,
                child: PrimaryButton(
                  label: allFilled
                      ? 'Kontrol Et ✅'
                      : 'Tüm boşlukları doldur...',
                  onPressed: _checkAnswer,
                  color: AppTheme.word,
                ),
              ),
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.greenLt,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.green.withValues(alpha: 0.4),
                ),
              ),
              child: const Row(
                children: [
                  Text('🎉 ', style: TextStyle(fontSize: 20)),
                  Expanded(
                    child: Text(
                      'Harika! Tüm boşlukları doğru doldurdun.',
                      style: TextStyle(
                        color: AppTheme.green,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Devam →',
              onPressed: widget.onComplete,
              color: AppTheme.word,
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
  int _tab = 0; // 0: sorular, 1: ipuçları, 2: tartışma

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StepHeader(
            emoji: '🧠',
            label: 'Kritik Düşünme',
            title: widget.title,
            color: AppTheme.quiz,
            colorLt: AppTheme.quizLt,
          ),
          const SizedBox(height: 16),

          // Tab bar
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                _TabBtn(
                  label: '❓ Sorular',
                  active: _tab == 0,
                  onTap: () => setState(() => _tab = 0),
                  color: AppTheme.quiz,
                ),
                _TabBtn(
                  label: '💡 İpuçları',
                  active: _tab == 1,
                  onTap: () => setState(() => _tab = 1),
                  color: AppTheme.quiz,
                ),
                _TabBtn(
                  label: '💬 Tartışma',
                  active: _tab == 2,
                  onTap: () => setState(() => _tab = 2),
                  color: AppTheme.quiz,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_tab == 0)
            ..._buildList(widget.prompts, AppTheme.quiz, AppTheme.quizLt, '❓')
          else if (_tab == 1)
            ..._buildList(
              widget.hints,
              AppTheme.concept,
              AppTheme.conceptLt,
              '💡',
            )
          else
            ..._buildList(
              widget.discussion,
              AppTheme.scenario,
              AppTheme.scenarioLt,
              '💬',
            ),

          if (widget.tasks.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              '📋 Görevler',
              style: TextStyle(
                color: AppTheme.quiz,
                fontSize: 12,
                fontWeight: FontWeight.w700,
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
                          color: AppTheme.quizLt,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppTheme.quiz.withValues(alpha: 0.4),
                          ),
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
            label: 'Düşündüm →',
            onPressed: widget.onComplete,
            color: AppTheme.quiz,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildList(
    List<String> items,
    Color color,
    Color lt,
    String icon,
  ) {
    return items
        .asMap()
        .entries
        .map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: lt,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
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

class _TabBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color color;
  const _TabBtn({
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
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppTheme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
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
      Future.delayed(const Duration(milliseconds: 300), _tick);
    }
  }

  static const _summaryColors = [
    AppTheme.primary,
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
            label: 'Özet',
            title: widget.title,
            color: AppTheme.primary,
            colorLt: AppTheme.primaryLt,
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
          ...widget.points.asMap().entries.map((e) {
            final visible = e.key <= _vis;
            final col = _summaryColors[e.key % _summaryColors.length];
            return AnimatedOpacity(
              opacity: visible ? 1 : 0,
              duration: const Duration(milliseconds: 350),
              child: AnimatedSlide(
                offset: visible ? Offset.zero : const Offset(-0.05, 0),
                duration: const Duration(milliseconds: 350),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: col.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${e.key + 1}',
                            style: TextStyle(
                              color: col,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
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
          const SizedBox(height: 20),
          PrimaryButton(label: 'Anladım →', onPressed: widget.onComplete),
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
      final pct = widget.questions.isEmpty
          ? 0
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
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 12),
            const Text(
              'Quiz Tamamlandı!',
              style: TextStyle(
                color: AppTheme.textBody,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGrad,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '$_score / ${widget.questions.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              pct == 1.0
                  ? 'Mükemmel! Tüm soruları doğru yanıtladın! 🏆'
                  : pct >= 0.7
                  ? 'Harika iş! Çok yaklaştın!'
                  : 'Tekrar deneyerek daha yüksek skor alabilirsin.',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            if (pct == 1.0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.certLt,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.cert.withValues(alpha: 0.4),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🏅 ', style: TextStyle(fontSize: 20)),
                    Text(
                      '"Bilgi Ustası" rozeti kazandın!',
                      style: TextStyle(
                        color: AppTheme.amber,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Devam →',
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
                label: 'Soru ${_qi + 1}/${widget.questions.length}',
                title: '',
                color: AppTheme.quiz,
                colorLt: AppTheme.quizLt,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.greenLt,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$_score ✓',
                  style: TextStyle(
                    color: AppTheme.green,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: _qi / widget.questions.length,
              minHeight: 6,
              backgroundColor: AppTheme.border,
              color: AppTheme.quiz,
            ),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.quizLt, AppTheme.primaryLt],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.quiz.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Text(
              q.q,
              style: const TextStyle(
                color: AppTheme.textBody,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1.5,
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
            Color txtColor = AppTheme.textBody;
            Color circleBg = AppTheme.bg;

            if (_answered && isCorr) {
              bg = AppTheme.greenLt;
              border = AppTheme.green;
              txtColor = AppTheme.green;
              circleBg = AppTheme.green;
            }
            if (_answered && isSel && !isCorr) {
              bg = AppTheme.redLt;
              border = AppTheme.red;
              txtColor = AppTheme.red;
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
                    border: Border.all(color: border, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: circleBg,
                        radius: 14,
                        child: Text(
                          _answered && isCorr
                              ? '✓'
                              : _answered && isSel
                              ? '✗'
                              : _letters[i],
                          style: TextStyle(
                            color: (_answered && (isCorr || isSel))
                                ? Colors.white
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
                            color: txtColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
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
                color: AppTheme.greenLt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.green.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡 '),
                  Expanded(
                    child: Text(
                      q.exp,
                      style: TextStyle(
                        color: AppTheme.green,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: _qi < widget.questions.length - 1
                  ? 'Sonraki Soru →'
                  : 'Sonuçları Gör →',
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
            label: 'Sözlük',
            title: 'Anahtar Kavramlar',
            color: AppTheme.concept,
            colorLt: AppTheme.conceptLt,
          ),
          const SizedBox(height: 16),
          ...widget.items.asMap().entries.map((e) {
            final i = e.key;
            final item = e.value;
            final open = _open == i;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                onTap: () => setState(() => _open = open ? null : i),
                background: open ? AppTheme.conceptLt : AppTheme.card,
                borderColor: open ? AppTheme.concept : AppTheme.border,
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
                                  ? AppTheme.concept
                                  : AppTheme.textBody,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Icon(
                          open
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          color: AppTheme.muted,
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
            );
          }),
          const SizedBox(height: 12),
          PrimaryButton(label: 'Devam →', onPressed: widget.onComplete),
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
          label: 'İlerleme',
          title: 'Harika Gidiyorsun!',
          color: AppTheme.game,
          colorLt: AppTheme.gameLt,
        ),
        const SizedBox(height: 24),
        PrimaryButton(label: 'Devam →', onPressed: onComplete),
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
          // Sertifika kartı
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: AppTheme.certGrad,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.cert.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 12),
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.message,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
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
              ],
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
                letterSpacing: 0.8,
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
                offset: visible ? Offset.zero : const Offset(-0.05, 0),
                duration: const Duration(milliseconds: 400),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: visible ? AppTheme.greenLt : AppTheme.bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: visible
                            ? AppTheme.green.withValues(alpha: 0.4)
                            : AppTheme.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppTheme.green,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
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
                color: AppTheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              children: [
                Text('🌟 ', style: TextStyle(fontSize: 18)),
                Expanded(
                  child: Text(
                    'Öğrendiklerini ailene ya da arkadaşına anlat!',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SecondaryButton(label: '🔄 Tekrar Al', onPressed: widget.onRestart),
        ],
      ),
    );
  }
}
