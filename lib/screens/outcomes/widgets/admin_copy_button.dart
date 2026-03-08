import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum AdminPromptType { content, questions }

class AdminCopyButton extends StatelessWidget {
  final String gradeName;
  final String lessonName;
  final String unitTitle;
  final String topicTitle;
  final List<Map<String, dynamic>> outcomes;
  final AdminPromptType promptType;

  const AdminCopyButton({
    super.key,
    required this.gradeName,
    required this.lessonName,
    required this.unitTitle,
    required this.topicTitle,
    required this.outcomes,
    this.promptType = AdminPromptType.content,
  });

  static String buildPrompt({
    required String gradeName,
    required String lessonName,
    required String unitTitle,
    required String topicTitle,
    required List<Map<String, dynamic>> outcomes,
    required AdminPromptType promptType,
  }) {
    final outcomesBuffer = StringBuffer();
    if (outcomes.isEmpty) {
      outcomesBuffer.writeln('(Kazanım bulunamadı)');
    } else {
      for (final outcome in outcomes) {
        final description = (outcome['description'] as String? ?? '').trim();
        if (description.isNotEmpty) {
          outcomesBuffer.writeln('- $description');
        }
      }
    }

    if (promptType == AdminPromptType.content) {
      return _buildContentPrompt(
        gradeName: gradeName,
        lessonName: lessonName,
        unitTitle: unitTitle,
        topicTitle: topicTitle,
        outcomesText: outcomesBuffer.toString(),
      );
    }
    return _buildQuestionsPrompt(
      gradeName: gradeName,
      lessonName: lessonName,
      unitTitle: unitTitle,
      topicTitle: topicTitle,
      outcomesText: outcomesBuffer.toString(),
    );
  }

