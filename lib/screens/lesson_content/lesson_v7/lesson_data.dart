import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'models.dart';

const String kDefaultLessonAssetPath = 'assets/lessons/lesson_engine.json';

String lessonTitle = 'Yapay Zeka Guvenlik Dersi';
int lessonTotalXP = 650;

List<LessonStep> lessonSteps = <LessonStep>[];

String _normalizeType(String type) {
  switch (type) {
    case 'concept_explanation':
      return 'concept_cards';
    case 'scenario_activity':
      return 'scenario_choice';
    case 'risk_cards':
      return 'risk_analysis';
    default:
      return type;
  }
}

int _xpForType(String type) {
  switch (_normalizeType(type)) {
    case 'intro':
      return 10;
    case 'concept_cards':
      return 20;
    case 'risk_analysis':
      return 20;
    case 'scenario_choice':
      return 30;
    case 'role_play':
      return 25;
    case 'mini_game':
      return 30;
    case 'word_bank':
      return 20;
    case 'quiz':
      return 40;
    case 'security_score':
      return 25;
    case 'summary':
      return 10;
    case 'reflection':
      return 15;
    case 'certificate':
      return 0;
    default:
      return 10;
  }
}

Future<void> loadLessonDataFromJsonAsset([
  String assetPath = kDefaultLessonAssetPath,
]) async {
  final raw = await rootBundle.loadString(assetPath);
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  final lesson =
      (decoded['lesson'] as Map<String, dynamic>? ?? <String, dynamic>{});
  final dynamicSteps = (lesson['steps'] as List<dynamic>? ?? const <dynamic>[])
      .whereType<Map<String, dynamic>>()
      .toList();

  lessonTitle = (lesson['title'] as String?)?.trim().isNotEmpty == true
      ? lesson['title'] as String
      : lessonTitle;

  final parsedSteps = <LessonStep>[];
  for (final step in dynamicSteps) {
    final id = (step['id'] ?? '').toString();
    final rawType = (step['type'] ?? '').toString();
    final type = _normalizeType(rawType);
    if (id.isEmpty || rawType.isEmpty) continue;

    final title = (step['title'] ?? '').toString();
    final content = step['content'] is Map<String, dynamic>
        ? (step['content'] as Map<String, dynamic>)
        : <String, dynamic>{};
    final activities = step['activities'] is Map<String, dynamic>
        ? (step['activities'] as Map<String, dynamic>)
        : <String, dynamic>{};
    final assessment = step['assessment'] is Map<String, dynamic>
        ? (step['assessment'] as Map<String, dynamic>)
        : <String, dynamic>{};

    parsedSteps.add(
      LessonStep(
        id: id,
        type: type,
        xp: _xpForType(type),
        data: <String, dynamic>{
          'title': title,
          'content': content,
          'activities': activities,
          'assessment': assessment,
          'teacher_notes': step['teacher_notes'] is Map<String, dynamic>
              ? (step['teacher_notes'] as Map<String, dynamic>)
              : <String, dynamic>{},
          'raw_type': rawType,
        },
      ),
    );
  }

  lessonSteps = parsedSteps;
  if (lessonSteps.isEmpty) {
    lessonSteps = <LessonStep>[
      const LessonStep(
        id: 'step_intro',
        type: 'intro',
        xp: 10,
        data: {'title': 'Giris'},
      ),
      const LessonStep(
        id: 'step_concepts',
        type: 'concept_cards',
        xp: 20,
        data: {'title': 'Kavramlar'},
      ),
      const LessonStep(
        id: 'step_risks',
        type: 'risk_cards',
        xp: 20,
        data: {'title': 'Riskler'},
      ),
      const LessonStep(
        id: 'step_quiz',
        type: 'quiz',
        xp: 40,
        data: {'title': 'Quiz'},
      ),
      const LessonStep(
        id: 'step_summary',
        type: 'summary',
        xp: 10,
        data: {'title': 'Ozet'},
      ),
      const LessonStep(
        id: 'step_reflection',
        type: 'reflection',
        xp: 15,
        data: {'title': 'Degerlendirme'},
      ),
      const LessonStep(
        id: 'step_certificate',
        type: 'certificate',
        xp: 0,
        data: {'title': 'Sertifika'},
      ),
    ];
  }

  lessonTotalXP = lessonSteps.fold<int>(0, (acc, s) => acc + s.xp);
}

const List<TimelineItem> defaultTimeline = [
  TimelineItem(
    time: '07:00',
    label: 'Sabah',
    app: 'Instagram / WhatsApp / YouTube',
    icon: '📸',
    data: ['Fotograflarin', 'Begenilerin', 'Arkadas listen', 'Konumun'],
  ),
  TimelineItem(
    time: '08:30',
    label: 'Okul Yolu',
    app: 'Spotify / Google Maps',
    icon: '🎵',
    data: ['Muzik zevkin', 'Dinleme saatlerin', 'Konumun', 'Guzergahin'],
  ),
  TimelineItem(
    time: '09:00',
    label: 'Okul',
    app: 'Google Classroom / EBA / Zoom',
    icon: '📚',
    data: ['Odevlerin', 'Notlarin', 'Etkinlik suren', 'Kamera goruntun'],
  ),
  TimelineItem(
    time: '19:00',
    label: 'Aksam',
    app: 'Roblox / Netflix / TikTok',
    icon: '🎮',
    data: [
      'Oyun davranislarin',
      'Izledigin videolar',
      'Arama gecmisin',
      'Satin alimlarin',
    ],
  ),
];

