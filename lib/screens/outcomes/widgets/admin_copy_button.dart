import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AdminCopyButton extends StatelessWidget {
  final String gradeName;
  final String lessonName;
  final String unitTitle;
  final String topicTitle;
  final List<Map<String, dynamic>> outcomes;

  const AdminCopyButton({
    super.key,
    required this.gradeName,
    required this.lessonName,
    required this.unitTitle,
    required this.topicTitle,
    required this.outcomes,
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

    final prompt = '''
Sen deneyimli bir öğretmen, akademik içerik yazarı, ölçme-değerlendirme uzmanı ve pedagojik tasarımcısın.  
Ortaokul ve lise seviyesinde, MEB kazanımlarına tam uyumlu, öğretici, akıcı ve derinlikli bir ders içeriği hazırlayacaksın.

Sana şu bilgileri vereceğim:

- Sınıf: $gradeName
- Ders: $lessonName
- Ünite: $unitTitle
- Konu: $topicTitle
- Kazanımlar:
${outcomesBuffer.toString()}
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
${outcomesBuffer.toString()} }

Not: İçerik mobil uygulamada rahat okunabilecek şekilde hazırlanmalıdır.
''';

    try {
      await Clipboard.setData(ClipboardData(text: prompt));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Haftalık bilgiler hazır ve kopyalandı'),
            duration: Duration(seconds: 2),
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

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _copyToClipboard(context),
      icon: const Icon(Icons.copy_rounded, size: 18),
      label: const Text('Bilgileri Kopyala'),
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