  static Future<void> copyPrompt(
    BuildContext context, {
    required String gradeName,
    required String lessonName,
    required String unitTitle,
    required String topicTitle,
    required List<Map<String, dynamic>> outcomes,
    required AdminPromptType promptType,
  }) async {
    final prompt = buildPrompt(
      gradeName: gradeName,
      lessonName: lessonName,
      unitTitle: unitTitle,
      topicTitle: topicTitle,
      outcomes: outcomes,
      promptType: promptType,
    );

    try {
      await Clipboard.setData(ClipboardData(text: prompt));
      if (context.mounted) {
        String message;
        switch (promptType) {
          case AdminPromptType.content:
            message = 'İçerik bilgileri kopyalandı';
            break;
          case AdminPromptType.questions:
            message = 'Soru hazırlama promptu kopyalandı';
            break;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Kopyalama hatası: $e')));
      }
    }
  }

  Future<void> _copyToClipboard(BuildContext context) {
    return copyPrompt(
      context,
      gradeName: gradeName,
      lessonName: lessonName,
      unitTitle: unitTitle,
      topicTitle: topicTitle,
      outcomes: outcomes,
      promptType: promptType,
    );
  }

  static String _buildContentPrompt({
    required String gradeName,
    required String lessonName,
    required String unitTitle,
    required String topicTitle,
    required String outcomesText,
  }) {
    return '''
Sen bir öğretim programı geliştiricisi, eğitim tasarımcısı ve öğretmen kılavuz kitabı yazarısın.

Görevin verilen ders bilgilerine göre TAM, PEDAGOJİK ve ETKİLEŞİMLİ bir ders içeriği oluşturmaktır.

Bu içerik üç amaca aynı anda hizmet etmelidir:
  • Öğretmen dersi anlatırken ekrandan takip eder — hiç hazırlık yapmadan anlatabilmeli
  • Öğrenci evde tek başına çalışır — konuyu baştan sona öğrenebilmeli
  • Öğrenci mobil uygulamadan interaktif öğrenir — aktivitelerle pekiştirebilmeli

TEK bir JSON, tek bir content alanı — ama bu alan üç kullanıcıya da yetecek kadar zengin olacak.

Bu ders bir mobil eğitim uygulamasında kullanılacaktır.
Cevap SADECE geçerli JSON olmalıdır. JSON dışında hiçbir şey yazma. Başına ```json ekleme.

═══════════════════════════════════════
SÜRE ANLAYIŞI
═══════════════════════════════════════

"estimated_time" alanı YOKTUR — yapay kısıtlama koymuyoruz.
Her step kendi "duration_minutes" değerini taşır.
Konunun derinliğine göre 10 dakika da olabilir, 10 saat de — gerçekçi tahmin yap.
Bir step 5 dakika da sürebilir, 120 dakika da.

═══════════════════════════════════════
TEMEL FELSEFE — Step sayısını nasıl belirlersin
═══════════════════════════════════════

Step sayısını önceden belirleme. Şu soruları zihninde yanıtla:

  1. Bu konunun kaç ALT KAVRAMI var?
     → Her alt kavram kendi concept_explanation step'ini hak eder.
     → Bir step'e birden fazla alt kavram sıkıştırma — gerekirse iki step yap.

  2. Her kavramı açıklamak için hangi ANALOJİLER işe yarar?
     → Her concept_explanation en az 1 güçlü, günlük hayattan analoji içermeli.

  3. Hangi YANILGILAR yaygın ve neden oluşuyor?
     → Her yanılgı için: ne yanlış düşünülüyor + neden + doğrusu ne.

  4. Hangi kavramlar birbirine KARISTIRILIR?
     → Karıştırılan kavram çiftleri için karşılaştırmalı concept_explanation ekle.

  5. Öğrenci nerede TAKILIR?
     → Zorlu noktalara ekstra critical_thinking veya mini_game ekle.

  6. Konu önceki/sonraki derslerle nasıl BAĞLANIYOR?
     → real_life_connections içinde hem önceki hem sonraki derse köprü kur.

Kazanımlar merkezdedir ama konunun tüm pedagojik içeriği eksiksiz işlenmelidir.

═══════════════════════════════════════
STEP KURALLARI
═══════════════════════════════════════

• Aynı type birden fazla kez kullanılabilir — içerik gerektiriyorsa kullan.
• Her step tek bir kavrama odaklanmalı — gerekirse iki step'e böl.
• Step sayısı için sınır yoktur.
• Her step'te "activities" ASLA boş {} bırakılamaz.
• teacher_notes içindeki tüm listeler ASLA boş [] bırakılamaz.
• Kartlar, seçenekler, oyun maddeleri NESNE formatında olmalıdır (string dizisi YASAKTIR).

═══════════════════════════════════════
İÇERİK KALİTESİ — ALAN BAZLI STANDARTLAR
═══════════════════════════════════════

──────────────────────────────────────
EXPLANATION — Tam ders anlatımı, kitap gibi
──────────────────────────────────────

• Paragraflar halinde yazılır — minimum 3 paragraf, her paragraf 4–6 cümle
• Toplam uzunluk: 10–15 cümle (1–2 paragraf)
• Bu metin hem öğretmenin sınıfta okuyacağı hem öğrencinin evde okuyacağı metindir
• Her paragraf tek bir fikri işler ve akıcı geçişlerle bağlanır

PARAGRAF YAPISI:
  Paragraf 1 — Bağlam + kavram açıklaması: Günlük hayattan giriş → teknik terimler parantez içinde → mutlaka 1 ANALOJİ
  Paragraf 2 — Detay + bağlantı: Nasıl çalışır, neye bağlıdır → önceki/sonraki konuya köprü → bir sonraki adıma geçiş cümlesi

ANALOJİ KURALI:
  Her explanation içinde mutlaka şu formatta bir analoji bulunmalıdır:
  "Bu tıpkı [günlük hayat durumu] gibidir — [benzerlik açıklaması]."

KÖTÜ ÖRNEK (YAPMA):
  "Tam gölge ışığın engellenmesiyle oluşur. Cisim opak olmalıdır. Gölge karanlık bölgedir."

İYİ ÖRNEK (BÖYLE YAZ):
  "Güneşli bir günde dışarı çıktığında yerde hep bir gölgen olduğunu fark etmişsindir. Bu sıradan görünen olay aslında ışığın temel bir özelliğini gözler önüne serer: ışık düz bir çizgi boyunca yayılır ve önüne çıkan engeli aşamaz. Peki bu basit gerçek nasıl bir gölgeye dönüşür?

  Işık kaynağından (güneş, lamba, el feneri) çıkan ışınlar, önlerine opak (ışığı hiç geçirmeyen) bir cisim çıkana kadar düz yollarına devam ederler. Cisimle karşılaştıklarında ise içinden geçemezler — bu tıpkı bir nehrin önüne beton duvar örülmesine benzer; su duvarın içinden geçemez, duvarın arkası tamamen kurudur. İşte cismin arkasında kalan, hiç ışık ulaşmayan bu tamamen karanlık bölgeye tam gölge (umbra) denir.

  Tam gölgenin en belirgin özelliği, içine hiç ışık girmemesidir. Bu nedenle tam gölge bölgesinden bakıldığında ışık kaynağı tamamen görünmez. Gölgenin boyutu ve şekli sabit değildir; ışık kaynağının konumuna, cismin büyüklüğüne ve aralarındaki mesafeye göre sürekli değişir. Sabah güneş alçakta olduğunda uzun gölgeler görürüz, öğlen güneş tepede olduğunda ise gölgeler ayaklarımızın hemen altına çekilir.

  Tam gölge kavramını anlamak, bir sonraki konumuz olan yarı gölgeyi (penumbra) kavramak için de temel oluşturur. Yarı gölgede ışık kaynağı büyüdükçe tam gölgenin etrafında kısmen aydınlık bir bölge belireceğini göreceğiz."

──────────────────────────────────────
KEY_POINTS — Kısa başlık + alt açıklama
──────────────────────────────────────

Her key_point iki katmanlı bir nesne değil, şu formatta tek bir string olarak yazılır:
  "[KISA BAŞLIK]: [2–3 cümle açıklama — neden önemli, ne anlama geliyor, sonucu ne]"

• En az 5 madde
• Kısa başlık 3–6 kelime
• Açıklama "ne" değil "ne + neden + ne anlama gelir" söylemeli
• Hangi kazanımı karşıladığı parantez içinde belirtilmeli

KÖTÜ ÖRNEK (YAPMA):
  "Tam gölge karanlıktır."
  "Işık engellenir."

İYİ ÖRNEK (BÖYLE YAZ):
  "Tam gölge nedir: Tam gölge (umbra), bir ışık kaynağından gelen tüm ışınların opak bir cisim tarafından tamamen engellenmesiyle oluşan karanlık bölgedir. Bu bölgeye hiç ışık ulaşmadığı için burası tamamen karanlık görünür. (Kazanım 1)"
  "Gölge boyutu değişkendir: Gölgenin büyüklüğü sabit değildir; cisim ışık kaynağına yaklaştıkça gölge büyür, uzaklaştıkça küçülür. Bunun nedeni, yakın mesafede cismin daha geniş bir ışın demetini engellemesidir. (Kazanım 3)"

──────────────────────────────────────
EXAMPLES — Açıklamalı, bağlamlı örnekler
──────────────────────────────────────

• En az 4 örnek, farklı bağlamlardan: doğa, ev, okul, teknoloji, sanat, tarih vb.
• Her örnek 2–3 cümle: durum + neden olduğu + gözlemlenebilir sonucu

KÖTÜ ÖRNEK (YAPMA):
  "Ağaç gölgesi."
  "El feneri."

İYİ ÖRNEK (BÖYLE YAZ):
  "Yaz öğleni ağacın altında serinlemek: Ağacın gövdesi ve yaprakları opak olduğu için güneş ışınlarını tamamen engeller ve altında tam gölge oluşturur. Öğlen güneş tepede olduğunda bu gölge küçük ve yoğundur; akşama doğru ise uzayıp soluklaşır."
  "Masaüstü lambası ve kitap: Gece masanın üzerindeki tek ampullü lambayı açtığında kitabın masaya düşürdüğü keskin kenarlı karanlık alan tam gölgedir. Lamba küçük bir nokta kaynak gibi davrandığından gölgenin kenarları belirgindir — büyük yüzeyli bir lamba olsaydı kenarlar bulanıklaşırdı."

──────────────────────────────────────
REAL_LIFE_CONNECTIONS — Köprü kuran bağlantılar
──────────────────────────────────────

• En az 4 madde, her biri 2–3 cümle
• Bir tanesi önceki konuyla bağlantı (ne öğrendik, nasıl bağlanıyor)
• Bir tanesi sonraki konuya köprü (ne öğreneceğiz, neden bu temel)
• İki tanesi günlük hayattan ilginç/şaşırtıcı bağlantı

──────────────────────────────────────
TEACHER_NOTES.TEACHING_TIPS
──────────────────────────────────────

• En az 4 madde, her biri 2–3 cümle
• Soyut tavsiye değil, yapılabilir somut eylem
• "Nasıl anlat + hangi materyal + ne kadar süre + dikkat et" formatında

KÖTÜ ÖRNEK (YAPMA):
  "Öğrencilere açıklayın."

İYİ ÖRNEK (BÖYLE YAZ):
  "Explanation metnini doğrudan okumadan önce sınıfı karartın ve el fenerini açın. 'Bu ışık nereden geliyor, arkasına geçebilir miyiz?' sorusunu sorun. Merak oluştuktan sonra metni birlikte okuyun — bu sırayla işlendiğinde kavram çok daha akılda kalıcı olur. Bu giriş için 3–4 dakika ayırın."

──────────────────────────────────────
TEACHER_NOTES.COMMON_MISCONCEPTIONS
──────────────────────────────────────

• En az 3 madde
• ZORUNLU FORMAT, her madde bu üç parçayı içermeli:
  "Öğrenciler [YANLIŞ DÜŞÜNCE] sanabilir çünkü [NEDEN OLUŞUYOR — psikolojik/deneyimsel sebep]. Doğrusu: [DOĞRU BİLGİ + kısa açıklama + nasıl düzeltilir]."

KÖTÜ ÖRNEK (YAPMA):
  "Gölgenin cismin parçası olduğu düşünülebilir."

İYİ ÖRNEK (BÖYLE YAZ):
  "Öğrenciler gölgenin cismin bir parçası ya da cismin yansıması olduğunu sanabilir çünkü gölge her zaman cisimle birlikte hareket eder ve cisimle aynı şekle sahiptir — bu güçlü görsel benzerlik yanıltıcıdır. Doğrusu: gölge cismin fiziksel bir parçası değildir; ışığın engellenmesiyle oluşan karanlık bir alandır. Bunu göstermek için cismi ortadan kaldırın — gölge de anında yok olur. Yansıma ise farklı bir kavramdır: ışığın yüzeyden geri sekip farklı bir yöne gitmesidir."

──────────────────────────────────────
TEACHER_NOTES.CLASSROOM_DISCUSSION
──────────────────────────────────────

• En az 3 soru — ASLA boş bırakma
• Her soru 1–2 cümle + parantez içinde beklenen cevap yönlendirmesi

KÖTÜ ÖRNEK (YAPMA):
  "Gölge nedir?"

İYİ ÖRNEK (BÖYLE YAZ):
  "Güneş sabah doğudan, öğlen tepeden, akşam batıdan gelir — bu durumda senin gölgen gün içinde nasıl değişir ve neden? (Beklenen: sabah ve akşam gölge uzun ve karşı yönde çünkü ışık açılı geliyor; öğlen kısa çünkü ışık dik geliyor)"

──────────────────────────────────────
TEACHER_NOTES.EXTENSION_IDEAS
──────────────────────────────────────

• En az 3 madde
• 1. madde: Sınıfta hızlı bitenler için (2–5 dk)
• 2. madde: Evde yapılabilecek gözlem veya deney (malzemeli, adım adım)
• 3. madde: İleri düzey / meraklı öğrenci için araştırma sorusu veya proje

═══════════════════════════════════════
ZORUNLU JSON ŞEMASI
═══════════════════════════════════════

{
  "lesson": {
    "grade": "string",
    "subject": "string",
    "unit": "string",
    "topic": "string",
    "title": "string",
    "description": "string",
    "difficulty_level": "kolay | orta | zor",
    "learning_objectives": ["string"],
    "keywords": ["string"],
    "steps": [ ...STEP nesneleri... ]
  }
}

NOT: "estimated_time" alanı YOKTUR. Süre her step'te "duration_minutes" olarak taşınır.

═══════════════════════════════════════
STEP ŞEMASI
═══════════════════════════════════════

{
  "id": "step1",
  "type": "string",
  "title": "string",
  "duration_minutes": sayı,
  "content": {
    "explanation": "string — 1–2 paragraf, 10–15 cümle, analoji zorunlu",
    "key_points": [
      "string — KISA BAŞLIK: 2–3 cümle açıklama (Kazanım X)"
    ],
    "examples": ["string — 2–3 cümle, neden olduğunu açıklayan"],
    "real_life_connections": ["string — 2–3 cümle, köprü kuran"]
  },
  "activities": { ... },
  "assessment": { ... },
  "teacher_notes": {
    "teaching_tips": ["string — 2–3 cümle, somut eylem"],
    "common_misconceptions": ["string — X sanabilir çünkü Y. Doğrusu: Z. formatında"],
    "classroom_discussion": ["string — soru + (beklenen cevap)"],
    "extension_ideas": ["string — 2–3 cümle, kime yönelik olduğu belirtilmiş"]
  }
}

═══════════════════════════════════════
TYPE LİSTESİ ve ACTIVITIES ŞEMALARI
═══════════════════════════════════════

─── TYPE: intro ──────────────────────
Kullanım: Her dersin ilk step'i. Merak uyandır, ön bilgileri aktive et.
"activities": {
  "discussion_prompts": ["string — en az 3 merak uyandırıcı soru"]
}

─── TYPE: concept_explanation ────────
Kullanım: Tek bir kavramı derinlemesine açıkla. Aynı derste birden fazla olabilir.
"activities": {
  "cards": [
    { "item": "string", "label": "string" }
    // en az 4 kart
  ]
}

─── TYPE: risk_analysis ──────────────
Kullanım: Yaygın yanılgıları ve yanlış düşünceleri ele al.
"activities": {
  "cards": [
    { "item": "string — yanlış düşünce", "label": "yüksek risk | orta risk | düşük risk" }
    // en az 3 kart
  ]
}

─── TYPE: scenario_activity ──────────
Kullanım: Kavramı gerçek bir durumda uygulat. Aynı derste birden fazla olabilir.
"activities": {
  "scenario": "string — ayrıntılı, gerçekçi senaryo, en az 3 cümle",
  "choices": [
    { "text": "string", "correct": true|false, "feedback": "string — 2–3 cümle" }
    // tam 3 seçenek, en az 1 correct:true
  ]
}

─── TYPE: role_play ──────────────────
Kullanım: Empati ve canlandırma yoluyla kavramı deneyimlet.
"activities": {
  "role_play": [
    { "role": "string", "action": "string — ayrıntılı" }
    // en az 3 rol
  ]
}

─── TYPE: mini_game ──────────────────
Kullanım: Hızlı pekiştirme. Aynı derste birden fazla olabilir.
"activities": {
  "mini_game": [
    { "situation": "string", "correct_answer": "string", "feedback": "string — neden doğru" }
    // en az 5 madde
  ]
}

─── TYPE: word_bank ──────────────────
Kullanım: ZORUNLU — her derste en az 1 tane bulunmalıdır.
Öğrenci kelime listesinden tıklayarak boşlukları doldurur.
"activities": {
  "word_bank": {
    "words": ["string — doğru cevaplar + en az 3 yanıltıcı kelime, karışık sırada"],
    "template": "string — boşluklar tam olarak ____ (4 alt çizgi) ile gösterilir",
    "blanks": [
      { "id": "blank1", "correct_answer": "string — words listesindeki değerlerden biri" }
    ]
  }
}
KURALLAR:
• template içindeki ____ sayısı = blanks dizisi uzunluğu (EŞİT OLMALI)
• Her correct_answer words listesinde BULUNMALI
• En iyi yer: kavram bloklarının sonunda, quiz'den önce

─── TYPE: quiz ───────────────────────
Kullanım: Tüm kazanımları ölçen test. Derste 1 kez.
"activities": {
  "quiz_questions": [
    {
      "question": "string",
      "options": ["string", "string", "string", "string"],
      "correct_answer": "string — options içindeki değerlerden biri"
    }
    // kazanım başına en az 2 soru
  ]
}
NOT: assessment.quiz_questions = activities.quiz_questions (birebir aynı)

─── TYPE: critical_thinking ──────────
Kullanım: Derinlemesine analiz. Zorlu kavramların ardından.
"activities": {
  "discussion_prompts": ["string — en az 3 derin soru"],
  "evaluation_tasks": ["string — en az 2 somut görev"]
}

─── TYPE: summary ────────────────────
Kullanım: Dersin tamamını özetle. 1 kez, kapanışta.
"activities": {
  "summary_points": ["string — en az 7 madde, tüm kazanım ve kavramları kapsar"]
}

─── TYPE: reflection ─────────────────
Kullanım: Öğrencinin kendi öğrenmesini değerlendirmesi.
"activities": {
  "discussion_prompts": ["string — en az 3 öz değerlendirme sorusu"],
  "evaluation_tasks": ["string — en az 2 somut görev"]
}

─── TYPE: certificate ────────────────
Kullanım: Dersin son step'i.
"activities": {
  "certificate_message": "string — konuya özgü, kişiselleştirilmiş tebrik",
  "earned_badges": ["string — en az 3 konuyla ilgili rozet"]
}

═══════════════════════════════════════
ASSESSMENT ŞEMASI
═══════════════════════════════════════

• intro, summary, certificate → assessment: {} boş bırakılabilir
• quiz → assessment.quiz_questions DOLU OLMALI (activities ile birebir aynı)
• Diğer type'lar → en az bir alan dolu:
    reflective_questions: ["string — en az 2"]
    evaluation_tasks: ["string — en az 1"]
    quiz_questions: [{ question, options:[4], correct_answer }]

═══════════════════════════════════════
DERS YAPISI
═══════════════════════════════════════

1. GİRİŞ
   └─ intro

2. KAVRAM BLOKLARI (her alt kavram için genişler)
   ├─ concept_explanation  ← kavramı derin anlat
   ├─ concept_explanation  ← alt detay veya karşılaştırma (gerekirse)
   ├─ scenario_activity    ← gerçek durumda uygulat
   ├─ role_play            ← empatiyle deneyimlet (gerekirse)
   ├─ mini_game            ← pekiştir
   └─ critical_thinking    ← zorlu kavramlarda ekle

3. KELİME BANKASI
   └─ word_bank ← tüm önemli terimleri içerir, quiz öncesi

4. YANILGI ANALİZİ
   └─ risk_analysis

5. ÖLÇME
   └─ quiz

6. KAPANIŞ
   ├─ summary
   ├─ reflection
   └─ certificate

═══════════════════════════════════════
KALİTE KONTROL LİSTESİ
═══════════════════════════════════════

JSON'u bitirmeden önce her step için kontrol et:

□ explanation 1–2 paragraf, toplamda 10–15 cümle mi?
□ explanation içinde analoji var mı ("Bu tıpkı... gibidir")?
□ Her key_point "BAŞLIK: açıklama (Kazanım X)" formatında mı?
□ Her example 2–3 cümle ve neden olduğunu açıklıyor mu?
□ Her misconception "X sanabilir çünkü Y. Doğrusu: Z." formatında mı?
□ Her classroom_discussion sorusu beklenen cevabı taşıyor mu?
□ word_bank var mı? ____ sayısı ile blanks sayısı eşit mi?
□ Her step duration_minutes taşıyor mu?
□ Hiçbir activities boş {} değil mi?
□ Hiçbir teacher_notes listesi boş [] değil mi?

═══════════════════════════════════════
KULLANICI GİRDİSİ
═══════════════════════════════════════

Sınıf: $gradeName
Ders: $lessonName
Ünite: $unitTitle
Konu: $topicTitle
Kazanımlar:
$outcomesText
''';
  }

  static String _buildQuestionsPrompt({
    required String gradeName,
    required String lessonName,
    required String unitTitle,
    required String topicTitle,
    required String outcomesText,
  }) {
    return '''
Sen deneyimli bir ölçme-değerlendirme uzmanı ve pedagojik içerik geliştiricisisin.

Görevin, verilen ders bilgileri ve kazanımlara göre, çeşitli tiplerde ve zorluk seviyelerinde 10 adet soru üretmektir.

Cevap SADECE geçerli JSON olmalıdır. JSON dışında hiçbir açıklama, markdown, yorum satırı yazma.

═══════════════════════════════════════
GENEL KURALLAR
═══════════════════════════════════════

• Toplam 10 soru üret.
• Sorular kazanımlarla doğrudan ilişkili olmalı.
• Sorular ezber değil, anlamaya dayalı olmalı.
• En az bir soru kavram yanılgısını ölçmeli.
• Zorluk dağılımı dengeli olmalı (kolay-orta-zor karışık).
• Her soru için mutlaka "solution_text" adında bir açıklama/çözüm alanı eklenmeli.
• Günlük hayat bağlantılı sorulara yer ver.
• En az 1 analiz düzeyi soru ekle.
• Soru tipleri dengeli dağıtılsın.

═══════════════════════════════════════
DESTEKLENEN SORU TİPLERİ
═══════════════════════════════════════

- 1 = Çoktan Seçmeli
- 2 = Doğru / Yanlış
- 3 = Boşluk Doldurma (Drag & Drop)
- 5 = Eşleştirme

═══════════════════════════════════════
FORMAT KURALLARI
═══════════════════════════════════════

• Çoktan seçmeli (ID: 1): 4 seçenek olmalı, sadece 1 doğru cevap olmalı.
• Doğru / Yanlış (ID: 2): "correct_answer" alanı olmalı. "choices" veya "blank" OLMAYACAK.
• Boşluk doldurma (ID: 3): "blank.options" en az 3 seçenek içermeli, 1 tanesi doğru olmalı.
• Eşleştirme (ID: 5): "pairs" en az 3 eşleştirme çifti olmalı.

═══════════════════════════════════════
ZORUNLU JSON ÇIKTI ŞEMASI
═══════════════════════════════════════

{
  "topic": "$topicTitle",
  "_supported_question_types": [
    { "type": "Çoktan Seçmeli", "id": 1, "keyboard_input": false },
    { "type": "Doğru / Yanlış", "id": 2, "keyboard_input": false },
    { "type": "Boşluk Doldurma (Drag & Drop)", "id": 3, "keyboard_input": false },
    { "type": "Eşleştirme", "id": 5, "keyboard_input": false }
  ],
  "questions": [
    {
      "question_type_id": 1,
      "question_text": "Soru metni...",
      "difficulty": 1,
      "score": 1,
      "solution_text": "Bu sorunun çözümü şöyledir çünkü...",
      "choices": [
        { "text": "Doğru Seçenek", "is_correct": true },
        { "text": "Yanlış Seçenek 1", "is_correct": false },
        { "text": "Yanlış Seçenek 2", "is_correct": false },
        { "text": "Yanlış Seçenek 3", "is_correct": false }
      ]
    },
    {
      "question_type_id": 2,
      "question_text": "Doğru yanlış soru metni...",
      "difficulty": 2,
      "score": 1,
      "solution_text": "İfadenin doğruluğu/yanlışlığı şuna dayanır...",
      "correct_answer": true
    },
    {
      "question_type_id": 3,
      "question_text": "Boşluk doldurma metni ____...",
      "difficulty": 3,
      "score": 1,
      "solution_text": "Cümledeki boşluğa gelecek kavram şudur çünkü...",
      "blank": {
        "options": [
          { "text": "Doğru", "is_correct": true },
          { "text": "Yanlış 1", "is_correct": false },
          { "text": "Yanlış 2", "is_correct": false }
        ]
      }
    },
    {
      "question_type_id": 5,
      "question_text": "Eşleştirme sorusu metni...",
      "difficulty": 3,
      "score": 1,
      "solution_text": "Eşleştirmelerin mantığı şöyledir...",
      "pairs": [
        { "left_text": "Sol 1", "right_text": "Sağ 1" },
        { "left_text": "Sol 2", "right_text": "Sağ 2" },
        { "left_text": "Sol 3", "right_text": "Sağ 3" }
      ]
    }
  ]
}

═══════════════════════════════════════
KULLANICI GİRDİSİ
═══════════════════════════════════════

Sınıf: $gradeName
Ders: $lessonName
Ünite: $unitTitle
Konu: $topicTitle
Kazanımlar:
$outcomesText
''';
  }

  @override
  Widget build(BuildContext context) {
    IconData icon;
    String label;

    switch (promptType) {
      case AdminPromptType.content:
        icon = Icons.copy_rounded;
        label = 'İçerik Promptu';
        break;
      case AdminPromptType.questions:
        icon = Icons.quiz_outlined;
        label = 'AI Questions Prompt';
        break;
    }

    return OutlinedButton.icon(
      onPressed: () => _copyToClipboard(context),
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF2F6FE4),
        side: const BorderSide(color: Color(0xFFC8DBFF)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
