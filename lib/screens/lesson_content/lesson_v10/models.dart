// ─── MODELS ───────────────────────────────────────────────────────────────────

class LessonStep {
  final String id;
  final String type;
  final int xp;
  final Map<String, dynamic> data;
  const LessonStep({
    required this.id,
    required this.type,
    required this.xp,
    required this.data,
  });
}

class ConceptItem {
  final String icon, title, desc;
  final String? example;
  const ConceptItem({
    required this.icon,
    required this.title,
    required this.desc,
    this.example,
  });
}

class InfoItem {
  final String text, example;
  const InfoItem({required this.text, required this.example});
}

class CaseStudy {
  final String emoji, title, where, desc, lesson, action;
  const CaseStudy({
    required this.emoji,
    required this.title,
    required this.where,
    required this.desc,
    required this.lesson,
    required this.action,
  });
}

class TimelineItem {
  final String time, label, app, icon;
  final List<String> data;
  const TimelineItem({
    required this.time,
    required this.label,
    required this.app,
    required this.icon,
    required this.data,
  });
}

class ScoreQuestion {
  final String text, icon;
  final int points;
  const ScoreQuestion({
    required this.text,
    required this.icon,
    required this.points,
  });
}

class RoleChoice {
  final String text, feedback;
  final int points;
  final bool isGood;
  const RoleChoice({
    required this.text,
    required this.feedback,
    required this.points,
    required this.isGood,
  });
}

class Permission {
  final String icon, name, reason;
  final bool needed;
  const Permission({
    required this.icon,
    required this.name,
    required this.reason,
    required this.needed,
  });
}

class AnalysisItem {
  final String icon, title, explanation;
  const AnalysisItem({
    required this.icon,
    required this.title,
    required this.explanation,
  });
}

class MythItem {
  final String icon, myth, truth, example;
  const MythItem({
    required this.icon,
    required this.myth,
    required this.truth,
    required this.example,
  });
}

class QuizQuestion {
  final String q, exp;
  final List<String> opts;
  final int ans;
  const QuizQuestion({
    required this.q,
    required this.exp,
    required this.opts,
    required this.ans,
  });
}

class KeywordItem {
  final String term, def;
  const KeywordItem({required this.term, required this.def});
}

class BadgeItem {
  final String id, name, condition, icon;
  const BadgeItem({
    required this.id,
    required this.name,
    required this.condition,
    required this.icon,
  });
}

class FirewallLayer {
  final String name, color;
  final List<String> items;
  const FirewallLayer({
    required this.name,
    required this.color,
    required this.items,
  });
}

class WordBankBlank {
  final String id;
  final String correctAnswer;
  const WordBankBlank({required this.id, required this.correctAnswer});
}
