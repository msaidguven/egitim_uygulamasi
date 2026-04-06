
## Sorular Sistemi

Her konu için **iki sayfa** oluşturulur:

### 1. İçerik Sayfası
`/gunes-tutulmasi/`
- Konu anlatımı (topic_contents)
- Kazanımlar (outcomes)
- "Sorularla Pekiştir" butonu (sorular varsa)

### 2. Sorular Sayfası  
`/gunes-tutulmasi-sorular/`
- Çoktan seçmeli sorular
- JS ile interaktif çözüm
- Zorluk filtresi (1-5 yıldız)
- Doğru/yanlış feedback
- Başarı skoru
- Her 3 soruda bir reklam

### Özellikler

**Skor Takibi:**
- Toplam soru
- Doğru/yanlış sayısı
- Başarı yüzdesi

**Etkileşim:**
- Şık seçimi → anında feedback (yeşil/kırmızı)
- Çözüm açıklaması otomatik gösterilir
- Otomatik scroll (sonraki soruya)
- Zorluk seviyesi filtresi

**Sıfırlama:**
- "Sıfırla" butonu → tüm cevapları temizle
- Onay dialogu ile güvenli

### Veri Kaynağı

- `questions` → Soru metni, zorluk, çözüm
- `question_choices` → Şıklar (A, B, C, D)
- `question_usages` → Topic ilişkisi
- Sadece çoktan seçmeli sorular desteklenir

### AdSense Entegrasyonu

Her sorular sayfasında **3+ reklam:**
- Üst: 728x90
- Her 3 soruda bir: 336x280
- Alt: 728x90

**Gelir Optimizasyonu:**
- İçerik sayfası (3 reklam) + Sorular sayfası (3+ reklam) = 6+ impression
- Kullanıcı journey: İçerik oku → soru çöz → 2x sayfa görüntüleme