const List<AnalysisItem> defaultAnalysisItems = [
  AnalysisItem(
    icon: '🔍',
    title: 'Sebepleri incele',
    explanation:
        'Bir sonucun neden ortaya ciktigini gozlem ve kanitlarla acikla.',
  ),
  AnalysisItem(
    icon: '🧪',
    title: 'Degiskenleri ayir',
    explanation:
        'Isik kaynagi, cisim ve uzaklik gibi degiskenleri tek tek dusun.',
  ),
  AnalysisItem(
    icon: '📏',
    title: 'Olc ve karsilastir',
    explanation: 'Golge boyunu farkli durumlarda olcerek sonucunu destekle.',
  ),
  AnalysisItem(
    icon: '💬',
    title: 'Sonucu acikla',
    explanation: 'Gozlemini kendi cumlelerinle anlat ve baskasina aktar.',
  ),
];

const List<MythItem> defaultMyths = [
  MythItem(
    icon: '🌞',
    myth: 'Golge kendi basina olusur.',
    truth: 'Golge, isigin bir cisim tarafindan engellenmesiyle olusur.',
    example: 'El feneri kapaliysa duvarda golge de olusmaz.',
  ),
  MythItem(
    icon: '📏',
    myth: 'Golge her zaman ayni boyda kalir.',
    truth: 'Isik kaynaginin yeri ve cismin uzakligi golge boyunu degistirir.',
    example: 'Gunes batarken golgeler daha uzun gorunur.',
  ),
  MythItem(
    icon: '🧱',
    myth: 'Her cisim ayni golgeyi olusturur.',
    truth: 'Cismin buyuklugu ve sekli golgenin sekil ve boyunu etkiler.',
    example: 'Top ile kitap ayni golgeyi olusturmaz.',
  ),
];

const List<String> defaultCriticalHints = [
  'Isik kaynaginin konumu degisirse golge nasil etkilenir?',
  'Cisim buyuklugu ve uzakligi ayni anda degisir mi?',
  'Sonucunu gozlemle destekleyebilir misin?',
];

const List<String> defaultCriticalDiscussion = [
  'Gun icinde golgeler neden farkli uzunlukta olur?',
  'Ayni cisim farkli isik kaynaklarinda ayni golgeyi verir mi?',
];

const List<FirewallLayer> defaultFirewallLayers = [
  FirewallLayer(
    name: '1. Katman',
    color: '#ef4444',
    items: ['Ana fikri belirle', 'En onemli bilgiyi ayikla'],
  ),
  FirewallLayer(
    name: '2. Katman',
    color: '#14b8a6',
    items: ['Ornekleri incele', 'Degiskenleri fark et'],
  ),
  FirewallLayer(
    name: '3. Katman',
    color: '#3b82f6',
    items: ['Gozlemini acikla', 'Gunluk hayatla bag kur'],
  ),
];

const List<KeywordItem> defaultKeywords = [
  KeywordItem(term: 'Isik', def: 'Gormemizi saglayan enerji turu.'),
  KeywordItem(
    term: 'Tam Golge',
    def: 'Isigin engellenmesiyle olusan tamamen karanlik bolge.',
  ),
  KeywordItem(term: 'Isik Kaynagi', def: 'Isik yayan kaynak.'),
  KeywordItem(term: 'Opak Cisim', def: 'Isigi gecirmeyen cisim.'),
];

const List<BadgeItem> defaultBadges = [
  BadgeItem(
    id: 'security_master',
    name: 'Bilgi Ustasi',
    condition: 'Quiz adimini yuksek basariyla tamamla',
    icon: '🎓',
  ),
  BadgeItem(
    id: 'detective',
    name: 'Kesifci',
    condition: 'Senaryo veya rol yapma adimlarini tamamla',
    icon: '🔍',
  ),
  BadgeItem(
    id: 'ethic_hacker',
    name: 'Dusunen Zihin',
    condition: 'Yansitma ve kritik dusunme adimlarini tamamla',
    icon: '🧠',
  ),
  BadgeItem(
    id: 'digital_citizen',
    name: 'Ders Tamamlandi',
    condition: 'Tum dersi bitir',
    icon: '🏆',
  ),
];

const List<String> defaultTakeaways = [
  'Ana kavramlari tekrar et.',
  'Deney ve gozlemleri not al.',
  'Sonuclari nedenleriyle acikla.',
  'Gunluk hayatta benzer ornekler ara.',
];
