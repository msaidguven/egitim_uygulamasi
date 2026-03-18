# 📚 Ders İçeriği JSON Üretici — Prompt v2

## Görev
Aşağıda verilen ham ders metnini, Flutter mobil uygulamasında etkileşimli olarak gösterilmek üzere yapılandırılmış bir `LessonModule` JSON'una dönüştür.

## Çıktı Kuralları
- **Yalnızca geçerli JSON** döndür. Hiçbir açıklama, yorum veya markdown bloğu ekleme.
- Tüm `id` alanları benzersiz ve snake_case formatında olmalı.
- `order` alanları 1'den başlamalı.
- Quiz soruları metinden çıkarılmalı; yoksa senin tarafından üretilmeli (en az 1 quiz/bölüm).
- `kavram_yanilgisi` bloğu varsa mutlaka ekle.
- Kod bloğu varsa `language` alanını belirt.

---

## JSON Şeması

```json
{
  "lessonModule": {
    "id": "string",
    "title": "string",
    "description": "string",
    "subject": "string",
    "gradeLevel": "string",
    "language": "tr",
    "tags": ["string"],
    "estimatedMinutes": 0,
    "createdAt": "ISO8601",
    "updatedAt": "ISO8601",

    "sections": [
      {
        "id": "string",
        "order": 1,
        "title": "string",
        "subsections": [
          {
            "id": "string",
            "order": 1,
            "title": "string",
            "blocks": [
              {
                "id": "string",
                "order": 1,
                "type": "text | markdown | code | quiz | misconception",
                "content": {}
              }
            ]
          }
        ]
      }
    ]
  }
}
```

---

## Block Tipleri ve `content` Yapısı

### `text`
```json
{
  "body": "Düz metin içerik."
}
```

### `markdown`
```json
{
  "body": "## Başlık\n\nMetin, **kalın**, *italik*, listeler ve tablolar desteklenir."
}
```

### `code`
```json
{
  "language": "dart | python | js | ...",
  "filename": "ornek.dart",
  "highlightLines": [1, 3],
  "body": "void main() {\n  print('Merhaba');\n}"
}
```

### `quiz`
```json
{
  "question": "Soru metni?",
  "questionType": "single_choice | multiple_choice | true_false",
  "options": [
    { "id": "opt_a", "label": "A", "text": "Seçenek" }
  ],
  "correctOptionId": "opt_a",
  "explanation": "Doğru cevabın açıklaması."
}
```

### `misconception` *(Kavram Yanılgısı)*
```json
{
  "wrong": "Yanlış inanç.",
  "correct": "Doğru bilgi.",
  "tip": "Hatırlatıcı ipucu (opsiyonel)."
}
```

---

## Bölüm Önerileri
Metni aşağıdaki mantığa göre bölümle:

| Bölüm Başlığı | Subsection Örnekleri |
|---|---|
| Giriş & Kavramlar | Tanımlar, Anahtar Kavramlar |
| Temel Bilgiler | Açıklamalar, Örnekler |
| Uygulama | Günlük Hayat, Örnek Senaryolar |
| Analiz | Derinleştirme, Karşılaştırma |
| Değerlendirme | Quiz, Kavram Yanılgıları, Özet |

---

## Kalite Kontrol
Üretilen JSON'da şunlar mutlaka bulunmalı:
- [ ] Her bölümde en az 1 `quiz` bloğu
- [ ] En az 1 `misconception` bloğu (varsa metinde, yoksa üret)
- [ ] `estimatedMinutes` gerçekçi şekilde hesaplanmış
- [ ] Tüm `id`'ler benzersiz
- [ ] `tags` alanı dolu

---

## Girdi
Aşağıya ham ders metnini yapıştır:

```
[DERS METNİ BURAYA]
```
