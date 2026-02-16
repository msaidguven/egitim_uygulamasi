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

  Future<void> _copyToClipboard(BuildContext context) async {
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

    final String prompt;
    if (promptType == AdminPromptType.content) {
      prompt = _getContentPrompt(outcomesBuffer.toString());
    } else {
      prompt = _getQuestionsPrompt(outcomesBuffer.toString());
    }

    try {
      await Clipboard.setData(ClipboardData(text: prompt));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(promptType == AdminPromptType.content
                ? 'İçerik bilgileri kopyalandı'
                : 'Soru hazırlama promptu kopyalandı'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kopyalama hatası: $e')),
        );
      }
    }
  }

  String _getContentPrompt(String outcomesText) {
    return '''
Sen deneyimli bir öğretmen, akademik içerik yazarı, ölçme-değerlendirme uzmanı ve pedagojik tasarımcısın.  
Ortaokul ve lise seviyesinde, MEB kazanımlarına tam uyumlu, öğretici, akıcı ve derinlikli bir ders içeriği hazırlayacaksın.

Sana şu bilgileri vereceğim:

- Sınıf: $gradeName
- Ders: $lessonName
- Ünite: $unitTitle
- Konu: $topicTitle
- Kazanımlar:
$outcomesText
────────────────────────
GENEL KURALLAR
────────────────────────

1. İçerik öğrencinin seviyesine uygun olmalı.
2. Dil sade, açık ve anlaşılır olmalı.
3. Gereksiz akademik karmaşıklık olmamalı.
4. Paragraflar kısa tutulmalı (mobil uyumlu).
5. Günlük hayat örnekleri içermeli.
6. Tanımlar net ve bilimsel olarak doğru olmalı.
7. İçerik yüzeysel değil, doyurucu ve sistematik olmalı.
8. Anlatım akışı mantıksal sıraya uygun olmalı.
9. İçerik yalnızca HTML formatında olmalı.
10. Stil, CSS veya gereksiz kod yazılmamalı.

────────────────────────
PEDAGOJİK YAPI ZORUNLULUKLARI
────────────────────────

İçerik Bloom Taksonomisine uygun yapılandırılsın:

- Bilgi düzeyi
- Kavrama düzeyi
- Uygulama düzeyi
- Analiz düzeyi

Ayrıca mutlaka:

- Kavram yanılgıları bölümü eklensin.
- Günlük hayat bağlantıları kurulsun.
- 1 adet mini etkinlik eklensin.
- 1 adet kritik düşünme sorusu eklensin.
- Özet bölümü eklensin.
- Anahtar kavramlar listesi eklensin.

────────────────────────
HTML FORMAT KURALLARI
────────────────────────

Sadece şu HTML etiketleri kullanılabilir:

<title>, <section>, <h2>, <h3>, <h4>, <p>, <ul>, <ol>, <li>, <strong>

Başka etiket kullanılmamalıdır.
CSS, style veya class kullanılmamalıdır.

────────────────────────
ZORUNLU İÇERİK YAPISI
────────────────────────

<title>Konu Başlığı</title>

<section>
<h2>Giriş</h2>
<p>Konuya dikkat çekici giriş yazısı...</p>
</section>

<section>
<h2>Temel Bilgiler (Bilgi Basamağı)</h2>
<p>Temel tanımlar ve kavramlar...</p>
</section>

<section>
<h2>Kavrama ve Açıklama</h2>
<p>Detaylı açıklamalar...</p>
</section>

<section>
<h2>Günlük Hayatla İlişkilendirme</h2>
<p>Gerçek yaşam örnekleri...</p>
</section>

<section>
<h2>Uygulama Örnekleri</h2>
<p>Örnek problem veya durum...</p>
</section>

<section>
<h2>Analiz ve Derinleştirme</h2>
<p>Karşılaştırma, neden-sonuç, yorum...</p>
</section>

<section>
<h2>Kavram Yanılgıları</h2>
<ul>
<li>Yanlış inanış → Doğrusu</li>
</ul>
</section>

<section>
<h2>Mini Etkinlik</h2>
<p>Öğrencinin yapabileceği kısa uygulama...</p>
</section>

<section>
<h2>Kritik Düşünme Sorusu</h2>
<p>Düşündürücü açık uçlu soru...</p>
</section>

<section>
<h2>Özet</h2>
<p>Kısa ve net konu özeti...</p>
</section>

<section>
<h2>Anahtar Kavramlar</h2>
<ul>
<li>Kavram 1</li>
<li>Kavram 2</li>
<li>Kavram 3</li>
</ul>
</section>

<section>
<h2>Örnek Sorular</h2>
<ol>
<li>Soru 1</li>
<li>Soru 2</li>
<li>Soru 3</li>
<li>Soru 4</li>
<li>Soru 5</li>
</ol>
</section>

<section>
<h2>Cevap Anahtarı</h2>
<p>Kısa cevaplar burada belirtilmeli.</p>
</section>

────────────────────────
SON KULLANIM
────────────────────────

Şimdi aşağıdaki bilgilere göre yukarıdaki tüm kurallara uygun, eksiksiz ve yüksek kaliteli içeriği üret:

Sınıf: { $gradeName }
Ders: { $lessonName }
Ünite: { $unitTitle }
Konu: { $topicTitle }
Kazanımlar: {
$outcomesText }

Not: İçerik mobil uygulamada rahat okunabilecek şekilde hazırlanmalıdır.
''';
  }

  String _getQuestionsPrompt(String outcomesText) {
    return '''
Sen deneyimli bir ölçme-değerlendirme uzmanı ve pedagojik içerik geliştiricisisin.

Ortaokul ve lise seviyesinde, MEB kazanımlarına tam uyumlu, kavram yanılgılarını ölçebilen, düşünme becerisi geliştiren sorular üreteceksin.

Aşağıda sistemin desteklediği soru tipleri ve ID’leri verilmiştir:

- 1 = Çoktan Seçmeli
- 2 = Doğru / Yanlış
- 3 = Boşluk Doldurma (Drag & Drop)
- 5 = Eşleştirme

────────────────────────
ZORUNLU KURALLAR
────────────────────────

1. Çıktı SADECE JSON formatında olmalı.
2. JSON dışında hiçbir açıklama yazılmamalı.
3. Format kesinlikle bozulmamalı.
4. Alan isimleri değiştirilmemeli.
5. question_type_id doğru kullanılmalı.
6. difficulty değeri 1 (kolay), 2 (orta), 3 (zor) olabilir.
7. score her soru için 1 olmalı.
8. Çoktan seçmeli sorularda (ID: 1): 4 seçenek olmalı, sadece 1 doğru cevap olmalı. Format: "choices": [{"text": "...", "is_correct": bool}, ...]
9. Doğru / Yanlış sorularda (ID: 2): "correct_answer": true/false şeklinde olmalı. (choices veya blank alanı OLMAYACAK)
10. Boşluk doldurma sorularında (ID: 3): "blank": {"options": [{"text": "...", "is_correct": bool}, ...]} şeklinde olmalı. Options en az 3 seçenek içermeli, 1 tanesi doğru olmalı.
11. Eşleştirme sorularında (ID: 5): "pairs": [{"left_text": "...", "right_text": "..."}, ...] şeklinde olmalı. En az 3 eşleştirme çifti olmalı.
12. Her soru için mutlaka "solution_text" adında bir açıklama/çözüm alanı eklenmeli. Bu alanda sorunun neden o cevap olduğu ve çözüm yolu açıklanmalı.
13. Sorular kazanımlarla doğrudan ilişkili olmalı.
14. Sorular ezber değil, anlamaya dayalı olmalı.
15. En az bir soru kavram yanılgısını ölçmeli.
16. Zorluk dağılımı dengeli olmalı (kolay-orta-zor karışık).

────────────────────────
ÜRETİM YAPISI
────────────────────────

- Toplam 10 soru üret.
- Her soru için mutlaka açıklayıcı bir "solution_text" ekle.
- Soru tipleri dengeli dağıtılsın.
- Günlük hayat bağlantılı sorulara yer ver.
- En az 1 analiz düzeyi soru ekle.

────────────────────────
ŞİMDİ ŞU BİLGİLERE GÖRE ÜRET:
────────────────────────

Sınıf: { $gradeName }
Ders: { $lessonName }
Konu: { $topicTitle }
Kazanımlar: {
$outcomesText }

────────────────────────
ÇIKTI ŞU FORMATTA VE YAPIDA OLMALI:
────────────────────────

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
      "difficulty": 3,
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

JSON dışında hiçbir şey yazma.
''';
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _copyToClipboard(context),
      icon: Icon(
          promptType == AdminPromptType.content
              ? Icons.copy_rounded
              : Icons.quiz_outlined,
          size: 18),
      label: Text(promptType == AdminPromptType.content
          ? 'İçerik Promptu'
          : 'AI Questions Prompt'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF2F6FE4),
        side: const BorderSide(color: Color(0xFFC8DBFF)),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
